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
	world_env.environment.background_mode = Environment.BG_COLOR
	world_env.environment.background_color = world.scene.background
	world_env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world_env.environment.ambient_light_color = world.scene.ambient
	# TODO: sky, fog
	self.add_child(world_env)
	if owner_node:
		world_env.owner = owner_node

	var lights_node = Node3D.new()
	lights_node.name = "Lights"
	self.add_child(lights_node)
	if owner_node:
		lights_node.owner = owner_node
	for light in world.lights.values():
		var light_node = SDFUtils.create_light(light, lights_node, owner_node)
		# <scene><shadows> switches the shadows of all lights
		if light_node and not world.scene.shadows:
			light_node.shadow_enabled = false

	for model in world.models:
		SDFUtils.create_body(model, false, self, owner_node)

	return self

# Gravity belongs to the physics space, so it can only be set at runtime.
func _ready():
	if Engine.is_editor_hint() or world == null:
		return
	var gravity = URDFUtils.URDF_TO_GODOT * world.gravity
	var space = get_world_3d().space
	PhysicsServer3D.area_set_param(
		space, PhysicsServer3D.AREA_PARAM_GRAVITY, gravity.length())
	PhysicsServer3D.area_set_param(
		space, PhysicsServer3D.AREA_PARAM_GRAVITY_VECTOR, gravity.normalized())

