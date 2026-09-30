class_name SDFScene
# see https://sdformat.org/spec/1.12/scene/
extends Resource

@export var ambient: Color = Color(0.5, 0.5, 0.5, 1.0)
@export var background: Color = Color.BLACK
@export var shadows: bool = true
# TODO: sky
# TODO: fog

func parse(parser: SDFParser):
	if parser.is_empty():
		return
	while parser.read() == OK:
		var node_type = parser.get_node_type()
		if node_type == XMLParser.NODE_ELEMENT_END:
			return
		if node_type != XMLParser.NODE_ELEMENT:
			continue
		match parser.get_node_name():
			"ambient":
				self.ambient = XMLHelper.text_to_color(parser, self.ambient)
			"background":
				self.background = XMLHelper.text_to_color(parser, self.background)
			"shadows":
				self.shadows = XMLHelper.text_to_bool(parser, self.shadows)
			"grid", "origin_visual", "sky", "fog":
				XMLHelper.skip_unknown(parser, "scene")  # TODO
			_:
				XMLHelper.skip_unknown(parser, "scene")
