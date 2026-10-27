extends CanvasLayer
## Presentation reads the local authority; buttons emit requests, never combat effects.

signal match_requested(hero_key: String, practice: bool)
signal ability_requested(slot: String)
signal growth_requested
signal investment_requested(stat: String)
signal resume_requested
signal selection_requested
signal restart_requested
signal pause_requested
signal growth_closed
signal help_requested
signal help_closed

const PortraitScript = preload("res://scripts/presentation/hero_portrait.gd")
const MapScript = preload("res://scripts/presentation/tactical_map.gd")
const OverlayScript = preload("res://scripts/presentation/unit_overlay.gd")
const AbilityScript = preload("res://scripts/battle/hero_abilities.gd")
const INK := Color("294943")
const MUTED := Color("65776b")
const PAPER := Color("faf2dc")
const TEAL := Color("2c8e80")
const COPPER := Color("b8754b")
const HEROES: Dictionary = {
	"bas": ["바스", "전선의 압력", "큰 장갑으로 파고들어\n가까운 적을 밀어내고 아군을 엄호합니다."],
	"rio": ["리오", "왕복하는 궤적", "원반의 출발과 귀환을 설계하고\n가로디딤으로 공격의 각도를 바꿉니다."],
	"nema": ["네마", "두 핀 사이의 약속", "연결 핀을 세워 길목을 지키고\n부채 모양 보호막으로 동료를 돕습니다."],
}
const SKILLS: Dictionary = {
	"bas": ["벼림 부채", "받침 펼치기", "엇박 발판", "세로 파열"],
	"rio": ["왕복 절삭", "회수 매듭", "가로디딤", "삼각 봉합"],
	"nema": ["짝핀 놓기", "직조 박동", "수선 부채", "결박 봉합"],
}
const SKILL_HELP: Dictionary = {
	"bas": ["짧고 넓은 부채로 공격합니다.", "가까운 지점의 아군에게 보호막을 줍니다.", "지형에 막히는 짧은 돌진입니다.", "넓은 직선에 피해와 속박을 줍니다."],
	"rio": ["출발과 귀환에 각각 적중하는 원반입니다.", "지점에 파동을 만들고 회수점을 남깁니다.", "옆으로 이동한 뒤 기본 공격을 강화합니다.", "삼각형의 세 변을 공격합니다. 내부는 안전합니다."],
	"nema": ["6m 안에 연결 핀을 설치합니다. 최대 2개입니다.", "핀 1개 주위 또는 연결된 핀 사이를 공격합니다.", "자신과 부채 안 아군을 보호하고 핀을 수선합니다.", "연결된 핀 2개를 소모해 띠를 속박합니다."],
}
const GROWTH: Dictionary = {
	"power": ["위력", "+10 위력", 5], "hp": ["최대 체력", "+80 체력", 5],
	"armor": ["방어", "+5 방어", 4], "regen": ["에너지 회복", "+1 /초", 3],
	"speed": ["이동 속도", "+0.15m /초", 3], "R": ["특수기 R", "레벨 3부터 해금", 1],
}

var root_control: Control
var minimap: Control
var unit_overlay: Control
var selection: Control
var growth: Control
var pause_menu: Control
var result: Control
var help_panel: Control
var ui_font: Font
var selected_hero: String = "bas"
var growth_button: Button
var _practice: CheckButton
var _start: Button
var _hero_buttons: Dictionary = {}
var _skill_buttons: Dictionary = {}
var _skill_labels: Dictionary = {}
var _growth_buttons: Dictionary = {}
var _top: PanelContainer
var _bottom: PanelContainer
var _map_panel: PanelContainer
var _hero_name: Label
var _health: ProgressBar
var _energy: ProgressBar
var _health_text: Label
var _energy_text: Label
var _passive: Label
var _xp: Label
var _timer: Label
var _mode: Label
var _west_core: Label
var _east_core: Label
var _hint: Label
var _toast: PanelContainer
var _toast_text: Label
var _toast_left: float = 0.0
var _target: PanelContainer
var _target_text: Label
var _growth_title: Label
var _growth_stats: Label
var _result_title: Label
var _result_stats: Label


