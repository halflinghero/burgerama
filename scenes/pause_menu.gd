extends Control

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if not event.is_action_pressed("ui_cancel"):
		return
	var main := get_parent()
	if main and main.has_method("_resume_from_pause"):
		main._resume_from_pause()
	get_viewport().set_input_as_handled()
