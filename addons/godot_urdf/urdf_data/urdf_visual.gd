class_name URDFVisual
extends URDFGeometry

# Visual is the same as geometry but it also has material properties

@export var material_name: String
@export var material_color: Variant = null
@export var material_texture_path: String

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
				"origin":
					self.origin_xyz = XMLHelper.attr_to_vector3(parser, "xyz")
					self.origin_rpy = XMLHelper.attr_to_vector3(parser, "rpy")
				"geometry":
					URDFUtils.parse_geometry(parser, self, true)
				"material":
					self.material_name = parser.get_named_attribute_value_safe("name")
					self.material_color = URDFUtils.parse_material_color(parser, null)
				_:
					push_error(
						"[URDF] Unsupported node for Visual link: " % node_name)
					parser.skip_section()
		elif node_type == XMLParser.NODE_ELEMENT_END:
			if node_name == "visual":
				return
	return
