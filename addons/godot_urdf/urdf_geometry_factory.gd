class_name URDFGeometryFactory

static var resource_cache: Dictionary = {}

static func _clean_path(
		package_path: String,
		options: URDFOptions,
		source_path: String) -> String:
	var clean_path = package_path.replace("package://", "")
	if options.package_folder and options.package_folder != "":
		return options["package_folder"].path_join(clean_path)
	# Fallback: try to find it relative to the URDF file
	return source_path.get_base_dir().path_join(clean_path)

static func load_resource(
		path: String, opts: URDFOptions, source_path: String) -> Resource:
	path = _clean_path(path, opts, source_path)
	if resource_cache.has(path): return resource_cache[path]
	var res = load(path)
	resource_cache[path] = res
	return res

static func get_visual_callable(type: int) -> Callable:
	match type:
		URDFGeometry.Type.BOX:
			return create_box_visual
		URDFGeometry.Type.CYLINDER:
			return create_cylinder_visual
		URDFGeometry.Type.SPHERE:
			return create_sphere_visual
		URDFGeometry.Type.MESH:
			return create_mesh_resource_visual
	return Callable()

static func get_collision_callable(type: int) -> Callable:
	match type:
		URDFGeometry.Type.BOX:
			return create_box_collision
		URDFGeometry.Type.CYLINDER:
			return create_cylinder_collision
		URDFGeometry.Type.SPHERE:
			return create_sphere_collision
		URDFGeometry.Type.MESH:
			return create_mesh_resource_collision
	return Callable()


# Visual
static func create_box_visual(
		parent: Node3D, owner: Node, data: URDFVisual,
		_opts: URDFOptions, _path: String, material: BaseMaterial3D,
		offset: Transform3D = Transform3D.IDENTITY):
	var mesh_inst = MeshInstance3D.new()
	mesh_inst.mesh = BoxMesh.new()
	var urdf_size = data.size
	mesh_inst.mesh.size = Vector3(urdf_size.y, urdf_size.z, urdf_size.x)
	_finalize(
		mesh_inst, parent, owner, material,
		data.origin_xyz, data.origin_rpy, offset)

static func create_cylinder_visual(
		parent: Node3D, owner: Node, data: URDFVisual,
		_opts: URDFOptions, _path: String, material: BaseMaterial3D,
		offset: Transform3D = Transform3D.IDENTITY):
	var mesh_inst = MeshInstance3D.new()
	var cm = CylinderMesh.new()
	cm.height = data.length
	cm.top_radius = data.radius
	cm.bottom_radius = data.radius
	mesh_inst.mesh = cm
	_finalize(
		mesh_inst, parent, owner, material,
		data.origin_xyz, data.origin_rpy, offset)

static func create_sphere_visual(
		parent: Node3D, owner: Node, data: URDFVisual,
		_opts: URDFOptions, _path: String, material: BaseMaterial3D,
		offset: Transform3D = Transform3D.IDENTITY):
	var mesh_inst = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = data.radius
	sphere.height = data.radius * 2
	mesh_inst.mesh = sphere
	_finalize(
		mesh_inst, parent, owner, material,
		data.origin_xyz, data.origin_rpy, offset)

static func create_mesh_resource_visual(
		parent: Node3D, owner: Node, data: URDFVisual,
		opts: URDFOptions, source_path: String, material: BaseMaterial3D,
		offset: Transform3D = Transform3D.IDENTITY):
	var resource = load_resource(data.mesh_path, opts, source_path)
	var instance
	if resource is PackedScene:
		instance = resource.instantiate()
		_finalize(
			instance, parent, owner, material,
			data.origin_xyz, data.origin_rpy, offset)
	elif (resource is Mesh) or (resource is ArrayMesh):
		instance = MeshInstance3D.new()
		instance.mesh = resource
		_finalize(
			instance, parent, owner, material,
			data.origin_xyz, data.origin_rpy, offset)
	else:
		push_error(
			"Error loading " + data.mesh_path +
			" - Unknown Resource type:" + type_string(typeof(resource)))
		return

	var ext = data.mesh_path.get_extension().to_lower()
	if ext == "stl":
		instance.transform.basis = instance.transform.basis * URDFUtils.URDF_TO_GODOT
	else:
		# The importer already applied some rotations
		instance.transform.basis = instance.transform.basis * URDFUtils.IMPORTED_TO_GODOT
	
	var _scale = opts.scale
	instance.scale = Vector3(_scale, _scale, _scale)

