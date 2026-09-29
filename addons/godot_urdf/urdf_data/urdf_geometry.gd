# URDF Geometry, either a collider or a visual
class_name URDFGeometry
extends Resource

# All XYZ will be kept as is originally in URDF file
# Y and Z should be flipped when generating Nodes

# transform
@export var origin_xyz: Vector3
@export var origin_rpy: Vector3

@export var type: Type
# BOX
@export var size: Vector3
# SPHERE, CYLINDER
@export var radius: float
@export var length: float
# MESH
@export var mesh_path: String
@export var mesh_scale: Vector3 = Vector3.ONE

enum Type {BOX, MESH, CYLINDER, SPHERE}

func parse_collision(parser):
	if parser.is_empty():
		return
	while parser.read() == OK:
		var node_type = parser.get_node_type()
		if node_type == XMLParser.NODE_TEXT:
			continue
		var node_name = parser.get_node_name()
		if node_type == XMLParser.NODE_ELEMENT:
			match node_name:
				"origin":
					self.origin_xyz = XMLHelper.attr_to_vector3(parser, "xyz")
					self.origin_rpy = XMLHelper.attr_to_vector3(parser, "rpy")
				"geometry":
					URDFUtils.parse_geometry(parser, self, false)
				_:
					push_error(
						"[URDF] Unsupported collider for Link: %s" % node_name)
					parser.skip_section()
		elif node_type == XMLParser.NODE_ELEMENT_END:
			if node_name == "collision":
				return
	return
