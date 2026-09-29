class_name SDFActor
# see https://sdformat.org/spec/1.12/actor/
extends SDFElement

@export var skin: Dictionary
@export var animation: Dictionary
@export var _script: Dictionary
@export var link: SDFLink
@export var joint: SDFJoint
@export var plugins: Array[SDFPlugin] = []

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
			"pose":
				self.pose.parse(parser)
			"plugin":
				var plugin = SDFPlugin.new()
				plugin.parse(parser)
				self.plugins.append(plugin)
			_:
				XMLHelper.skip_unknown(parser, "actor")