# Collision
static func create_box_collision(
		parent: Node3D, owner: Node, data: URDFGeometry,
		_opts: URDFOptions, _path: String,
		offset: Transform3D = Transform3D.IDENTITY):
	var coll = CollisionShape3D.new()
	coll.shape = BoxShape3D.new()
	var urdf_size = data.size
	coll.shape.size = Vector3(urdf_size.y, urdf_size.z, urdf_size.x)
	_finalize(
		coll, parent, owner, null, data.origin_xyz, data.origin_rpy, offset)

static func create_cylinder_collision(
		parent: Node3D, owner: Node, data: URDFGeometry,
		_opts: URDFOptions, _path: String,
		offset: Transform3D = Transform3D.IDENTITY):
	var coll = CollisionShape3D.new()
	var shape = CylinderShape3D.new()
	shape.height = data.length
	shape.radius = data.radius
	coll.shape = shape
	_finalize(
		coll, parent, owner, null, data.origin_xyz, data.origin_rpy, offset)

static func create_sphere_collision(
		parent: Node3D, owner: Node, data: URDFGeometry,
		_opts: URDFOptions, _path: String,
		offset: Transform3D = Transform3D.IDENTITY):
	var coll = CollisionShape3D.new()
	var shape = SphereShape3D.new()
	shape.radius = data.radius
	coll.shape = shape
	_finalize(
		coll, parent, owner, null, data.origin_xyz, data.origin_rpy, offset)


static func create_mesh_resource_collision(
		parent: Node3D, owner: Node, data: URDFGeometry,
		opts: URDFOptions, source_path: String,
		offset: Transform3D = Transform3D.IDENTITY):
	var resource = load_resource(data.mesh_path, opts, source_path)
	var urdf_transform = offset * URDFUtils.godot_xyz_rpy(
		data.origin_xyz, data.origin_rpy)
	
	if resource is Mesh:
		_create_col_shape_from_mesh(
			resource, urdf_transform, parent, owner, opts)
	elif resource is PackedScene:
		var temp_scene = resource.instantiate()
		_recursive_collision_gen(
			temp_scene, urdf_transform, parent, owner, opts)
		temp_scene.queue_free()


static func _recursive_collision_gen(
		node: Node, base_transform: Transform3D, 
		parent: Node3D, owner: Node,
		opts: URDFOptions):
	if node is MeshInstance3D:
		# Combine the URDF offset with the mesh's internal local transform
		var final_transform = base_transform * node.transform
		_create_col_shape_from_mesh(
			node.mesh, final_transform, parent, owner, opts)
	
	for child in node.get_children():
		_recursive_collision_gen(
			child, base_transform, parent, owner, opts)


static func _create_col_shape_from_mesh(
		mesh: Mesh, tr: Transform3D, 
		parent: Node3D, owner: Node,
		opts: URDFOptions):
	var shape = mesh.create_convex_shape(true, true)
	if shape:
		var coll = CollisionShape3D.new()
		coll.shape = shape
		coll.name = parent.name + "_collision"
		parent.add_child(coll)
		coll.owner = owner
		coll.transform = tr
		coll.transform.basis = coll.transform.basis * URDFUtils.URDF_TO_GODOT

static func _finalize(
		node: Node3D, parent: Node, owner: Node, 
		material: BaseMaterial3D,
		xyz: Vector3, rpy: Vector3,
		offset: Transform3D = Transform3D.IDENTITY, num: int = 0):
	parent.add_child(node)
	if node is CollisionShape3D:
		node.name = parent.name + "_collision"
	else:
		node.name = parent.name + "_mesh"
		if material:
			node.material_override = material
	if num > 0:
		node.name += "_" + str(num)
	node.owner = owner
	node.transform = offset * URDFUtils.godot_xyz_rpy(xyz, rpy)


static func create_visuals(
		parent: Node3D,
		robot_node: Node3D,
		owner_node: Node3D,
		options: URDFOptions,
		source_path: String,
		link: URDFLink,
		offset: Transform3D = Transform3D.IDENTITY):
	for visual in link.visuals:
		var material = StandardMaterial3D.new()
		var color = visual.material_color
		var urdf_robot = robot_node.urdf_robot
		if color != null:
			material.albedo_color = color
		elif visual.material_name in urdf_robot.materials:
			color = urdf_robot.materials[visual.material_name]
			material.albedo_color = color
		else:
			push_warning(
				"Invalid color for %s, highlighting part in pink!" % link.name)
			material.albedo_color = Color.PINK

		var gen = get_visual_callable(int(visual.type))
		if gen:
			gen.call(
				parent, owner_node, visual, options, source_path, 
				material, offset)
		else:
			push_error("Unknown type %s" % visual.type)
