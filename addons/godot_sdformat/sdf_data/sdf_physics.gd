class_name SDFPhysics
# see https://sdformat.org/spec/1.12/physics/
extends Resource

# we ignore the engine and just use Jolt
enum EngineType { ODE, BULLET, SIMBODY, DART, CUSTOM }

@export var engine: EngineType = EngineType.CUSTOM  # aka type
@export var max_step_size: float = 0.001
@export var real_time_factor: float = 1.0
@export var real_time_update_rate: float = 1000.0

func apply_to_world(world_node: Node):
	return
	# ProjectSettings.set_setting(
	# 	"physics/3d/default_gravity_vector", Vector3(0,-1,0))
	# get_tree().call_group("gravity_change", "gravity_changed")

func parse(parser: XMLParser):
	match parser.get_named_attribute_value_safe("type").to_lower():
		"ode": self.engine = EngineType.ODE
		"bullet": self.engine = EngineType.BULLET
		"simbody": self.engine = EngineType.SIMBODY
		"dart": self.engine = EngineType.DART
		_: self.engine = EngineType.CUSTOM
	if parser.is_empty():
		return
	while parser.read() == OK:
		var node_type = parser.get_node_type()
		if node_type == XMLParser.NODE_ELEMENT_END:
			return
		if node_type != XMLParser.NODE_ELEMENT:
			continue
		match parser.get_node_name():
			"max_step_size":
				self.max_step_size = XMLHelper.text_to_float(parser, self.max_step_size)
			"real_time_factor":
				self.real_time_factor = XMLHelper.text_to_float(parser, self.real_time_factor)
			"real_time_update_rate":
				self.real_time_update_rate = XMLHelper.text_to_float(parser, self.real_time_update_rate)
			_:
				# TODO: ode ... and its specifics translated to jolt?
				XMLHelper.skip_unknown(parser, "physics")
