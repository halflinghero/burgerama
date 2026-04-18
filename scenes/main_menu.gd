extends Control

signal play_game_requested

const SETTINGS_PATH := "user://audio_settings.cfg"

@onready var settings_panel: Control = $SettingsPanel
@onready var versus_info: Label = $Content/Buttons/VersusInfo
@onready var music_slider: HSlider = $SettingsPanel/SettingsPanelVBox/MusicSlider
@onready var sound_slider: HSlider = $SettingsPanel/SettingsPanelVBox/SoundSlider
@onready var settings_back_button: Button = $SettingsPanel/SettingsPanelVBox/BackButton

func _ready() -> void:
	# Load persisted audio settings (if any).
	var cfg := ConfigFile.new()
	var err := cfg.load(SETTINGS_PATH)
	var music_volume_db := -6.0
	var sound_offset_db := 0.0
	if err == OK:
		music_volume_db = float(cfg.get_value("audio", "music_volume_db", music_volume_db))
		sound_offset_db = float(cfg.get_value("audio", "sound_offset_db", sound_offset_db))

	# Initialize UI.
	music_slider.value = music_volume_db
	sound_slider.value = sound_offset_db
	settings_panel.visible = false
	versus_info.visible = false

	# Apply music immediately (MusicPlayer is an autoload).
	var music_player := get_node_or_null("/root/MusicPlayer")
	if music_player:
		music_player.volume_db = music_volume_db

	# Wire buttons.
	$Content/Buttons/PlayButton.pressed.connect(_on_play_pressed)
	$Content/Buttons/VersusButton.pressed.connect(_on_versus_pressed)
	$Content/Buttons/SettingsButton.pressed.connect(_on_settings_pressed)
	$Content/Buttons/QuitButton.pressed.connect(_on_quit_pressed)
	settings_back_button.pressed.connect(_on_settings_back_pressed)

	# Wire sliders.
	music_slider.value_changed.connect(_on_music_volume_changed)
	sound_slider.value_changed.connect(_on_sound_offset_changed)

	# Ensure sliders start by saving if file was missing.
	_save_audio_settings(music_slider.value, sound_slider.value)

func _save_audio_settings(music_volume_db: float, sound_offset_db: float) -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "music_volume_db", music_volume_db)
	cfg.set_value("audio", "sound_offset_db", sound_offset_db)
	cfg.save(SETTINGS_PATH)

func _on_play_pressed() -> void:
	emit_signal("play_game_requested")

func _on_versus_pressed() -> void:
	settings_panel.visible = false
	versus_info.text = "Versus mode not implemented yet."
	versus_info.visible = true

func _on_settings_pressed() -> void:
	versus_info.visible = false
	settings_panel.visible = !settings_panel.visible

func _on_settings_back_pressed() -> void:
	settings_panel.visible = false

func _on_quit_pressed() -> void:
	get_tree().quit()

func _on_music_volume_changed(value: float) -> void:
	var music_player := get_node_or_null("/root/MusicPlayer")
	if music_player:
		music_player.volume_db = value
	_save_audio_settings(value, sound_slider.value)

func _on_sound_offset_changed(value: float) -> void:
	# Sound volume is applied by `player.gd` when the Player scene is ready.
	_save_audio_settings(music_slider.value, value)

