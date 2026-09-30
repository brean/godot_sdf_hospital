class_name SDFModel
# see https://sdformat.org/spec/1.12/model/
extends SDFElement

@export var model_namespace: String = ""
@export var canonical_link: String = ""
@export var placement_frame: String = ""
@export var static_model: bool = false
@export var self_collide: bool = false
@export var allow_auto_disable: bool = true
@export var enable_wind: bool = false

# include missing?
@export var frames: Array[SDFFrame] = []
@export var links: Array[SDFLink] = []
@export var joints: Array[SDFJoint] = []
@export var models: Array[SDFModel] = []  # nested and included models
@export var plugins: Array[SDFPlugin] = []
# for now we ignore gripper and model_state
# TODO: gripper
# TODO: model_state

func parse(parser: XMLParser):
	var _name = parser.get_named_attribute_value_safe("name")
	if not _name:
		_name = "UnnamedModel"
	self.name = _name
	self.model_namespace = parser.get_named_attribute_value_safe("namespace")
	self.canonical_link = parser.get_named_attribute_value_safe("canonical_link")
	self.placement_frame = parser.get_named_attribute_value_safe("placement_frame")
	if parser.is_empty():
		return

	while parser.read() == OK:
		var node_type = parser.get_node_type()
		if node_type == XMLParser.NODE_ELEMENT_END:
			return
		if node_type != XMLParser.NODE_ELEMENT:
			continue
		match parser.get_node_name():
			"static":
				self.static_model = XMLHelper.text_to_bool(
					parser, self.static_model)
			"self_collide":
				self.self_collide = XMLHelper.text_to_bool(
					parser, self.self_collide)
			"allow_auto_disable":
				self.allow_auto_disable = XMLHelper.text_to_bool(
					parser, self.allow_auto_disable)
			"enable_wind":
				self.enable_wind = XMLHelper.text_to_bool(
					parser, self.enable_wind)
			"pose":
				self.pose.parse(parser)
			"frame":
				var frame = SDFFrame.new()
				frame.parse(parser)
				self.frames.append(frame)
			"link":
				var link = SDFLink.new()
				link.parse(parser)
				self.links.append(link)
			"joint":
				var joint = SDFJoint.new()
				joint.parse(parser)
				self.joints.append(joint)
			"plugin":
				var plugin = SDFPlugin.new()
				plugin.parse(parser)
				self.plugins.append(plugin)
			"include":
				_parse_include(parser)
			"model":
				var model = SDFModel.new()
				model.parse(parser)
				self.models.append(model)
			"gripper", "model_state":
				XMLHelper.skip_unknown(parser, "model")
			_:
				XMLHelper.skip_unknown(parser, "model")

func _parse_include(parser: SDFParser):
	var include = SDFInclude.new()
	include.parse(parser)
	var element = include.instantiate(parser)
	if element == null:
		return
	if element is not SDFModel:
		push_error("<include> inside <model> must reference a model: " + include.uri)
		return
	# TODO: include.merge (add the children to this model instead)
	self.models.append(element)
