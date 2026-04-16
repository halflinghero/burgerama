extends Node

@export var burger_scene: PackedScene

func _ready():
	$UserInterface/Retry.hide()

func _on_burger_timer_timeout():
# Create a new instance of the Burger scene.
	var burger = burger_scene.instantiate()

	# Choose a random location on the SpawnPath.
	# We store the reference to the SpawnLocation node.
	var burger_spawn_location = get_node("SpawnPath/SpawnLocation")
	# And give it a random offset.
	burger_spawn_location.progress_ratio = randf()

	var player_position = $Player.position
	burger.initialize(burger_spawn_location.position, player_position)

	# Spawn the burger by adding it to the Main scene.
	add_child(burger)

	# Connecting burger to score label to update value
	burger.eaten.connect($UserInterface/ScoreLabel._on_burger_eaten.bind())

func _on_player_hit():
	$BurgerTimer.stop()
	$UserInterface/Retry.show()

func _unhandled_input(event):
	if event.is_action_pressed("ui_accept") and $UserInterface/Retry.visible:
		# This restarts the current scene.
		get_tree().reload_current_scene()
