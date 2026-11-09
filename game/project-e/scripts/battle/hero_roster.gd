extends RefCounted
## V8 prototype roster. New values are local design experiments.
const KEYS: Array = ["bas", "rio", "nema", "orin", "tere", "mua", "sera", "lume"]
const HEROES: Dictionary = {
	"bas": ["바스", "룬 건틀릿 전사", "룬을 쌓으며 전선을 여는 근접 전사"],
	"rio": ["리오", "별빛 원반 마법사", "왕복 궤도와 삼각 성좌를 설계하는 술사"],
	"nema": ["네마", "숲의 결계술사", "정령목 연결로 아군을 보호하는 지원가"],
	"orin": ["오린", "바람의 사수", "준비된 파동과 강화 사격을 잇는 사수"],
	"tere": ["테르", "수정 방패 수호자", "후방 보호와 후퇴 반격을 맡는 수호자"],
	"mua": ["무아", "물결의 화가", "두 물결 구역을 교대하는 지원가"],
	"sera": ["세라", "월영 쌍검사", "월영 표식을 소모하는 근접 암살자"],
	"lume": ["루메", "잿불 연금술사", "지연 폭발과 연속 포격을 설계하는 술사"],
}
const STATS: Dictionary = {
	"bas": [1100.0, 5.8, 2.0, 0.18], "rio": [950.0, 6.2, 6.5, 0.16], "nema": [1000.0, 6.0, 5.5, 0.18],
	"orin": [930.0, 6.1, 7.0, 0.17], "tere": [1250.0, 5.4, 2.0, 0.22], "mua": [980.0, 6.0, 5.5, 0.18],
	"sera": [900.0, 6.5, 1.8, 0.13], "lume": [940.0, 5.8, 6.0, 0.20],
}
const ACCENTS: Dictionary = {"bas": "e6b76b", "rio": "83c9ee", "nema": "a5d78c", "orin": "e4cd88", "tere": "8ccce5", "mua": "84ded6", "sera": "c2a1e8", "lume": "f4a16f"}
const MELEE: Array = ["bas", "tere", "sera"]
const OPPONENTS: Dictionary = {"orin": ["bas", "sera", "mua"], "tere": ["bas", "lume", "orin"], "mua": ["bas", "tere", "lume"], "sera": ["bas", "orin", "tere"], "lume": ["bas", "mua", "sera"]}
static func team_for(selected: String, team: int) -> Array:
	if selected in ["bas", "rio", "nema"] or not KEYS.has(selected):
		return ["bas", "rio", "nema"]
	return [selected, "bas", "nema"] if team == 0 else OPPONENTS[selected].duplicate()