func _ready() -> void:
	layer = 10
	root_control = Control.new()
	root_control.name = "Interface"
	add_child(root_control)
	root_control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var font_path: String = "res://assets/fonts/ProjectEKorean.woff2"
	if ResourceLoader.exists(font_path):
		ui_font = load(font_path) as Font
	else:
		var system_font := SystemFont.new()
		system_font.font_names = PackedStringArray(["Noto Sans CJK KR", "Malgun Gothic", "Apple SD Gothic Neo", "sans-serif"])
		ui_font = system_font
	root_control.theme = _theme()
	unit_overlay = OverlayScript.new()
	unit_overlay.ui_font = ui_font
	unit_overlay.use_korean = true
	root_control.add_child(unit_overlay)
	_build_top()
	_build_bottom()
	_build_map()
	_build_feedback()
	_build_selection()
	_build_growth()
	_build_pause()
	_build_result()
	_build_help()
	show_selection()


func _process(delta: float) -> void:
	if _toast_left > 0.0:
		_toast_left -= delta
		_toast.visible = _toast_left > 0.0 and not selection.visible


func _build_top() -> void:
	_top = _panel(root_control)
	_top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_top.offset_left = 18
	_top.offset_right = -18
	_top.offset_top = 14
	_top.offset_bottom = 76
	var row: HBoxContainer = _row(_inset(_top, 16, 8), 18)
	var title: VBoxContainer = _column(row, 0)
	title.custom_minimum_size.x = 226
	_label(title, "PROJECT E  /  수로 공방", 20, INK)
	_label(title, "M01 · 세 라인 · 오프라인 3 대 3", 12, MUTED)
	_west_core = _label(row, "청록 핵 · 잠금", 16, TEAL)
	_west_core.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_west_core.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var clock_column: VBoxContainer = _column(row, 0)
	_timer = _label(clock_column, "00:00", 24, INK)
	_timer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label(clock_column, "경기 시간", 10, MUTED).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_east_core = _label(row, "주황 핵 · 잠금", 16, COPPER)
	_east_core.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_east_core.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_mode = _label(row, "일반 경기", 13, MUTED)
	_button(row, "F1 도움말", Vector2(88, 40)).pressed.connect(func() -> void: help_requested.emit())
	var pause_button: Button = _button(row, "Esc  메뉴", Vector2(99, 40))
	pause_button.pressed.connect(func() -> void: pause_requested.emit())


func _build_bottom() -> void:
	_bottom = _panel(root_control)
	_bottom.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_bottom.offset_left = 18
	_bottom.offset_right = -298
	_bottom.offset_top = -164
	_bottom.offset_bottom = -18
	var row: HBoxContainer = _row(_inset(_bottom, 14, 12), 14)
	var hero_column: VBoxContainer = _column(row, 4)
	hero_column.custom_minimum_size.x = 245
	hero_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_hero_name = _label(hero_column, "바스  /  Lv. 1", 21, INK)
	_health = _bar(hero_column, Color("3bbda6"), 18)
	_health_text = _bar_text(_health)
	_energy = _bar(hero_column, Color("6eaeca"), 13)
	_energy_text = _bar_text(_energy)
	_passive = _label(hero_column, "압력 0 / 2", 12, TEAL)
	_xp = _label(hero_column, "경험치 0 / 100 · 0 / 0 / 0", 11, MUTED)
	var divider := VSeparator.new()
	row.add_child(divider)
	var skill_row: HBoxContainer = _row(row, 8)
	skill_row.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	for index: int in range(4):
		var slot: String = ["Q", "W", "E", "R"][index]
		var button: Button = _button(skill_row, "", Vector2(104, 108))
		button.pressed.connect(func() -> void: ability_requested.emit(slot))
		var margin: MarginContainer = _inset(button, 7, 7)
		margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var column: VBoxContainer = _column(margin, 3)
		column.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var key_label: Label = _label(column, slot, 27, INK)
		key_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var name_label: Label = _label(column, "", 12, INK)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var state_label: Label = _label(column, "", 12, TEAL)
		state_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var cost_label: Label = _label(column, "", 10, MUTED)
		cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_skill_buttons[slot] = button
		_skill_labels[slot] = [name_label, state_label, cost_label]
	growth_button = _button(row, "G  성장\n+ 2", Vector2(100, 108))
	growth_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	growth_button.add_theme_color_override("font_color", TEAL)
	growth_button.pressed.connect(func() -> void: growth_requested.emit())
	_hint = _label(root_control, "우클릭 이동·공격 · A+좌클릭 공격 이동 · QWER 기술 · G 성장 · S 정지 · F1 도움말", 12, Color("fff5da"))
	_hint.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_hint.offset_left = 22
	_hint.offset_right = -300
	_hint.offset_top = -192
	_hint.offset_bottom = -168
	_hint.add_theme_color_override("font_shadow_color", Color("294943"))
	_hint.add_theme_constant_override("shadow_offset_y", 1)


