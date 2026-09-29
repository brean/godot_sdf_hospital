# A URDFLink that has a visual but no collision children
class_name URDFVisualNode
extends Node3D

func update_link(
		link: URDFLink,
		robot_node: Node3D,
		owner_node: Node3D,
		options: URDFOptions,
		source_path: String) -> void:
	self.name = link.name

	robot_node.add_child(self)
	self.owner = owner_node

	URDFGeometryFactory.create_visuals(
		self, robot_node, owner_node, options, source_path, link)
