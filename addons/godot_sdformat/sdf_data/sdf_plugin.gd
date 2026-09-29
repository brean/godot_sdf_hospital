class_name SDFPlugin
extends Resource

@export var name: String
@export var filename: String # parsed from URI
@export var elements: Dictionary = {}  # plugin configuration

func parse(parser: SDFParser):
	self.name = parser.get_named_attribute_value_safe("name")
	self.filename = parser.get_named_attribute_value_safe("filename")
	# TODO: parse correctly, skip for now
	parser.skip_section()
