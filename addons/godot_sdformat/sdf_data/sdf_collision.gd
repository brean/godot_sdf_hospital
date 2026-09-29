class_name SDFCollision
# see https://sdformat.org/spec/1.12/collision/
extends SDFElement

@export var laser_retro: float = 0.0
@export var max_contacts: int = 10
@export var density: float = 1000.0
@export var geometry: SDFGeometry = SDFGeometry.new()
@export var surface: SDFSurface = null  # null: physics engine defaults

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
			"laser_retro":
				self.laser_retro = XMLHelper.text_to_float(parser, self.laser_retro)
			"max_contacts":
				self.max_contacts = XMLHelper.text_to_int(parser, self.max_contacts)
			"density":
				self.density = XMLHelper.text_to_float(parser, self.density)
			"pose":
				self.pose.parse(parser)
			"geometry":
				self.geometry.parse(parser)
			"surface":
				self.surface = SDFSurface.new()
				self.surface.parse(parser)
			"auto_inertia_params":
				parser.skip_section()
			_:
				XMLHelper.skip_unknown(parser, "collision")
