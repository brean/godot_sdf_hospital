@tool
class_name URDFJoint
extends Resource

var robot: URDFRobot

@export var name: String
@export var type: String = "fixed"

# Link names
@export var parent: String
@export var child: String

# Transform
# All XYZ will be kept as is originally in URDF file
# Y and Z should be flipped when generating Nodes
@export var origin_xyz: Vector3
@export var origin_rpy: Vector3
@export var axis: Vector3

# Physics
@export var limit: URDFLimit = null
@export var dynamics: URDFDynamics = null

# currently selected value
@export var value: float:
	set(_value):
		value = clamp_value(_value)
		if robot:
			robot.joint_values_changed.emit(self)


var _godot_axis: Vector3 = Vector3.ZERO
var _godot_axis_cached: bool = false
@export var godot_axis: Vector3:
	get():
		if not _godot_axis_cached:
			_godot_axis = urdf_to_godot_axis()
			_godot_axis_cached = true
		return _godot_axis

func clamp_value(v: float) -> float:
	if position_limits():
		return clampf(v, limit.lower, limit.upper)
	return v


func position_limits() -> bool:
	return type in ["revolute", "prismatic"] \
		and limit != null and limit.upper > limit.lower


func movable() -> bool:
	return type in ["revolute", "continuous", "prismatic"]

func urdf_to_godot_axis() -> Vector3:
	# get axis valie from URDF and transform to Godot
	var urdf_axis = self.axis
	if urdf_axis == Vector3.ZERO:
		urdf_axis = Vector3(1, 0, 0)
	return URDFUtils.convert_axis(urdf_axis).normalized()

func axis_alignment() -> Basis:
	var local_z = Vector3(0, 0, 1)
	var _axis_alignment = Basis()
	
	if local_z.is_equal_approx(self.godot_axis):
		_axis_alignment = Basis.IDENTITY
	elif local_z.is_equal_approx(-self.godot_axis):
		# 180 degree flip around X if the axes are exactly opposite
		_axis_alignment = Basis(Vector3(1, 0, 0), PI)
	else:
		# Shortest arc rotation to align Z with the target axis
		_axis_alignment = Basis(Quaternion(local_z, self.godot_axis))
	return _axis_alignment

func urdf_to_godot_transform(
		godot_robot: GodotURDFRobot,
		link_name: String) -> Transform3D:
	var child_transform = godot_robot.get_rel_transform(link_name)
	var _axis_alignment = axis_alignment()
	return Transform3D(
		child_transform.basis * _axis_alignment,
		child_transform.origin)
class URDFLimit extends Resource:
	@export var lower: float
	@export var upper: float
	@export var effort: float
	@export var velocity: float

class URDFDynamics extends Resource:
	@export var damping: float
	@export var friction: float

enum JointType {FIXED, REVOLUTE, CONTINUOUS}

func parse(parser: XMLParser):
	self.name = parser.get_named_attribute_value_safe("name")
	if parser.is_empty():
		return
	self.type = parser.get_named_attribute_value_safe("type")

	while parser.read() == OK:
		var node_type = parser.get_node_type()
		if node_type == XMLParser.NODE_TEXT:
			continue
		var node_name = parser.get_node_name()
		var axis: Vector3 = Vector3(0, 0, 1)
		if node_type == XMLParser.NODE_ELEMENT:
			match node_name:
				"parent":
					self.parent = parser.get_named_attribute_value_safe("link")
				"child":
					self.child = parser.get_named_attribute_value_safe("link")
				"axis":
					self.axis = XMLHelper.attr_to_vector3(parser, "xyz")
				"origin":
					self.origin_xyz = XMLHelper.attr_to_vector3(parser, "xyz")
					self.origin_rpy = XMLHelper.attr_to_vector3(parser, "rpy")
				"limit":
					parse_joint_limit(parser)
				"dynamics":
					parse_joint_dynamics(parser)
				_:
					push_error(
						"[URDF] Unsupported tag in joint: %s" % node_name)
					parser.skip_section()
		elif node_type == XMLParser.NODE_ELEMENT_END:
			if node_name == "joint":
				return
	return

func parse_joint_limit(parser: XMLParser) -> void:
	self.limit = URDFJoint.URDFLimit.new()
	self.limit.lower = XMLHelper.attr_to_float(parser, "lower")
	self.value = max(0.0, self.limit.lower)
	self.limit.upper = XMLHelper.attr_to_float(parser, "upper")
	self.limit.effort = XMLHelper.attr_to_float(parser, "effort")
	self.limit.velocity = XMLHelper.attr_to_float(parser, "velocity")

func parse_joint_dynamics(parser: XMLParser) -> void:
	self.dynamics = URDFJoint.URDFDynamics.new()
	self.dynamics.damping = XMLHelper.attr_to_float(parser, "damping")
	self.dynamics.friction = XMLHelper.attr_to_float(parser, "friction")