func _build_map() -> void:
	_map_panel = _panel(root_control)
	_map_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	_map_panel.offset_left = -284
	_map_panel.offset_right = -18
	_map_panel.offset_top = -240
	_map_panel.offset_bottom = -18
	var column: VBoxContainer = _column(_inset(_map_panel, 10, 9), 5)
	_label(column, "전장   N / C / S", 12, INK)
	minimap = MapScript.new()
	column.add_child(minimap)
	minimap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_label(column, "좌클릭 시점 · 우클릭 이동", 10, MUTED)


func _build_feedback() -> void:
	_toast = _panel(root_control)
	_toast.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_toast.offset_left = -310
	_toast.offset_right = 310
	_toast.offset_top = 91
	_toast.offset_bottom = 133
	_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast_text = _label(_inset(_toast, 12, 8), "", 15, INK)
	_toast_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.hide()
	_target = _panel(root_control)
	_target.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_target.offset_left = -270
	_target.offset_right = -18
	_target.offset_top = 90
	_target.offset_bottom = 145
	_target_text = _label(_inset(_target, 12, 8), "", 13, INK)
	_target.hide()


func _build_selection() -> void:
	selection = _modal("HeroSelection", 1040)
	var column: VBoxContainer = selection.get_meta("column") as VBoxContainer
	_label(column, "수로 공방의 조율사", 32, INK)
	_label(column, "영웅을 고르고, 세 라인에서 동료와 함께 상대 핵을 파괴하세요.", 16, MUTED)
	var cards: HBoxContainer = _row(column, 14)
	var group := ButtonGroup.new()
	for key: String in ["bas", "rio", "nema"]:
		var button: Button = _button(cards, "", Vector2(308, 240))
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.toggle_mode = true
		button.button_group = group
		button.button_pressed = key == "bas"
		button.pressed.connect(func() -> void: select_hero(key))
		_hero_buttons[key] = button
		var margin: MarginContainer = _inset(button, 13, 10)
		margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var content: VBoxContainer = _column(margin, 3)
		content.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var portrait: Control = PortraitScript.new()
		portrait.hero_key = key
		portrait.custom_minimum_size = Vector2(180, 111)
		content.add_child(portrait)
		var name_label: Label = _label(content, HEROES[key][0], 25, INK)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var role_label: Label = _label(content, HEROES[key][1], 14, TEAL)
		role_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var description: Label = _label(content, HEROES[key][2], 12, MUTED)
		description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label(column, "나 + 아군 봇 2명  vs  상대 봇 3명 · 각 팀에 바스 / 리오 / 네마가 한 명씩 참가합니다.", 13, MUTED)
	_practice = CheckButton.new()
	_practice.text = "기술 체험  ·  레벨 3 / R 해금으로 시작"
	_practice.focus_mode = Control.FOCUS_NONE
	column.add_child(_practice)
	_label(column, "일반 경기: 레벨 1 · 성장 2포인트 · R은 레벨 3부터 1포인트로 해금", 13, MUTED)
	_start = _button(column, "바스로 경기 시작", Vector2(0, 52), true)
	_start.pressed.connect(func() -> void: match_requested.emit(selected_hero, _practice.button_pressed))
	_label(column, "우클릭 이동·공격    A+좌클릭 공격 이동    QWER 기술    G 성장    경기 중 F1 도움말", 13, MUTED).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


