extends Node3D

const SKINS := [
	{
		"name": "Royal Gold",
		"arabic": "الذهبي الملكي",
		"rarity": "Legendary",
		"price": 500,
		"description": "نرد ذهبي فخم بحواف لامعة ونقاط مضيئة.",
		"body": Color("#f6c75f"),
		"edge": Color("#8b4b13"),
		"pip": Color("#fff6c3"),
		"accent": Color("#ffd86b"),
		"metallic": 0.9,
		"roughness": 0.16,
		"effect": "lion",
	},
	{
		"name": "Inferno Core",
		"arabic": "قلب النار",
		"rarity": "Epic",
		"price": 900,
		"description": "نرد داكن بقلب ناري وشرارات حمراء أثناء الرمي.",
		"body": Color("#1b0b0a"),
		"edge": Color("#ff4b1f"),
		"pip": Color("#ffd3a4"),
		"accent": Color("#ff5c25"),
		"metallic": 0.45,
		"roughness": 0.28,
		"effect": "snake",
	},
	{
		"name": "Frost Crystal",
		"arabic": "كريستال الجليد",
		"rarity": "Rare",
		"price": 700,
		"description": "نرد زجاجي بارد بنقاط بيضاء وضباب خفيف.",
		"body": Color("#8adcf7"),
		"edge": Color("#defbff"),
		"pip": Color("#ffffff"),
		"accent": Color("#8deaff"),
		"metallic": 0.15,
		"roughness": 0.05,
		"effect": "eagle",
	},
	{
		"name": "Galaxy Void",
		"arabic": "فراغ المجرة",
		"rarity": "Mythic",
		"price": 1500,
		"description": "نرد فضائي داكن مع نجوم صغيرة وهالة بنفسجية.",
		"body": Color("#16122d"),
		"edge": Color("#7f5cff"),
		"pip": Color("#f3e8ff"),
		"accent": Color("#a77dff"),
		"metallic": 0.62,
		"roughness": 0.17,
		"effect": "eagle",
	},
	{
		"name": "Emerald Royal",
		"arabic": "الزمرد الملكي",
		"rarity": "Epic",
		"price": 1100,
		"description": "نرد زمردي لامع بنقاط ذهبية مناسب للبطولات.",
		"body": Color("#0fa66f"),
		"edge": Color("#b7ffbd"),
		"pip": Color("#ffe49c"),
		"accent": Color("#39ff9e"),
		"metallic": 0.62,
		"roughness": 0.14,
		"effect": "snake",
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

const BOARD_CELL := 44.0
const MAIN_PATH_LENGTH := 52
const HOME_ENTRY_PROGRESS := 52
const FINISH_PROGRESS := 58
const HUMAN_TURN_SECONDS := 10.0
const HUMAN_CHOICE_SECONDS := 6.0

const PLAYER_NAMES := ["أنت", "زهور CPU", "عليوش CPU", "Biso Nova CPU"]
const PLAYER_SYMBOLS := ["⬮", "⬮", "⬮", "⬮"]
const PLAYER_COLORS := [Color("#ffe15b"), Color("#91eaff"), Color("#ffc1ef"), Color("#95ff7d")]
const PLAYER_START_OFFSETS := [39, 0, 13, 26]
const SAFE_GLOBAL_INDICES := [0, 8, 13, 21, 26, 34, 39, 47]

var result_rotations := {}
var selected_skin := 0
var equipped_skin := 0
var current_screen := "login"
var demo_piece_index := 0
var bet_amount := 500
var current_player := 0
var six_chain := 0
var pending_moves: Array[int] = []
var awaiting_piece_choice := false
var game_busy := false
var game_over := false
var turn_deadline := 0.0
var turn_timer_active := false

var camera: Camera3D
var dice_root: Node3D
var dice_body: MeshInstance3D
var pip_root: Node3D
var cinematic_root: Node3D
var ring: MeshInstance3D
var accent_light: OmniLight3D
var under_light: OmniLight3D
var sparks: Array[MeshInstance3D] = []

var ui_root: Control
var screens := {}
var result_label: Label
var dice_name_label: Label
var dice_description_label: Label
var market_cards: Array[Button] = []
var play_skin_buttons: Array[Button] = []
var roll_button: Button
var bet_label: Label
var status_label: Label
var turn_label: Label
var timer_label: Label
var demo_piece: Label
var board_holder: Control
var piece_labels: Array = []
var piece_progress: Array = []
var home_origins: Array[Vector2] = [
	Vector2(1.1, 10.2),
	Vector2(1.1, 1.2),
	Vector2(10.2, 1.2),
	Vector2(10.2, 10.2),
]

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
	_show_screen("login")
	dice_root.quaternion = result_rotations[1]


func _process(delta: float) -> void:
	var time := Time.get_ticks_msec() / 1000.0
	ring.rotation.y += delta * 0.48
	accent_light.light_energy = 4.2 + sin(time * 2.5) * 0.9
	under_light.light_energy = 2.3 + sin(time * 3.7) * 0.65
	_update_camera(time)

	if rolling:
		_update_roll(delta)
	else:
		dice_root.position.y = _dice_base_y() + sin(time * 1.35) * 0.045
		dice_root.rotate_y(delta * 0.22)

	_update_sparks(delta)
	_update_turn_timer()
	if roll_button:
		roll_button.pivot_offset = roll_button.size / 2.0
		if rolling and current_screen == "play":
			roll_button.rotation += delta * 10.0
			roll_button.scale = Vector2.ONE * (1.0 + abs(sin(time * 16.0)) * 0.08)
		else:
			roll_button.rotation = lerp_angle(roll_button.rotation, 0.0, min(1.0, delta * 8.0))
			if not awaiting_piece_choice:
				roll_button.scale = roll_button.scale.lerp(Vector2.ONE, min(1.0, delta * 8.0))


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
	environment.background_color = Color("#090725")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("#90b4ff")
	environment.ambient_light_energy = 0.42
	environment.glow_enabled = true
	environment.glow_intensity = 0.38
	environment.glow_strength = 0.9
	world.environment = environment
	add_child(world)

	camera = Camera3D.new()
	camera.fov = 42.0
	camera.position = Vector3(0, 3.25, 7.4)
	add_child(camera)
	camera.current = true

	var key_light := DirectionalLight3D.new()
	key_light.light_energy = 3.9
	key_light.rotation_degrees = Vector3(-58, -35, 0)
	key_light.shadow_enabled = true
	add_child(key_light)

	accent_light = OmniLight3D.new()
	accent_light.position = Vector3(3.2, 2.7, 2.8)
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
	floor.material_override = _make_material(Color("#10162b"), Color("#273255"), 0.3, 0.34)
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
	dice_root.name = "EngineDice"
	dice_root.position.y = 0.32
	add_child(dice_root)

	dice_body = MeshInstance3D.new()
	var box_mesh := BoxMesh.new()
	box_mesh.size = Vector3(2.0, 2.0, 2.0)
	dice_body.mesh = box_mesh
	dice_root.add_child(dice_body)

	var glow_shell := MeshInstance3D.new()
	var glow_mesh := BoxMesh.new()
	glow_mesh.size = Vector3(2.08, 2.08, 2.08)
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

	cinematic_root = Node3D.new()
	cinematic_root.name = "DiceCinematics"
	add_child(cinematic_root)


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)

	ui_root = Control.new()
	ui_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(ui_root)

	screens["login"] = _build_login_screen()
	screens["lobby"] = _build_lobby_screen()
	screens["mode"] = _build_mode_screen()
	screens["play"] = _build_play_screen()
	screens["market"] = _build_market_screen()


func _build_login_screen() -> Control:
	var screen := _screen_base("login", Color("#171338"), Color("#0a7ca0"))
	var card := _panel(Vector2(380, 430), Vector2(170, 210), Color("#162a51"), 18)
	screen.add_child(card)

	var title := _label("Ludo Nova", 44, Color("#ffe67b"), HORIZONTAL_ALIGNMENT_CENTER)
	title.position = Vector2(25, 26)
	title.size = Vector2(330, 58)
	card.add_child(title)

	var subtitle := _label("تطبيق Kotlin يشغل محرك Godot - كل الواجهات هنا داخل المحرك", 16, Color("#d8ecff"), HORIZONTAL_ALIGNMENT_CENTER)
	subtitle.position = Vector2(28, 88)
	subtitle.size = Vector2(324, 48)
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card.add_child(subtitle)

	var name_box := LineEdit.new()
	name_box.placeholder_text = "اسم اللاعب"
	name_box.text = "Biso Nova"
	name_box.position = Vector2(42, 158)
	name_box.size = Vector2(296, 48)
	card.add_child(name_box)

	var pass_box := LineEdit.new()
	pass_box.placeholder_text = "كلمة المرور"
	pass_box.secret = true
	pass_box.position = Vector2(42, 220)
	pass_box.size = Vector2(296, 48)
	card.add_child(pass_box)

	var login_button := _button("دخول اللوبي", Vector2(260, 56), Color("#ffd233"), Color("#422400"))
	login_button.position = Vector2(60, 300)
	login_button.pressed.connect(_show_screen.bind("lobby"))
	card.add_child(login_button)

	var guest_button := _button("الدخول كزائر", Vector2(220, 44), Color("#28a8ff"), Color.WHITE)
	guest_button.position = Vector2(80, 368)
	guest_button.pressed.connect(_show_screen.bind("lobby"))
	card.add_child(guest_button)

	ui_root.add_child(screen)
	return screen


func _build_lobby_screen() -> Control:
	var screen := _screen_base("lobby", Color("#251640"), Color("#083a5a"))
	_add_top_bar(screen, "اللوبي", true)

	var left_card := _player_card("زهور", "VIP", Color("#22c4ff"), Vector2(34, 150))
	screen.add_child(left_card)
	var right_card := _player_card("عليوش", "Gold", Color("#ffcf40"), Vector2(356, 150))
	screen.add_child(right_card)

	var center := _panel(Vector2(500, 410), Vector2(110, 390), Color("#10264a"), 18)
	screen.add_child(center)

	var title := _label("اختر تجربتك", 38, Color("#fff2a6"), HORIZONTAL_ALIGNMENT_CENTER)
	title.position = Vector2(30, 24)
	title.size = Vector2(440, 58)
	center.add_child(title)

	var play_button := _button("ابدأ اللعب", Vector2(340, 66), Color("#ffd21f"), Color("#3d2600"))
	play_button.position = Vector2(80, 114)
	play_button.pressed.connect(_show_screen.bind("mode"))
	center.add_child(play_button)

	var market_button := _button("سوق النرد داخل المحرك", Vector2(340, 58), Color("#2bc4ff"), Color.WHITE)
	market_button.position = Vector2(80, 198)
	market_button.pressed.connect(_show_screen.bind("market"))
	center.add_child(market_button)

	var preview_hint := _label("النرد 3D الموجود أمامك من Godot. اضغط عليه للرمي في أي شاشة.", 17, Color("#cfeaff"), HORIZONTAL_ALIGNMENT_CENTER)
	preview_hint.position = Vector2(50, 285)
	preview_hint.size = Vector2(400, 76)
	preview_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	center.add_child(preview_hint)

	ui_root.add_child(screen)
	return screen


func _build_mode_screen() -> Control:
	var screen := _screen_base("mode", Color("#191c58"), Color("#00a6aa"))
	_add_top_bar(screen, "غرفة اللعب", true)

	var content := _panel(Vector2(560, 560), Vector2(80, 170), Color("#123d65"), 16)
	screen.add_child(content)

	var moon := _label("☾", 132, _with_alpha(Color("#e7edff"), 0.35), HORIZONTAL_ALIGNMENT_CENTER)
	moon.position = Vector2(214, -30)
	moon.size = Vector2(132, 150)
	content.add_child(moon)

	var players_4 := _button("4 لاعبين", Vector2(190, 96), Color("#36a8ff"), Color.WHITE)
	players_4.position = Vector2(78, 54)
	content.add_child(players_4)

	var players_2 := _button("1 مقابل 1", Vector2(190, 96), Color("#27c7ff"), Color.WHITE)
	players_2.position = Vector2(292, 54)
	content.add_child(players_2)

	var mode_label := _label("حدد النمط", 26, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	mode_label.position = Vector2(160, 180)
	mode_label.size = Vector2(240, 42)
	content.add_child(mode_label)

	var classic := _button("الكلاسيكي ✓", Vector2(220, 50), Color("#21b9f2"), Color("#fffbc7"))
	classic.position = Vector2(52, 238)
	content.add_child(classic)

	var arrow := _button("السهم Hot", Vector2(220, 50), Color("#2498d2"), Color("#d6f0ff"))
	arrow.position = Vector2(288, 238)
	content.add_child(arrow)

	var master := _button("الماستر", Vector2(220, 50), Color("#2288c5"), Color("#b9d6e9"))
	master.position = Vector2(52, 302)
	content.add_child(master)

	var fast := _button("السريع", Vector2(220, 50), Color("#2288c5"), Color("#b9d6e9"))
	fast.position = Vector2(288, 302)
	content.add_child(fast)

	var magic := _button("أدوات سحرية 🎲", Vector2(456, 72), Color("#114b70"), Color.WHITE)
	magic.position = Vector2(52, 382)
	magic.pressed.connect(_show_screen.bind("market"))
	content.add_child(magic)

	var minus := _button("-", Vector2(58, 58), Color("#7f91a3"), Color.WHITE)
	minus.position = Vector2(64, 474)
	minus.pressed.connect(_change_bet.bind(-100))
	content.add_child(minus)

	bet_label = _label(str(bet_amount) + " 🪙", 30, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	bet_label.position = Vector2(152, 482)
	bet_label.size = Vector2(256, 44)
	content.add_child(bet_label)

	var plus := _button("+", Vector2(58, 58), Color("#ffcf33"), Color("#402000"))
	plus.position = Vector2(438, 474)
	plus.pressed.connect(_change_bet.bind(100))
	content.add_child(plus)

	var start := _button("ابدأ!", Vector2(300, 62), Color("#ffdb22"), Color("#412500"))
	start.position = Vector2(210, 1020)
	start.pressed.connect(_start_new_match)
	screen.add_child(start)

	ui_root.add_child(screen)
	return screen


func _build_play_screen() -> Control:
	var screen := _screen_base("play", Color("#281738"), Color("#0a0d26"))
	_add_top_bar(screen, "اللعبة", true)

	screen.add_child(_player_chip("زهور", Color("#28b6ff"), Vector2(34, 104)))
	screen.add_child(_player_chip("عليوش", Color("#ffcf40"), Vector2(458, 104)))
	screen.add_child(_player_chip("Biso Nova", Color("#f3d9ff"), Vector2(448, 936)))
	screen.add_child(_player_chip("أنت", Color("#ffd24d"), Vector2(40, 936)))

	board_holder = Control.new()
	board_holder.position = Vector2(30, 234)
	board_holder.size = Vector2(BOARD_CELL * 15.0, BOARD_CELL * 15.0)
	screen.add_child(board_holder)
	_build_ludo_board(board_holder)

	turn_label = _label("دورك", 24, Color("#fff2a6"), HORIZONTAL_ALIGNMENT_CENTER)
	turn_label.position = Vector2(140, 910)
	turn_label.size = Vector2(440, 42)
	screen.add_child(turn_label)

	status_label = _label("ارم النرد. تحتاج 6 لإخراج قطعة من البيت.", 18, Color("#dff5ff"), HORIZONTAL_ALIGNMENT_CENTER)
	status_label.position = Vector2(70, 988)
	status_label.size = Vector2(580, 64)
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	screen.add_child(status_label)

	var bottom_bar := _panel(Vector2(560, 78), Vector2(80, 1082), Color("#15182c"), 18)
	screen.add_child(bottom_bar)

	roll_button = _button("⚂", Vector2(92, 92), Color("#d5b47b"), Color("#402400"))
	roll_button.position = Vector2(118, 1012)
	roll_button.add_theme_font_size_override("font_size", 48)
	_style_dice_button()
	roll_button.pressed.connect(_roll_dice)
	screen.add_child(roll_button)

	result_label = _label("جاهز", 30, Color("#fff4aa"), HORIZONTAL_ALIGNMENT_CENTER)
	result_label.position = Vector2(20, 14)
	result_label.size = Vector2(160, 48)
	bottom_bar.add_child(result_label)

	timer_label = _label("10", 30, Color("#7dffbc"), HORIZONTAL_ALIGNMENT_CENTER)
	timer_label.position = Vector2(210, 14)
	timer_label.size = Vector2(120, 48)
	bottom_bar.add_child(timer_label)

	var market_tab := _button("السوق", Vector2(96, 44), Color("#2bc4ff"), Color.WHITE)
	market_tab.position = Vector2(440, 17)
	market_tab.pressed.connect(_show_screen.bind("market"))
	bottom_bar.add_child(market_tab)

	var restart := _button("جديدة", Vector2(96, 42), Color("#3a456a"), Color.WHITE)
	restart.position = Vector2(312, 1168)
	restart.pressed.connect(_start_new_match)
	screen.add_child(restart)

	var dice_strip_label := _label("نرداتي", 16, Color("#fff2a6"), HORIZONTAL_ALIGNMENT_CENTER)
	dice_strip_label.position = Vector2(34, 1162)
	dice_strip_label.size = Vector2(92, 28)
	screen.add_child(dice_strip_label)

	var dice_strip := HBoxContainer.new()
	dice_strip.position = Vector2(34, 1192)
	dice_strip.size = Vector2(360, 56)
	dice_strip.add_theme_constant_override("separation", 8)
	screen.add_child(dice_strip)
	play_skin_buttons.clear()
	for i in range(SKINS.size()):
		var skin: Dictionary = SKINS[i]
		var skin_button := _button(_dice_face(i % 6 + 1), Vector2(56, 50), skin["body"], Color.WHITE)
		skin_button.add_theme_font_size_override("font_size", 28)
		skin_button.pressed.connect(_select_skin.bind(i))
		play_skin_buttons.append(skin_button)
		dice_strip.add_child(skin_button)

	ui_root.add_child(screen)
	return screen


func _build_market_screen() -> Control:
	var screen := _screen_base("market", Color("#11172d"), Color("#1a0642"))
	_add_top_bar(screen, "سوق النرد", true)

	var info := _panel(Vector2(640, 170), Vector2(40, 120), Color("#162a51"), 16)
	screen.add_child(info)

	dice_name_label = _label("", 32, Color("#ffe879"), HORIZONTAL_ALIGNMENT_CENTER)
	dice_name_label.position = Vector2(20, 20)
	dice_name_label.size = Vector2(600, 42)
	info.add_child(dice_name_label)

	dice_description_label = _label("", 17, Color("#dff5ff"), HORIZONTAL_ALIGNMENT_CENTER)
	dice_description_label.position = Vector2(24, 72)
	dice_description_label.size = Vector2(592, 72)
	dice_description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_child(dice_description_label)

	var title := _label("كل نرد هنا مصنوع ويظهر من محرك Godot", 25, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	title.position = Vector2(60, 316)
	title.size = Vector2(600, 42)
	screen.add_child(title)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.position = Vector2(96, 390)
	grid.size = Vector2(520, 300)
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	screen.add_child(grid)

	market_cards.clear()
	for i in range(SKINS.size()):
		var skin: Dictionary = SKINS[i]
		var card := _button("%s\n%s • %s • %s 🪙" % [skin["arabic"], skin["rarity"], skin["effect"], skin["price"]], Vector2(250, 88), skin["body"], Color.WHITE)
		card.pressed.connect(_select_skin.bind(i))
		market_cards.append(card)
		grid.add_child(card)

	var equip := _button("تجهيز النرد المختار", Vector2(250, 60), Color("#ffd429"), Color("#3d2600"))
	equip.position = Vector2(94, 950)
	equip.pressed.connect(_equip_selected_skin)
	screen.add_child(equip)

	var roll := _button("جرب الرمي", Vector2(180, 54), Color("#2bc4ff"), Color.WHITE)
	roll.position = Vector2(388, 954)
	roll.pressed.connect(_roll_dice)
	screen.add_child(roll)

	ui_root.add_child(screen)
	return screen


func _add_top_bar(screen: Control, title_text: String, with_tabs: bool) -> void:
	var bar := _panel(Vector2(672, 70), Vector2(24, 18), Color("#201a38"), 18)
	screen.add_child(bar)

	var title := _label(title_text, 28, Color("#fff2b5"), HORIZONTAL_ALIGNMENT_CENTER)
	title.position = Vector2(312, 14)
	title.size = Vector2(120, 42)
	bar.add_child(title)

	var coins := _label("0 مشاهد 👁    2,400 🪙", 18, Color("#e8f5ff"), HORIZONTAL_ALIGNMENT_CENTER)
	coins.position = Vector2(420, 18)
	coins.size = Vector2(140, 34)
	bar.add_child(coins)

	if with_tabs:
		var lobby := _button("لوبي", Vector2(88, 42), Color("#2b3558"), Color.WHITE)
		lobby.position = Vector2(20, 14)
		lobby.pressed.connect(_show_screen.bind("lobby"))
		bar.add_child(lobby)

		var play := _button("لعب", Vector2(88, 42), Color("#2b3558"), Color.WHITE)
		play.position = Vector2(116, 14)
		play.pressed.connect(_show_screen.bind("play"))
		bar.add_child(play)

		var market := _button("سوق", Vector2(88, 42), Color("#2b3558"), Color.WHITE)
		market.position = Vector2(212, 14)
		market.pressed.connect(_show_screen.bind("market"))
		bar.add_child(market)

		var settings := _label("⚙  🏆", 30, Color("#dfe8ff"), HORIZONTAL_ALIGNMENT_CENTER)
		settings.position = Vector2(570, 13)
		settings.size = Vector2(110, 44)
		bar.add_child(settings)


func _build_ludo_board(parent: Control) -> void:
	var frame := _panel(Vector2(BOARD_CELL * 15.0 + 18.0, BOARD_CELL * 15.0 + 18.0), Vector2(-9, -9), Color("#8a4f2b"), 16)
	parent.add_child(frame)

	_add_home_area(parent, Vector2(0, 0), Color("#1c9dff"), Color("#1070c3"))
	_add_home_area(parent, Vector2(9, 0), Color("#f33a2f"), Color("#b52b26"))
	_add_home_area(parent, Vector2(9, 9), Color("#24bf45"), Color("#168934"))
	_add_home_area(parent, Vector2(0, 9), Color("#ffd21c"), Color("#bd9914"))

	for y in range(15):
		for x in range(15):
			if _is_track_cell(x, y):
				_add_board_cell(parent, x, y, _ludo_cell_color(x, y))

	_add_center_triangles(parent)

	_create_game_pieces(parent)
	_reset_ludo_game()


func _add_home_area(parent: Control, origin: Vector2, color: Color, inner_color: Color) -> void:
	var home := _panel(Vector2(BOARD_CELL * 6.0, BOARD_CELL * 6.0), origin * BOARD_CELL, color, 22)
	parent.add_child(home)
	var circle := _panel(Vector2(BOARD_CELL * 4.25, BOARD_CELL * 4.25), origin * BOARD_CELL + Vector2(BOARD_CELL * 0.88, BOARD_CELL * 0.88), _with_alpha(inner_color, 0.62), 120)
	parent.add_child(circle)
	var slots: Array[Vector2] = [Vector2(1.65, 1.65), Vector2(3.55, 1.65), Vector2(1.65, 3.55), Vector2(3.55, 3.55)]
	for slot in slots:
		var slot_panel := _panel(Vector2(BOARD_CELL * 0.72, BOARD_CELL * 0.72), (origin + slot) * BOARD_CELL, _with_alpha(Color.WHITE, 0.18), 28)
		parent.add_child(slot_panel)


func _add_board_cell(parent: Control, x: int, y: int, color: Color) -> void:
	var cell := _panel(Vector2(BOARD_CELL, BOARD_CELL), Vector2(x, y) * BOARD_CELL, color, 0)
	parent.add_child(cell)
	if _is_safe_cell(x, y):
		var star := _label("★", 22, Color("#777777"), HORIZONTAL_ALIGNMENT_CENTER)
		star.size = Vector2(BOARD_CELL, BOARD_CELL)
		cell.add_child(star)


func _is_track_cell(x: int, y: int) -> bool:
	if x >= 6 and x <= 8:
		return true
	if y >= 6 and y <= 8:
		return true
	return false


func _add_center_triangles(parent: Control) -> void:
	var center := _panel(Vector2(BOARD_CELL * 3.0, BOARD_CELL * 3.0), Vector2(6, 6) * BOARD_CELL, Color("#132342"), 0)
	parent.add_child(center)
	var colors: Array[Color] = [Color("#299dff"), Color("#f43a32"), Color("#21c24c"), Color("#ffd21c")]
	var labels: Array[String] = ["◀", "▲", "▶", "▼"]
	var positions: Array[Vector2] = [Vector2(6, 7), Vector2(7, 6), Vector2(8, 7), Vector2(7, 8)]
	for i in range(4):
		var tri := _label(labels[i], 42, colors[i], HORIZONTAL_ALIGNMENT_CENTER)
		tri.position = positions[i] * BOARD_CELL
		tri.size = Vector2(BOARD_CELL, BOARD_CELL)
		parent.add_child(tri)


func _ludo_cell_color(x: int, y: int) -> Color:
	if x < 6 and y < 6:
		return Color("#1c9dff")
	if x > 8 and y < 6:
		return Color("#f33a2f")
	if x < 6 and y > 8:
		return Color("#ffd21c")
	if x > 8 and y > 8:
		return Color("#24bf45")
	if x >= 6 and x <= 8 and y >= 6 and y <= 8:
		if x == 7 and y == 7:
			return Color("#ffce2e")
		if x < 7:
			return Color("#299dff")
		if x > 7:
			return Color("#21c24c")
		if y < 7:
			return Color("#f43a32")
		return Color("#ffd21c")
	if x >= 6 and x <= 8:
		if x == 7 and y > 0 and y < 6:
			return Color("#f43a32")
		if x == 7 and y > 8 and y < 14:
			return Color("#ffd21c")
		return Color("#f7f7f7")
	if y >= 6 and y <= 8:
		if y == 7 and x > 0 and x < 6:
			return Color("#1b95f2")
		if y == 7 and x > 8 and x < 14:
			return Color("#1fb946")
		return Color("#f7f7f7")
	return Color("#f7f7f7")


func _is_safe_cell(x: int, y: int) -> bool:
	return Vector2i(x, y) in [
		Vector2i(1, 6),
		Vector2i(6, 2),
		Vector2i(8, 1),
		Vector2i(12, 6),
		Vector2i(13, 8),
		Vector2i(8, 12),
		Vector2i(6, 13),
		Vector2i(2, 8),
	]


func _add_home_tokens(parent: Control, origin: Vector2, color: Color, token_text: String) -> void:
	var offsets := [Vector2(0, 0), Vector2(2, 0), Vector2(0, 2), Vector2(2, 2)]
	for offset in offsets:
		var token := _label(token_text, 30, color, HORIZONTAL_ALIGNMENT_CENTER)
		token.size = Vector2(BOARD_CELL, BOARD_CELL)
		token.position = (origin + offset) * BOARD_CELL
		parent.add_child(token)


func _create_game_pieces(parent: Control) -> void:
	piece_labels.clear()
	for player in range(4):
		var player_labels: Array[Label] = []
		for piece in range(4):
			var token := _label(PLAYER_SYMBOLS[player], 42, PLAYER_COLORS[player], HORIZONTAL_ALIGNMENT_CENTER)
			token.size = Vector2(BOARD_CELL * 1.15, BOARD_CELL * 1.15)
			token.mouse_filter = Control.MOUSE_FILTER_STOP
			token.add_theme_color_override("font_shadow_color", Color("#231400"))
			token.add_theme_color_override("font_outline_color", Color("#fff6cf"))
			token.add_theme_constant_override("outline_size", 2)
			token.add_theme_constant_override("shadow_offset_x", 2)
			token.add_theme_constant_override("shadow_offset_y", 2)
			token.gui_input.connect(_on_piece_gui_input.bind(player, piece))
			parent.add_child(token)
			player_labels.append(token)
		piece_labels.append(player_labels)


func _reset_ludo_game() -> void:
	piece_progress.clear()
	for player in range(4):
		var player_progress: Array[int] = []
		for piece in range(4):
			player_progress.append(-1)
		piece_progress.append(player_progress)

	current_player = 0
	six_chain = 0
	pending_moves.clear()
	awaiting_piece_choice = false
	game_busy = false
	game_over = false
	_update_all_piece_positions()
	_start_turn(0)


func _on_piece_gui_input(event: InputEvent, player: int, piece: int) -> void:
	if not awaiting_piece_choice or player != current_player or current_player != 0:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if piece in pending_moves:
			_stop_turn_timer()
			awaiting_piece_choice = false
			pending_moves.clear()
			_clear_piece_highlights()
			_move_piece(player, piece, roll_result)
	elif event is InputEventScreenTouch and event.pressed:
		if piece in pending_moves:
			_stop_turn_timer()
			awaiting_piece_choice = false
			pending_moves.clear()
			_clear_piece_highlights()
			_move_piece(player, piece, roll_result)


func _home_position(player: int, piece: int) -> Vector2:
	var offsets: Array[Vector2] = [Vector2(1.45, 1.45), Vector2(3.35, 1.45), Vector2(1.45, 3.35), Vector2(3.35, 3.35)]
	return (home_origins[player] + offsets[piece]) * BOARD_CELL + _stack_offset(piece)


func _piece_position(player: int, piece: int) -> Vector2:
	var progress: int = piece_progress[player][piece]
	if progress < 0:
		return _home_position(player, piece)
	if progress >= FINISH_PROGRESS:
		return Vector2(7, 7) * BOARD_CELL + _finish_offset(player, piece)
	if progress >= HOME_ENTRY_PROGRESS:
		return _home_lane_position(player, progress - HOME_ENTRY_PROGRESS, piece)
	return _board_path_position(_global_index_for_progress(player, progress)) + _stack_offset(piece)


func _finish_offset(player: int, piece: int) -> Vector2:
	var offsets: Array[Vector2] = [Vector2(-16, -16), Vector2(16, -16), Vector2(-16, 16), Vector2(16, 16)]
	return offsets[piece] + Vector2(player % 2 * 4, player / 2 * 4)


func _home_lane_position(player: int, lane_index: int, piece: int) -> Vector2:
	var lanes: Array = [
		[Vector2(7, 12), Vector2(7, 11), Vector2(7, 10), Vector2(7, 9), Vector2(7, 8), Vector2(7, 7)],
		[Vector2(2, 7), Vector2(3, 7), Vector2(4, 7), Vector2(5, 7), Vector2(6, 7), Vector2(7, 7)],
		[Vector2(7, 2), Vector2(7, 3), Vector2(7, 4), Vector2(7, 5), Vector2(7, 6), Vector2(7, 7)],
		[Vector2(12, 7), Vector2(11, 7), Vector2(10, 7), Vector2(9, 7), Vector2(8, 7), Vector2(7, 7)],
	]
	var cell: Vector2 = lanes[player][clampi(lane_index, 0, 5)]
	return cell * BOARD_CELL + _stack_offset(piece) + Vector2(-3, -5)


func _stack_offset(piece: int) -> Vector2:
	var offsets: Array[Vector2] = [Vector2(-9, -9), Vector2(9, -9), Vector2(-9, 9), Vector2(9, 9)]
	return offsets[piece]


func _update_all_piece_positions() -> void:
	for player in range(4):
		for piece in range(4):
			if piece_labels.size() > player and piece_labels[player].size() > piece:
				piece_labels[player][piece].position = _piece_position(player, piece)
	_update_piece_visual_states()


func _update_piece_visual_states() -> void:
	for player in range(4):
		for piece in range(4):
			var label: Label = piece_labels[player][piece]
			var progress: int = piece_progress[player][piece]
			label.modulate = Color(1, 1, 1, 1.0 if progress < FINISH_PROGRESS else 0.55)


func _set_piece_highlights(moves: Array[int]) -> void:
	_clear_piece_highlights()
	for piece in moves:
		var label: Label = piece_labels[current_player][piece]
		label.scale = Vector2(1.28, 1.28)
		label.add_theme_color_override("font_outline_color", Color("#fff56d"))
		label.add_theme_constant_override("outline_size", 6)


func _clear_piece_highlights() -> void:
	for player in range(piece_labels.size()):
		for piece in range(piece_labels[player].size()):
			var label: Label = piece_labels[player][piece]
			label.scale = Vector2.ONE
			label.add_theme_color_override("font_outline_color", Color("#fff6cf"))
			label.add_theme_constant_override("outline_size", 2)


func _board_path_position(index: int) -> Vector2:
	var path: Array[Vector2] = [
		Vector2(1, 6), Vector2(2, 6), Vector2(3, 6), Vector2(4, 6), Vector2(5, 6),
		Vector2(6, 5), Vector2(6, 4), Vector2(6, 3), Vector2(6, 2), Vector2(6, 1),
		Vector2(6, 0), Vector2(7, 0), Vector2(8, 0), Vector2(8, 1), Vector2(8, 2),
		Vector2(8, 3), Vector2(8, 4), Vector2(8, 5), Vector2(9, 6), Vector2(10, 6),
		Vector2(11, 6), Vector2(12, 6), Vector2(13, 6), Vector2(14, 6), Vector2(14, 7),
		Vector2(14, 8), Vector2(13, 8), Vector2(12, 8), Vector2(11, 8), Vector2(10, 8),
		Vector2(9, 8), Vector2(8, 9), Vector2(8, 10), Vector2(8, 11), Vector2(8, 12),
		Vector2(8, 13), Vector2(8, 14), Vector2(7, 14), Vector2(6, 14), Vector2(6, 13),
		Vector2(6, 12), Vector2(6, 11), Vector2(6, 10), Vector2(6, 9), Vector2(5, 8),
		Vector2(4, 8), Vector2(3, 8), Vector2(2, 8), Vector2(1, 8), Vector2(0, 8),
		Vector2(0, 7), Vector2(0, 6),
	]
	var cell: Vector2 = path[index % path.size()]
	return cell * BOARD_CELL + Vector2(-3, -5)


func _move_demo_piece(steps: int) -> void:
	# Kept for compatibility with the first visual prototype. The complete game
	# now moves real player tokens through _move_piece().
	pass


func _global_index_for_progress(player: int, progress: int) -> int:
	return (PLAYER_START_OFFSETS[player] + progress) % MAIN_PATH_LENGTH


func _is_safe_global_index(index: int) -> bool:
	return index in SAFE_GLOBAL_INDICES


func _get_valid_moves(player: int, die: int) -> Array[int]:
	var moves: Array[int] = []
	for piece in range(4):
		var progress: int = piece_progress[player][piece]
		if progress < 0:
			if die == 6:
				moves.append(piece)
		elif progress < FINISH_PROGRESS and progress + die <= FINISH_PROGRESS:
			moves.append(piece)
	return moves


func _start_turn(player: int) -> void:
	if game_over:
		return
	current_player = player
	awaiting_piece_choice = false
	pending_moves.clear()
	_clear_piece_highlights()
	_update_turn_ui()
	if current_player == 0 and current_screen == "play":
		_start_human_timer(HUMAN_TURN_SECONDS)
	else:
		_stop_turn_timer()

	if current_screen == "play" and current_player != 0:
		await get_tree().create_timer(0.85).timeout
		if current_screen == "play" and current_player == player and not rolling and not game_busy and not game_over:
			_roll_dice()


func _advance_turn() -> void:
	var next_player := (current_player + 1) % 4
	_start_turn(next_player)


func _update_turn_ui() -> void:
	if turn_label:
		turn_label.text = "الدور: " + PLAYER_NAMES[current_player]
	if roll_button:
		roll_button.position = _dice_button_position_for_player(current_player)
		if not rolling:
			roll_button.text = _dice_face(max(1, roll_result))
	if status_label:
		if current_player == 0:
			status_label.text = "دورك. ارم النرد، ثم اختر قطعة مضيئة إذا وجدت أكثر من حركة."
		else:
			status_label.text = PLAYER_NAMES[current_player] + " يفكر ويرمي النرد..."
	if roll_button:
		roll_button.disabled = current_player != 0 or rolling or game_busy or game_over


func _dice_button_position_for_player(player: int) -> Vector2:
	match player:
		0:
			return Vector2(128, 1010)
		1:
			return Vector2(128, 158)
		2:
			return Vector2(500, 158)
		3:
			return Vector2(500, 1010)
	return Vector2(128, 1010)


func _start_human_timer(seconds: float) -> void:
	turn_deadline = Time.get_ticks_msec() / 1000.0 + seconds
	turn_timer_active = true
	if timer_label:
		timer_label.text = str(int(ceil(seconds)))


func _stop_turn_timer() -> void:
	turn_timer_active = false
	if timer_label:
		timer_label.text = "--"


func _update_turn_timer() -> void:
	if not turn_timer_active or current_screen != "play" or game_over or current_player != 0:
		return
	var remaining: float = max(0.0, turn_deadline - Time.get_ticks_msec() / 1000.0)
	if timer_label:
		timer_label.text = str(int(ceil(remaining)))
	if remaining > 0.0:
		return
	turn_timer_active = false
	if awaiting_piece_choice:
		var fallback := _choose_cpu_move(0, pending_moves, roll_result)
		if status_label:
			status_label.text = "انتهى الوقت، تم اختيار حركة تلقائيًا."
		awaiting_piece_choice = false
		pending_moves.clear()
		_clear_piece_highlights()
		_move_piece(0, fallback, roll_result)
	elif not rolling and not game_busy:
		if status_label:
			status_label.text = "انتهى الوقت، تم رمي النرد تلقائيًا."
		_roll_dice()


func _handle_roll_result() -> void:
	if current_screen != "play":
		if result_label:
			result_label.text = str(roll_result)
		if roll_button:
			roll_button.disabled = false
		game_busy = false
		return

	if roll_result == 6:
		six_chain += 1
	else:
		six_chain = 0

	if six_chain >= 3:
		if status_label:
			status_label.text = PLAYER_NAMES[current_player] + " حصل على ثلاث 6 متتالية. ينتقل الدور."
		six_chain = 0
		game_busy = false
		await get_tree().create_timer(0.7).timeout
		_advance_turn()
		return

	var moves := _get_valid_moves(current_player, roll_result)
	if moves.is_empty():
		if status_label:
			status_label.text = "لا توجد حركة قانونية لـ " + PLAYER_NAMES[current_player] + "."
		game_busy = false
		await get_tree().create_timer(0.75).timeout
		if roll_result == 6:
			_start_turn(current_player)
		else:
			_advance_turn()
		return

	if current_player == 0:
		if moves.size() == 1:
			await get_tree().create_timer(0.25).timeout
			_move_piece(current_player, moves[0], roll_result)
		else:
			awaiting_piece_choice = true
			pending_moves = moves
			game_busy = false
			_set_piece_highlights(moves)
			_start_human_timer(HUMAN_CHOICE_SECONDS)
			if status_label:
				status_label.text = "اختر القطعة المضيئة التي تريد تحريكها " + str(roll_result) + " خطوات."
	else:
		var chosen := _choose_cpu_move(current_player, moves, roll_result)
		await get_tree().create_timer(0.35).timeout
		_move_piece(current_player, chosen, roll_result)


func _choose_cpu_move(player: int, moves: Array[int], die: int) -> int:
	var best_piece: int = moves[0]
	var best_score := -99999
	for piece in moves:
		var score := _score_move(player, piece, die)
		if score > best_score:
			best_score = score
			best_piece = piece
	return best_piece


func _score_move(player: int, piece: int, die: int) -> int:
	var progress: int = piece_progress[player][piece]
	var new_progress := 0 if progress < 0 else progress + die
	var score := new_progress
	if progress < 0 and die == 6:
		score += 35
	if new_progress == FINISH_PROGRESS:
		score += 120
	if new_progress < HOME_ENTRY_PROGRESS and _would_capture(player, new_progress):
		score += 95
	if new_progress < HOME_ENTRY_PROGRESS and _is_safe_global_index(_global_index_for_progress(player, new_progress)):
		score += 15
	return score


func _would_capture(player: int, new_progress: int) -> bool:
	var global_index := _global_index_for_progress(player, new_progress)
	if _is_safe_global_index(global_index):
		return false
	for opponent in range(4):
		if opponent == player:
			continue
		for piece in range(4):
			var opponent_progress: int = piece_progress[opponent][piece]
			if opponent_progress >= 0 and opponent_progress < HOME_ENTRY_PROGRESS:
				if _global_index_for_progress(opponent, opponent_progress) == global_index:
					return true
	return false


func _move_piece(player: int, piece: int, die: int) -> void:
	game_busy = true
	awaiting_piece_choice = false
	_clear_piece_highlights()
	if roll_button:
		roll_button.disabled = true

	if status_label:
		status_label.text = PLAYER_NAMES[player] + " يحرك قطعة " + str(die) + " خطوات..."

	var progress: int = piece_progress[player][piece]
	if progress < 0:
		piece_progress[player][piece] = 0
		await _animate_piece_to(player, piece, _piece_position(player, piece), 0.26)
	else:
		for step in range(die):
			piece_progress[player][piece] += 1
			await _animate_piece_to(player, piece, _piece_position(player, piece), 0.16)

	await _resolve_capture(player, piece)
	_update_all_piece_positions()

	if _player_has_won(player):
		game_over = true
		if status_label:
			status_label.text = PLAYER_NAMES[player] + " فاز! كل القطع وصلت للنهاية."
		if turn_label:
			turn_label.text = "انتهت اللعبة"
		if roll_button:
			roll_button.disabled = true
		game_busy = false
		return

	game_busy = false
	if die == 6:
		if status_label:
			status_label.text = PLAYER_NAMES[player] + " حصل على 6 وله رمية إضافية."
		await get_tree().create_timer(0.55).timeout
		_start_turn(player)
	else:
		await get_tree().create_timer(0.45).timeout
		_advance_turn()


func _animate_piece_to(player: int, piece: int, target: Vector2, duration: float) -> void:
	var label: Label = piece_labels[player][piece]
	var start_y := label.position.y
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position", target, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(label, "scale", Vector2(1.22, 1.22), duration * 0.45).set_trans(Tween.TRANS_BACK)
	await tween.finished
	var settle := create_tween()
	settle.tween_property(label, "scale", Vector2.ONE, 0.08)
	await settle.finished


func _resolve_capture(player: int, moved_piece: int) -> void:
	var progress: int = piece_progress[player][moved_piece]
	if progress < 0 or progress >= HOME_ENTRY_PROGRESS:
		return
	var global_index := _global_index_for_progress(player, progress)
	if _is_safe_global_index(global_index):
		return

	var captured := false
	for opponent in range(4):
		if opponent == player:
			continue
		for piece in range(4):
			var opponent_progress: int = piece_progress[opponent][piece]
			if opponent_progress >= 0 and opponent_progress < HOME_ENTRY_PROGRESS:
				if _global_index_for_progress(opponent, opponent_progress) == global_index:
					piece_progress[opponent][piece] = -1
					captured = true
					await _animate_piece_to(opponent, piece, _home_position(opponent, piece), 0.28)
	if captured and status_label:
		status_label.text = PLAYER_NAMES[player] + " أكل قطعة خصم!"
		_spawn_sparks(34, 0.8)
		await get_tree().create_timer(0.35).timeout


func _player_has_won(player: int) -> bool:
	for piece in range(4):
		if piece_progress[player][piece] < FINISH_PROGRESS:
			return false
	return true


func _show_screen(name: String) -> void:
	current_screen = name
	for key in screens.keys():
		screens[key].visible = key == name
	_apply_screen_camera()
	if name == "play":
		_update_turn_ui()


func _start_new_match() -> void:
	_show_screen("play")
	_reset_ludo_game()


func _apply_screen_camera() -> void:
	if current_screen == "play":
		dice_root.visible = true
		dice_root.position.x = -3.55
		dice_root.position.z = 0.25
		dice_root.scale = Vector3.ONE * 0.68
	elif current_screen == "market":
		dice_root.visible = true
		dice_root.position.x = 1.45
		dice_root.position.z = 0.0
		dice_root.scale = Vector3.ONE * 1.0
	else:
		dice_root.visible = true
		dice_root.position.x = 0.0
		dice_root.position.z = 0.0
		dice_root.scale = Vector3.ONE * 0.86


func _update_camera(time: float) -> void:
	if current_screen == "play":
		camera.position = Vector3(-2.45 + sin(time * 0.22) * 0.08, 2.15, 5.6)
		camera.look_at(Vector3(-2.45, -0.28, 0.0), Vector3.UP)
	elif current_screen == "market":
		camera.position = Vector3(1.3 + sin(time * 0.22) * 0.12, 2.8, 6.2)
		camera.look_at(Vector3(1.3, 0.05, 0.0), Vector3.UP)
	else:
		camera.position = Vector3(sin(time * 0.22) * 0.18, 3.25, 7.4)
		camera.look_at(Vector3(0, 0.1, 0), Vector3.UP)


func _dice_base_y() -> float:
	if current_screen == "play":
		return -1.28
	return 0.32


func _change_bet(amount: int) -> void:
	bet_amount = clampi(bet_amount + amount, 100, 5000)
	if bet_label:
		bet_label.text = str(bet_amount) + " 🪙"


func _equip_selected_skin() -> void:
	equipped_skin = selected_skin
	_select_skin(selected_skin)


func _select_skin(index: int) -> void:
	selected_skin = index
	var skin: Dictionary = SKINS[index]
	if dice_name_label:
		dice_name_label.text = "%s / %s" % [skin["arabic"], skin["name"]]
	if dice_description_label:
		dice_description_label.text = "%s\nمؤثر 6: %s • السعر: %s 🪙" % [skin["description"], skin["effect"], skin["price"]]

	for i in range(market_cards.size()):
		market_cards[i].disabled = i == index
		market_cards[i].text = "%s\n%s • %s • %s 🪙%s" % [
			SKINS[i]["arabic"],
			SKINS[i]["rarity"],
			SKINS[i]["effect"],
			SKINS[i]["price"],
			" • مجهز" if i == equipped_skin else "",
		]
	for i in range(play_skin_buttons.size()):
		var skin_button := play_skin_buttons[i]
		var skin_i: Dictionary = SKINS[i]
		skin_button.disabled = i == index
		skin_button.text = _dice_face(i % 6 + 1)
		skin_button.add_theme_color_override("font_color", _readable_dice_font_color(skin_i["body"]))
		var style := StyleBoxFlat.new()
		style.bg_color = skin_i["body"]
		style.border_color = skin_i["accent"] if i == index else _with_alpha(Color.WHITE, 0.25)
		style.border_width_left = 4 if i == index else 2
		style.border_width_right = style.border_width_left
		style.border_width_top = style.border_width_left
		style.border_width_bottom = style.border_width_left
		style.corner_radius_top_left = 10
		style.corner_radius_top_right = 10
		style.corner_radius_bottom_left = 10
		style.corner_radius_bottom_right = 10
		skin_button.add_theme_stylebox_override("normal", style)
		skin_button.add_theme_stylebox_override("hover", style)
		skin_button.add_theme_stylebox_override("pressed", style)
		skin_button.add_theme_stylebox_override("disabled", style)

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
	_style_dice_button()
	if roll_button and not rolling:
		roll_button.text = _dice_face(max(1, roll_result))


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
	if current_screen == "play":
		if game_busy or awaiting_piece_choice or game_over:
			return
		if current_player == 0 and roll_button and roll_button.disabled:
			return
		game_busy = true
		_stop_turn_timer()
	rolling = true
	roll_time = 0.0
	roll_result = randi_range(1, 6)
	roll_seed = Vector3(randf() * PI, randf() * PI, randf() * PI)
	roll_spin = Vector3(randf_range(15, 22), randf_range(18, 27), randf_range(13, 21)) * PI
	blend_started = false
	target_rotation = result_rotations[roll_result]
	if result_label:
		result_label.text = "يدور..."
	if roll_button:
		roll_button.text = "⋯"
		roll_button.disabled = true
	_spawn_sparks(42, 0.82)


func _update_roll(delta: float) -> void:
	roll_time += delta
	var t := clampf(roll_time / roll_duration, 0.0, 1.0)
	var eased := 1.0 - pow(1.0 - t, 3.0)
	var base_y := _dice_base_y()

	if t < 0.78:
		dice_root.rotation = roll_seed + roll_spin * eased
		dice_root.position.y = base_y + abs(sin(t * PI * 5.4)) * (1.06 - t * 0.42)
	else:
		if not blend_started:
			blend_started = true
			blend_start = dice_root.quaternion
			_spawn_sparks(26, 0.36)
		var u := _smoothstep((t - 0.78) / 0.22)
		dice_root.quaternion = blend_start.slerp(target_rotation, u)
		dice_root.position.y = base_y + sin((1.0 - u) * PI * 3.0) * 0.09

	if t >= 1.0:
		rolling = false
		dice_root.quaternion = target_rotation
		dice_root.position.y = base_y
		if result_label:
			result_label.text = str(roll_result)
		if roll_button:
			roll_button.text = _dice_face(roll_result)
		if roll_button and current_screen != "play":
			roll_button.disabled = false
		_spawn_sparks(54, 1.2 if roll_result == 6 else 0.74)
		_trigger_dice_cinematic(roll_result)
		_handle_roll_result()


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
		spark.position = dice_root.position + Vector3(randf_range(-0.7, 0.7), randf_range(0.1, 0.9), randf_range(-0.7, 0.7))
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


func _screen_base(_name: String, top_color: Color, bottom_color: Color) -> Control:
	var screen := Control.new()
	screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = _with_alpha(bottom_color, 0.86)
	screen.add_child(bg)
	for i in range(7):
		var stripe := ColorRect.new()
		stripe.color = _with_alpha(top_color.lightened(0.08 * i), 0.2)
		stripe.position = Vector2(i * 130.0 - 90.0, -30.0)
		stripe.size = Vector2(110.0, 1400.0)
		stripe.rotation = -0.55
		bg.add_child(stripe)
	return screen


func _panel(size: Vector2, position: Vector2, color: Color, radius: int) -> Panel:
	var panel := Panel.new()
	panel.position = position
	panel.size = size
	var style := StyleBoxFlat.new()
	style.bg_color = _with_alpha(color, 0.88)
	style.border_color = _with_alpha(Color.WHITE, 0.12)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.shadow_color = _with_alpha(Color.BLACK, 0.32)
	style.shadow_size = 8
	panel.add_theme_stylebox_override("panel", style)
	return panel


func _button(text: String, size: Vector2, color: Color, font_color: Color) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = size
	button.size = size
	button.add_theme_font_size_override("font_size", 20)
	button.add_theme_color_override("font_color", font_color)
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.border_color = _with_alpha(Color.WHITE, 0.22)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style)
	button.add_theme_stylebox_override("pressed", style)
	return button


func _style_dice_button() -> void:
	if not roll_button:
		return
	var skin: Dictionary = SKINS[selected_skin]
	var normal := StyleBoxFlat.new()
	normal.bg_color = skin["body"]
	normal.border_color = skin["accent"]
	normal.border_width_left = 5
	normal.border_width_right = 5
	normal.border_width_top = 5
	normal.border_width_bottom = 5
	normal.corner_radius_top_left = 16
	normal.corner_radius_top_right = 16
	normal.corner_radius_bottom_left = 16
	normal.corner_radius_bottom_right = 16
	normal.shadow_color = _with_alpha(Color.BLACK, 0.42)
	normal.shadow_size = 8
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = skin["edge"]
	roll_button.add_theme_stylebox_override("normal", normal)
	roll_button.add_theme_stylebox_override("hover", normal)
	roll_button.add_theme_stylebox_override("pressed", pressed)
	roll_button.add_theme_stylebox_override("disabled", normal)
	roll_button.add_theme_color_override("font_color", _readable_dice_font_color(skin["body"]))
	roll_button.add_theme_color_override("font_disabled_color", _readable_dice_font_color(skin["body"]))


func _readable_dice_font_color(color: Color) -> Color:
	var brightness := color.r * 0.299 + color.g * 0.587 + color.b * 0.114
	return Color("#2a1400") if brightness > 0.55 else Color("#fff4ca")


func _dice_face(value: int) -> String:
	match value:
		1:
			return "⚀"
		2:
			return "⚁"
		3:
			return "⚂"
		4:
			return "⚃"
		5:
			return "⚄"
		6:
			return "⚅"
	return "⚂"


func _label(text: String, font_size: int, color: Color, align: HorizontalAlignment) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.horizontal_alignment = align
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return label


func _player_card(player_name: String, badge: String, color: Color, position: Vector2) -> Panel:
	var card := _panel(Vector2(330, 112), position, Color("#18152d"), 18)
	var avatar := _label("●", 64, color, HORIZONTAL_ALIGNMENT_CENTER)
	avatar.position = Vector2(18, 18)
	avatar.size = Vector2(76, 76)
	card.add_child(avatar)
	var name_label := _label(player_name, 22, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
	name_label.position = Vector2(112, 24)
	name_label.size = Vector2(180, 32)
	card.add_child(name_label)
	var badge_label := _label("🎁 " + badge, 18, Color("#ffe17a"), HORIZONTAL_ALIGNMENT_LEFT)
	badge_label.position = Vector2(112, 62)
	badge_label.size = Vector2(160, 28)
	card.add_child(badge_label)
	return card


func _player_chip(player_name: String, color: Color, position: Vector2) -> Control:
	var chip := Control.new()
	chip.position = position
	chip.size = Vector2(220, 80)
	var avatar := _label("●", 52, color, HORIZONTAL_ALIGNMENT_CENTER)
	avatar.position = Vector2(0, 0)
	avatar.size = Vector2(70, 70)
	chip.add_child(avatar)
	var name_label := _label(player_name, 18, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
	name_label.position = Vector2(76, 22)
	name_label.size = Vector2(130, 30)
	chip.add_child(name_label)
	return chip


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


func _trigger_dice_cinematic(result: int) -> void:
	if not cinematic_root:
		return
	for child in cinematic_root.get_children():
		child.queue_free()
	if result != 6:
		_spawn_shock_ring(SKINS[selected_skin]["accent"], 0.9)
		return

	var skin: Dictionary = SKINS[selected_skin]
	match String(skin.get("effect", "lion")):
		"snake":
			_spawn_snake_cinematic(skin["accent"])
		"eagle":
			_spawn_eagle_cinematic(skin["accent"])
		_:
			_spawn_lion_cinematic(skin["accent"])


func _spawn_snake_cinematic(color: Color) -> void:
	var group := Node3D.new()
	group.position = dice_root.position + Vector3(0.0, 0.45, 0.0)
	cinematic_root.add_child(group)

	var snake_material := _make_material(Color("#124e24"), color, 0.25, 0.22, 1.3)
	var belly_material := _make_material(Color("#ffe58c"), Color("#ffcf57"), 0.1, 0.34, 0.6)
	for i in range(12):
		var body := MeshInstance3D.new()
		var mesh := SphereMesh.new()
		mesh.radius = 0.11 - float(i) * 0.003
		mesh.height = mesh.radius * 1.45
		mesh.radial_segments = 16
		mesh.rings = 8
		body.mesh = mesh
		body.material_override = snake_material
		var angle := float(i) * 0.52
		body.position = Vector3(cos(angle) * (0.75 - i * 0.018), sin(float(i) * 0.7) * 0.18, sin(angle) * (0.75 - i * 0.018))
		group.add_child(body)
	var head := MeshInstance3D.new()
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.18
	head_mesh.height = 0.25
	head.mesh = head_mesh
	head.material_override = snake_material
	head.position = Vector3(0.65, 0.16, 0.25)
	group.add_child(head)
	var tongue := MeshInstance3D.new()
	var tongue_mesh := BoxMesh.new()
	tongue_mesh.size = Vector3(0.05, 0.012, 0.28)
	tongue.mesh = tongue_mesh
	tongue.material_override = _make_material(Color("#ff2244"), Color("#ff6680"), 0.0, 0.2, 1.2)
	tongue.position = Vector3(0.82, 0.14, 0.34)
	tongue.rotation_degrees.y = -28
	group.add_child(tongue)
	_spawn_shock_ring(color, 1.4)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(group, "rotation:y", TAU * 1.6, 1.15).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(group, "scale", Vector3.ONE * 1.22, 0.55).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.chain().tween_callback(group.queue_free)


func _spawn_lion_cinematic(color: Color) -> void:
	var group := Node3D.new()
	group.position = dice_root.position + Vector3(0.0, 0.5, 0.0)
	cinematic_root.add_child(group)

	var mane_material := _make_material(Color("#d78a1d"), Color("#ffd45c"), 0.25, 0.26, 1.2)
	var face_material := _make_material(Color("#f2c064"), Color("#ffdd80"), 0.1, 0.32, 0.7)
	var mane := MeshInstance3D.new()
	var mane_mesh := TorusMesh.new()
	mane_mesh.inner_radius = 0.34
	mane_mesh.outer_radius = 0.58
	mane_mesh.ring_segments = 36
	mane_mesh.rings = 12
	mane.mesh = mane_mesh
	mane.material_override = mane_material
	mane.rotation_degrees.x = 90
	group.add_child(mane)
	var face := MeshInstance3D.new()
	var face_mesh := SphereMesh.new()
	face_mesh.radius = 0.34
	face_mesh.height = 0.46
	face_mesh.radial_segments = 24
	face_mesh.rings = 12
	face.mesh = face_mesh
	face.material_override = face_material
	group.add_child(face)
	for side in [-1, 1]:
		var ear := MeshInstance3D.new()
		var ear_mesh := CylinderMesh.new()
		ear_mesh.top_radius = 0.0
		ear_mesh.bottom_radius = 0.11
		ear_mesh.height = 0.22
		ear.mesh = ear_mesh
		ear.material_override = mane_material
		ear.position = Vector3(side * 0.24, 0.26, 0.0)
		ear.rotation_degrees.z = side * -26
		group.add_child(ear)
	_spawn_shock_ring(color, 1.8)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(group, "scale", Vector3.ONE * 1.55, 0.42).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(group, "rotation:y", TAU * 0.35, 0.85)
	tween.tween_property(group, "position:y", group.position.y + 0.35, 0.42).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.chain().tween_callback(group.queue_free)


func _spawn_eagle_cinematic(color: Color) -> void:
	var group := Node3D.new()
	group.position = dice_root.position + Vector3(0.0, 0.75, 0.0)
	cinematic_root.add_child(group)

	var wing_material := _make_material(Color("#f3f5ff"), color, 0.18, 0.2, 1.4)
	var body_material := _make_material(Color("#334055"), Color("#8fb7ff"), 0.25, 0.28, 0.6)
	var body := MeshInstance3D.new()
	var body_mesh := SphereMesh.new()
	body_mesh.radius = 0.18
	body_mesh.height = 0.34
	body.mesh = body_mesh
	body.material_override = body_material
	group.add_child(body)
	for side in [-1, 1]:
		var wing := MeshInstance3D.new()
		var wing_mesh := BoxMesh.new()
		wing_mesh.size = Vector3(0.74, 0.035, 0.24)
		wing.mesh = wing_mesh
		wing.material_override = wing_material
		wing.position = Vector3(side * 0.42, 0.0, 0.0)
		wing.rotation_degrees.z = side * 18
		group.add_child(wing)
	var beak := MeshInstance3D.new()
	var beak_mesh := CylinderMesh.new()
	beak_mesh.top_radius = 0.0
	beak_mesh.bottom_radius = 0.08
	beak_mesh.height = 0.2
	beak.mesh = beak_mesh
	beak.material_override = _make_material(Color("#ffcf35"), Color("#ffe88a"), 0.1, 0.22, 0.8)
	beak.position = Vector3(0.0, 0.0, 0.22)
	beak.rotation_degrees.x = 90
	group.add_child(beak)
	_spawn_shock_ring(color, 1.5)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(group, "position:z", group.position.z - 1.15, 0.85).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(group, "position:y", group.position.y + 0.38, 0.5).set_trans(Tween.TRANS_SINE)
	tween.tween_property(group, "scale", Vector3.ONE * 1.35, 0.38).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.chain().tween_callback(group.queue_free)


func _spawn_shock_ring(color: Color, scale_target: float) -> void:
	var ring_fx := MeshInstance3D.new()
	var mesh := TorusMesh.new()
	mesh.inner_radius = 0.35
	mesh.outer_radius = 0.39
	mesh.ring_segments = 80
	mesh.rings = 8
	ring_fx.mesh = mesh
	ring_fx.material_override = _make_particle_material(color)
	ring_fx.position = dice_root.position + Vector3(0.0, 0.12, 0.0)
	ring_fx.rotation_degrees.x = 90
	cinematic_root.add_child(ring_fx)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(ring_fx, "scale", Vector3.ONE * scale_target, 0.55).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.chain().tween_callback(ring_fx.queue_free)


func _smoothstep(value: float) -> float:
	var x := clampf(value, 0.0, 1.0)
	return x * x * (3.0 - 2.0 * x)


func _with_alpha(color: Color, alpha: float) -> Color:
	return Color(color.r, color.g, color.b, alpha)
