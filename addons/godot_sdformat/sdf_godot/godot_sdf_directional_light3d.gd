class_name GodotSDFDirectionalLight3D
extends DirectionalLight3D

@export var light: SDFLight

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
	parent_node.add_child(self)
	self.owner = owner_node