func _build_growth() -> void:
	growth = _modal("Growth", 620)
	var column: VBoxContainer = growth.get_meta("column") as VBoxContainer
	_growth_title = _label(column, "성장", 27, INK)
	_label(column, "전투가 잠시 멈춥니다. 한 번 투자할 때 1포인트를 사용합니다.", 14, MUTED)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	column.add_child(grid)
	for stat: String in GROWTH:
		var button: Button = _button(grid, "", Vector2(276, 76))
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(func() -> void: investment_requested.emit(stat))
		_growth_buttons[stat] = button
	_growth_stats = _label(column, "", 13, MUTED)
	var close: Button = _button(column, "G / Esc  ·  전장으로 돌아가기", Vector2(0, 44), true)
	close.pressed.connect(func() -> void: growth_closed.emit())
	growth.hide()


func _build_pause() -> void:
	pause_menu = _modal("Pause", 420)
	var column: VBoxContainer = pause_menu.get_meta("column") as VBoxContainer
	_label(column, "잠시 멈춤", 29, INK)
	_label(column, "로컬 경기의 시간과 전투가 멈춰 있습니다.", 14, MUTED)
	_button(column, "Esc  계속하기", Vector2(0, 46), true).pressed.connect(func() -> void: resume_requested.emit())
	_button(column, "F1  조작과 전장 안내", Vector2(0, 42)).pressed.connect(func() -> void: help_requested.emit())
	_button(column, "현재 영웅으로 다시 시작", Vector2(0, 42)).pressed.connect(func() -> void: restart_requested.emit())
	_button(column, "영웅 선택으로", Vector2(0, 42)).pressed.connect(func() -> void: selection_requested.emit())
	pause_menu.hide()


func _build_result() -> void:
	result = _modal("Result", 520)
	var column: VBoxContainer = result.get_meta("column") as VBoxContainer
	_label(column, "수로 공방 · 경기 종료", 15, MUTED)
	_result_title = _label(column, "승리", 42, TEAL)
	_result_stats = _label(column, "", 17, INK)
	_button(column, "같은 영웅으로 다시 시작", Vector2(0, 48), true).pressed.connect(func() -> void: restart_requested.emit())
	_button(column, "다른 영웅 고르기", Vector2(0, 44)).pressed.connect(func() -> void: selection_requested.emit())
	result.hide()


func _build_help() -> void:
	help_panel = _modal("FirstPlayGuide", 900)
	var column: VBoxContainer = help_panel.get_meta("column") as VBoxContainer
	_label(column, "전장 첫걸음", 28, INK)
	_label(column, "세 라인에서 성장하고, 병력을 동반해 상대 핵을 파괴하세요. 읽는 동안 경기는 멈춥니다.", 14, MUTED)
	var row: HBoxContainer = _row(column, 24)
	var left: VBoxContainer = _column(row, 8)
	var right: VBoxContainer = _column(row, 8)
	left.custom_minimum_size.x = 402
	right.custom_minimum_size.x = 402
	_label(left, "1  이동과 기본 공격", 18, TEAL)
	_label(left, "우클릭: 지면으로 이동 / 보이는 적을 지정 공격\nA → 지면 좌클릭: 이동 중 적을 기본 공격\n교전이 끝나면 원래 목적지로 이동 · S: 정지", 14, INK)
	_label(left, "2  기술과 카메라", 18, TEAL)
	_label(left, "Q / W / E / R → 좌클릭 확정 · Esc: 조준 취소\n가운데 버튼 드래그: 시점 이동 · 휠: 확대/축소\nSpace: 내 영웅 보기 · 미니맵 좌클릭: 시점 이동", 14, INK)
	_label(left, "3  성장과 회복", 18, TEAL)
	_label(left, "G: 성장 포인트 투자 · 일반 경기 시작은 2포인트\nR: 레벨 3부터 성장 1포인트로 해금\nB: 기지까지 걸어서 복귀 · 기지에서 전투 이탈 후 회복", 14, INK)
	_label(right, "4  경험치 셀", 18, COPPER)
	_label(right, "작은 셀 20 / 중간 셀 30 / 큰 셀 40 XP\n처치 팀의 14m 안 살아 있는 영웅이 보상을 나눔\n첫 생성 30초 · 파괴 후 45초에 같은 종류로 재생성", 14, INK)
	_label(right, "5  우리 팀의 시야", 18, COPPER)
	_label(right, "밝은 곳: 현재 관측 / 어두운 곳: 현재 보이지 않음\n아군 영웅·병력·포탑·핵이 시야를 제공합니다.\n시야원에 마우스를 올려 범위 확인 · 셀과 핀은 제공 안 함", 14, INK)
	_label(right, "6  병력과 함께 공성", 18, COPPER)
	_label(right, "아군 라인 병력이 12m 안에 오면 구조물 보호 해제\n같은 라인의 외곽탑 → 내곽탑 → 상대 핵 공격\n포탑 공격 8.5m · 잠긴 구조물은 먼저 앞선 탑을 파괴", 14, INK)
	_button(column, "F1 / Esc  ·  닫기", Vector2(0, 44), true).pressed.connect(func() -> void: help_closed.emit())
	help_panel.hide()


