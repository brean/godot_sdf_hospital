class_name SDFPose
# see e.g. https://sdformat.org/spec/1.12/actor/#actor_pose
extends Resource

@export var position: Vector3 = Vector3.ZERO
@export var rotation: Quaternion = Quaternion.IDENTITY
@export var relative_to: String = ""  # Frame this pose is relative to

func to_transform3d() -> Transform3D:
	return Transform3D(rotation, position)

# SDF uses the same axes as URDF (x forward, z up)
func to_godot_transform3d() -> Transform3D:
	return URDFUtils.godot_transform3d(to_transform3d())

func parse(parser: SDFParser):
	self.relative_to = parser.get_named_attribute_value_safe("relative_to")
	var rotation_format = parser.get_named_attribute_value_safe("rotation_format")
	var degrees = XMLHelper.string_to_bool(
		parser.get_named_attribute_value_safe("degrees"))
	var values = XMLHelper.string_to_floats(
		XMLHelper.text_to_string(parser))
	if values.is_empty():
		return

	match rotation_format:
		"", "euler_rpy":
			if values.size() != 6:
				push_error(
					"euler_rpy pose expects 6 values, got %d" % values.size())
				return
			var rpy = Vector3(values[3], values[4], values[5])
			if degrees:
				rpy = Vector3(
					deg_to_rad(rpy.x),
					deg_to_rad(rpy.y),
					deg_to_rad(rpy.z))
			# TODO: maybe use URDFUtils.godot_xyz_rpy instead?
			self.rotation = Basis.from_euler(
				rpy, EULER_ORDER_ZYX).get_rotation_quaternion()
		"quat_xyzw":
			if values.size() != 7:
				push_error(
					"quat_xyzw pose expects 7 values, got %d" % values.size())
				return
			self.rotation = Quaternion(values[3], values[4], values[5], values[6]).normalized()
		_:
			push_error("Unknown rotation_format '%s'" % rotation_format)
			return
	self.position = Vector3(values[0], values[1], values[2])
