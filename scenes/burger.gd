extends CharacterBody3D

# Emitted when the player jumped on the burger.
signal eaten

# Minimum speed of the mob in meters per second.
@export var min_speed = 10
# Maximum speed of the mob in meters per second.
@export var max_speed = 18


# This function will be called from the Main scene.
func initialize(start_position, player_position):

	# We position the burger by placing it at start_position
	# and rotate it towards player_position, so it looks at the player.
	look_at_from_position(start_position, player_position, Vector3.UP)
	# Rotate this burger randomly within range of -45 and +45 degrees,
	# so that it doesn't move directly towards the player.
	rotate_y(randf_range(-PI / 4, PI / 4))

		# We calculate a random speed (integer)
	var random_speed = randi_range(min_speed, max_speed)
	# We calculate a forward velocity that represents the speed.
	velocity = Vector3.FORWARD * random_speed
	# We then rotate the velocity vector based on the burger's Y rotation
	# in order to move in the direction the burger is looking.
	velocity = velocity.rotated(Vector3.UP, rotation.y)
	
	$Pivot/AnimationPlayer.speed_scale = random_speed / min_speed

func _physics_process(_delta):

	# Lock rotation so it never tilts
	rotation.x = 0
	rotation.z = 0
	move_and_slide()

	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i)
		
		if collision.get_collider() == null:
			continue
			
		# Only react to other burgers
		if collision.get_collider().is_in_group("burger"):
			var normal = collision.get_normal()
			
			# Reflect velocity (bounce)
			velocity = velocity.bounce(normal)
			
			# Keep speed consistent
			velocity = velocity.normalized() * randf_range(min_speed, max_speed)

func eat():

	eaten.emit()
	queue_free()

func _on_burger_vis_notifier_screen_exited():

	queue_free()
