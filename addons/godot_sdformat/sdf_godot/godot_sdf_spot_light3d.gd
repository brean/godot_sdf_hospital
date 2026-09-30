class_name GodotSDFSpotLight3D
extends SpotLight3D

@export var light: SDFLight

# TODO: attenuation constant, linear and quadratic, inner angle, falloff
func to_godot(
		light: SDFLight,
		parent_node: Node3D,
		owner_node: Node3D):
	self.light = light
	self.name = light.name
	self.transform = light.to_godot_transform3d()
	self.light_color = light.diffuse
	self.light_energy = light.intensity
	self.light_specular = light.specular.get_luminance()
	self.shadow_enabled = light.cast_shadows
	self.spot_range = light.attenuation_range
	# SDF outer_angle is the full cone, Godot spot_angle half of it
	self.spot_angle = rad_to_deg(light.spot_outer_angle) / 2.0
	parent_node.add_child(self)
	self.owner = owner_node
