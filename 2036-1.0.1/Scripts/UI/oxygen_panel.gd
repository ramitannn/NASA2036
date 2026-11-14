extends PanelContainer

@onready var oxygen_bar: ProgressBar = $VBoxContainer/ProgressBar
@onready var oxygen_label: Label = $VBoxContainer/Label

func _ready() -> void:
	# Keep the HUD in the top-right corner.
	set_anchors_preset(Control.PRESET_TOP_RIGHT)

	offset_left = -220.0
	offset_top = 20.0
	offset_right = -20.0
	offset_bottom = 85.0

	visible = true

	OxygenSystem.oxygen_changed.connect(_on_oxygen_changed)

	_on_oxygen_changed(
		OxygenSystem.current_oxygen,
		OxygenSystem.max_oxygen
	)


func _on_oxygen_changed(current: float, maximum: float) -> void:
	if maximum <= 0.0:
		return

	var percentage: float = (current / maximum) * 100.0

	oxygen_bar.max_value = maximum
	oxygen_bar.value = current

	oxygen_label.text = "OXYGEN: %d%%" % roundi(percentage)

	if percentage > 50.0:
		oxygen_bar.modulate = Color.GREEN
	elif percentage > 20.0:
		oxygen_bar.modulate = Color.YELLOW
	else:
		oxygen_bar.modulate = Color.RED
