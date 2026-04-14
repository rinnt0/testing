class_name ChoiceMaker extends Node

@export var label: String = "Examine"
@export var icon: Texture2D

@export_group("Visibility Condition")
@export var requires_flag: bool = false
@export var flag_name: String = ""
@export var flag_value: bool = true  # show when flag equals this value
