class_name SDFSurface
# see https://sdformat.org/spec/1.12/collision/#collision_surface
extends Resource

@export_group("Bounce")
@export var restitution_coefficient: float = 0.0
@export var bounce_threshold: float = 100000.0

@export_group("Friction")
@export var torsional_coefficient: float = 1.0
# TODO: more values
@export var torsional_ode_slip: float = 1.0
# ODE
@export var ode_mu: float = 1.0
@export var ode_mu2: float = 1.0
@export var ode_fdir1: Vector3 = Vector3.ZERO
@export var ode_slip1: float = 0.0
@export var ode_slip2: float = 0.0

@export_group("Contact")
@export var collide_without_contact: bool = false
@export var collide_without_contact_bitmask: int = 1
@export var collide_bitmask: int = 0xFFFF
@export var category_bitmask: int = 0xFFFF
@export var poissons_ratio: float = 0.3
@export var elastic_modulus: float = -1.0
# TODO: special ODE/bullet/soft_contact values

func parse(parser: XMLParser):
	if parser.is_empty():
		return
	while parser.read() == OK:
		var node_type = parser.get_node_type()
		if node_type == XMLParser.NODE_ELEMENT_END:
			return
		if node_type != XMLParser.NODE_ELEMENT:
			continue
		match parser.get_node_name():
			"bounce":
				_parse_bounce(parser)
			"friction":
				_parse_friction(parser)
			"contact":
				_parse_contact(parser)
			"soft_contact":
				parser.skip_section()
			_:
				XMLHelper.skip_unknown(parser, "surface")

func _parse_bounce(parser: XMLParser):
	if parser.is_empty():
		return
	while parser.read() == OK:
		var node_type = parser.get_node_type()
		if node_type == XMLParser.NODE_ELEMENT_END:
			return
		if node_type != XMLParser.NODE_ELEMENT:
			continue
		match parser.get_node_name():
			"restitution_coefficient":
				self.restitution_coefficient = XMLHelper.text_to_float(
					parser, self.restitution_coefficient)
			"threshold":
				self.bounce_threshold = XMLHelper.text_to_float(
					parser, self.bounce_threshold)
			_:
				XMLHelper.skip_unknown(parser, "bounce")

func _parse_friction(parser: XMLParser):
	if parser.is_empty():
		return
	while parser.read() == OK:
		var node_type = parser.get_node_type()
		if node_type == XMLParser.NODE_ELEMENT_END:
			return
		if node_type != XMLParser.NODE_ELEMENT:
			continue
		match parser.get_node_name():
			"torsional":
				_parse_torsional(parser)
			"ode":
				_parse_friction_ode(parser)
			"bullet":
				parser.skip_section()
			_:
				XMLHelper.skip_unknown(parser, "friction")

func _parse_torsional(parser: XMLParser):
	if parser.is_empty():
		return
	while parser.read() == OK:
		var node_type = parser.get_node_type()
		if node_type == XMLParser.NODE_ELEMENT_END:
			return
		if node_type != XMLParser.NODE_ELEMENT:
			continue
		match parser.get_node_name():
			"coefficient":
				self.torsional_coefficient = XMLHelper.text_to_float(
					parser, self.torsional_coefficient)
			"use_patch_radius", "patch_radius", "surface_radius", "ode":
				parser.skip_section()
			_:
				XMLHelper.skip_unknown(parser, "torsional")

func _parse_friction_ode(parser: XMLParser):
	if parser.is_empty():
		return
	while parser.read() == OK:
		var node_type = parser.get_node_type()
		if node_type == XMLParser.NODE_ELEMENT_END:
			return
		if node_type != XMLParser.NODE_ELEMENT:
			continue
		match parser.get_node_name():
			"mu":
				self.ode_mu = XMLHelper.text_to_float(
					parser, self.ode_mu)
			"mu2":
				self.ode_mu2 = XMLHelper.text_to_float(
					parser, self.ode_mu2)
			"fdir1":
				self.ode_fdir1 = XMLHelper.text_to_vector3(
					parser, self.ode_fdir1)
			"slip1":
				self.ode_slip1 = XMLHelper.text_to_float(
					parser, self.ode_slip1)
			"slip2":
				self.ode_slip2 = XMLHelper.text_to_float(
					parser, self.ode_slip2)
			_:
				XMLHelper.skip_unknown(parser, "friction/ode")

func _parse_contact(parser: XMLParser):
	if parser.is_empty():
		return
	while parser.read() == OK:
		var node_type = parser.get_node_type()
		if node_type == XMLParser.NODE_ELEMENT_END:
			return
		if node_type != XMLParser.NODE_ELEMENT:
			continue
		match parser.get_node_name():
			"collide_without_contact":
				self.collide_without_contact = XMLHelper.text_to_bool(
					parser, self.collide_without_contact)
			"collide_without_contact_bitmask":
				self.collide_without_contact_bitmask = XMLHelper.text_to_int(
					parser, self.collide_without_contact_bitmask)
			"collide_bitmask":
				self.collide_bitmask = XMLHelper.text_to_int(
					parser, self.collide_bitmask)
			"category_bitmask":
				self.category_bitmask = XMLHelper.text_to_int(
					parser, self.category_bitmask)
			"poissons_ratio":
				self.poissons_ratio = XMLHelper.text_to_float(
					parser, self.poissons_ratio)
			"elastic_modulus":
				self.elastic_modulus = XMLHelper.text_to_float(
					parser, self.elastic_modulus)
			"ode", "bullet":
				parser.skip_section()
			_:
				XMLHelper.skip_unknown(parser, "contact")
