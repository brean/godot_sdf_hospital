@tool
extends Node3D
# Script you can attach to your node to load a robots elements as child
# making it easier to modify/extend the robot

@export_group("URDF File")
@export_file("*.urdf", "*.xml") var urdf_file_path: String

@export_tool_button("Reload robot", "Godot") var _load_urdf_button = _load_urdf

@export_group("Package Directory")
# Change "package://robot_description/meshes/..." to "res://urdf/..."
@export_dir var package_folder: String = "res://"

@export_group("Transform")
@export var _position: Vector3 = Vector3(0, 0, 0)
@export var _rotation: Vector3 = Vector3(0, 0, 0)
@export var _scale: float = 0.001

@export_group("Physics")
# If collider are missing we use the visual elements to create them
@export var _create_collider_from_visual: bool = true

# Only create static physic objects, no URDF6DOFJoint-instances
@export var _static_only_physics: bool = false


func _load_urdf():
	for child in get_children():
		if child is GodotURDFRobot:
			child.free()

	if urdf_file_path.is_empty():
		push_error("[URDF] No file selected!")
		return

	var parser = URDFXMLParser.new()

	var options = URDFOptions.new()
	options.package_folder = package_folder
	options.scale = _scale
	options.static_only_physics = _static_only_physics
	options.create_collider_from_visual = _create_collider_from_visual

	var _root = get_tree().edited_scene_root

	var robot_node = parser.as_node3d(
		urdf_file_path, options, self, _root)

	if robot_node:
		robot_node.set_position(_position)
		robot_node.set_rotation(_rotation / 180 * PI)

		print("[URDF] Robot loaded successfully!")
	else:
		push_error("[URDF] Failed to load robot node.")
