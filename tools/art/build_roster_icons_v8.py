#!/usr/bin/env python3
"""Write original vector motifs for the five V8 prototype hero skill sets."""
from pathlib import Path
from xml.sax.saxutils import escape
ROOT = Path(__file__).resolve().parents[2] / 'game/project-e/assets/ui/skills'
# One authored symbol for each action, in a shared 64px frame.
HEROES = {
 'orin': ('e4cd88', ['바람살','돌개 숨결','순풍 걸음','쌍둥이 폭풍'], [
  '<path d="M12 44L48 18M35 18H49V32M13 25Q26 16 35 22M12 33Q24 25 31 29"/>',
  '<path d="M12 42Q53 44 48 25Q45 13 29 18Q18 23 27 31Q38 38 42 29M16 49Q35 54 48 44"/>',
  '<path d="M15 44L27 22L35 26L29 37L45 34L48 43L28 49ZM9 26H19M8 33H16M39 17L46 22L39 27"/>',
  '<path d="M14 17Q38 8 32 28Q28 40 12 37Q3 29 20 26M36 25Q60 16 54 36Q50 49 34 45Q25 37 42 34M19 47L15 54M44 12L48 7"/>' ]),
 'tere': ('8ccce5',['수정 방패격','후위의 성벽','수호 후퇴','빙정 봉쇄'],[
  '<path d="M20 12L42 17L40 37L30 49L18 35ZM28 19L34 24L29 37M44 29L54 24M45 37L55 40M17 19L9 15"/>',
  '<path d="M10 46V24L20 17L29 25V46M29 46V19L39 12L49 20V46M15 50H53M34 29L39 24L44 29M16 31L20 27L24 31"/>',
  '<path d="M28 15L46 20L43 38L33 47L24 33ZM22 22L10 33L22 44M10 33H30"/>',
  '<path d="M12 45L18 17L26 44M25 46L34 10L42 46M40 45L49 22L54 45M12 49H54M18 17L22 31M34 10L38 28"/>' ]),
 'mua': ('84ded6',['물감 웅덩이','흐름 바꾸기','물결 덧칠','만조의 화폭'],[
  '<path d="M39 10L46 16L30 34L23 27ZM23 27Q13 33 20 38Q30 40 30 34M11 45Q23 34 40 42Q54 47 41 52Q23 57 11 45"/>',
  '<path d="M12 24Q20 11 31 22M31 22L26 12M31 22H21M52 40Q43 53 33 42M33 42L38 52M33 42H43"/><ellipse cx="17" cy="42" rx="9" ry="6"/><ellipse cx="46" cy="21" rx="9" ry="6"/>',
  '<path d="M11 37Q19 25 28 37Q37 49 46 37M15 45Q23 33 32 45Q41 57 50 45M33 10L48 18L41 30L26 22ZM29 25L24 34M35 28L30 37"/>',
  '<path d="M12 15H52V49H12ZM15 37Q24 13 35 32Q41 43 50 25M17 43Q27 31 38 43Q44 48 50 39M19 54L23 49M45 54L41 49"/>' ]),
 'sera': ('c2a1e8',['초승 베기','달그림자','월영 쇄도','그믐의 심판'],[
  '<path d="M15 14Q17 39 48 43Q17 57 10 31ZM24 49L30 43M42 12L20 36M43 12L40 23"/>',
  '<path d="M35 10Q19 22 35 36Q12 36 15 19Q20 8 35 10M43 28Q31 41 47 52Q26 52 28 37Q33 27 43 28"/>',
  '<path d="M16 15Q36 15 43 36L51 22Q51 47 27 51Q42 39 16 15M8 31H22M10 39H19M28 10L36 15"/>',
  '<path d="M30 9Q17 23 30 35Q7 32 13 17Q19 8 30 9M19 54L48 18L44 38L38 34M50 54L21 25L27 42L32 38"/>' ]),
 'lume': ('f4a16f',['잿불 병','화약 고리','불씨 망토','유성 가마'],[
  '<path d="M25 11H39M28 12V25L17 41Q15 52 32 52Q49 52 47 41L36 25V12M23 37Q31 43 41 35M31 44L34 38M45 15L51 10M47 23H55"/>',
  '<ellipse cx="32" cy="39" rx="22" ry="11"/><path d="M16 36L12 25L20 29M30 29L32 18L36 29M46 35L52 24L52 37M24 48L20 55M42 48L46 55"/>',
  '<path d="M24 13Q32 8 40 13L52 49Q32 57 12 49ZM24 13L32 23L40 13M21 44Q17 35 27 31Q24 42 32 44Q41 37 36 29Q50 39 40 47"/>',
  '<path d="M13 35H51L46 50H20ZM20 50L17 55M44 50L47 55M35 10L22 29L37 22L51 9M23 17L13 28M50 24L43 31"/>' ])}

def build():
    for hero,(color,names,symbols) in HEROES.items():
        for slot,name,symbol in zip('qwer',names,symbols):
            svg = f'<svg xmlns="http://www.w3.org/2000/svg" width="144" height="144" viewBox="0 0 64 64"><title>{escape(name)}</title><rect x="2" y="2" width="60" height="60" rx="12" fill="#122d35" stroke="#{color}" stroke-width="2"/><g fill="none" stroke="#{color}" stroke-width="2.8" stroke-linecap="round" stroke-linejoin="round">{symbol}</g></svg>\n'
            (ROOT/f'{hero}_{slot}.svg').write_text(svg)
if __name__ == '__main__':
    build()
