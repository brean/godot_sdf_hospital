class_name GodotSDFCollisionShape3D
extends CollisionShape3D

func to_godot(
		collision: SDFCollision,
		convex: bool,
		offset: Transform3D = Transform3D.IDENTITY):
	self.name = collision.name + "_collision"
	self.transform = offset * collision.pose.to_godot_transform3d()
	self.shape = collision.geometry.create_godot_shape(convex)
