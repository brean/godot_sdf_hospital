@tool
extends Node3D
class_name WheeledRobotController

@export var robot: GodotURDFRobot

@export var speed: float = 20.0

@export_group("Robot Type")
enum MobilityType {
	TWO_WHEEL_DIFF_DRIVE,
	FOUR_WHEEL_DIFF_DRIVE,
	# ACKERMANN
	# add hexapods, quadrupeds and humanoids?!
}

@export_group("Control")
@export var mobile_type: MobilityType = MobilityType.FOUR_WHEEL_DIFF_DRIVE:
	set(value):
		if mobile_type != value:
			mobile_type = value
			notify_property_list_changed()

# TODO: have names as Generic6DOFJoint3D directly?
var front_left_wheel: String = ""
var front_right_wheel: String = ""
var rear_left_wheel: String = ""
var rear_right_wheel: String = ""

var front_left_joint: URDFHingeJoint3D
var front_right_joint: URDFHingeJoint3D
var rear_left_joint: URDFHingeJoint3D
var rear_right_joint: URDFHingeJoint3D

func _physics_process(delta):
	if Engine.is_editor_hint():
		return
	var throttle = Input.get_axis("accelerate", "decelerate")
	var steering = Input.get_axis("left", "right")
	var left_target = throttle - steering
	var right_target = throttle + steering
	var left_velocity = left_target * speed
	var right_velocity = right_target * speed

	match mobile_type:
		MobilityType.TWO_WHEEL_DIFF_DRIVE:
			apply_motor_velocity(front_left_joint, left_velocity)
			apply_motor_velocity(front_right_joint, right_velocity)
		MobilityType.FOUR_WHEEL_DIFF_DRIVE:
			apply_motor_velocity(front_left_joint, left_velocity)
			apply_motor_velocity(front_right_joint, right_velocity)
			apply_motor_velocity(rear_left_joint, left_velocity)
			apply_motor_velocity(rear_right_joint, right_velocity)

func apply_motor_velocity(joint: URDFHingeJoint3D, target_velocity: float):
	if joint:
		joint.control_mode = URDFHingeJoint3D.ControlMode.VELOCITY
		joint.velocity_target = target_velocity
		# joint["motor/enable"] = true
		# joint["motor/target_velocity"] = target_velocity

func _get_property_list():
	var list: Array[Dictionary] = []
	list.append({name = "front_left_wheel", type = TYPE_STRING})
	list.append({name = "front_right_wheel", type = TYPE_STRING})
	match mobile_type:
		MobilityType.FOUR_WHEEL_DIFF_DRIVE: #, MobilityType.ACKERMANN:
			list.append({name = "rear_left_wheel", type = TYPE_STRING})
			list.append({name = "rear_right_wheel", type = TYPE_STRING})
	return list

func _ready():
	if not Engine.is_editor_hint():
		_initialize_robot()

func _initialize_robot():
	if not robot:
		push_error("Robot Controller: No Robot Node assigned!")
		return
	front_left_joint = robot.find_child(front_left_wheel, true, false)
	if not front_left_joint:
		push_error("Front left joint not found: %s" % front_left_wheel)
	front_right_joint = robot.find_child(front_right_wheel, true, false)
	if not front_right_joint:
		push_error("Front right joint not found: %s" % front_right_wheel)
	match mobile_type:
		MobilityType.FOUR_WHEEL_DIFF_DRIVE: #, MobilityType.ACKERMANN:
			rear_left_joint = robot.find_child(rear_left_wheel, true, false)
			if not rear_left_joint:
				push_error("Rear left joint not found: %s" % rear_left_wheel)
			rear_right_joint = robot.find_child(rear_right_wheel, true, false)
			if not rear_right_joint:
				push_error("Rear right joint not found: %s" % rear_right_joint)
