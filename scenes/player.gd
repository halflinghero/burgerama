extends CharacterBody3D

signal hit

@onready var cam_pivot = get_parent().get_node("CameraPivot")

# Persisted audio settings live in the main menu.
const SETTINGS_PATH := "user://audio_settings.cfg"

# Sound references
@onready var jump_sound = $JumpSound
@onready var eat_sound = $EatSound
@onready var hit_sound = $HitSound
@onready var land_sound = $LandSound

# Movement values
@export var speed = 14
@export var fall_acceleration = 75
@export var jump_impulse = 20
@export var bounce_impulse = 16

var was_on_floor = true

var is_knockedOut = false

var target_velocity = Vector3.ZERO
var accel = 12.0
var decel = 8.0

# Camera shake
var base_cam_pos: Vector3
var shake_time = 0.0
var shake_strength = 0.0

func _ready():
	base_cam_pos = cam_pivot.position
	apply_sound_volume_offset()

func apply_sound_volume_offset() -> void:
	# The Player scene provides default `volume_db` values per sound.
	# We store only an offset in the settings file and apply it on top of those defaults.
	var cfg := ConfigFile.new()
	var err := cfg.load(SETTINGS_PATH)
	var sound_offset_db := 0.0
	if err == OK:
		sound_offset_db = float(cfg.get_value("audio", "sound_offset_db", 0.0))

	var jump_base_db: float = jump_sound.volume_db
	var eat_base_db: float = eat_sound.volume_db
	var hit_base_db: float = hit_sound.volume_db
	var land_base_db: float = land_sound.volume_db

	jump_sound.volume_db = jump_base_db + sound_offset_db
	eat_sound.volume_db = eat_base_db + sound_offset_db
	hit_sound.volume_db = hit_base_db + sound_offset_db
	land_sound.volume_db = land_base_db + sound_offset_db

func start_camera_shake(duration, strength):
	shake_time = duration
	shake_strength = strength

func _physics_process(delta):

	# Input
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction = Vector3(input_dir.x, 0, input_dir.y)

	if direction != Vector3.ZERO:
		var target_basis = Basis.looking_at(direction)
		$Pivot.basis = $Pivot.basis.slerp(target_basis, 10 * delta)

	# Gamepad deadzone correction
	if input_dir.length() < 0.1:
		input_dir = Vector2.ZERO

	# Ground movement
	var target_speed = direction * speed
	var lerp_speed = accel if direction != Vector3.ZERO else decel
	target_velocity.x = lerp(target_velocity.x, target_speed.x, lerp_speed * delta)
	target_velocity.z = lerp(target_velocity.z, target_speed.z, lerp_speed * delta)

	# Gravity
	if not is_on_floor():
		target_velocity.y -= fall_acceleration * delta

	# Jump
	if is_on_floor() and Input.is_action_just_pressed("jump"):
		target_velocity.y = jump_impulse
		
		# 🔊 Jump sound with slight variation
		jump_sound.pitch_scale = randf_range(0.95, 1.1)
		jump_sound.play()

	# Collisions
	for index in range(get_slide_collision_count()):
		var collision = get_slide_collision(index)

		if collision.get_collider() == null:
			continue

		if collision.get_collider().is_in_group("burger"):
			var burger = collision.get_collider()

			if Vector3.UP.dot(collision.get_normal()) > 0.1:
				burger.eat()
				target_velocity.y = bounce_impulse
				
				# 🔊 Eat sound
				eat_sound.pitch_scale = randf_range(0.95, 1.05)
				eat_sound.play()
				
				start_camera_shake(0.15, 0.3)
				break

	# Tilt animation
	var vertical_tilt = PI / 6 * (velocity.y / jump_impulse)
	var horizontal_tilt = PI / 10 * (Vector2(velocity.x, velocity.z).length() / speed)
	var target_x = vertical_tilt - horizontal_tilt

	$Pivot.rotation.x = lerp_angle($Pivot.rotation.x, target_x, 20 * delta)

	# Animation speed
	if direction != Vector3.ZERO:
		$Pivot/Snom/AnimationPlayer.speed_scale = 4
	else:
		$Pivot/Snom/AnimationPlayer.speed_scale = 1

	# Move
	velocity = target_velocity
	move_and_slide()
	
	var just_landed = false

	if not was_on_floor and is_on_floor():
		for i in range(get_slide_collision_count()):
			var collision = get_slide_collision(i)
			
			if collision.get_collider() == null:
				continue
			
			# Ignore burgers
			if not collision.get_collider().is_in_group("burger"):
				just_landed = true
				break

	was_on_floor = is_on_floor()
	
	if just_landed:
		land_sound.pitch_scale = randf_range(0.7, 0.9)
		land_sound.play()

	# Camera shake
	if shake_time > 0:
		shake_time -= delta

		var fade = shake_time
		var offset = Vector3(
			randf_range(-1, 1),
			randf_range(-1, 1),
			0
		) * shake_strength * fade

		cam_pivot.position = base_cam_pos + offset
	else:
		cam_pivot.position = base_cam_pos


func knockout():
	if is_knockedOut:
		return
		
	is_knockedOut = true
	
	# Play hit sound before freeing
	hit_sound.play()
	hit.emit()
	
	visible = false
	set_physics_process(false)
	set_collision_layer(0)
	set_collision_mask(0)
	
	# Wait for sound to finish before removing player
	hit_sound.finished.connect(queue_free)


func _on_burger_detector_body_entered(_body):
	if is_on_floor():
		knockout()
