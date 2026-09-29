class_name URDFStaticBody3D
extends StaticBody3D

@export var link: URDFLink
@export var root_link: String = ""

func update_link(
		link: URDFLink,
		robot_node: Node3D,
		owner_node: Node3D,
		options: URDFOptions,
		source_path: String) -> void:
	self.link = link

	URDFPhysicsBody3D.create_root_link(
		self, link, robot_node, owner_node, options, source_path)
