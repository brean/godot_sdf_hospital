@tool
class_name URDFRobot
extends Resource

signal joint_values_changed(joint)

@export var name: String
@export var links: Array[URDFLink] = []
@export var joints: Array[URDFJoint] = []
@export var materials: Dictionary[String, Color] = {}

func get_child_joints(link_name: String) -> Array[URDFJoint]:
	var children: Array[URDFJoint] = []
	for joint in joints:
		if joint.parent == link_name:
			children.append(joint)
	return children
	
func get_link(link_name: String) -> URDFLink:
	for link in links:
		if link.name == link_name:
			return link
	return null

func get_root_links() -> Array[String]:
	var roots: Array[String] = []
	for link in links:
		var parent = get_parent_joint(link.name)
		if not parent:
			roots.append(link.name)
	return roots

func get_parent_joint(link_name: String) -> URDFJoint:
	for joint in joints:
		if joint.child == link_name:
			return joint
	return null

func dynamic_root(link_name: String) -> String:
	# Get root links for fixed links so we can join them together.
	var joint = get_parent_joint(link_name)
	if joint == null or not joint.type == "fixed":
		return link_name
	return dynamic_root(joint.parent)


func group_fixed_to_dynamics() -> Dictionary:
	# Create groups of fixed links so we can add them to
	# dynamic (revolute, continous or prismatic) links as children.
	var groups := {}
	for link in links:
		var root = dynamic_root(link.name)
		if not groups.has(root):
			groups[root] = []
		groups[root].append(link.name)
	for root in groups.keys():
		groups[root].erase(root)
		groups[root].push_front(root)
	return groups

func fixed_offset(link_name: String) -> Transform3D:
	var joint = get_parent_joint(link_name)
	if joint == null or not joint.type == "fixed":
		return Transform3D.IDENTITY
	return fixed_offset(joint.parent) \
		* URDFUtils.godot_xyz_rpy(joint.origin_xyz, joint.origin_rpy)


func link_fk(link_name: String) -> Transform3D:
	# get transform of link using forward kinematics
	var joint = get_parent_joint(link_name)
	if joint == null:
		return Transform3D.IDENTITY

	var parent_transform = link_fk(joint.parent) \
		* URDFUtils.godot_xyz_rpy(joint.origin_xyz, joint.origin_rpy)
	var value: float = joint.value
	if value != 0.0:
		if joint.type == "revolute" or joint.type == "continuous":
			parent_transform.basis *= Basis(joint.godot_axis, value)
		elif joint.type == "prismatic":
			parent_transform.origin += parent_transform.basis * (
				joint.godot_axis * value)
	return parent_transform


func parse(parser):
	self.name = parser.get_named_attribute_value_safe("name")
	print("[URDF] robot name: %s" % self.name)

	while parser.read() == OK:
		var node_type = parser.get_node_type()
		if node_type == XMLParser.NODE_TEXT:
			continue
		var node_name = parser.get_node_name()
		
		if node_type == XMLParser.NODE_ELEMENT:
			match node_name:
				"link":
					var link: URDFLink = URDFLink.new()
					link.parse(parser)
					self.links.append(link)
				"joint":
					var joint: URDFJoint = URDFJoint.new()
					joint.robot = self
					joint.parse(parser)
					self.joints.append(joint)
				"material":
					parse_material(parser)
				_:
					push_warning(
						"[URDF]" +
						"Ignoring unsupported tag in robot: ", node_name)
					parser.skip_section()

		elif node_type == XMLParser.NODE_ELEMENT_END:
			if node_name == "robot":
				return

func parse_material(parser: XMLParser):
	var material_name = parser.get_named_attribute_value_safe("name")
	self.materials[material_name] = URDFUtils.parse_material_color(parser, Color.PINK)
