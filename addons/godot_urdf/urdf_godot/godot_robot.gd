@tool
class_name GodotURDFRobot
extends Node3D

var _transform_cache: Dictionary[String, Transform3D] = {}
var _joint_defs: Dictionary[String, Dictionary] = {}

var links: Dictionary[String, Node3D] = {}

@export var urdf_robot: URDFRobot
@export var position_gain := 8.0

const DEFAULT_VMAX: float = 3.0
const DEFAULT_EFFORT: float = 60.0


func _ready() -> void:
	if urdf_robot:
		for joint in urdf_robot.joints:
			joint.robot = urdf_robot
		if not urdf_robot.joint_values_changed.is_connected(_on_joint_value_changed):
			urdf_robot.joint_values_changed.connect(_on_joint_value_changed)
	if Engine.is_editor_hint():
		return
	_apply_self_collision_filter()

func _on_joint_value_changed(_joint) -> void:
	# Editor: pose directly (no physics). Runtime: drive() already reads
	# joint.value every tick, so nothing to do here.
	if Engine.is_editor_hint():
		_pose_bodies_from_values()


func _pose_bodies_from_values() -> void:
	if urdf_robot == null:
		return
	for root in urdf_robot.group_fixed_to_dynamics().keys():
		var body: Node3D = _get_body_for_root(root)
		if body:
			body.transform = urdf_robot.link_fk(root)

func _get_body_for_root(root: String) -> Node3D:
	for child in get_children():
		if child.get("root_link") == root:
			return child
	return null

func _apply_self_collision_filter() -> void:
	# Like Gazebo ignore all self-collisions for now.
	# TODO: optionally remove self-collisions again for robots where we don't
	# want the robot to learn to not collide with itself!
	var bodies: Array[PhysicsBody3D] = []
	for child in get_children():
		if child is PhysicsBody3D:
			bodies.append(child)
	for i in bodies.size():
		for k in range(i + 1, bodies.size()):
			bodies[i].add_collision_exception_with(bodies[k])
			bodies[k].add_collision_exception_with(bodies[i])


func add_joint(joint: URDFJoint, godot_transform: Transform3D):
	_joint_defs[joint.child] = {
		"parent": joint.parent,
		"godot_transform": godot_transform
	}


func get_rel_transform(link_name: String) -> Transform3D:
	if _transform_cache.has(link_name):
		return _transform_cache[link_name]
	
	if not _joint_defs.has(link_name):
		_transform_cache[link_name] = Transform3D.IDENTITY
		return Transform3D.IDENTITY
	
	var joint = _joint_defs[link_name]
	var parent_transform = get_rel_transform(joint.parent)
	var transform = parent_transform * joint.godot_transform
	
	_transform_cache[link_name] = transform
	return transform


func to_godot(
		robot: URDFRobot,
		parent: Node3D,
		owner: Node3D,
		options: URDFOptions,
		source_path: String) -> bool:
	self.urdf_robot = robot
	self.name = robot.name
	var success = true
	if parent:
		parent.add_child(self)
	if owner:
		self.owner = owner
	else:
		owner = self

	_transform_cache.clear()
	_joint_defs.clear()
	links.clear()

	var groups = robot.group_fixed_to_dynamics()
	for root in groups.keys():
		var members: Array = groups[root]
		var make_static = options.static_only_physics
		var link_node: Node3D = URDFStaticBody3D.new() if make_static \
			else URDFRigidBody3D.new()
		link_node.root_link = root
		var root_link = robot.get_link(root)
		if root_link:
			link_node.update_link(
				root_link, self, owner, options, source_path)
		else:
			link_node.name = root
			self.add_child(link_node)
			link_node.owner = owner

		for member in members.slice(1):
			var link = robot.get_link(member)
			if not link:
				continue
			URDFPhysicsBody3D.update_link(
				link_node, link, self, owner, options, source_path,
				robot.fixed_offset(member))

		# TODO: add up group inertias!

		for member in members:
			links[member] = link_node

	for joint in robot.joints:
		var child_node: Node3D = links.get(joint.child)

		# Set center position and store in cache so we can
		# calculate the global positions later.
		var godot_transform: Transform3D = URDFUtils.godot_xyz_rpy(
				joint.origin_xyz, joint.origin_rpy)

		self.add_joint(joint, godot_transform)

	for link_name in groups.keys():
		var global_rel_transform = self.get_rel_transform(link_name)
		var _link_node = links[link_name]
		_link_node.transform = global_rel_transform

	for joint in robot.joints:
		if not self.create_godot_joint(joint, owner):
			success = false
	return success

