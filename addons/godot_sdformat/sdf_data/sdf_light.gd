class_name SDFLight
# see https://sdformat.org/spec/1.12/light/
extends SDFElement

@export var type: String = "point"  # point, directional, spot
@export var cast_shadows: bool = false
@export var intensity: float = 1.0
@export var diffuse: Color = Color.WHITE
@export var specular: Color = Color(0.1, 0.1, 0.1, 1.0)
@export var direction: Vector3 = Vector3(0, 0, -1)  # directional and spot

@export_group("Attenuation")
@export var attenuation_range: float = 10.0
@export var attenuation_constant: float = 1.0
@export var attenuation_linear: float = 1.0
@export var attenuation_quadratic: float = 0.0

@export_group("Spot")
@export var spot_inner_angle: float = 0.0
@export var spot_outer_angle: float = 0.0
@export var spot_falloff: float = 0.0

# Light3D shines along -z, in SDF along direction, in the frame of the pose.
func to_godot_transform3d() -> Transform3D:
	var transform = pose.to_godot_transform3d()
	if type == "point":
		return transform
	var godot_direction = (URDFUtils.URDF_TO_GODOT * direction).normalized()
	var up = Vector3.UP
	if abs(godot_direction.dot(up)) > 0.999:
		up = Vector3.FORWARD  # looking_at fails for parallel vectors
	transform.basis = transform.basis * Basis.looking_at(godot_direction, up)
	return transform

func parse(parser: SDFParser):
	self.name = parser.get_named_attribute_value_safe("name")
	self.type = parser.get_named_attribute_value_safe("type")
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
			"cast_shadows":
				self.cast_shadows = XMLHelper.text_to_bool(parser, self.cast_shadows)
			"intensity":
				self.intensity = XMLHelper.text_to_float(parser, self.intensity)
			"diffuse":
				self.diffuse = XMLHelper.text_to_color(parser, self.diffuse)
			"specular":
				self.specular = XMLHelper.text_to_color(parser, self.specular)
			"direction":
				self.direction = XMLHelper.text_to_vector3(parser, self.direction)
			"attenuation":
				_parse_attenuation(parser)
			"spot":
				_parse_spot(parser)
			"light_on", "visualize":
				XMLHelper.skip_unknown(parser, "light")  # TODO
			_:
				XMLHelper.skip_unknown(parser, "light")

func _parse_attenuation(parser: SDFParser):
	if parser.is_empty():
		return
	while parser.read() == OK:
		var node_type = parser.get_node_type()
		if node_type == XMLParser.NODE_ELEMENT_END:
			return
		if node_type != XMLParser.NODE_ELEMENT:
			continue
		match parser.get_node_name():
			"range":
				self.attenuation_range = XMLHelper.text_to_float(parser, self.attenuation_range)
			"constant":
				self.attenuation_constant = XMLHelper.text_to_float(parser, self.attenuation_constant)
			"linear":
				self.attenuation_linear = XMLHelper.text_to_float(parser, self.attenuation_linear)
			"quadratic":
				self.attenuation_quadratic = XMLHelper.text_to_float(parser, self.attenuation_quadratic)
			_:
				XMLHelper.skip_unknown(parser, "attenuation")

func _parse_spot(parser: SDFParser):
	if parser.is_empty():
		return
	while parser.read() == OK:
		var node_type = parser.get_node_type()
		if node_type == XMLParser.NODE_ELEMENT_END:
			return
		if node_type != XMLParser.NODE_ELEMENT:
			continue
		match parser.get_node_name():
			"inner_angle":
				self.spot_inner_angle = XMLHelper.text_to_float(parser, self.spot_inner_angle)
			"outer_angle":
				self.spot_outer_angle = XMLHelper.text_to_float(parser, self.spot_outer_angle)
			"falloff":
				self.spot_falloff = XMLHelper.text_to_float(parser, self.spot_falloff)
			_:
				XMLHelper.skip_unknown(parser, "spot")
