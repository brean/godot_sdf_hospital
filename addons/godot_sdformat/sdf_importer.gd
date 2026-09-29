@tool
class_name GodotSDFImporter
extends EditorImportPlugin

func _get_importer_name() -> String:
	return "godot_sdformat"
	
func _get_visible_name() -> String:
	return "Godot SDFormat"
	
func _get_recognized_extensions() -> PackedStringArray:
	return ["sdf", "world"]

func _get_save_extension() -> String:
	return "tscn"
	
func _get_import_options(_path: String, _preset_index: int) -> Array[Dictionary]:
	return [
		{
			"name": "model_folder",
			"default_value": "res://models",
			"property_hint": PROPERTY_HINT_GLOBAL_DIR,
			"hint_string": ""
		},
	]
	
func _get_import_order() -> int:
	return IMPORT_ORDER_SCENE + 1  # after the meshes are loaded
	
func _get_resource_type() -> String:
	return "PackedScene"
	
func _get_preset_count() -> int:
	return 1
	
func _get_preset_name(_preset_index: int) -> String:
	return "Default preset"
	
func _get_option_visibility(_path: String, _option_name: StringName, _options: Dictionary) -> bool:
	return true
	
func _get_priority() -> float:
	return 1.0

func _import(
		source_file: String, save_path: String, options: Dictionary,
		_platform_variants: Array[String], _gen_files: Array[String]) -> Error:
	var scene = PackedScene.new()
	var sdf_options = SDFOptions.new()
	sdf_options.model_folder = options["model_folder"]
	var sdf_parser = SDFParser.new(sdf_options)

	# Create a new directory for the imported scene
	# Get filename without extension
	var basename = source_file.get_basename()
	var source_dir_result = DirAccess.make_dir_recursive_absolute(basename)
	if source_dir_result != OK:
		push_error("Failed to create import directory: %s" % basename)
		return source_dir_result
	var sdf_node = sdf_parser.as_node3d(source_file, null, null)
	if sdf_node == null:
		push_error("Failed to import SDF file: %s" % source_file)
		if sdf_node:
			sdf_node.free()
		return ERR_PARSE_ERROR
	scene.pack(sdf_node)
	sdf_node.free()
	var saved_path = save_path + "." + _get_save_extension()
	# Save the packed scene to the target path
	var save_result = ResourceSaver.save(scene, saved_path)
	if save_result != OK:
		push_error("Failed to save imported .sdf as a scene.")
		return ERR_CANT_CREATE
	return OK