func create_godot_joint(
		joint: URDFJoint,
		owner: Node3D) -> bool:
	var collision_node_a: Node3D = links.get(joint.parent)
	var collision_node_b: Node3D = links.get(joint.child)
	if not _validate_nodes_exist(collision_node_a, collision_node_b, joint):
		return false

	if joint.type == "fixed":
		return true  # fixed joints do not need actual joints

	if not _validate_physics_bodies(collision_node_a, collision_node_b, joint):
		return false

	# Choose joint type based on URDF joint type
	var godot_joint: Node3D
	if joint.type in ["revolute", "continuous"]:
		godot_joint = URDFHingeJoint3D.new()
	else:
		godot_joint = URDF6DOFJoint3D.new()
	
	godot_joint.update_joint(self, owner, joint)

	godot_joint.node_a = godot_joint.get_path_to(collision_node_a)
	godot_joint.node_b = godot_joint.get_path_to(collision_node_b)
	godot_joint.body_a_name = collision_node_a.name
	godot_joint.body_b_name = collision_node_b.name
	godot_joint.rest_rel = collision_node_a.transform.affine_inverse() \
		* collision_node_b.transform
	godot_joint.axis_in_parent = (collision_node_a.transform.basis.inverse() \
		* (collision_node_b.transform.basis * joint.godot_axis)).normalized()

	collision_node_a.add_collision_exception_with(collision_node_b)
	return true

func _validate_nodes_exist(
		node_a: Node3D, node_b: Node3D, joint: URDFJoint) -> bool:
	# Make sure we print out all invalid nodes so its easier to debug
	# so we only return success in the end, not not return after the first
	# errror.
	var success = true
	if not node_a:
		push_error(
			"[URDF - Joint %s] Can not find parent joint %s" % [
				joint.name, joint.parent])
		success = false
	if not node_b:
		push_error(
			"[URDF - Joint %s] Can not find child joint %s" % [
				joint.name, joint.parent])
		success = false
	return success

func _validate_physics_bodies(
		node_a: Node3D, node_b: Node3D, joint: URDFJoint) -> bool:
	# Make sure we print out all invalid bodies so its easier to debug
	# so we only return success in the end, not not return after the first 
	# errror.
	var success = true
	if node_a is not PhysicsBody3D:
		push_error(
			"[URDF - Joint %s] Parent link %s is not a PhysicsBody3D" % [
				joint.name, joint.parent])
		success = false
	if node_b is not PhysicsBody3D:
		push_error(
			"[URDF - Joint %s] Child link %s is not a PhysicsBody3D" % [
				joint.name, joint.child])
		success = false
	return success


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	for child in get_children():
		if child is URDFHingeJoint3D:
			var joint := _find_joint(child)
			if joint == null:
				continue
			var vmax = DEFAULT_VMAX
			if joint.limit and joint.limit.velocity > 0.0:
				vmax = joint.limit.velocity
			var effort = DEFAULT_EFFORT
			if joint.limit and joint.limit.effort > 0.0:
				effort = joint.limit.effort
			child.drive(joint.value, position_gain, vmax, effort, delta)

func _find_joint(node: URDFHingeJoint3D) -> URDFJoint:
	for j in urdf_robot.joints:
		if j.name == node.name or ("joint_" + j.name) == node.name:
			return j
	return null
