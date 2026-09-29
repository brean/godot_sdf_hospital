class_name SDFFrame
# see https://sdformat.org/spec/1.12/model/#model_frame
extends SDFElement

@export var attached_to: String = ""

func parse(parser: SDFParser):
	self.name = parser.get_named_attribute_value_safe("name")
	self.attached_to = parser.get_named_attribute_value_safe("attached_to")
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
			_:
				XMLHelper.skip_unknown(parser, "frame")
