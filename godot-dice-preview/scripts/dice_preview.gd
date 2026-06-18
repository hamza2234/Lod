extends Node3D

const SKINS := [
	{
		"name": "Royal Gold",
		"label": "ذهب ملكي",
		"rarity": "Legendary",
		"description": "نرد ذهبي ملكي بحواف لامعة ونقاط مضيئة.",
		"body": Color("#f6c75f"),
		"edge": Color("#8b4b13"),
		"pip": Color("#fff6c3"),
		"accent": Color("#ffd86b"),
		"metallic": 0.9,
		"roughness": 0.16,
	},
	{
		"name": "Inferno Core",
		"label": "نار وبركان",
		"rarity": "Epic",
		"description": "نرد داكن بقلب ناري وشرارات حمراء أثناء الرمي.",
		"body": Color("#1b0b0a"),
		"edge": Color("#ff4b1f"),
		"pip": Color("#ffd3a4"),
		"accent": Color("#ff5c25"),
		"metallic": 0.45,
		"roughness": 0.28,
	},
	{
		"name": "Frost Crystal",
		"label": "كريستال جليدي",
		"rarity": "Rare",
		"description": "نرد زجاجي بارد بنقاط بيضاء وضباب خفيف.",
		"body": Color("#8adcf7"),
		"edge": Color("#defbff"),
		"pip": Color("#ffffff"),
		"accent": Color("#8deaff"),
		"metallic": 0.15,
		"roughness": 0.05,
	},
	{
		"name": "Galaxy Void",
		"label": "مجرة بنفسجية",
		"rarity": "Mythic",
		"description": "نرد فضائي داكن مع نجوم صغيرة وهالة بنفسجية.",
		"body": Color("#16122d"),
		"edge": Color("#7f5cff"),
		"pip": Color("#f3e8ff"),
		"accent": Color("#a77dff"),
		"metallic": 0.62,
		"roughness": 0.17,
	},
	{
		"name": "Emerald Royal",
		"label": "زمرد فاخر",
		"rarity": "Epic",
		"description": "نرد زمردي لامع بنقاط ذهبية مناسب للبطولات.",
		"body": Color("#0fa66f"),
		"edge": Color("#b7ffbd"),
		"pip": Color("#ffe49c"),
		"accent": Color("#39ff9e"),
		"metallic": 0.62,
		"roughness": 0.14,
	},
]

const FACE_PIPS := {
	1: [Vector2.ZERO],
	2: [Vector2(-0.42, -0.42), Vector2(0.42, 0.42)],
	3: [Vector2(-0.42, -0.42), Vector2.ZERO, Vector2(0.42, 0.42)],
	4: [Vector2(-0.42, -0.42), Vector2(-0.42, 0.42), Vector2(0.42, -0.42), Vector2(0.42, 0.42)],
	5: [Vector2(-0.42, -0.42), Vector2(-0.42, 0.42), Vector2.ZERO, Vector2(0.42, -0.42), Vector2(0.42, 0.42)],
	6: [Vector2(-0.42, -0.48), Vector2(-0.42, 0.0), Vector2(-0.42, 0.48), Vector2(0.42, -0.48), Vector2(0.42, 0.0), Vector2(0.42, 0.48)],
}

var result_rotations := {}
var selected_skin := 0
var dice_root: Node3D
var dice_body: MeshInstance3D
var pip_root: Node3D
var accent_light: OmniLight3D
var under_light: OmniLight3D
var ring: MeshInstance3D
var camera: Camera3D
var result_label: Label
var name_label: Label
var rarity_label: Label
var description_label: Label
var roll_button: Button
var skin_buttons: Array[Button] = []
var sparks: Array[MeshInstance3D] = []

var rolling := false
var roll_time := 0.0
var roll_duration := 2.7
var roll_result := 1
var roll_seed := Vector3.ZERO
var roll_spin := Vector3.ZERO
var blend_start := Quaternion.IDENTITY
var target_rotation := Quaternion.IDENTITY
var blend_started := false


