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
signal shop_requested
signal shop_closed
signal consumable_purchase_requested(item_id: String)
signal consumable_selected(item_id: String)
signal consumable_use_requested

const ConsumablesScript = preload("res://scripts/battle/battle_consumables.gd")
const PortraitScript = preload("res://scripts/presentation/hero_portrait.gd")
const MapScript = preload("res://scripts/presentation/tactical_map.gd")
const OverlayScript = preload("res://scripts/presentation/unit_overlay.gd")
const AbilityScript = preload("res://scripts/battle/hero_abilities.gd")
const INK := Color("f7f0e9")
const MUTED := Color("b5c8c5")
const PAPER := Color("132d35")
const TEAL := Color("73d4e6")
const COPPER := Color("f0c47d")
const HEROES: Dictionary = {
	"bas": ["바스", "룬 건틀릿 전사", "거대한 마력 장갑으로 파고들어\n가까운 적을 밀어내고 아군을 엄호합니다."],
	"rio": ["리오", "별빛 원반 마법사", "마법 원반의 출발과 귀환을 제어하고\n가로디딤으로 공격의 각도를 바꿉니다."],
	"nema": ["네마", "숲의 결계술사", "정령 룬핀을 세워 길목을 지키고\n부채 모양 보호막으로 동료를 돕습니다."],
}
const SKILLS: Dictionary = {
	"bas": ["화염 원호", "룬 수호", "대지 도약", "천둥 균열"],
	"rio": ["혜성 원반", "성운 고리", "월광 발걸음", "삼각 성좌"],
	"nema": ["씨앗 룬핀", "숲결 진동", "자연 수호", "덩굴 결박"],
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
var shop: Control
var _inventory: PanelContainer
var _inventory_credits: Label
var _inventory_status: Label
var _item_buttons: Dictionary = {}
var _shop_buy_buttons: Dictionary = {}
var _shop_reasons: Dictionary = {}
var _shop_button: Button
var _use_button: Button
var _shop_close: Button
var _shop_balance: Label
var _shop_feedback: Label
var _last_consumable_event_seq: int = 0
var ui_font: Font
var selected_hero: String = "bas"
var growth_button: Button
var _practice: CheckButton
var _start: Button
var _hero_buttons: Dictionary = {}
var _selection_frame: Control
var _selection_tags: Dictionary = {}
var _skill_buttons: Dictionary = {}
var _skill_icons: Dictionary = {}
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
	_build_inventory()
	_build_map()
	_build_feedback()
	_build_selection()
	_build_growth()
	_build_shop()
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
	_top.offset_bottom = 70
	var row: HBoxContainer = _row(_inset(_top, 10, 4), 8)
	var title: VBoxContainer = _column(row, 0)
	title.custom_minimum_size.x = 174
	_label(title, "PROJECT E  /  아스트라", 17, INK)
	_label(title, "수로 전장 · 세 라인 · 3 대 3", 11, MUTED)
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
	_mode = _label(row, "일반 경기", 12, MUTED)
	_button(row, "F1 도움말", Vector2(78, 36)).pressed.connect(func() -> void: help_requested.emit())
	var pause_button: Button = _button(row, "Esc  메뉴", Vector2(89, 36))
	pause_button.pressed.connect(func() -> void: pause_requested.emit())


func _build_bottom() -> void:
	_bottom = _panel(root_control)
	_bottom.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_bottom.offset_left = -402
	_bottom.offset_right = 402
	_bottom.offset_top = -124
	_bottom.offset_bottom = -12
	var row: HBoxContainer = _row(_inset(_bottom, 10, 4), 12)
	var hero_column: VBoxContainer = _column(row, 1)
	hero_column.custom_minimum_size.x = 230
	_hero_name = _label(hero_column, "바스  /  Lv. 1", 17, INK)
	_health = _bar(hero_column, Color("3bbda6"), 14)
	_health_text = _bar_text(_health)
	_energy = _bar(hero_column, Color("6eaeca"), 12)
	_energy_text = _bar_text(_energy)
	_passive = _label(hero_column, "압력 0 / 2", 11, TEAL)
	_passive.clip_text = true
	_passive.mouse_filter = Control.MOUSE_FILTER_PASS
	_xp = _label(hero_column, "XP 0 / 100 · K/D/A 0/0/0", 10, MUTED)
	_xp.mouse_filter = Control.MOUSE_FILTER_PASS
	var divider := VSeparator.new()
	row.add_child(divider)
	var skill_row: HBoxContainer = _row(row, 6)
	skill_row.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	for index: int in range(4):
		var slot: String = ["Q", "W", "E", "R"][index]
		var button: Button = _button(skill_row, "", Vector2(80, 84))
		button.pressed.connect(func() -> void: ability_requested.emit(slot))
		var key_label: Label = _label(button, slot, 12, COPPER)
		_place(key_label, Rect2(7, 4, 20, 18))
		var icon := TextureRect.new()
		icon.name = "SkillIcon" + slot
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(icon)
		_place(icon, Rect2(27, 7, 30, 25))
		_skill_icons[slot] = icon
		var name_label: Label = _label(button, "", 12, INK)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_place(name_label, Rect2(2, 34, 76, 18))
		var state_label: Label = _label(button, "", 11, TEAL)
		state_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_place(state_label, Rect2(2, 51, 76, 16))
		var cost_label: Label = _label(button, "", 10, MUTED)
		cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_place(cost_label, Rect2(2, 67, 76, 15))
		_skill_buttons[slot] = button
		_skill_labels[slot] = [name_label, state_label, cost_label]
	growth_button = _button(row, "G  성장\n+ 2", Vector2(90, 84))
	growth_button.add_theme_font_size_override("font_size", 12)
	growth_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	growth_button.add_theme_color_override("font_color", TEAL)
	growth_button.pressed.connect(func() -> void: growth_requested.emit())
	_hint = _label(root_control, "우클릭 이동·공격 · A 공격 이동 · QWER 기술 · G 성장 · B 복귀 · P 상점 · D 사용 · F1 도움말", 10, Color("fff5da"))
	_hint.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_hint.offset_left = -402
	_hint.offset_right = 402
	_hint.offset_top = -204
	_hint.offset_bottom = -188
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.add_theme_color_override("font_shadow_color", Color("102a31"))
	_hint.add_theme_constant_override("shadow_offset_y", 1)


func _build_inventory() -> void:
	_inventory = _panel(root_control)
	_inventory.name = "ConsumableInventory"
	_inventory.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_inventory.offset_left = -376
	_inventory.offset_right = 376
	_inventory.offset_top = -184
	_inventory.offset_bottom = -130
	var row: HBoxContainer = _row(_inset(_inventory, 8, 1), 8)
	_inventory_credits = _label(row, "0 크레딧", 11, INK)
	_inventory_credits.custom_minimum_size.x = 80
	_inventory_credits.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	for item_id: String in ConsumablesScript.ITEMS:
		var button: Button = _button(row, "", Vector2(124, 36))
		button.name = "Select" + item_id
		button.add_theme_font_size_override("font_size", 12)
		button.pressed.connect(func() -> void: consumable_selected.emit(item_id))
		_item_buttons[item_id] = button
	_shop_button = _button(row, "P 상점", Vector2(72, 36))
	_shop_button.add_theme_font_size_override("font_size", 12)
	_shop_button.pressed.connect(func() -> void: shop_requested.emit())
	_use_button = _button(row, "D 사용", Vector2(72, 36))
	_use_button.add_theme_font_size_override("font_size", 12)
	_use_button.pressed.connect(func() -> void: consumable_use_requested.emit())
	_inventory_status = _label(row, "공유 대기 · 준비", 11, TEAL)
	_inventory_status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_inventory_status.vertical_alignment = VERTICAL_ALIGNMENT_CENTER


func _build_shop() -> void:
	shop = _modal("BaseShop", 750)
	var column: VBoxContainer = shop.get_meta("column") as VBoxContainer
	_label(column, "기지 상점  /  소모품", 28, INK)
	_shop_balance = _label(column, "", 16, TEAL)
	_label(column, "자기 기지의 살아 있는 영웅만 구매 · 두 종류 합산 최대 2개", 14, MUTED)
	_label(column, "공유 사용 대기 12초 · 상점을 닫고 소모품 칸 선택 → D로 사용", 13, MUTED)
	var cards: HBoxContainer = _row(column, 14)
	for item_id: String in ConsumablesScript.ITEMS:
		var item: Dictionary = ConsumablesScript.ITEMS[item_id]
		var card: PanelContainer = _panel(cards)
		card.custom_minimum_size.x = 334
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var content: VBoxContainer = _column(_inset(card, 15, 14), 10)
		_label(content, item.name, 23, INK)
		_label(content, "%d 크레딧" % item.cost, 20, TEAL)
		_label(content, "에너지 40을 2초 동안 회복" if item_id == "I01" else "체력 200을 4초 동안 회복", 15, INK)
		_label(content, "적 영웅 피해에도 회복 유지" if item_id == "I01" else "적 영웅 귀속 유효 피해를 받으면 중단", 12, MUTED)
		var reason: Label = _label(content, "", 13, COPPER)
		_shop_reasons[item_id] = reason
		var button: Button = _button(content, "구매", Vector2(0, 42), true)
		button.name = "Buy" + item_id
		button.pressed.connect(func() -> void: consumable_purchase_requested.emit(item_id))
		_shop_buy_buttons[item_id] = button
	_shop_feedback = _label(column, "", 14, TEAL)
	_shop_feedback.custom_minimum_size.y = 22
	_shop_close = _button(column, "P / Esc  ·  전장으로 돌아가기", Vector2(0, 44), true)
	_shop_close.pressed.connect(func() -> void: shop_closed.emit())
	shop.hide()


static func consumable_reason(reason: String) -> String:
	var reasons: Dictionary = {
		"Match ended": "경기가 종료되었습니다.",
		"Invalid hero": "사용할 영웅을 확인하세요.",
		"Hero defeated": "부활 후 구매·사용할 수 있습니다.",
		"Unknown consumable": "알 수 없는 소모품입니다.",
		"Return to home base": "자기 기지로 돌아오면 구매할 수 있습니다.",
		"Consumable inventory full": "합산 2개까지 보유할 수 있습니다.",
		"Not enough credits": "크레딧이 부족합니다.",
		"No selected consumable": "선택한 아이템의 재고가 없습니다.",
		"Consumable cooldown": "소모품의 공유 사용 대기 중입니다.",
		"Health already full": "체력이 이미 가득 찼습니다.",
		"Energy already full": "에너지가 이미 가득 찼습니다.",
		"Invalid consumable state": "소모품 상태를 확인하세요.",
	}
	return str(reasons.get(reason, "지금은 소모품을 사용할 수 없습니다."))


func reset_consumable_feedback() -> void:
	_last_consumable_event_seq = 0
	_shop_feedback.text = ""
	_toast_left = 0.0
	_toast.hide()


func show_consumable_message(message: String) -> void:
	_shop_feedback.text = message
	show_message(message)


func _update_consumables(battle: Variant, hero: Dictionary) -> void:
	var stock: int = int(hero.consumables.I01) + int(hero.consumables.I02)
	_inventory_credits.text = "%d 크레딧\n보유 %d / 2" % [floori(hero.credits), stock]
	_shop_balance.text = "보유 %d 크레딧  ·  재고 %d / 2  ·  읽는 동안 경기 일시정지" % [floori(hero.credits), stock]
	for item_id: String in ConsumablesScript.ITEMS:
		var item: Dictionary = ConsumablesScript.ITEMS[item_id]
		var button: Button = _item_buttons[item_id]
		var selected: bool = hero.consumable_selected == item_id
		button.text = "%s %s ×%d" % ["●" if selected else "○", item.name, hero.consumables[item_id]]
		button.tooltip_text = "클릭: 선택만 / D: 선택한 아이템 사용"
		button.add_theme_stylebox_override("normal", _style(Color("30574e") if selected else Color("203c42"), TEAL if selected else Color("668178")))
		var reason: String = battle.consumable_purchase_error(hero.id, item_id)
		_shop_reasons[item_id].text = "구매 가능 · 보유 %d개" % hero.consumables[item_id] if reason.is_empty() else consumable_reason(reason)
		_shop_buy_buttons[item_id].disabled = not reason.is_empty()
		_shop_buy_buttons[item_id].text = "%d 크레딧 · 구매" % item.cost
	var cooldown: float = hero.consumable_cooldown
	_inventory_status.text = "공유 대기 %.1f초" % cooldown if cooldown > 0.0 else "공유 대기: 준비"
	if not hero.consumable_effect.is_empty():
		var effect: Dictionary = hero.consumable_effect
		_inventory_status.text += "\n%s 회복 %.1f초" % [ConsumablesScript.ITEMS[effect.item_id].name, effect.remaining]
	else:
		_inventory_status.text += "\n선택 후 D로 사용"
	_use_button.tooltip_text = consumable_reason(battle.consumable_use_error(hero.id)) if not battle.consumable_use_error(hero.id).is_empty() else "선택한 아이템 사용 · 공유 대기 12초"
	for event: Dictionary in battle.events:
		var sequence: int = int(event.get("seq", 0))
		if sequence <= _last_consumable_event_seq:
			continue
		_last_consumable_event_seq = sequence
		if int(event.get("target_id", -1)) != int(hero.id) or not ConsumablesScript.ITEMS.has(event.get("item_id", "")):
			continue
		var item_name: String = ConsumablesScript.ITEMS[event.item_id].name
		match str(event.get("type", "")):
			"consumable_purchase": show_consumable_message(item_name + " 구매 완료")
			"consumable_use": show_consumable_message(item_name + " 사용 · 회복 시작")
			"consumable_end":
				var endings: Dictionary = {"completed": " 회복 완료", "interrupted": " 회복 중단 · 적 영웅 피해", "death": " 회복 종료 · 영웅 사망"}
				show_consumable_message(item_name + str(endings.get(event.get("reason", ""), " 회복 종료")))


func _build_map() -> void:
	_map_panel = _panel(root_control)
	# The concept-board minimap sits below the top bar, preserving lane view.
	_map_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	_map_panel.offset_left = 18
	_map_panel.offset_right = 284
	_map_panel.offset_top = 89
	_map_panel.offset_bottom = 311
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
	_toast.offset_top = 124
	_toast.offset_bottom = 166
	_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast_text = _label(_inset(_toast, 10, 4), "", 13, INK)
	_toast_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_toast_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.hide()
	_target = _panel(root_control)
	_target.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_target.offset_left = -270
	_target.offset_right = -18
	_target.offset_top = 124
	_target.offset_bottom = 179
	_target_text = _label(_inset(_target, 12, 8), "", 13, INK)
	_target.hide()


	root_control.resized.connect(_layout_feedback)
	_layout_feedback()


func _layout_feedback() -> void:
	var half_width: float = minf(310.0, maxf(160.0, (root_control.size.x - 600.0) * 0.5))
	_toast.offset_left = -half_width
	_toast.offset_right = half_width


func _build_selection() -> void:
	selection = Control.new()
	selection.name = "HeroSelection"
	selection.mouse_filter = Control.MOUSE_FILTER_STOP
	root_control.add_child(selection)
	selection.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var backdrop := TextureRect.new()
	backdrop.name = "CanalBackdrop"
	backdrop.texture = preload("res://assets/ui/canal-backdrop.webp")
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	selection.add_child(backdrop)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.28, 0.65, 1.0])
	gradient.colors = PackedColorArray([Color(0.025, 0.09, 0.11, 0.90), Color(0.025, 0.09, 0.11, 0.36), Color(0.025, 0.09, 0.11, 0.52), Color(0.025, 0.09, 0.11, 0.96)])
	var shade_texture := GradientTexture2D.new()
	shade_texture.gradient = gradient
	shade_texture.fill_from = Vector2(0.0, 0.0)
	shade_texture.fill_to = Vector2(0.0, 1.0)
	var shade := TextureRect.new()
	shade.texture = shade_texture
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	selection.add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_selection_frame = Control.new()
	_selection_frame.name = "SelectionFrame"
	_selection_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_selection_frame.size = Vector2(1280, 720)
	selection.add_child(_selection_frame)
	_place(_label(_selection_frame, "PROJECT E  /  아스트라 전장", 13, COPPER), Rect2(64, 30, 600, 25))
	_place(_label(_selection_frame, "어떤 영웅과 함께할까요?", 38, INK), Rect2(64, 60, 1100, 54))
	_place(_label(_selection_frame, "세 갈래 길, 하나의 목표. 적의 마법 핵을 파괴하세요.", 15, Color("d6e3dc")), Rect2(66, 116, 1100, 28))
	var version: Label = _label(_selection_frame, "v" + str(ProjectSettings.get_setting("application/config/version", "0.6.0")), 12, MUTED)
	version.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_place(version, Rect2(1036, 31, 180, 24))
	var group := ButtonGroup.new()
	var accents: Dictionary = {"bas": Color("edbf7a"), "rio": Color("b9b4f2"), "nema": Color("a6dbae")}
	for index: int in range(3):
		var key: String = ["bas", "rio", "nema"][index]
		var button: Button = _button(_selection_frame, "", Vector2(368, 350))
		button.name = "HeroCard" + key.capitalize()
		_place(button, Rect2(64 + index * 392, 160, 368, 350))
		button.toggle_mode = true
		button.button_group = group
		button.button_pressed = key == selected_hero
		button.pressed.connect(func() -> void: select_hero(key))
		var normal: StyleBoxFlat = _style(Color("102b32"), Color("69837b"), 1)
		normal.shadow_color = Color(0.0, 0.025, 0.03, 0.60)
		normal.shadow_size = 14
		normal.shadow_offset = Vector2(0, 6)
		button.add_theme_stylebox_override("normal", normal)
		button.add_theme_stylebox_override("hover", _style(Color("1b3b40"), accents[key], 2))
		button.add_theme_stylebox_override("pressed", _style(Color("234246"), COPPER, 3))
		button.add_theme_stylebox_override("hover_pressed", _style(Color("294d4e"), COPPER, 3))
		_hero_buttons[key] = button
		var portrait: TextureRect = PortraitScript.new()
		portrait.hero_key = key
		portrait.name = "HeroIllustration"
		portrait.custom_minimum_size = Vector2(352, 232)
		button.add_child(portrait)
		_place(portrait, Rect2(8, 8, 352, 232))
		var name_label: Label = _label(button, HEROES[key][0], 28, INK)
		_place(name_label, Rect2(18, 249, 90, 40))
		var role_label: Label = _label(button, HEROES[key][1], 14, accents[key])
		_place(role_label, Rect2(106, 258, 244, 28))
		var description: Label = _label(button, HEROES[key][2], 12, Color("d0ded7"))
		_place(description, Rect2(18, 300, 332, 40))
		var tag := PanelContainer.new()
		tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tag.add_theme_stylebox_override("panel", _style(Color("163a3c"), COPPER, 1))
		button.add_child(tag)
		_place(tag, Rect2(18, 18, 114, 28))
		_label(tag, "선택한 영웅", 12, Color("fff0c9")).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tag.visible = key == selected_hero
		_selection_tags[key] = tag
	_place(_label(_selection_frame, "플레이 방식", 12, COPPER), Rect2(66, 526, 400, 22))
	var mode_group := ButtonGroup.new()
	var regular: Button = _button(_selection_frame, "일반 경기\n레벨 1 · 성장 2포인트", Vector2(268, 62))
	regular.toggle_mode = true
	regular.button_group = mode_group
	regular.button_pressed = true
	regular.add_theme_font_size_override("font_size", 14)
	_place(regular, Rect2(64, 553, 268, 62))
	_practice = CheckButton.new()
	_practice.text = "기술 체험\n레벨 3 · R 해금"
	_practice.focus_mode = Control.FOCUS_NONE
	_practice.button_group = mode_group
	_practice.add_theme_font_size_override("font_size", 14)
	for state: String in ["normal", "hover", "pressed", "hover_pressed"]:
		_practice.add_theme_stylebox_override(state, _style(Color("244247") if state.contains("pressed") else Color("142e35"), TEAL if state != "normal" else Color("67857e"), 2 if state.contains("pressed") else 1))
	_selection_frame.add_child(_practice)
	_place(_practice, Rect2(344, 553, 280, 62))
	_start = _button(_selection_frame, "바스로 경기 시작", Vector2(568, 62), true)
	_start.add_theme_font_size_override("font_size", 22)
	_start.add_theme_color_override("font_color", Color("142e32"))
	_start.add_theme_color_override("font_hover_color", Color("142e32"))
	_start.add_theme_color_override("font_pressed_color", Color("142e32"))
	_start.add_theme_stylebox_override("normal", _style(Color("edc680"), Color("ffe4aa"), 2))
	_start.add_theme_stylebox_override("hover", _style(Color("ffdea0"), Color("fff2cf"), 2))
	_start.add_theme_stylebox_override("pressed", _style(Color("d4ac67"), Color("fff2cf"), 2))
	_place(_start, Rect2(648, 553, 568, 62))
	_start.pressed.connect(func() -> void: match_requested.emit(selected_hero, _practice.button_pressed))
	var team_note: Label = _label(_selection_frame, "나 + 아군 봇 2명  vs  상대 봇 3명   ·   각 팀에 바스 / 리오 / 네마가 한 명씩 참가합니다.", 13, Color("d0ded7"))
	team_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_place(team_note, Rect2(64, 630, 1152, 30))
	_place(_label(_selection_frame, "우클릭 이동·공격   ·   A 공격 이동   ·   QWER 기술   ·   G 성장   ·   F1 도움말", 12, MUTED), Rect2(64, 680, 940, 24))
	var review_hint: Label = _label(_selection_frame, "F7  전장 둘러보기", 12, MUTED)
	review_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_place(review_hint, Rect2(984, 680, 232, 24))
	selection.resized.connect(_layout_selection)
	_layout_selection()
	call_deferred("_layout_selection")


