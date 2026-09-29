class_name SDFParser
extends XMLParser

@export var options: SDFOptions

var _root_dir: String = ""
var _file_stack :PackedStringArray = PackedStringArray()

func _init(options: SDFOptions = SDFOptions.new()):
	self.options = options

func current_file() -> String:
	return _file_stack[-1] if not _file_stack.is_empty() else ""

func current_dir() -> String:
	return current_file().get_base_dir() if not _file_stack.is_empty() else _root_dir

func as_node3d(
		source_path: String,
		parent_node: Node3D,
		owner_node: Node3D) -> Node3D:
	# Load and parse the SDF file
	self.options = options
	var root: SDFRoot = parse(source_path)
	if root == null:
		return null
	var sdf_root = GodotSDFRoot.new()
	sdf_root.to_godot(root, parent_node, owner_node)
	return sdf_root

func parse(source_path: String) -> SDFRoot:
	if source_path.begins_with("uid://"):
		source_path = ResourceUID.uid_to_path(source_path)
	_file_stack.clear()
	_root_dir = source_path.get_base_dir()
	return load_file(source_path)

func load_file(source_path: String) -> SDFRoot:
	var path = source_path.simplify_path()
	if path in _file_stack:
		push_error(
			"[SDF] Include cycle: %s -> %s" % [
				" -> ".join(_file_stack), path])
		return null

	var parser = SDFParser.new(options)
	if parser.open(path) != OK:
		push_error("Failed to open SDF file: %s" % path)
		return null
	
	if not _read_to_first_element(parser) or parser.get_node_name() != "sdf":
		push_error("Not an SDFormat file (root element must be <sdf>): %s" % path)
		return null

	# each file has its own parser, it inherits the include chain
	parser._root_dir = _root_dir
	parser._file_stack = _file_stack.duplicate()
	parser._file_stack.push_back(path)
	var root = SDFRoot.new()
	root.filename = path.get_file().get_basename()
	root.parse(parser)
	return root

# Resolve the <uri> of an <include> to the SDF file.
func resolve_include_file(uri: String) -> String:
	if uri.begins_with("http://") or uri.begins_with("https://"):
		push_warning("[SDF] Fuel includes are not supported, skipped: %s" % uri)
		return ""
	var path = resolve_uri(uri)
	if path.is_empty():
		push_error("[SDF] Cannot resolve include: %s" % uri)
		return ""
	if DirAccess.dir_exists_absolute(path):
		return _sdf_file_in_model_dir(path)
	return path

# Returns the SDF file with the highest version listed in model.config.
func _sdf_file_in_model_dir(dir: String) -> String:
	var config = XMLParser.new()
	if config.open(dir.path_join("model.config")) != OK:
		push_error("[SDF] No model.config found in %s" % dir)
		return ""
	var best_file = ""
	var best_version = Vector2i(-1, -1)
	while config.read() == OK:
		if config.get_node_type() != XMLParser.NODE_ELEMENT or config.get_node_name() != "sdf":
			continue
		var parts = config.get_named_attribute_value_safe("version").split(".")
		var version = Vector2i(int(parts[0]), int(parts[1]) if parts.size() > 1 else 0)
		var file = dir.path_join(XMLHelper.text_to_string(config))
		if version > best_version and FileAccess.file_exists(file):
			best_version = version
			best_file = file
	if best_file.is_empty():
		push_error("[SDF] model.config in %s lists no existing SDF file" % dir)
	return best_file

func _existing(path: String) -> String:
	path = path.simplify_path()
	if FileAccess.file_exists(path) or DirAccess.dir_exists_absolute(path):
		return ProjectSettings.localize_path(path)
	return ""

# Resolves an SDF URI to an existing file or directory. Returns "" if it
# cannot be resolved.
#   model://name/..., package://name/...  searched in search_paths()
#   file://path, res://, user://, /abs    used as is
#   relative/path                          relative to the current file
#   http(s)://                             unsupported (no Fuel download)
func resolve_uri(uri: String) -> String:
	uri = uri.strip_edges()
	if uri.is_empty():
		return ""
	for scheme in ["model://", "package://"]:
		if uri.begins_with(scheme):
			var relative = uri.trim_prefix(scheme)
			for search_path in search_paths():
				var found = _existing(search_path.path_join(relative))
				if not found.is_empty():
					return found
			return ""
	if uri.begins_with("http://") or uri.begins_with("https://"):
		return ""
	if uri.begins_with("file://"):
		return _existing(uri.trim_prefix("file://"))
	if uri.is_absolute_path():
		return _existing(uri)
	return _existing(current_dir().path_join(uri))

func search_paths() -> PackedStringArray:
	var paths := PackedStringArray()
	for path in [options.model_folder, _root_dir, current_dir().get_base_dir()]:
		if not path.is_empty() and path not in paths:
			paths.append(path)
	return paths

func _read_to_first_element(parser: XMLParser) -> bool:
	while parser.read() == OK:
		if parser.get_node_type() == XMLParser.NODE_ELEMENT:
			return true
	return false