func _ready() -> void:
	randomize()
	_build_result_rotations()
	_build_world()
	_build_ui()
	_select_skin(0)
	dice_root.quaternion = result_rotations[1]


func _process(delta: float) -> void:
	var time := Time.get_ticks_msec() / 1000.0
	ring.rotation.y += delta * 0.45
	accent_light.light_energy = 4.3 + sin(time * 2.5) * 0.8
	under_light.light_energy = 2.4 + sin(time * 3.8) * 0.65
	camera.position.x = sin(time * 0.25) * 0.22
	camera.position.y = 3.15 + sin(time * 0.18) * 0.08
	camera.look_at(Vector3(0, 0.15, 0), Vector3.UP)

	if rolling:
		_update_roll(delta)
	else:
		dice_root.position.y = 0.28 + sin(time * 1.35) * 0.045
		dice_root.rotate_y(delta * 0.22)

	_update_sparks(delta)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("roll_dice"):
		_roll_dice()


func _build_result_rotations() -> void:
	result_rotations = {
		1: Basis.from_euler(Vector3(-PI / 2.0, 0, 0)).get_rotation_quaternion(),
		2: Quaternion.IDENTITY,
		3: Basis.from_euler(Vector3(0, 0, PI / 2.0)).get_rotation_quaternion(),
		4: Basis.from_euler(Vector3(0, 0, -PI / 2.0)).get_rotation_quaternion(),
		5: Basis.from_euler(Vector3(PI, 0, 0)).get_rotation_quaternion(),
		6: Basis.from_euler(Vector3(PI / 2.0, 0, 0)).get_rotation_quaternion(),
	}


