class_name ChoiceMaker extends Node

@export var label: String = "Examine"
@export var icon: Texture2D

@export_group("Visibility Condition")
@export var requires_flag: bool = false
@export var flag_name: String = ""
@export var flag_value: bool = true  # show when flag equals this value
## Additional flags, ALL must match too (flag name -> required value)
@export var extra_flags: Dictionary[String, bool] = {}

func conditions_met() -> bool:
	if not requires_flag:
		return true
	if PersistentData.get_flag(flag_name) != flag_value:
		return false
	for f in extra_flags:
		if PersistentData.get_flag(f) != extra_flags[f]:
			return false
	return true
