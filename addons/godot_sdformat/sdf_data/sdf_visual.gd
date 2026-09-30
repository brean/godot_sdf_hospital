class_name SDFVisual
# see https://sdformat.org/spec/1.12/visual/
extends SDFElement

@export var geometry: SDFGeometry = SDFGeometry.new()
@export var material: SDFMaterial = SDFMaterial.new()

func parse(parser: SDFParser):
	self.name = parser.get_named_attribute_value_safe("name")
	if parser.is_empty():
		return
	while parser.read() == OK:
		var node_type = parser.get_node_type()
		if node_type == XMLParser.NODE_ELEMENT_END:
			return
		if node_type != XMLParser.NODE_ELEMENT:
			continue
		match parser.get_node_name():
			"pose":
				self.pose.parse(parser)
			"geometry":
				self.geometry.parse(parser)
			"material":
				self.material.parse(parser)
			"cast_shadows", "laser_retro", "transparency", "visibility_flags", "meta", "plugin":
				XMLHelper.skip_unknown(parser, "visual")  # TODO
			_:
				XMLHelper.skip_unknown(parser, "visual")