func _build_world() -> void:
	var world := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("#070913")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("#a8bbff")
	environment.ambient_light_energy = 0.38
	environment.glow_enabled = true
	environment.glow_intensity = 0.38
	environment.glow_strength = 0.88
	world.environment = environment
	add_child(world)

	camera = Camera3D.new()
	camera.fov = 42.0
	camera.position = Vector3(0, 3.2, 7.0)
	add_child(camera)
	camera.current = true

	var key_light := DirectionalLight3D.new()
	key_light.light_energy = 3.9
	key_light.rotation_degrees = Vector3(-58, -35, 0)
	key_light.shadow_enabled = true
	add_child(key_light)

	accent_light = OmniLight3D.new()
	accent_light.position = Vector3(3.1, 2.6, 2.7)
	accent_light.omni_range = 9.0
	add_child(accent_light)

	under_light = OmniLight3D.new()
	under_light.position = Vector3(0, -0.35, 0.9)
	under_light.omni_range = 6.0
	add_child(under_light)

	var floor := MeshInstance3D.new()
	var floor_mesh := CylinderMesh.new()
	floor_mesh.top_radius = 4.4
	floor_mesh.bottom_radius = 4.4
	floor_mesh.height = 0.06
	floor_mesh.radial_segments = 128
	floor.mesh = floor_mesh
	floor.position.y = -1.08
	floor.material_override = _make_material(Color("#111827"), Color("#1b2440"), 0.3, 0.34)
	add_child(floor)

	var pedestal := MeshInstance3D.new()
	var pedestal_mesh := CylinderMesh.new()
	pedestal_mesh.top_radius = 1.82
	pedestal_mesh.bottom_radius = 2.15
	pedestal_mesh.height = 0.34
	pedestal_mesh.radial_segments = 128
	pedestal.mesh = pedestal_mesh
	pedestal.position.y = -0.86
	pedestal.material_override = _make_material(Color("#161a2c"), Color("#242945"), 0.72, 0.22)
	add_child(pedestal)

	ring = MeshInstance3D.new()
	var ring_mesh := TorusMesh.new()
	ring_mesh.inner_radius = 2.12
	ring_mesh.outer_radius = 2.18
	ring_mesh.ring_segments = 160
	ring_mesh.rings = 10
	ring.mesh = ring_mesh
	ring.position.y = -0.63
	add_child(ring)

	dice_root = Node3D.new()
	dice_root.name = "LuxuryDice"
	dice_root.position.y = 0.28
	add_child(dice_root)

	dice_body = MeshInstance3D.new()
	var box_mesh := BoxMesh.new()
	box_mesh.size = Vector3(2.0, 2.0, 2.0)
	dice_body.mesh = box_mesh
	dice_root.add_child(dice_body)

	var glow_shell := MeshInstance3D.new()
	var glow_mesh := BoxMesh.new()
	glow_mesh.size = Vector3(2.06, 2.06, 2.06)
	glow_shell.mesh = glow_mesh
	glow_shell.name = "SoftOuterGlow"
	dice_root.add_child(glow_shell)

	var click_area := Area3D.new()
	click_area.input_ray_pickable = true
	click_area.input_event.connect(_on_dice_input)
	var shape := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = Vector3(2.25, 2.25, 2.25)
	shape.shape = box_shape
	click_area.add_child(shape)
	dice_root.add_child(click_area)

	pip_root = Node3D.new()
	pip_root.name = "Pips"
	dice_root.add_child(pip_root)


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)

	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(root)

	var left := VBoxContainer.new()
	left.position = Vector2(26, 24)
	left.custom_minimum_size = Vector2(360, 0)
	root.add_child(left)

	var title := Label.new()
	title.text = "Godot Engine Dice Preview"
	title.add_theme_font_size_override("font_size", 28)
	left.add_child(title)

	name_label = Label.new()
	name_label.add_theme_font_size_override("font_size", 36)
	left.add_child(name_label)

	description_label = Label.new()
	description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description_label.custom_minimum_size = Vector2(360, 0)
	left.add_child(description_label)

	var market_title := Label.new()
	market_title.text = "سوق النرد"
	market_title.add_theme_font_size_override("font_size", 22)
	left.add_child(market_title)

	for i in range(SKINS.size()):
		var button := Button.new()
		button.text = "%s - %s" % [SKINS[i]["name"], SKINS[i]["label"]]
		button.custom_minimum_size = Vector2(340, 42)
		button.pressed.connect(_select_skin.bind(i))
		skin_buttons.append(button)
		left.add_child(button)

	var bottom := HBoxContainer.new()
	bottom.anchor_left = 0.5
	bottom.anchor_top = 1.0
	bottom.anchor_right = 0.5
	bottom.anchor_bottom = 1.0
	bottom.offset_left = -230
	bottom.offset_right = 230
	bottom.offset_top = -88
	bottom.offset_bottom = -24
	bottom.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom.add_theme_constant_override("separation", 18)
	root.add_child(bottom)

	result_label = Label.new()
	result_label.text = "جاهز"
	result_label.add_theme_font_size_override("font_size", 38)
	bottom.add_child(result_label)

	roll_button = Button.new()
	roll_button.text = "ارم النرد"
	roll_button.custom_minimum_size = Vector2(160, 56)
	roll_button.pressed.connect(_roll_dice)
	bottom.add_child(roll_button)

	rarity_label = Label.new()
	rarity_label.anchor_left = 1.0
	rarity_label.anchor_right = 1.0
	rarity_label.offset_left = -220
	rarity_label.offset_right = -24
	rarity_label.offset_top = 26
	rarity_label.offset_bottom = 68
	rarity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rarity_label.add_theme_font_size_override("font_size", 22)
	root.add_child(rarity_label)


func _select_skin(index: int) -> void:
	selected_skin = index
	var skin: Dictionary = SKINS[index]
	name_label.text = skin["name"]
	rarity_label.text = skin["rarity"]
	description_label.text = skin["description"]

	for i in range(skin_buttons.size()):
		skin_buttons[i].disabled = i == index

	dice_body.material_override = _make_material(
		skin["body"],
		skin["edge"],
		skin["metallic"],
		skin["roughness"],
	)

	var shell := dice_root.get_node_or_null("SoftOuterGlow") as MeshInstance3D
	if shell:
		var shell_material := StandardMaterial3D.new()
		shell_material.albedo_color = _with_alpha(skin["accent"], 0.12)
		shell_material.emission_enabled = true
		shell_material.emission = skin["accent"]
		shell_material.emission_energy_multiplier = 0.42
		shell_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		shell_material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		shell.material_override = shell_material

	accent_light.light_color = skin["accent"]
	under_light.light_color = skin["accent"]
	ring.material_override = _make_material(skin["accent"], skin["accent"], 0.2, 0.12, 1.8)
	_rebuild_pips()


