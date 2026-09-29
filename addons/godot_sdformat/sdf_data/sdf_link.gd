class_name SDFLink
# see https://sdformat.org/spec/1.12/link/
extends SDFElement

@export var gravity: bool = true
@export var enable_wind: bool = false
@export var self_collide: bool = false
@export var kinematic: bool = false
@export var must_be_base_link: bool = false
@export var velocity_decay_linear: float = 0
@export var velocity_decay_angular: float = 0
@export var inertial: Dictionary = {}
@export var collision: Array[SDFCollision] = []
@export var visual: Array[SDFVisual] = []
# TODO: sensor
# TODO: projector
# TODO: battery
# TODO: light
# TODO: particle_emitter

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
			"gravity":
				self.gravity = XMLHelper.text_to_bool(parser, self.gravity)
			"enable_wind":
				self.enable_wind = XMLHelper.text_to_bool(parser, self.enable_wind)
			"self_collide":
				self.self_collide = XMLHelper.text_to_bool(parser, self.self_collide)
			"kinematic":
				self.kinematic = XMLHelper.text_to_bool(parser, self.kinematic)
			"must_be_base_link":
				self.must_be_base_link = XMLHelper.text_to_bool(parser, self.must_be_base_link)
			"pose":
				self.pose.parse(parser)
			"collision":
				var collision = SDFCollision.new()
				collision.parse(parser)
				self.collision.append(collision)
			"visual":
				var visual = SDFVisual.new()
				visual.parse(parser)
				self.visual.append(visual)
			"inertial", "velocity_decay", "sensor", "projector", "audio_sink", "audio_source", "battery", "light", "particle_emitter":
				parser.skip_section()  # TODO
			_:
				XMLHelper.skip_unknown(parser, "link")
