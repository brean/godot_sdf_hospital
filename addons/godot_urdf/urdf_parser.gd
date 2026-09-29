@tool
class_name URDFXMLParser
extends XMLParser

func as_node3d(
		source_path: String,
		options: URDFOptions,
		parent_node: Node3D,
		owner_node: Node3D) -> GodotURDFRobot:
	var start_time = Time.get_ticks_msec()
	var robot: URDFRobot = parse(source_path)
	if source_path.begins_with("uid://"):
		var id = ResourceUID.text_to_id(source_path)
		source_path = ResourceUID.get_id_path(id)
	print("[URDF] Parsing %s" % source_path)
	if not robot:
		push_error("[URDF] No URDFRobot given")
		return null

	# Note that we have one root node that we will use to represent the URDF
	# tree structure, the robots collision and visual elements
	# are connected to this as well, NOT to their parents in the URDF
	# structure!
	var robot_node = GodotURDFRobot.new()
	var success = robot_node.to_godot(
		robot, parent_node, owner_node, options, source_path)

	var now = Time.get_ticks_msec()
	var elapsed = (now - start_time) / 1000.0
	if success:
		print(
			"[URDF] Done generating robot without errors, took: %f" % elapsed)
	else:
		print(
			"[URDF] Done but got errors during robot generation, took: %f" %
			elapsed)
	return robot_node

func parse(source_path: String) -> URDFRobot:
	var parser = XMLParser.new()
	var err = parser.open(source_path)
	if err != OK:
		push_error("[URDF] Failed to open URDF file: %s" % source_path)
		return null

	var robot = URDFRobot.new()
	while parser.read() == OK:
		var node_type = parser.get_node_type()
		if node_type == XMLParser.NODE_TEXT: continue # Skip whitespace
		
		if node_type == XMLParser.NODE_ELEMENT:
			if parser.get_node_name() == "robot":
				robot.parse(parser)
				
	return robot
