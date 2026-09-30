class_name SDFUtils

static func text_to_bool(text: String) -> bool:
	return text.strip_edges().to_lower() in ["true", "yes", "1", "t", "y"]

static func create_body(
		model: SDFModel,
		parent_static: bool,
		parent_node: Node3D,
		owner_node: Node3D) -> Node3D:
	if model.links.is_empty():
		# without link there is nothing to collide
		var group = GodotSDFModel.new()
		group.to_godot(model, parent_static, parent_node, owner_node)
		return group
	var body
	if parent_static or model.static_model:
		body = GodotSDFStaticBody3D.new()
	else:
		body = GodotSDFRigidBody3D.new()
	body.to_godot(model, parent_node, owner_node)
	return body

# For now all links are merged into the body of their model.
# TODO: one body per link, connected by the joints.
static func add_links(
		body: PhysicsBody3D,
		model: SDFModel,
		owner_node: Node3D,
		convex: bool):
	for link in model.links:
		var link_transform = link.pose.to_godot_transform3d()
		for visual in link.visual:
			var visual_node = GodotSDFVisual.new()
			visual_node.to_godot(visual, body, owner_node, link_transform)
		for collision in link.collision:
			var shape = GodotSDFCollisionShape3D.new()
			shape.to_godot(collision, convex, link_transform)
			body.add_child(shape)
			shape.owner = owner_node
		for sensor in link.sensors:
			if sensor.type == "camera":
				var camera = GodotSDFCamera3D.new()
				camera.to_godot(sensor, body, owner_node, link_transform)
			# TODO: other sensor types
	for nested_model in model.models:
		create_body(nested_model, body is StaticBody3D, body, owner_node)

static func create_light(
		light: SDFLight,
		parent_node: Node3D,
		owner_node: Node3D) -> Light3D:
	var light_node
	match light.type:
		"directional":
			light_node = GodotSDFDirectionalLight3D.new()
		"point":
			light_node = GodotSDFOmniLight3D.new()
		"spot":
			light_node = GodotSDFSpotLight3D.new()
		_:
			push_error("[SDF] Unknown type '%s' of light %s" % [light.type, light.name])
			return null
	light_node.to_godot(light, parent_node, owner_node)
	return light_node

