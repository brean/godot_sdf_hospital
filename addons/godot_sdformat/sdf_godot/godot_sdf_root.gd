@tool
class_name GodotSDFRoot
extends Node3D

@export var root: SDFRoot

func to_godot(
		sdf_root: SDFRoot,
		parent_node: Node3D,
		owner_node: Node3D):
	self.root = sdf_root
	self.name = sdf_root.filename
	if parent_node:
		parent_node.add_child(self)
	if owner_node:
		self.owner = owner_node

	for sdf_world in sdf_root.worlds:
		var world = GodotSDFWorld.new()
		world.to_godot(sdf_world, self, owner_node)

	if sdf_root.model:
		SDFUtils.create_body(sdf_root.model, false, self, owner_node)
	if sdf_root.light:
		SDFUtils.create_light(sdf_root.light, self, owner_node)