func select_hero(key: String) -> void:
	if not HEROES.has(key):
		return
	selected_hero = key
	_hero_buttons[key].button_pressed = true
	_start.text = "%s로 경기 시작" % HEROES[key][0]


func show_selection() -> void:
	selection.show()
	growth.hide()
	pause_menu.hide()
	result.hide()
	help_panel.hide()
	_toast.hide()
	_toast_left = 0
	_target.hide()
	_set_match_visible(false)


func show_match() -> void:
	selection.hide()
	growth.hide()
	pause_menu.hide()
	result.hide()
	help_panel.hide()
	_set_match_visible(true)


func _set_match_visible(active: bool) -> void:
	for item: Control in [_top, _bottom, _map_panel, _hint]:
		item.visible = active
	unit_overlay.enabled = active
	minimap.active = active


func update_state(battle: Variant, aim_slot: String, practice: bool, attack_aim: bool = false) -> void:
	if not battle.units.has(battle.controlled_id):
		return
	var hero: Dictionary = battle.units[battle.controlled_id]
	_hint.text = "A 공격 이동 · 지면 좌클릭 확정 · Esc 취소" if attack_aim else "우클릭 이동·공격 · A+좌클릭 공격 이동 · QWER 기술 · G 성장 · S 정지 · F1 도움말"
	var key: String = str(hero.hero)
	_hero_name.text = "%s  /  Lv. %d%s" % [HEROES[key][0], hero.level, "  ·  부활 %.0f초" % ceilf(hero.respawn_left) if not hero.alive else ""]
	_health.max_value = hero.max_hp
	_health.value = hero.hp
	_health_text.text = "체력 %d / %d%s" % [ceili(hero.hp), hero.max_hp, "  +%d 보호막" % ceili(hero.shield) if hero.shield > 0 else ""]
	_energy.max_value = hero.max_energy
	_energy.value = hero.energy
	_energy_text.text = "에너지 %d / %d" % [floori(hero.energy), hero.max_energy]
	_xp.text = "XP %d / %d · 처치 / 사망 / 도움  %d / %d / %d" % [hero.xp, 100 + 25 * (hero.level - 1), hero.kills, hero.deaths, hero.assists] if hero.level < 12 else "최고 레벨 · 처치 / 사망 / 도움  %d / %d / %d" % [hero.kills, hero.deaths, hero.assists]
	_passive.text = _passive_text(battle, hero)
	_timer.text = "%02d:%02d" % [int(battle.time) / 60, int(battle.time) % 60]
	_mode.text = "기술 체험 · Lv.3 / R" if practice else "일반 경기 · 봇 3 대 3"
	_mode.add_theme_color_override("font_color", COPPER if practice else MUTED)
	for core: Dictionary in battle.units.values():
		if core.kind != "core":
			continue
		var label: Label = _west_core if core.team == 0 else _east_core
		label.text = "%s 핵 · %s" % ["청록" if core.team == 0 else "주황", "파괴" if not core.alive else ("잠금" if core.locked else "노출")]
	for index: int in range(4):
		var slot: String = ["Q", "W", "E", "R"][index]
		var labels: Array = _skill_labels[slot]
		var button: Button = _skill_buttons[slot]
		var cost: float = AbilityScript.CONFIG[key][slot][0]
		labels[0].text = SKILLS[key][index]
		labels[2].text = "에너지 %d" % int(cost)
		var state: String = "준비"
		if slot == "R" and not hero.r_unlocked:
			state = "Lv.3 · 성장 해금"
		elif hero.cooldowns[slot] > 0.0:
			state = "%.1f초" % hero.cooldowns[slot]
		elif hero.energy < cost:
			state = "에너지 부족"
		elif aim_slot == slot:
			state = "좌클릭 확정"
		labels[1].text = state
		labels[1].add_theme_color_override("font_color", COPPER if state != "준비" and aim_slot != slot else TEAL)
		button.tooltip_text = "%s · %s\n에너지 %d / 재사용 %.1f초\n%s" % [slot, SKILLS[key][index], cost, AbilityScript.CONFIG[key][slot][1], SKILL_HELP[key][index]]
		button.add_theme_stylebox_override("normal", _style(Color("d7eddb") if aim_slot == slot else Color("eee5cf"), TEAL if aim_slot == slot else Color("d2c5a7")))
	growth_button.text = "G  성장\n+ %d 포인트" % hero.points
	_growth_title.text = "성장  ·  사용 가능 %d포인트" % hero.points
	_growth_stats.text = "현재 위력 %d · 방어 %d · 이동 %.2fm/초 · 에너지 회복 %.1f/초" % [hero.power, hero.armor, hero.speed, hero.energy_regen]
	for stat: String in GROWTH:
		var spec: Array = GROWTH[stat]
		var used: int = int(hero.investments[stat])
		var button: Button = _growth_buttons[stat]
		var note: String = spec[1]
		if stat == "R":
			note = "해금 완료" if hero.r_unlocked else ("레벨 3 필요" if hero.level < 3 else "1포인트로 해금")
		button.text = "%s   %d / %d\n%s" % [spec[0], used, spec[2], note]
		button.disabled = hero.points <= 0 or used >= int(spec[2]) or (stat == "R" and hero.level < 3)
	minimap.queue_redraw()