func _layout_selection() -> void:
	if not is_instance_valid(_selection_frame):
		return
	var fit: float = minf(selection.size.x / 1280.0, selection.size.y / 720.0)
	_selection_frame.scale = Vector2.ONE * fit
	_selection_frame.position = (selection.size - Vector2(1280, 720) * fit) * 0.5


func _place(control: Control, rect: Rect2) -> void:
	control.position = rect.position
	control.size = rect.size


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
	_label(left, "G: 성장 포인트 투자 · 일반 경기 시작은 2포인트\nR: 레벨 3부터 성장 1포인트로 해금\nB: 기지까지 걸어서 복귀 · 기지에서 전투 이탈 후 회복\nP: 상점 · 자기 기지에서 구매 / 합산 2개 보유\n슬롯 클릭: 선택만 · D: 선택한 아이템 사용 / 공유 12초", 14, INK)
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
	for hero_key: String in _selection_tags:
		_selection_tags[hero_key].visible = hero_key == key


func show_selection() -> void:
	selection.show()
	growth.hide()
	pause_menu.hide()
	result.hide()
	help_panel.hide()
	shop.hide()
	reset_consumable_feedback()
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
	shop.hide()
	reset_consumable_feedback()
	_set_match_visible(true)


func _set_match_visible(active: bool) -> void:
	for item: Control in [_top, _bottom, _inventory, _map_panel, _hint]:
		item.visible = active
	unit_overlay.enabled = active
	minimap.active = active


