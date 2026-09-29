class_name URDFRigidBody3D
extends RigidBody3D

@export var link: URDFLink
@export var root_link: String = ""

func update_link(
		link: URDFLink,
		robot_node: Node3D,
		owner_node: Node3D,
		options: URDFOptions,
		source_path: String) -> void:
	self.link = link
	# Sleeping means that we can ignore motor parameter,
	# a robot should not ignore motor parameter!
	self.can_sleep = false
	URDFPhysicsBody3D.create_root_link(
		self, link, robot_node, owner_node, options, source_path)
	if link.inertial:
		self.mass = link.inertial.mass
		self.center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
		self.center_of_mass = \
			URDFUtils.URDF_TO_GODOT * link.inertial.origin_xyz
