class_name GodotSDFCamera3D
extends Camera3D
# SDF cameras look along +x with +z up, in Godot axes that is -z with +y up,
# the default of Camera3D.

@export var sensor: SDFSensor

func to_godot(
		sensor: SDFSensor,
		parent_node: Node3D,
		owner_node: Node3D,
		offset: Transform3D = Transform3D.IDENTITY):
	self.sensor = sensor
	self.name = sensor.name
	self.transform = offset * sensor.pose.to_godot_transform3d()
	self.keep_aspect = Camera3D.KEEP_WIDTH  # SDF defines the horizontal fov
	self.fov = rad_to_deg(sensor.horizontal_fov)
	self.near = sensor.clip_near
	self.far = sensor.clip_far
	self.parent_node.add_child(self)
	self.owner = owner_node
