class_name GodotSDFModel
extends Node3D
# A model without links, e.g. a world model that only includes other models.

@export var model: SDFModel

func to_godot(
		model: SDFModel,
		parent_static: bool,
		parent_node: Node3D,
		owner_node: Node3D):
	self.model = model
	self.name = model.name
	self.transform = model.pose.to_godot_transform3d()
	parent_node.add_child(self)
	owner = owner_node
	for nested_model in model.models:
		SDFUtils.create_body(
			nested_model, parent_static or model.static_model, self, owner_node)