func update_state(battle: Variant, aim_slot: String, practice: bool, attack_aim: bool = false) -> void:
	if not battle.units.has(battle.controlled_id):
		return
	var hero: Dictionary = battle.units[battle.controlled_id]
	_hint.text = "A 공격 이동 · 지면 좌클릭 확정 · Esc 취소" if attack_aim else "우클릭 이동·공격 · A 공격 이동 · QWER 기술 · G 성장 · B 복귀 · P 상점 · D 사용 · F1 도움말"
	var key: String = str(hero.hero)
	_hero_name.text = "%s  /  Lv. %d%s" % [HEROES[key][0], hero.level, "  ·  부활 %.0f초" % ceilf(hero.respawn_left) if not hero.alive else ""]
	_health.max_value = hero.max_hp
	_health.value = hero.hp
	_health_text.text = "체력 %d / %d%s" % [ceili(hero.hp), hero.max_hp, "  +%d 보호막" % ceili(hero.shield) if hero.shield > 0 else ""]
	_energy.max_value = hero.max_energy
	_energy.value = hero.energy
	_energy_text.text = "에너지 %d / %d" % [floori(hero.energy), hero.max_energy]
	_xp.text = "XP %d / %d · K/D/A %d/%d/%d" % [hero.xp, 100 + 25 * (hero.level - 1), hero.kills, hero.deaths, hero.assists] if hero.level < 12 else "최고 레벨 · K/D/A %d/%d/%d" % [hero.kills, hero.deaths, hero.assists]
	_passive.text = _passive_text(battle, hero)
	_passive.tooltip_text = _passive.text
	_xp.tooltip_text = "K / D / A · 처치 / 사망 / 도움"
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
		var icon: TextureRect = _skill_icons[slot]
		var icon_path: String = "res://assets/ui/skills/%s_%s.svg" % [key, slot.to_lower()]
		if icon.get_meta("asset_path", "") != icon_path:
			icon.texture = load(icon_path) as Texture2D
			icon.set_meta("asset_path", icon_path)
		var cost: float = AbilityScript.CONFIG[key][slot][0]
		labels[0].text = SKILLS[key][index]
		labels[2].text = "에너지 %d" % int(cost)
		var state: String = "준비"
		if slot == "R" and not hero.r_unlocked:
			state = "Lv.3 해금"
		elif hero.cooldowns[slot] > 0.0:
			state = "%.1f초" % hero.cooldowns[slot]
		elif hero.energy < cost:
			state = "에너지 부족"
		elif aim_slot == slot:
			state = "좌클릭 확정"
		labels[1].text = state
		labels[1].add_theme_color_override("font_color", COPPER if state != "준비" and aim_slot != slot else TEAL)
		button.tooltip_text = "%s · %s\n에너지 %d / 재사용 %.1f초\n%s" % [slot, SKILLS[key][index], cost, AbilityScript.CONFIG[key][slot][1], SKILL_HELP[key][index]]
		button.add_theme_stylebox_override("normal", _style(Color("305450") if aim_slot == slot else Color("19373d"), TEAL if aim_slot == slot else Color("a18d6f"), 2 if aim_slot == slot else 1))
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
	_update_consumables(battle, hero)
	minimap.queue_redraw()


