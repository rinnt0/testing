class_name ToastContent extends Node

enum Timing { START, END }

@export var timing: Timing = Timing.END
@export var header_text: String = "Picked Up"
@export var icon: Texture2D
@export var item_name: String = "Item Name"
