class_name SDFGeometry
# see https://sdformat.org/spec/1.12/geometry/
extends Resource

# see also URDFGeometry.Type
enum GeometryType {
	BOX, SPHERE, CONE, CYLINDER, MESH, PLANE, CAPSULE,
	ELLIPSOID, HEIGHTMAP, POLYLINE, EMPTY
}


@export var type: GeometryType = GeometryType.BOX
@export var size: Vector3 = Vector3.ONE  # plane, box, mesh or heightmap

@export var radius: float = 1.0  # sphere, cone or cylinder

@export var length: float = 1.0  # cone or cylinder

@export var uri: String = ""  # mesh, heightmap
@export var scale: Vector3 = Vector3.ONE  # mesh
@export var submesh_name: String = ""  # mesh
@export var submesh_center: bool = false  # mesh

@export var radii: Vector3 = Vector3.ONE  # ellipsoid

@export var normal: Vector3 = Vector3(0, 0, 1)  # plane
@export var plane_size: Vector2 = Vector2.ONE  # plane

@export var points: PackedVector2Array = PackedVector2Array()  # polyline
@export var height: float = 1.0  # polyline

@export var heightmap_pos: Vector3 = Vector3.ZERO  # heightmap
# TODO: heightmap texture and blend?
# TODO: image?

func parse(parser: SDFParser):
	if parser.is_empty():
		return
	while parser.read() == OK:
		var node_type = parser.get_node_type()
		if node_type == XMLParser.NODE_ELEMENT_END:
			return
		if node_type != XMLParser.NODE_ELEMENT:
			continue
		match parser.get_node_name():
			"empty":
				self.type = GeometryType.EMPTY
				parser.skip_section()
			"box":
				self.type = GeometryType.BOX
				_parse_shape(parser)
			"sphere":
				self.type = GeometryType.SPHERE
				_parse_shape(parser)
			"cylinder":
				self.type = GeometryType.CYLINDER
				_parse_shape(parser)
			"cone":
				self.type = GeometryType.CONE
				_parse_shape(parser)
			"capsule":
				self.type = GeometryType.CAPSULE
				self.radius = 0.5  # spec default differs from the other shapes
				_parse_shape(parser)
			"ellipsoid":
				self.type = GeometryType.ELLIPSOID
				_parse_shape(parser)
			"plane":
				self.type = GeometryType.PLANE
				_parse_shape(parser)
			"mesh":
				self.type = GeometryType.MESH
				_parse_shape(parser)
			"polyline":
				self.type = GeometryType.POLYLINE
				_parse_shape(parser)
			"heightmap":
				self.type = GeometryType.HEIGHTMAP
				_parse_shape(parser)
			"image":
				push_warning("image geometry is deprecated and not supported, skipped")
				parser.skip_section()
			_:
				XMLHelper.skip_unknown(parser, "geometry")

## Shape elements share a flat set of child names, so one loop handles all.
func _parse_shape(parser: SDFParser):
	var shape = parser.get_node_name()
	if parser.is_empty():
		return
	while parser.read() == OK:
		var node_type = parser.get_node_type()
		if node_type == XMLParser.NODE_ELEMENT_END:
			return
		if node_type != XMLParser.NODE_ELEMENT:
			continue
		match parser.get_node_name():
			"size":
				if self.type == GeometryType.PLANE:
					self.plane_size = XMLHelper.text_to_vector2(parser, self.plane_size)
				else:
					self.size = XMLHelper.text_to_vector3(parser, self.size)
			"radius":
				self.radius = XMLHelper.text_to_float(parser, self.radius)
			"length":
				self.length = XMLHelper.text_to_float(parser, self.length)
			"radii":
				self.radii = XMLHelper.text_to_vector3(parser, self.radii)
			"normal":
				self.normal = XMLHelper.text_to_vector3(parser, self.normal)
			"uri":
				var raw_uri = XMLHelper.text_to_string(parser)
				var resolved = parser.resolve_uri(raw_uri)
				self.uri = resolved if not resolved.is_empty() else raw_uri
			"scale":
				self.scale = XMLHelper.text_to_vector3(parser, self.scale)
			"submesh":
				_parse_submesh(parser)
			"point":
				self.points.append(XMLHelper.text_to_vector2(parser, Vector2.ZERO))
			"height":
				self.height = XMLHelper.text_to_float(parser, self.height)
			"pos":
				self.heightmap_pos = XMLHelper.text_to_vector3(parser, self.heightmap_pos)
			"convex_decomposition", "texture", "blend", "use_terrain_paging", "sampling":
				parser.skip_section()
			_:
				XMLHelper.skip_unknown(parser, shape)

