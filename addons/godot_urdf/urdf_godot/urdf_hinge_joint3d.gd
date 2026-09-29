class_name URDFHingeJoint3D
extends HingeJoint3D

enum ControlMode { POSITION, VELOCITY }

@export var joint: URDFJoint

@export var control_mode: ControlMode = ControlMode.POSITION
@export var velocity_target: float = 0.0

@export var rest_rel: Transform3D = Transform3D.IDENTITY
@export var axis_in_parent: Vector3 = Vector3(0, 0, 1)

@export var body_a_name: String
@export var body_b_name: String

@export var flip_sign: bool = true

@export var overwrite_vmax: float = -1

var _measure_ok: bool = false
var cached_node_a: Node3D
var cached_node_b: Node3D

func update_joint(
		godot_robot: GodotURDFRobot,
		owner: Node3D,
		joint: URDFJoint) -> void:
	godot_robot.add_child(self)
	self.owner = owner

	self.joint = joint
	self.name = "joint_" + joint.name
	self.exclude_nodes_from_collision = false

	# Configure limits
	if joint.type == "revolute" and joint.limit:
		# Limited revolute joint
		self["angular_limit/enable"] = true
		self["angular_limit/lower"] = joint.limit.lower
		self["angular_limit/upper"] = joint.limit.upper
	elif joint.type == "continuous":
		# Unlimited continuous joint
		control_mode = ControlMode.VELOCITY
		self["angular_limit/enable"] = false

	# Enable and configure motor
	self["motor/enable"] = true
	self["motor/target_velocity"] = 0.0

	# Handle dynamics and effort
	if joint.limit and joint.limit.effort > 0:
		self["motor/max_impulse"] = joint.limit.effort
	elif joint.dynamics and joint.dynamics.friction > 0:
		self["motor/max_impulse"] = joint.dynamics.friction
	else:
		self["motor/max_impulse"] = 1.0  # Default fallback

	self.transform = joint.urdf_to_godot_transform(
		godot_robot, joint.child)


func _resolve_bodies() -> bool:
	if cached_node_a and cached_node_b:
		return true
	var p := get_parent()
	if p == null:
		return false
	if cached_node_a == null and body_a_name != "":
		cached_node_a = p.get_node_or_null(NodePath(body_a_name))
	if cached_node_b == null and body_b_name != "":
		cached_node_b = p.get_node_or_null(NodePath(body_b_name))
	return cached_node_a != null and cached_node_b != null


func current_position() -> float:
	if not _resolve_bodies():
		_measure_ok = false
		return 0.0
	_measure_ok = true
	var rel = cached_node_a.global_transform.affine_inverse() * cached_node_b.global_transform
	var d: Basis = rel.basis * rest_rel.basis.inverse()
	return URDFUtils.signed_angle_about(d, axis_in_parent)


func drive(
		target_position: float, gain: float,
		vmax: float, effort: float, delta: float) -> void:
	var velocity: float
	if overwrite_vmax > 0:
		vmax = overwrite_vmax
	if control_mode == ControlMode.VELOCITY:
		velocity = clampf(velocity_target, -vmax, vmax)
	else:
		var pos: float = current_position()
		if not _measure_ok:
			push_error(
				"[URDF] Hinge '%s' can't resolve its bodies; holding." % name)
			velocity = 0.0
		else:
			# P controller for ControlMode.POSITION
			velocity = clampf(gain * (target_position - pos), -vmax, vmax)
			if flip_sign:
				velocity = -velocity
	self["motor/target_velocity"] = velocity
	self["motor/max_impulse"] = effort * delta
