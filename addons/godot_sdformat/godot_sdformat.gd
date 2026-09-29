@tool
extends EditorPlugin

var godot_sdf = GodotSDFImporter.new()
var dock: SDFDock

func _enter_tree() -> void:
	add_import_plugin(godot_sdf)

	dock = preload("res://addons/godot_sdformat/sdf_dock.gd").new()
	# below the URDF Tree (DOCK_SLOT_RIGHT_UR)
	add_control_to_dock(DOCK_SLOT_RIGHT_BR, dock)

	EditorInterface.get_selection().selection_changed.connect(_on_selection_changed)

	# Check selection in case a GodotSDFRoot is already selected
	_on_selection_changed()

func _exit_tree() -> void:
	remove_import_plugin(godot_sdf)
	EditorInterface.get_selection().selection_changed.disconnect(_on_selection_changed)
	remove_control_from_docks(dock)
	if dock:
		dock.free()

func _on_selection_changed():
	var selected_nodes = EditorInterface.get_selection().get_selected_nodes()
	var active_root: GodotSDFRoot = null
	if selected_nodes.size() > 0:
		var current_node = selected_nodes[0]
		# Walk up the scene tree to find a GodotSDFRoot parent
		while current_node != null:
			if current_node is GodotSDFRoot:
				active_root = current_node
				break
			current_node = current_node.get_parent()
	if active_root:
		if active_root.root != null:
			dock.load_root(active_root.root)
			dock.set_ui_state("active")
		else:
			dock.set_ui_state("missing_sdf")
	else:
		dock.set_ui_state("hidden")