func _passive_text(battle: Variant, hero: Dictionary) -> String:
	if hero.hero == "bas":
		return "압력 %d / 2%s" % [hero.pressure, "  ·  %.1f초" % hero.pressure_left if hero.pressure > 0 else "  ·  영웅에게 기술 적중 시 충전"]
	if hero.hero == "rio":
		var phase: String = "원반 준비"
		for projectile: Dictionary in battle.projectiles:
			if projectile.get("owner_id", -1) == hero.id and projectile.kind == "rio_disc":
				phase = {"outbound": "원반 출발", "turn": "원반 회전", "return": "원반 귀환"}.get(projectile.get("phase", ""), "원반 비행")
		if not hero.return_mark.is_empty():
			phase += " · 회수점 %.1f초" % maxf(0, hero.return_mark.expires - battle.time)
		if hero.empowered_left > 0:
			phase += " · 강화 %.1f초" % hero.empowered_left
		return phase
	var remaining: Array[String] = []
	for pin_id: int in hero.pins:
		if battle.units.has(pin_id) and battle.units[pin_id].alive:
			remaining.append("%.1f" % maxf(0, battle.units[pin_id].expires - battle.time))
	var link: Dictionary = battle.get_pin_link(hero.id)
	return "핀 %d / 2 · %s%s" % [remaining.size(), "연결 유효" if not link.is_empty() else "연결 대기", " · " + "/".join(remaining) + "초" if not remaining.is_empty() else ""]


func show_message(text: String, duration: float = 3.2) -> void:
	_toast_text.text = text
	_toast_left = duration
	_toast.visible = not selection.visible


func show_target(target: Dictionary) -> void:
	_target.visible = not target.is_empty() and not selection.visible
	if target.is_empty():
		return
	var name_text: String = HEROES[target.hero][0] if target.kind == "hero" else {"tower": "방어탑", "core": "핵", "minion": "라인 병력", "cell": "경험치 셀", "pin": "연결 핀"}.get(target.kind, "대상")
	_target_text.text = "%s · %s\n체력 %d / %d%s" % ["적" if target.team == 1 else "중립", name_text, ceili(target.hp), target.max_hp, " · 잠금" if target.locked else (" · 병력 보호" if target.get("siege_protected", false) else "")]


