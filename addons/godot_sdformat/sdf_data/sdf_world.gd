class_name SDFWorld
# see https://sdformat.org/spec/1.12/world/
extends SDFElement

# for now we ignore audio

@export var wind: SDFWind

@export var includes: Array[String] = []
@export var gravity: Vector3 = Vector3(0, 0, -9.81)
@export var magnetic_field: Vector3 = Vector3(5.5645e-6, 2.28758e-5, -4.23884e-5)

# for now we ignore atmosphere for now
# for now we ignore gui
@export var physics: SDFPhysics = SDFPhysics.new()
@export var scene: SDFScene = SDFScene.new()

var lights: Dictionary = {}  # name -> SDFLight
# TODO: frame

@export var joint: SDFJoint
@export var model: SDFModel
@export var actor: SDFActor
@export var plugins: Array[SDFPlugin] = []
# for now we ignore road
# for now we ignore spherical_coordinates
# for now we ignore state
# for now we ignore population

func parse(parser: SDFParser):
	var _name = parser.get_named_attribute_value_safe("name")
	if not _name:
		_name = "World"
	self.name = _name

	if parser.is_empty():
		return

	while parser.read() == OK:
		var node_type = parser.get_node_type()
		if node_type == XMLParser.NODE_ELEMENT_END:
			return
		if node_type != XMLParser.NODE_ELEMENT:
			continue
		match parser.get_node_name():
			"physics":
				self.physics = parse_physics(parser)
			"plugin":
				self.plugins.append(parse_plugin(parser))
			"model":
				var model = SDFModel.new()
				model.parse(parser)
				self.model = model
			"include":
				var include = SDFInclude.new()
				include.parse(parser)
				var element = include.instantiate(parser)
				if element is SDFModel:
					self.models.append(element)
				# TODO: included actors and lights
			_:
				XMLHelper.skip_unknown(parser, "world")

func parse_physics(parser):
	var physics = SDFPhysics.new()
	physics.parse(parser)
	return physics

func parse_plugin(parser):
	var plugin = SDFPlugin.new()
	plugin.parse(parser)
	return plugin

func add_light(light: SDFLight) -> void:
	lights[light.name] = light
