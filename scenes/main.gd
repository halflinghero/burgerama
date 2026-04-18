extends Node

@export var burger_scene: PackedScene

@onready var main_menu: Control = $MainMenu
@onready var player: Node = $Player
@onready var pause_menu: Control = $PauseMenu

const META_SKIP_MENU_ON_RELOAD := "skip_main_menu_on_reload"

func _ready():
	$UserInterface/Retry.hide()
	pause_menu.hide()
	if not main_menu.play_game_requested.is_connected(_on_main_menu_play_game_requested):
		main_menu.play_game_requested.connect(_on_main_menu_play_game_requested)
	$PauseMenu/Panel/PauseMenuVBox/ResumeButton.pressed.connect(_on_pause_resume_pressed)
	$PauseMenu/Panel/PauseMenuVBox/QuitToMenuButton.pressed.connect(_on_pause_quit_to_menu_pressed)
	$PauseMenu/Panel/PauseMenuVBox/QuitToDesktopButton.pressed.connect(_on_pause_quit_to_desktop_pressed)

	# Allow the menu to show only on the first load.
	# When the player uses Retry (scene reload), we start the game immediately.
	var should_skip_menu := false
	if get_tree().root.has_meta(META_SKIP_MENU_ON_RELOAD):
		should_skip_menu = bool(get_tree().root.get_meta(META_SKIP_MENU_ON_RELOAD))

	if should_skip_menu:
		_start_game()
	else:
		_show_main_menu()

func _show_main_menu() -> void:
	get_tree().paused = false
	$BurgerTimer.stop()
	player.set_physics_process(false)
	$UserInterface.hide()
	pause_menu.hide()
	main_menu.show()

func _start_game() -> void:
	get_tree().paused = false
	main_menu.hide()
	pause_menu.hide()
	$UserInterface.show()
	if player.has_method("apply_sound_volume_offset"):
		player.apply_sound_volume_offset()
	player.set_physics_process(true)
	$BurgerTimer.start()

func _on_main_menu_play_game_requested() -> void:
	get_tree().root.set_meta(META_SKIP_MENU_ON_RELOAD, true)
	_start_game()

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
	if event.is_action_pressed("ui_cancel") and not main_menu.visible:
		if pause_menu.visible:
			_resume_from_pause()
		else:
			_open_pause_menu()
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("ui_accept") and $UserInterface/Retry.visible:
		# This restarts the current scene.
		get_tree().reload_current_scene()

func _open_pause_menu() -> void:
	if main_menu.visible:
		return
	pause_menu.show()
	$UserInterface.hide()
	get_tree().paused = true

func _resume_from_pause() -> void:
	pause_menu.hide()
	$UserInterface.show()
	get_tree().paused = false

func _on_pause_resume_pressed() -> void:
	_resume_from_pause()

func _on_pause_quit_to_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().root.set_meta(META_SKIP_MENU_ON_RELOAD, false)
	get_tree().reload_current_scene()

func _on_pause_quit_to_desktop_pressed() -> void:
	get_tree().paused = false
	get_tree().quit()
