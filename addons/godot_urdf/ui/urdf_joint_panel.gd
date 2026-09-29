extends Control

@export var robot: GodotURDFRobot


func _ready() -> void:
	if robot == null or robot.urdf_robot == null:
		push_warning("Joint panel: no robot assigned")
		return

	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_TOP_LEFT)
	scroll.custom_minimum_size = Vector2(260, 400)
	add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(240, 0)
	scroll.add_child(vbox)

	for joint in robot.urdf_robot.joints:
		if joint.type == "revolute" or joint.type == "prismatic":
			_add_position_slider(vbox, joint)
		elif joint.type == "continuous":
			_add_velocity_slider(vbox, joint)


func _add_position_slider(parent: Node, joint: URDFJoint) -> void:
	var label := Label.new()
	label.text = joint.name
	parent.add_child(label)

	var slider: HSlider = _joint_slider(joint, PI)
	slider.step = 0.01
	parent.add_child(slider)
	# Setting joint.value is all that's needed; the P controller does the work.
	slider.value_changed.connect(func(v: float): joint.value = v)


func _add_velocity_slider(parent: Node, joint: URDFJoint) -> void:
	var label: Label = Label.new()
	label.text = joint.name + " (speed)"
	parent.add_child(label)

	var slider: HSlider = _joint_slider(joint, 10)
	slider.step = 0.1
	parent.add_child(slider)
	slider.value_changed.connect(func(v: float):
		var hinge := _find_hinge(joint.name)
		if hinge:
			hinge.velocity_target = v)


func _joint_slider(joint: URDFJoint, default: float) -> HSlider:
	var slider: HSlider = HSlider.new()
	if joint.limit and joint.limit.upper > joint.limit.lower:
		slider.min_value = joint.limit.lower
		slider.max_value = joint.limit.upper
	else:
		slider.min_value = -default
		slider.max_value = default
	slider.value = joint.value
	return slider


func _find_hinge(joint_name: String) -> URDFHingeJoint3D:
	for child in robot.get_children():
		if child is URDFHingeJoint3D and child.joint and child.joint.name == joint_name:
			return child
	return null
