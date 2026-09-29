class_name GodotSDFRigidBody3D
extends RigidBody3D

@export var model: SDFModel

func to_godot(
		model: SDFModel,
		parent_node: Node3D,
		owner_node: Node3D):
	self.model = model
	self.name = model.name
	self.transform = model.pose.to_godot_transform3d()
	parent_node.add_child(self)
	owner = owner_node
	SDFUtils.add_links(self, model, owner_node, true)
