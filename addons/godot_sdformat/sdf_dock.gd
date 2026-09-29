@tool
extends VBoxContainer
class_name SDFDock
# Show the selected GodotSDFRoots structure, similar to URDFDock.

var main_content: VBoxContainer
var message_label: Label
var tree: Tree

# Elements shown in the tree, value elements like <pose> or <geometry> are
# edited in the inspector.
const ICONS = {
	"sdf": "File",
	"world": "WorldEnvironment",
	"physics": "PhysicsMaterial",
	"plugin": "Script",
	"model": "Node3D",
	"link": "RigidBody3D",
	"visual": "MeshInstance3D",
	"collision": "CollisionShape3D",
	"sensor": "Camera3D",
	"joint": "PinJoint3D",
	"frame": "Marker3D",
	"light": "OmniLight3D",
	"actor": "Skeleton3D",
}

func _init():
	name = "SDF Tree"
	size_flags_vertical = Control.SIZE_EXPAND_FILL

	message_label = Label.new()
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	message_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	add_child(message_label)

	main_content = VBoxContainer.new()
	main_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_content.hide()
	add_child(main_content)

	tree = Tree.new()
	tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tree.item_selected.connect(_on_tree_item_selected)
	main_content.add_child(tree)

func _show_message(text: String):
	# instead of the main content show the message
	main_content.hide()
	message_label.text = text
	message_label.show()
	tree.clear()

# Manage visibility of the UI
func set_ui_state(state: String):
	if state == "active":
		message_label.hide()
		main_content.show()
	elif state == "missing_sdf":
		_show_message("GodotSDFRoot selected, but its 'root' property is empty.")
	elif state == "hidden":
		_show_message("Select a GodotSDFRoot node in the scene to view its SDF tree.")
	else:
		_show_message("Unknown state " + state)

func load_root(sdf_root: SDFRoot):
	tree.clear()
	var root_item = _add_item(null, "sdf", sdf_root.filename, sdf_root)
	for world in sdf_root.worlds:
		var world_item = _add_item(root_item, "world", world.name, world)
		var engine = SDFPhysics.EngineType.find_key(world.physics.engine).to_lower()
		_add_item(world_item, "physics", engine, world.physics)
		for plugin in world.plugins:
			_add_item(world_item, "plugin", plugin.name, plugin)
		if world.model:
			_add_model(world_item, world.model)
	if sdf_root.model:
		_add_model(root_item, sdf_root.model)

func _add_model(parent_item: TreeItem, model: SDFModel):
	var model_item = _add_item(parent_item, "model", model.name, model)
	for link in model.links:
		var link_item = _add_item(model_item, "link", link.name, link)
		for collision in link.collision:
			_add_item(link_item, "collision", collision.name, collision)
		for visual in link.visual:
			_add_item(link_item, "visual", visual.name, visual)
	for joint in model.joints:
		_add_item(model_item, "joint", joint.name, joint)
	for frame in model.frames:
		_add_item(model_item, "frame", frame.name, frame)
	for nested_model in model.models:
		_add_model(model_item, nested_model)
	for plugin in model.plugins:
		_add_item(model_item, "plugin", plugin.name, plugin)

func _add_item(
		parent_item: TreeItem, tag: String,
		text: String, data: Resource) -> TreeItem:
	var item = tree.create_item(parent_item)
	item.set_text(0, "<%s> %s" % [tag, text])
	item.set_icon(0, get_theme_icon(ICONS[tag], "EditorIcons"))
	item.set_metadata(0, data)
	return item

func _on_tree_item_selected():
	var data = tree.get_selected().get_metadata(0)
	if data:
		EditorInterface.edit_resource(data)