func _rebuild_pips() -> void:
	for child in pip_root.get_children():
		child.queue_free()

	var pip_material := StandardMaterial3D.new()
	var skin: Dictionary = SKINS[selected_skin]
	pip_material.albedo_color = skin["pip"]
	pip_material.emission_enabled = true
	pip_material.emission = skin["accent"]
	pip_material.emission_energy_multiplier = 1.15
	pip_material.metallic = 0.25
	pip_material.roughness = 0.14

	_add_face_pips(1, "+z", pip_material)
	_add_face_pips(6, "-z", pip_material)
	_add_face_pips(2, "+y", pip_material)
	_add_face_pips(5, "-y", pip_material)
	_add_face_pips(3, "+x", pip_material)
	_add_face_pips(4, "-x", pip_material)

	if SKINS[selected_skin]["name"] == "Galaxy Void":
		_add_galaxy_specks(pip_material)


func _add_face_pips(value: int, face: String, material: StandardMaterial3D) -> void:
	for point in FACE_PIPS[value]:
		var pip := MeshInstance3D.new()
		var mesh := CylinderMesh.new()
		mesh.top_radius = 0.115
		mesh.bottom_radius = 0.115
		mesh.height = 0.032
		mesh.radial_segments = 32
		pip.mesh = mesh
		pip.material_override = material
		_set_face_transform(pip, face, point.x, point.y, 1.018)
		pip_root.add_child(pip)

		var glow := MeshInstance3D.new()
		var glow_mesh := SphereMesh.new()
		glow_mesh.radius = 0.16
		glow_mesh.height = 0.04
		glow_mesh.radial_segments = 24
		glow_mesh.rings = 8
		glow.mesh = glow_mesh
		var glow_material := StandardMaterial3D.new()
		glow_material.albedo_color = _with_alpha(material.emission, 0.18)
		glow_material.emission_enabled = true
		glow_material.emission = material.emission
		glow_material.emission_energy_multiplier = 0.52
		glow_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		glow_material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		glow.material_override = glow_material
		_set_face_transform(glow, face, point.x, point.y, 1.028)
		pip_root.add_child(glow)


func _set_face_transform(node: Node3D, face: String, a: float, b: float, h: float) -> void:
	match face:
		"+z":
			node.position = Vector3(a, b, h)
			node.rotation_degrees = Vector3(90, 0, 0)
		"-z":
			node.position = Vector3(-a, b, -h)
			node.rotation_degrees = Vector3(90, 0, 0)
		"+y":
			node.position = Vector3(a, h, -b)
			node.rotation_degrees = Vector3(0, 0, 0)
		"-y":
			node.position = Vector3(a, -h, b)
			node.rotation_degrees = Vector3(180, 0, 0)
		"+x":
			node.position = Vector3(h, b, -a)
			node.rotation_degrees = Vector3(0, 0, 90)
		"-x":
			node.position = Vector3(-h, b, a)
			node.rotation_degrees = Vector3(0, 0, 90)


func _add_galaxy_specks(material: StandardMaterial3D) -> void:
	for i in range(36):
		var speck := MeshInstance3D.new()
		var mesh := SphereMesh.new()
		mesh.radius = randf_range(0.012, 0.026)
		mesh.height = mesh.radius * 2.0
		mesh.radial_segments = 8
		mesh.rings = 4
		speck.mesh = mesh
		speck.material_override = material
		var faces := ["+z", "-z", "+y", "-y", "+x", "-x"]
		_set_face_transform(
			speck,
			faces[randi() % faces.size()],
			randf_range(-0.72, 0.72),
			randf_range(-0.72, 0.72),
			1.036,
		)
		pip_root.add_child(speck)


