class_name XMLHelper

static func string_to_bool(text: String) -> bool:
	return text.strip_edges().to_lower() in ["true", "yes", "1", "t", "y"]

# Understands "inf"/"-inf" as used by the spec for joint limits.
# Returns NAN for invalid numbers.
static func string_to_float(text: String) -> float:
	var value = text.strip_edges().to_lower()
	match value:
		"inf", "+inf", "infinity", "+infinity":
			return INF
		"-inf", "-infinity":
			return -INF
	if not value.is_valid_float():
		return NAN
	return value.to_float()

static func has_nan(values: PackedFloat64Array) -> bool:
	for value in values:
		if is_nan(value):
			return true
	return false

# Read the text content of the current element and consumes its closing tag.
static func text_to_string(parser: XMLParser) -> String:
	if parser.is_empty():
		return ""
	var tag = parser.get_node_name()
	var text = ""
	while parser.read() == OK:
		match parser.get_node_type():
			XMLParser.NODE_TEXT, XMLParser.NODE_CDATA:
				text += parser.get_node_data()
			XMLParser.NODE_ELEMENT:
				skip_unknown(parser, tag)
			XMLParser.NODE_ELEMENT_END:
				break
	return text.strip_edges()

static func string_to_floats(text: String) -> PackedFloat64Array:
	var values := PackedFloat64Array()
	var normalized = text.strip_edges().replace("\t", " ").replace("\n", " ").replace("\r", " ")
	for part in normalized.split(" ", false):
		values.append(string_to_float(part))
	return values

static func text_to_numbers(parser: XMLParser) -> PackedFloat64Array:
	var tag = parser.get_node_name()
	var text = text_to_string(parser)
	if text.is_empty():
		return PackedFloat64Array()
	return string_to_floats(text)

static func text_to_bool(parser: XMLParser, fallback: bool = false) -> bool:
	var text = text_to_string(parser)
	if text.is_empty():
		return fallback
	return string_to_bool(text)

static func text_to_float(parser: XMLParser, fallback: float = 0.0) -> float:
	var values = text_to_numbers(parser)
	return values[0] if values.size() == 1 else fallback

static func text_to_int(parser: XMLParser, fallback: int = 0) -> int:
	var text = text_to_string(parser)
	if text.is_empty():
		return fallback
	if text.to_lower().begins_with("0x") and text.is_valid_hex_number(true):
		return text.hex_to_int()
	if not text.is_valid_int():
		var tag = parser.get_node_name()
		push_error("%s expected an integer, got '%s'" % [tag, text])
		return fallback
	return text.to_int()

static func text_to_vector2(
		parser: XMLParser, fallback: Vector2 = Vector2.ZERO) -> Vector2:
	var val = text_to_numbers(parser)
	return Vector2(val[0], val[1]) if val.size() == 2 else fallback

static func text_to_vector3(
		parser: XMLParser, fallback: Vector3 = Vector3.ZERO) -> Vector3:
	var val = text_to_numbers(parser)
	return Vector3(val[0], val[1], val[2]) if val.size() == 3 else fallback

static func text_to_color(
		parser: XMLParser, fallback: Color = Color.PINK) -> Color:
	var val = string_to_floats(text_to_string(parser))
	if val.is_empty():
		return fallback
	if val.size() < 3 or val.size() > 4 or has_nan(val):
		var tag = parser.get_node_name()
		push_error("%s expects 'r g b [a]'" % tag)
		return fallback
	return Color(val[0], val[1], val[2], val[3] if val.size() == 4 else 1.0)

static func attr_to_numbers(parser: XMLParser, name: String):
	var text = parser.get_named_attribute_value_safe(name)
	if text.is_empty():
		return PackedFloat64Array()
	return string_to_floats(text)

static func attr_to_float(
		parser: XMLParser, name: String, fallback: float = 0.0) -> float:
	var val = parser.get_named_attribute_value_safe(name)
	if val.is_empty():
		var tag = parser.get_node_name()
		push_error("%s.%s is not a valid integer" % tag, name)
		return fallback
	val = float(val)
	if is_nan(val):
		return fallback
	return val

static func attr_to_int(
		parser: XMLParser, name: String, fallback: int = 0) -> int:
	var text = text_to_string(parser)
	if text.is_empty():
		push_warning("%s is not a valid integer" % name)
		return fallback
	if text.to_lower().begins_with("0x") and text.is_valid_hex_number(true):
		return text.hex_to_int()
	if not text.is_valid_int():
		var tag = parser.get_node_name()
		push_error("%s.%s expected an integer, got '%s'" % [tag, name, text])
		return fallback
	return text.to_int()

static func attr_to_vector2(
		parser: XMLParser,
		name: String,
		fallback: Vector2 = Vector2.ZERO) -> Vector2:
	var val = attr_to_numbers(parser, name)
	return Vector2(val[0], val[1]) if val.size() == 2 else fallback

static func attr_to_vector3(
		parser: XMLParser,
		name: String,
		fallback: Vector3 = Vector3.ZERO) -> Vector3:
	var val = attr_to_numbers(parser, name)
	return Vector3(val[0], val[1], val[2]) if val.size() == 3 else fallback

static func attr_to_color(
		parser: XMLParser,
		name: String,
		fallback: Color = Color.PINK) -> Color:
	var val_str = parser.get_named_attribute_value_safe(name)
	var val = string_to_floats(val_str)
	if val.is_empty():
		return fallback
	if val.size() < 3 or val.size() > 4 or has_nan(val):
		var tag = parser.get_node_name()
		push_error("%s.%s expects 'r g b [a]'" % [tag, name])
		return fallback
	return Color(val[0], val[1], val[2], val[3] if val.size() == 4 else 1.0)

static func attr_to_bool(
		parser: XMLParser,
		name: String,
		fallback: bool = false) -> bool:
	var text = parser.get_named_attribute_value_safe(name)
	if text.is_empty():
		return fallback
	return string_to_bool(text)

static func skip_unknown(parser: XMLParser, parent_tag: String) -> void:
	var tag = parser.get_node_name()
	if not tag.contains(":"):
		push_warning(
			"Unknown element %s in %s skipped" % [tag, parent_tag])
	parser.skip_section()