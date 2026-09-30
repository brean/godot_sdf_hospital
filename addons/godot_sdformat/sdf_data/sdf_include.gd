class_name SDFInclude
# see https://sdformat.org/spec/1.12/world/#world_include
# and https://sdformat.org/spec/1.12/model/#model_include
extends SDFElement

@export var uri: String = ""
@export var merge: bool = false
@export var model_namespace: String = ""
@export var has_static: bool = false
@export var static_model: bool = false
@export var has_pose: bool = false
@export var placement_frame: String = ""
@export var plugins: Array[SDFPlugin] = []

func parse(parser: XMLParser):
	self.merge = XMLHelper.attr_to_bool(parser, "merge")
	if parser.is_empty():
		return
	while parser.read() == OK:
		var node_type = parser.get_node_type()
		if node_type == XMLParser.NODE_ELEMENT_END:
			return
		if node_type != XMLParser.NODE_ELEMENT:
			continue
		match parser.get_node_name():
			"uri":
				self.uri = XMLHelper.text_to_string(parser)
			"name":
				self.name = XMLHelper.text_to_string(parser)
			"namespace":
				self.model_namespace = XMLHelper.text_to_string(parser)
			"static":
				self.has_static = true
				self.static_model = XMLHelper.text_to_bool(parser, self.static_model)
			"pose":
				self.has_pose = true
				self.pose.parse(parser)
			"placement_frame":
				self.placement_frame = XMLHelper.text_to_string(parser)
			"plugin":
				var plugin = SDFPlugin.new()
				plugin.parse(parser)
				self.plugins.append(plugin)
			"model_state":
				XMLHelper.skip_unknown(parser, "include")
			_:
				XMLHelper.skip_unknown(parser, "include")

func instantiate(parser: SDFParser) -> SDFElement:
	if self.uri.is_empty():
		push_error("<include> without <uri>")
		return null
	var path = parser.resolve_include_file(self.uri)
	if path.is_empty():
		return null
	var root = parser.load_file(path)
	if root == null:
		return null

	var element: SDFElement = null
	if root.model:
		element = root.model
	elif root.actor:
		element = root.actor
	elif root.light:
		element = root.light
	else:
		push_error("Included file contains no model, actor or light: " + path)
		return null

	if not self.name.is_empty():
		element.name = self.name
	if self.has_pose:
		element.pose = self.pose
	if element is SDFModel:
		if self.has_static:
			element.static_model = self.static_model
		if not self.model_namespace.is_empty():
			element.model_namespace = self.model_namespace
		if not self.placement_frame.is_empty():
			element.placement_frame = self.placement_frame
		element.plugins.append_array(self.plugins)
	elif element is SDFActor:
		element.plugins.append_array(self.plugins)
	return element
