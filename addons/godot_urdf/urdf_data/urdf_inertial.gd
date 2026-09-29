class_name URDFInertial
extends Resource

@export var mass: float = 1.0 # Default to 1kg if missing to prevent physics errors
@export var inertia_tensor: Dictionary = {} # (Optional)
@export var origin_xyz: Vector3
@export var origin_rpy: Vector3

func parse(parser: XMLParser):
	if parser.is_empty():
		return
	while parser.read() == OK:
		var node_type = parser.get_node_type()
		if node_type == XMLParser.NODE_TEXT:
			continue
		var node_name = parser.get_node_name() 
		if node_type == XMLParser.NODE_ELEMENT:
			match node_name:
				"mass":
					self.mass = XMLHelper.attr_to_float(parser, "value")
				"origin":
					self.origin_xyz = XMLHelper.attr_to_vector3(parser, "xyz")
					self.origin_rpy = XMLHelper.attr_to_vector3(parser, "rpy")
				"inertia":
					self.inertia_tensor = parse_inertia(parser)
				_:
					XMLHelper.skip_unknown(parser, node_name)
		elif node_type == XMLParser.NODE_ELEMENT_END:
			if node_name == "inertial":
				return
	return

func parse_inertia(parser: XMLParser) -> Dictionary:
	var inertia = {}
	for idx in range(parser.get_attribute_count()):
		var attr_name = parser.get_attribute_name(idx)
		var attr_value = parser.get_attribute_value(idx)
		if attr_value.is_valid_float():
			inertia[attr_name] = float(attr_value)
	return inertia
