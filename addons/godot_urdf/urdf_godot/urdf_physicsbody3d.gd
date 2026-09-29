class_name URDFPhysicsBody3D

static func create_root_link(
		body: PhysicsBody3D,
		link: URDFLink,
		robot_node: GodotURDFRobot,
		owner_node: Node3D,
		options: URDFOptions,
		source_path: String,
		offset: Transform3D = Transform3D.IDENTITY) -> void:
	body.name = link.name
	robot_node.add_child(body)
	body.owner = owner_node
	update_link(
		body, link, robot_node, owner_node, options, source_path, offset)

static func update_link(
		body: PhysicsBody3D,
		link: URDFLink,
		robot_node: GodotURDFRobot,
		owner_node: Node3D,
		options: URDFOptions,
		source_path: String,
		offset: Transform3D = Transform3D.IDENTITY) -> void:
	body.name = link.name
	var has_collider = false
	for col_data in link.colliders:
		var gen = URDFGeometryFactory.get_collision_callable(int(col_data.type))
		if gen:
			has_collider = true
			gen.call(body, owner_node, col_data, options, source_path, offset)
		else:
			push_error("Unknown type %s" % col_data.type)

	if options.create_collider_from_visual and not has_collider:
		# print("[URDF " + link.name + "] Create collider from visual.")
		for vis_data in link.visuals:
			var gen = URDFGeometryFactory.get_collision_callable(
				int(vis_data.type))
			if gen:
				gen.call(body, owner_node, vis_data, options, source_path, offset)
			else:
				push_error("Unknown type %s" % vis_data.type)

	URDFGeometryFactory.create_visuals(
		body, robot_node, owner_node, options, source_path, link, offset)