func _on_dice_input(_camera: Node, event: InputEvent, _position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_roll_dice()
	elif event is InputEventScreenTouch and event.pressed:
		_roll_dice()


func _roll_dice() -> void:
	if rolling:
		return

	rolling = true
	roll_time = 0.0
	roll_result = randi_range(1, 6)
	roll_seed = Vector3(randf() * PI, randf() * PI, randf() * PI)
	roll_spin = Vector3(randf_range(15, 22), randf_range(18, 27), randf_range(13, 21)) * PI
	blend_started = false
	target_rotation = result_rotations[roll_result]
	result_label.text = "يدور..."
	roll_button.disabled = true
	_spawn_sparks(42, 0.82)


func _update_roll(delta: float) -> void:
	roll_time += delta
	var t := clampf(roll_time / roll_duration, 0.0, 1.0)
	var eased := 1.0 - pow(1.0 - t, 3.0)

	if t < 0.78:
		dice_root.rotation = roll_seed + roll_spin * eased
		dice_root.position.y = 0.28 + abs(sin(t * PI * 5.4)) * (1.06 - t * 0.42)
		dice_root.scale = Vector3.ONE * (1.0 + sin(t * PI) * 0.075)
	else:
		if not blend_started:
			blend_started = true
			blend_start = dice_root.quaternion
			_spawn_sparks(26, 0.36)

		var u := smoothstep(0.0, 1.0, (t - 0.78) / 0.22)
		dice_root.quaternion = blend_start.slerp(target_rotation, u)
		dice_root.position.y = 0.28 + sin((1.0 - u) * PI * 3.0) * 0.09
		dice_root.scale = Vector3.ONE * (1.0 + sin(u * PI) * 0.04)

	if t >= 1.0:
		rolling = false
		dice_root.quaternion = target_rotation
		dice_root.position.y = 0.28
		dice_root.scale = Vector3.ONE
		result_label.text = str(roll_result)
		roll_button.disabled = false
		_spawn_sparks(54, 1.2 if roll_result == 6 else 0.74)


func _spawn_sparks(count: int, force: float) -> void:
	var skin: Dictionary = SKINS[selected_skin]
	for i in range(count):
		var spark := MeshInstance3D.new()
		var mesh := SphereMesh.new()
		mesh.radius = randf_range(0.025, 0.05)
		mesh.height = mesh.radius * 2.0
		mesh.radial_segments = 8
		mesh.rings = 4
		spark.mesh = mesh
		spark.position = Vector3(randf_range(-0.7, 0.7), randf_range(0.1, 0.9), randf_range(-0.7, 0.7))
		spark.material_override = _make_particle_material(skin["accent"])
		spark.set_meta("velocity", Vector3(randf_range(-1.2, 1.2), randf_range(0.8, 2.2), randf_range(-1.2, 1.2)) * force)
		spark.set_meta("life", randf_range(0.55, 1.2))
		spark.set_meta("max_life", spark.get_meta("life"))
		sparks.append(spark)
		add_child(spark)


func _update_sparks(delta: float) -> void:
	for i in range(sparks.size() - 1, -1, -1):
		var spark := sparks[i]
		var life: float = spark.get_meta("life") - delta
		var max_life: float = spark.get_meta("max_life")
		var velocity: Vector3 = spark.get_meta("velocity")
		velocity.y -= delta * 1.8
		spark.position += velocity * delta
		spark.scale = Vector3.ONE * max(life / max_life, 0.0)
		spark.set_meta("life", life)
		spark.set_meta("velocity", velocity)

		if life <= 0.0:
			sparks.remove_at(i)
			spark.queue_free()


func _make_material(
	albedo: Color,
	emission: Color,
	metallic: float,
	roughness: float,
	emission_energy := 0.22
) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = albedo
	material.metallic = metallic
	material.roughness = roughness
	material.emission_enabled = true
	material.emission = emission
	material.emission_energy_multiplier = emission_energy
	return material


func _make_particle_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = _with_alpha(color, 0.86)
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 1.8
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	return material


func _with_alpha(color: Color, alpha: float) -> Color:
	return Color(color.r, color.g, color.b, alpha)
