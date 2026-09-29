class_name URDFUtils

const URDF_TO_GODOT = Basis(
	Vector3(0, 0, -1), # URDF X is Godot -Z
	Vector3(-1, 0, 0), # URDF Y is Godot -X
	Vector3(0, 1, 0)   # URDF Z is Godot Y
)

# Used for meshes where the importer for Godot already applied a Z-up to Y-up 
# conversion, but the forward axis (+X) still needs to be aligned to Godot (-Z).
# ( same as rotate_y(PI / 2) )
const IMPORTED_TO_GODOT = Basis(
	Vector3(0, 0, -1), # Map X-forward to -Z-forward
	Vector3(0, 1, 0),  # Keep Y-up as is
	Vector3(1, 0, 0)   # Map Z to X
)

const GODOT_TO_URDF = Basis(
	Vector3(0, -1, 0),
	Vector3(0, 0, 1),
	Vector3(-1, 0, 0)
)

static func xyz_rpy_to_transform3d(xyz: Vector3, rpy: Vector3) -> Transform3D:
	var urdf_basis = Basis.from_euler(rpy, EULER_ORDER_ZYX)
	return Transform3D(urdf_basis, xyz)

static func godot_xyz_rpy(xyz: Vector3, rpy: Vector3) -> Transform3D:
	return godot_transform3d(xyz_rpy_to_transform3d(xyz, rpy))

static func godot_transform3d(urdf_transform: Transform3D) -> Transform3D:
	var godot_origin = URDF_TO_GODOT * urdf_transform.origin
	var godot_basis = URDF_TO_GODOT * urdf_transform.basis * GODOT_TO_URDF
	return Transform3D(godot_basis, godot_origin)

static func convert_axis(urdf_axis: Vector3) -> Vector3:
	# Convert axis from URDF to godot coordinate system.
	return URDF_TO_GODOT * urdf_axis


static func signed_angle_about(delta_basis: Basis, axis: Vector3) -> float:
	# Calculate the signed rotation angle of `delta_basis` about `axis`
	# (right hand rule), in (-PI, PI].
	var quat: Quaternion = delta_basis.get_rotation_quaternion()
	if quat.w < 0.0:
		quat = Quaternion(-quat.x, -quat.y, -quat.z, -quat.w)
	var v: Vector3 = Vector3(quat.x, quat.y, quat.z)
	var angle: float= 2.0 * acos(clampf(quat.w, -1.0, 1.0))
	if v.length_squared() < 1e-12:
		return 0.0
	return angle * signf(v.dot(axis))

static func parse_material_color(
		parser: XMLParser,
		fallback = Color.TRANSPARENT) -> Variant:
	var material_color = fallback
	if parser.is_empty():
		return material_color

	while parser.read() == OK:
		var node_type = parser.get_node_type()
		if node_type == XMLParser.NODE_TEXT: continue
		if node_type == XMLParser.NODE_ELEMENT and \
				parser.get_node_name() == "color":
			material_color = XMLHelper.attr_to_color(
				parser, "rgba", fallback)
		elif node_type == XMLParser.NODE_ELEMENT_END:
			if parser.get_node_name() == "material":
				return material_color
	return material_color


static func parse_geometry(
		parser: XMLParser,
		target_object: Object,
		is_visual: bool) -> void:
	if parser.is_empty():
		return

	while parser.read() == OK:
		var node_type = parser.get_node_type()
		if node_type == XMLParser.NODE_TEXT: continue
		
		if node_type == XMLParser.NODE_ELEMENT:
			var node_name = parser.get_node_name()
			match node_name:
				"box":
					if is_visual: target_object.type = URDFVisual.Type.BOX
					else: target_object.type = URDFGeometry.Type.BOX
					
					var size = parser.get_named_attribute_value_safe("size")
					target_object.size = XMLHelper.attr_to_vector3(
						parser, "size", Vector3.ONE)
				"cylinder":
					if is_visual: target_object.type = URDFVisual.Type.CYLINDER
					else: target_object.type = URDFGeometry.Type.CYLINDER
					
					target_object.length = XMLHelper.attr_to_float(parser, "length")
					target_object.radius = XMLHelper.attr_to_float(parser, "radius")
				"sphere":
					if is_visual: target_object.type = URDFVisual.Type.SPHERE
					else: target_object.type = URDFGeometry.Type.SPHERE
					
					target_object.radius = XMLHelper.attr_to_float(parser,"radius")
				"mesh":
					if is_visual: target_object.type = URDFVisual.Type.MESH
					else: target_object.type = URDFGeometry.Type.MESH
					
					var filename = parser.get_named_attribute_value_safe("filename")
					target_object.mesh_path = filename
				_:
					push_error(
						"[URDF] Unsupported geometry for visual" +
						" in link properties: " + node_name)
					parser.skip_section()
		elif node_type == XMLParser.NODE_ELEMENT_END:
			if parser.get_node_name() == "geometry":
				return