func _passive_text(battle: Variant, hero: Dictionary) -> String:
	if hero.hero == "bas":
		return "압력 %d / 2%s" % [hero.pressure, "  ·  %.1f초" % hero.pressure_left if hero.pressure > 0 else " · 기술 적중 시 충전"]
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
	shop.hide()
	result.show()
	_result_title.text = "승리" if battle.winner == 0 else ("패배" if battle.winner == 1 else "무승부")
	_result_title.add_theme_color_override("font_color", TEAL if battle.winner == 0 else COPPER)
	var hero: Dictionary = battle.units[battle.controlled_id]
	var outcome: String = "상대 핵을 파괴했습니다." if battle.winner == 0 else ("아군 핵이 파괴되었습니다." if battle.winner == 1 else "양 팀 핵이 동시에 파괴되었습니다.")
	_result_stats.text = "%s\n\n%s · %02d:%02d\n%s  ·  레벨 %d  ·  %d / %d / %d" % [outcome, "기술 체험" if practice else "일반 경기", int(battle.time) / 60, int(battle.time) % 60, HEROES[hero.hero][0], hero.level, hero.kills, hero.deaths, hero.assists]
	minimap.active = false


func blocks_point(point: Vector2) -> bool:
	if selection.visible or growth.visible or pause_menu.visible or result.visible or help_panel.visible or shop.visible:
		return true
	for control: Control in [_top, _bottom, _inventory, _map_panel, _target, _hint, _toast]:
		if control.visible and control.get_global_rect().has_point(point):
			return true
	return false


