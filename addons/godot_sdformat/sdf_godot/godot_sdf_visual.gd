class_name GodotSDFVisual
extends Node3D

@export var visual: SDFVisual

func to_godot(
		visual: SDFVisual,
		parent_node: Node3D,
		owner_node: Node3D,
		offset: Transform3D = Transform3D.IDENTITY):
	self.visual = visual
	self.name = visual.name
	self.transform = offset * visual.pose.to_godot_transform3d()
	parent_node.add_child(self)
	owner = owner_node

	var geometry = visual.geometry
	var scene = null
	if geometry.type == SDFGeometry.GeometryType.MESH:
		scene = load(geometry.uri)
	var node: Node3D
	if scene is PackedScene:
		node = scene.instantiate()
	else:
		node = MeshInstance3D.new()
		node.mesh = geometry.create_godot_mesh()
	if geometry.type == SDFGeometry.GeometryType.MESH:
		node.transform.basis = geometry.mesh_basis()
	add_child(node)
	node.owner = owner_node
	# TODO: visual.material