func show_result(battle: Variant, practice: bool) -> void:
	growth.hide()
	pause_menu.hide()
	help_panel.hide()
	result.show()
	_result_title.text = "승리" if battle.winner == 0 else ("패배" if battle.winner == 1 else "무승부")
	_result_title.add_theme_color_override("font_color", TEAL if battle.winner == 0 else COPPER)
	var hero: Dictionary = battle.units[battle.controlled_id]
	var outcome: String = "상대 핵을 파괴했습니다." if battle.winner == 0 else ("아군 핵이 파괴되었습니다." if battle.winner == 1 else "양 팀 핵이 동시에 파괴되었습니다.")
	_result_stats.text = "%s\n\n%s · %02d:%02d\n%s  ·  레벨 %d  ·  %d / %d / %d" % [outcome, "기술 체험" if practice else "일반 경기", int(battle.time) / 60, int(battle.time) % 60, HEROES[hero.hero][0], hero.level, hero.kills, hero.deaths, hero.assists]
	minimap.active = false


func blocks_point(point: Vector2) -> bool:
	if selection.visible or growth.visible or pause_menu.visible or result.visible or help_panel.visible:
		return true
	for control: Control in [_top, _bottom, _map_panel, _target]:
		if control.visible and control.get_global_rect().has_point(point):
			return true
	return false


func _modal(node_name: String, width: float) -> Control:
	var backdrop := ColorRect.new()
	backdrop.name = node_name
	backdrop.color = Color(0.08, 0.18, 0.17, 0.65)
	root_control.add_child(backdrop)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	var center := CenterContainer.new()
	backdrop.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var panel: PanelContainer = _panel(center)
	panel.custom_minimum_size.x = width
	var column: VBoxContainer = _column(_inset(panel, 24, 20), 12)
	backdrop.set_meta("column", column)
	return backdrop


func _theme() -> Theme:
	var result_theme := Theme.new()
	result_theme.default_font = ui_font
	result_theme.default_font_size = 15
	result_theme.set_color("font_color", "Label", INK)
	result_theme.set_color("font_color", "Button", INK)
	result_theme.set_color("font_hover_color", "Button", INK)
	result_theme.set_color("font_pressed_color", "Button", INK)
	result_theme.set_color("font_disabled_color", "Button", Color("939b89"))
	result_theme.set_color("font_color", "CheckButton", INK)
	result_theme.set_color("font_hover_color", "CheckButton", TEAL)
	result_theme.set_stylebox("panel", "PanelContainer", _style(PAPER, Color("c7b899")))
	result_theme.set_stylebox("normal", "Button", _style(Color("eee5cf"), Color("d2c5a7")))
	result_theme.set_stylebox("hover", "Button", _style(Color("e0edda"), TEAL))
	result_theme.set_stylebox("pressed", "Button", _style(Color("d1e8d3"), TEAL, 2))
	result_theme.set_stylebox("disabled", "Button", _style(Color("e8e2d1"), Color("d8cfb8")))
	result_theme.set_stylebox("focus", "Button", _style(Color(0, 0, 0, 0), TEAL, 2))
	return result_theme


func _style(fill: Color, border: Color, thickness: int = 1) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(thickness)
	style.set_corner_radius_all(8)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	return style


func _panel(parent: Node) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	parent.add_child(panel)
	return panel


func _inset(parent: Node, horizontal: int, vertical: int) -> MarginContainer:
	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side: String in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, horizontal)
	for side: String in ["top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, vertical)
	parent.add_child(margin)
	return margin


func _column(parent: Node, separation: int) -> VBoxContainer:
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", separation)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(column)
	return column


func _row(parent: Node, separation: int) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", separation)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(row)
	return row


func _label(parent: Node, value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
	return label


func _button(parent: Node, value: String, minimum: Vector2, primary: bool = false) -> Button:
	var button := Button.new()
	button.text = value
	button.custom_minimum_size = minimum
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	if primary:
		button.add_theme_stylebox_override("normal", _style(Color("d5e8d2"), TEAL))
		button.add_theme_color_override("font_color", TEAL)
	parent.add_child(button)
	return button


func _bar(parent: Node, fill: Color, height: float) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.custom_minimum_size.y = height
	bar.show_percentage = false
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_theme_stylebox_override("background", _style(Color("d6dac5"), Color("bdc7b3")))
	bar.add_theme_stylebox_override("fill", _style(fill, fill, 0))
	parent.add_child(bar)
	return bar


func _bar_text(bar: ProgressBar) -> Label:
	var label: Label = _label(bar, "", 10, Color("183f3d"))
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return label