func _modal(node_name: String, width: float) -> Control:
	var backdrop := ColorRect.new()
	backdrop.name = node_name
	backdrop.color = Color(0.04, 0.07, 0.16, 0.74)
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
	result_theme.set_color("font_disabled_color", "Button", Color("8993a8"))
	result_theme.set_color("font_color", "CheckButton", INK)
	result_theme.set_color("font_hover_color", "CheckButton", TEAL)
	result_theme.set_stylebox("panel", "PanelContainer", _style(PAPER, Color("d8b57b"), 2))
	result_theme.set_stylebox("normal", "Button", _style(Color("19373d"), Color("a18d6f")))
	result_theme.set_stylebox("hover", "Button", _style(Color("294f50"), TEAL, 2))
	result_theme.set_stylebox("pressed", "Button", _style(Color("345b55"), TEAL, 2))
	result_theme.set_stylebox("disabled", "Button", _style(Color("203236"), Color("56576a")))
	result_theme.set_stylebox("focus", "Button", _style(Color(0, 0, 0, 0), TEAL, 2))
	return result_theme


func _style(fill: Color, border: Color, thickness: int = 1) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(thickness)
	style.set_corner_radius_all(12)
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
		button.add_theme_stylebox_override("normal", _style(Color("344d69"), COPPER, 2))
		button.add_theme_color_override("font_color", Color("fff2d4"))
	parent.add_child(button)
	return button


func _bar(parent: Node, fill: Color, height: float) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.custom_minimum_size.y = height
	bar.show_percentage = false
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_theme_stylebox_override("background", _style(Color("141f31"), Color("6b7694")))
	bar.add_theme_stylebox_override("fill", _style(fill, fill, 0))
	parent.add_child(bar)
	return bar


func _bar_text(bar: ProgressBar) -> Label:
	var label: Label = _label(bar, "", 10, Color("fff4dc"))
	label.add_theme_color_override("font_outline_color", Color("102a31"))
	label.add_theme_constant_override("outline_size", 2)
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return label
