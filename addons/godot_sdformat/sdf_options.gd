class_name SDFOptions
extends Resource

# searched in order for model:// and package:// uris, like GAZEBO_MODEL_PATH
@export_dir var model_folders: PackedStringArray = []
@export var static_only_physics: bool = false
@export var create_collider_from_visual: bool = true
