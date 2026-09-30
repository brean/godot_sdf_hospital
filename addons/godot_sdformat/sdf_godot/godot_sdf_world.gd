@tool
class_name GodotSDFWorld
extends Node3D

@export var world: SDFWorld

func to_godot(
		world: SDFWorld,
		parent_node: Node3D,
		owner_node: Node3D) -> Node3D:
	print("Create new World: %s" % world.name)
	self.name = world.name
	self.world = world

	if parent_node:
		parent_node.add_child(self)
	if owner_node:
		self.owner = owner_node

	var world_env = WorldEnvironment.new()
	world_env.name = "Environment"
	world_env.environment = Environment.new()
	self.add_child(world_env)
	if owner_node:
		world_env.owner = owner_node

	var lights_node = Node3D.new()
	lights_node.name = "Lights"
	self.add_child(lights_node)
	if owner_node:
		lights_node.owner = owner_node
	# for light_name in world.lights.keys():
	# 	var light = world.lights[light_name]
	# 	lights_node.add_child(light.to_godot())

	for model in world.models:
		SDFUtils.create_body(model, false, self, owner_node)

	return self
