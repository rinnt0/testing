extends PanelContainer

func setup(label: String, icon: Texture2D):
	$HBoxContainer/Label.text = label
	if icon:
		$HBoxContainer/Icon.texture = icon
