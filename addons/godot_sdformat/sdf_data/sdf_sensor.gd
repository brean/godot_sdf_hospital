class_name SDFSensor
# see https://sdformat.org/spec/1.12/sensor/
extends SDFElement

@export var type: String = ""  # camera, gpu_lidar, imu, ...
@export var always_on: bool = false
@export var update_rate: float = 0.0

@export var frame_id: String = ""

@export_group("Camera")
@export var horizontal_fov: float = 1.047
@export var image_size: Vector2i = Vector2i(320, 240)
@export var image_format: String = "R8G8B8"
@export var clip_near: float = 0.1
@export var clip_far: float = 100.0

# TODO: other sensors, including:
# TODO: ennable_metrics
# TODO: plugin
# TODO: air_pressure
# TODO: air_speed

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
			"frame_id":
				self.frame_id = XMLHelper.text_to_string(parser)
			"pose":
				self.pose.parse(parser)
			"always_on":
				self.always_on = XMLHelper.text_to_bool(parser, self.always_on)
			"update_rate":
				self.update_rate = XMLHelper.text_to_float(parser, self.update_rate)
			"camera":
				_parse_camera(parser)
			_:
				XMLHelper.skip_unknown(parser, "sensor")  # other sensor types, plugins, ...

func _parse_camera(parser: SDFParser):
	if parser.is_empty():
		return
	while parser.read() == OK:
		var node_type = parser.get_node_type()
		if node_type == XMLParser.NODE_ELEMENT_END:
			return
		if node_type != XMLParser.NODE_ELEMENT:
			continue
		match parser.get_node_name():
			"horizontal_fov":
				self.horizontal_fov = XMLHelper.text_to_float(parser, self.horizontal_fov)
			"image":
				_parse_image(parser)
			"clip":
				_parse_clip(parser)
			_:
				XMLHelper.skip_unknown(parser, "camera")  # noise, distortion, lens, ...

func _parse_image(parser: SDFParser):
	if parser.is_empty():
		return
	while parser.read() == OK:
		var node_type = parser.get_node_type()
		if node_type == XMLParser.NODE_ELEMENT_END:
			return
		if node_type != XMLParser.NODE_ELEMENT:
			continue
		match parser.get_node_name():
			"width":
				self.image_size.x = XMLHelper.text_to_int(parser, self.image_size.x)
			"height":
				self.image_size.y = XMLHelper.text_to_int(parser, self.image_size.y)
			"format":
				self.image_format = XMLHelper.text_to_string(parser)
			_:
				XMLHelper.skip_unknown(parser, "image")

func _parse_clip(parser: SDFParser):
	if parser.is_empty():
		return
	while parser.read() == OK:
		var node_type = parser.get_node_type()
		if node_type == XMLParser.NODE_ELEMENT_END:
			return
		if node_type != XMLParser.NODE_ELEMENT:
			continue
		match parser.get_node_name():
			"near":
				self.clip_near = XMLHelper.text_to_float(parser, self.clip_near)
			"far":
				self.clip_far = XMLHelper.text_to_float(parser, self.clip_far)
			_:
				XMLHelper.skip_unknown(parser, "clip")
