class_name SDFRoot
# see https://sdformat.org/spec/1.12/sdf/
extends Resource

@export var filename: String
@export var version: String = "1.12"
@export var worlds: Array[SDFWorld] = []
@export var model: SDFModel = null
@export var actor: SDFActor = null
@export var light: SDFLight = null


func get_version_parts() -> Dictionary:
	var parts = version.split(".")
	if parts.size() >= 2:
		return {
			"major": int(parts[0]),
			"minor": int(parts[1])
		}
	return {"major": 1, "minor": 0}

func parse(parser: SDFParser):
	if parser.is_empty():
		return
	while parser.read() == OK:
		var node_type = parser.get_node_type()
		if node_type == XMLParser.NODE_ELEMENT_END:
			return
		if node_type != XMLParser.NODE_ELEMENT:
			continue

		var node_name = parser.get_node_name()
		var element_name = node_name.to_lower()
		match parser.get_node_name():
			"world":
				var world = SDFWorld.new()
				world.parse(parser)
				self.worlds.append(world)
			"model":
				error_if_set(self.model, "model")
				self.model = SDFModel.new()
				self.model.parse(parser)
			"actor":
				error_if_set(self.actor, "actor")
				self.actor = SDFActor.new()
				self.actor.parse(parser)
			"light":
				error_if_set(self.light, "light")
				self.light = SDFLight.new()
				self.light.parse(parser)
			_:
				XMLHelper.skip_unknown(parser, "sdf")

func error_if_set(existing: Resource, tag: String) -> void:
	if existing:
		push_error("Only one <%s> is allowed directly in <sdf>, using the last one" % tag)
