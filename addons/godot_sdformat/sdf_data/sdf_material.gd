class_name SDFMaterial
# https://sdformat.org/spec/1.12/material/
extends Resource

@export var render_order: float = 0
@export var lighting: bool = true
@export var ambient: Color = Color.WHITE
@export var diffuse: Color = Color.WHITE
@export var specular: Color = Color.WHITE
@export var shininess: float = 0.0
@export var double_sided: bool = false
@export var emissive: Color = Color.BLACK

func parse(parser: XMLParser):
	if parser.is_empty():
		return
	while parser.read() == OK:
		var node_type = parser.get_node_type()
		if node_type == XMLParser.NODE_ELEMENT_END:
			return
		if node_type != XMLParser.NODE_ELEMENT:
			continue
		match parser.get_node_name():
			"render_order":
				self.render_order = XMLHelper.text_to_float(parser, self.render_order)
			"lighting":
				self.lighting = XMLHelper.text_to_bool(parser, self.lighting)
			"ambient":
				self.ambient = XMLHelper.text_to_color(parser, self.ambient)
			"diffuse":
				self.diffuse = XMLHelper.text_to_color(parser, self.diffuse)
			"specular":
				self.specular = XMLHelper.text_to_color(parser, self.specular)
			"shininess":
				self.shininess = XMLHelper.text_to_float(parser, self.shininess)
			"double_sided":
				self.double_sided = XMLHelper.text_to_bool(parser, self.double_sided)
			"emissive":
				self.emissive = XMLHelper.text_to_color(parser, self.emissive)
			"script", "shader", "pbr":
				XMLHelper.skip_unknown(parser, "material")  # TODO
			_:
				XMLHelper.skip_unknown(parser, "material")