func _parse_submesh(parser: XMLParser):
	if parser.is_empty():
		return
	while parser.read() == OK:
		var node_type = parser.get_node_type()
		if node_type == XMLParser.NODE_ELEMENT_END:
			return
		if node_type != XMLParser.NODE_ELEMENT:
			continue
		match parser.get_node_name():
			"name":
				self.submesh_name = XMLHelper.text_to_string(parser)
			"center":
				self.submesh_center = XMLHelper.text_to_bool(parser, self.submesh_center)
			_:
				XMLHelper.skip_unknown(parser, "submesh")

func create_godot_shape(convex: bool = false) -> Shape3D:
	match type:
		GeometryType.BOX:
			var shape = BoxShape3D.new()
			shape.size = size
			return shape
		GeometryType.SPHERE:
			var shape = SphereShape3D.new()
			shape.radius = radius
			return shape
		# TODO: cone
		GeometryType.CYLINDER:
			var shape = CylinderShape3D.new()
			shape.radius = radius
			shape.height = length
			return shape
		GeometryType.CAPSULE:
			var shape = CapsuleShape3D.new()
			shape.radius = radius
			shape.height = length + 2.0 * radius  # Godot height includes the caps
			return shape
		GeometryType.PLANE:
			return BoxShape3D.new()  # Simplified as flat box for now
		GeometryType.MESH:
			var faces = _mesh_faces()
			if convex:
				var shape = ConvexPolygonShape3D.new()
				shape.points = faces
				return shape
			var shape = ConcavePolygonShape3D.new()
			shape.set_faces(faces)
			return shape
		_:
			return BoxShape3D.new()

func create_godot_mesh() -> Mesh:
	match type:
		GeometryType.BOX:
			var mesh = BoxMesh.new()
			mesh.size = size
			return mesh
		GeometryType.SPHERE:
			var mesh = SphereMesh.new()
			mesh.radius = radius
			mesh.height = radius * 2.0
			return mesh
		GeometryType.CYLINDER:
			var mesh = CylinderMesh.new()
			mesh.top_radius = radius
			mesh.bottom_radius = radius
			mesh.height = length
			return mesh
		GeometryType.CAPSULE:
			var mesh = CapsuleMesh.new()
			mesh.radius = radius
			mesh.height = length + 2.0 * radius
			return mesh
		GeometryType.MESH:
			if ResourceLoader.exists(uri):
				return load(uri)
			return PlaneMesh.new()
		_:
			return PlaneMesh.new()

func mesh_basis() -> Basis:
	return URDFUtils.URDF_TO_GODOT * Basis.from_scale(scale)

# Faces of the mesh file including its scale, physics shapes must not be
# scaled by their node.
func _mesh_faces() -> PackedVector3Array:
	var faces = PackedVector3Array()
	if not ResourceLoader.exists(uri):
		push_error("[SDF] Mesh not found: %s" % uri)
		return faces
	var resource = load(uri)
	var mesh_transform = Transform3D(mesh_basis(), Vector3.ZERO)
	if resource is Mesh:
		return mesh_transform * resource.get_faces()
	if resource is PackedScene:  # e.g. dae
		var scene = resource.instantiate()
		for mesh_instance in scene.find_children("*", "MeshInstance3D"):
			var transform = Transform3D.IDENTITY
			var node: Node = mesh_instance
			while node != scene:
				transform = node.transform * transform
				node = node.get_parent()
			faces.append_array(mesh_transform * transform * mesh_instance.mesh.get_faces())
		scene.free()
	return faces
