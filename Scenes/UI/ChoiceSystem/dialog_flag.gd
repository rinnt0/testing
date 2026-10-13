class_name DialogFlag extends Node

enum DeleteMode { NO, CHOICE_MAKER, CHOICE_BRIDGE }

@export var set_flag_on_complete: bool = false
@export var flag_name: String = ""
@export var flag_value: bool = true
@export var delete_after_interaction: DeleteMode = DeleteMode.NO
