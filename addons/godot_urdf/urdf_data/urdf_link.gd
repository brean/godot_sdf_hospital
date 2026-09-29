class_name URDFLink
extends Resource

@export var name: String
@export var visuals: Array[URDFVisual] = [] 
@export var colliders: Array[URDFGeometry] = [] 
@export var inertial: URDFInertial

func parse(parser: XMLParser):
	self.name = parser.get_named_attribute_value_safe("name")
	if parser.is_empty():
		return
	while parser.read() == OK:
		var node_type = parser.get_node_type()
		if node_type == XMLParser.NODE_TEXT:
			continue
		var node_name = parser.get_node_name()
		if node_type == XMLParser.NODE_ELEMENT:
			match node_name:
				"visual":
					var visual = URDFVisual.new()
					visual.parse(parser)
					self.visuals.append(visual)
				"collision":
					var collider = URDFGeometry.new()
					collider.parse_collision(parser)
					self.colliders.append(collider)
				"inertial":
					self.inertial = URDFInertial.new()
					self.inertial.parse(parser)
				_:
					parser.skip_section()
					push_error(
						"[URDF] Unsupported Tag in Link: " % node_type)
		elif node_type == XMLParser.NODE_ELEMENT_END:
			if node_name == "link":
				return
	return