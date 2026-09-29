@tool
extends Node3D

@export_group("SDF/World File")
@export_file("*.sdf", "*.world", "*.xml") var sdf_file_path: String

@export_tool_button("Reload SDF", "WorldEnvironment") var _load_sdf_button = _load_sdf

@export_group("Model Directory")
@export_dir var model_folder: String = "res://models"

@export_group("Transform")
@export var _position: Vector3 = Vector3(0, 0, 0)
@export var _rotation: Vector3 = Vector3(0, 0, 0)
@export var _scale: float = 1.0

func _load_sdf():
	for child in get_children():
		child.free()

	if sdf_file_path.is_empty():
		push_error("[SDF] No file selected!")
		return

	var options = SDFOptions.new()
	options.model_folder = model_folder

	var parser = SDFParser.new(options)
	var _root = get_tree().edited_scene_root
	var _node = parser.as_node3d(
		sdf_file_path,
		self, _root)