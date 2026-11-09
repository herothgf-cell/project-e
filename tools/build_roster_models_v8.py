#!/usr/bin/env python3
"""Author five articulated vertex-painted fantasy heroes without raster dependencies.
Reuses the original mesh writer and pivot contract. Run from any directory.
"""
import math
from build_hero_models import Part, rgb, save_glb, OUT

COLORS = {'orin': 'E4CD88', 'tere': '8CCCE5', 'mua': '84DED6', 'sera': 'C2A1E8', 'lume': 'F4A16F'}

def build(key):
    accent, ivory, dark, skin, gold = map(rgb, [COLORS[key], 'F0E7CD', '293C48', 'EAB48F', 'BD8C4F'])
    wide = {'orin': .34, 'tere': .48, 'mua': .39, 'sera': .31, 'lume': .43}[key]
    tall = .14 if key == 'tere' else 0
    parts = {}
    def add(name, origin=(0, 0, 0), parent=None):
        parts[name] = Part(name, origin, parent)
        return parts[name]
    head = add('Head', (0, 2.12 + tall, 0))
    head.oval((0, 0, 0), (.37, .40, .32), skin, 20, 12)
    hair = add('HairDetail', parent='Head')
    hair.loft([(0,.07,.03,.38,.32),(0,.36,.04,.32,.28),(0,.44,.04,.06,.08)], dark, 18)
    # Eyes, highlights, eyebrows and a small smile are authored solid geometry.
    for side in [-1, 1]:
        head.oval((side*.135,.015,-.302),(.075,.09,.025), ivory, 10, 6)
        head.oval((side*.13,.005,-.327),(.037,.060,.016), dark, 10, 6)
        head.oval((side*.12,.030,-.341),(.012,.016,.009), ivory, 8, 4)
        hair.line([(side*.07,.15,-.30),(side*.19,.16,-.28)], .025, dark)
    head.line([(-.07,-.17,-.30),(0,-.19,-.323),(.06,-.17,-.30)], .012, dark)
    torso = add('Torso', (0, 1.48 + tall, 0))
    torso.loft([(0,-.42,0,wide*.85,.22),(0,-.22,0,wide,.25),(0,.15,0,wide,.25),(0,.31,0,.20,.17)], accent, 18)
    torso.band((0,-.25,0),(wide,.045,.26),gold)
    mark = add('TeamMark', parent='Torso')
    mark.gem((0,.06,-.27),(.07,.09,.025),ivory)
    panel = add('SwingPanel', (0,-.25,0), 'Torso')
    panel.loft([(0,-.35,.02,wide*.8,.27),(0,0,0,wide*.65,.24)], dark, 14)
    cloth = add('Cloth', (0,1.73+tall,.22))
    length = {'orin': .65, 'tere': .95, 'mua': .43, 'sera': .60, 'lume': .30}[key]
    cloth.sweep([(0,0,.04),(0,-length*.5,.19),(0,-length,.30)], [wide*.8,wide,wide*.75],[.045,.04,.025],accent*.58,8)
    weapons = {}
    for side, label in [(-1,'Left'),(1,'Right')]:
        arm = add(label+'Arm',(side*wide,1.70+tall,0))
        arm.oval((0,-.17,0),(.14,.24,.16),ivory)
        weapon = add('LeftWeapon' if side < 0 else 'WeaponDetail',(side*.03,-.33,-.03),label+'Arm')
        weapon.oval((0,-.08,0),(.12,.14,.12),skin)
        weapons[label] = weapon
        leg = add(label+'Leg',(side*.18,.96+tall,0))
        leg.loft([(0,-.48,0,.12,.13),(0,0,0,.15,.16)],dark,12)
        shin = add('Shin' if side<0 else 'RightShin',(0,-.48,0),label+'Leg')
        shin.oval((0,-.20,-.07),(.16,.25,.23),gold if key=='tere' else dark*.7)
        shin.band((0,-.05,0),(.15,.04,.16),accent)
    left, right = weapons['Left'], weapons['Right']
    if key == 'orin':
        # Hood, long plume and a splayed pair of brass air tubes.
        hair.loft([(0,-.12,.10,.40,.30),(0,.38,.06,.39,.32),(0,.62,.16,.02,.03)],accent*.75,14)
        hair.sweep([(.17,.42,0),(.32,.68,.12),(.47,.74,.19)],[.06,.10,.002],[.02,.03,.001],ivory)
        for side in [-1,1]:
            right.sweep([(side*.10,-.08,-.12),(side*.22,.02,-.45),(side*.34,.12,-.80)],[.10,.13,.17],[.10,.13,.17],gold,12)
            right.oval((side*.34,.12,-.81),(.11,.11,.025),dark)
        left.band((0,-.10,0),(.15,.08,.16),accent)
    elif key == 'tere':
        hair.gem((0,.46,0),(.20,.27,.20),ivory)
        # Three thin hinged crystal leaves make a tall folding shield.
        for i in [-1,0,1]:
            left.gem((i*.25,-.12,-.23),(.18,.69-abs(i)*.10,.09),accent)
            left.line([(i*.25,-.66,-.34),(i*.25,.40,-.34)],.024,ivory)
        right.sweep([(0,-.1,0),(0,-.1,-.55)],[.07,.055],[.07,.055],gold)
        right.gem((0,-.1,-.68),(.17,.19,.27),accent)
        torso.band((0,.14,0),(.51,.12,.29),ivory)
    elif key == 'mua':
        hair.band((0,.29,0),(.45,.08,.35),accent)
        hair.oval((-.10,.38,.04),(.40,.13,.32),dark)
        # Horizontal brush and round paint reservoir carried opposite it.
        right.sweep([(-.55,-.10,0),(.56,-.10,0)],[.055,.055],[.055,.055],gold)
        right.sweep([(.52,-.10,0),(.72,-.10,0),(.91,-.10,0)],[.13,.14,.025],[.13,.14,.025],ivory)
        right.oval((.86,-.10,0),(.08,.10,.10),accent)
        left.oval((0,-.18,0),(.28,.32,.28),dark)
        left.band((0,.06,0),(.28,.055,.28),gold)
        for i in range(3):
            left.line([((i-1)*.12,.02,0),((i-1)*.13,.39,.03)],.028,ivory)
    elif key == 'sera':
        hair.sweep([(-.23,.23,.20),(-.40,-.18,.26),(-.25,-.57,.32)],[.16,.12,.01],[.12,.10,.01],accent*.5)
        hair.gem((.22,.23,-.24),(.10,.16,.035),ivory)
        for side, weapon in [(-1,left),(1,right)]:
            points = [(side*(.20+.38*math.cos(a)),-.08+.45*math.sin(a),-.15) for a in [-1.5,-.9,-.3,.3,.9,1.5]]
            weapon.sweep(points,[.005,.055,.08,.08,.055,.005],[.015]*6,ivory,8,(0,1,0))
            weapon.band((0,-.08,0),(.14,.035,.14),gold)
    elif key == 'lume':
        hair.band((0,.28,0),(.56,.07,.46),dark)
        hair.oval((0,.40,.06),(.40,.28,.35),accent*.7)
        hair.band((0,.37,.03),(.40,.045,.35),gold)
        left.oval((0,-.05,-.05),(.32,.37,.30),accent)
        left.loft([(0,.15,-.05,.18,.17),(0,.44,-.05,.085,.085)],ivory,14)
        left.band((0,.45,-.05),(.11,.05,.11),gold)
        right.oval((0,-.04,-.07),(.16,.20,.16),accent)
        right.line([(0,.13,-.07),(.05,.24,-.06),(.10,.23,-.07)],.025,gold)
        for side in [-1,1]:
            torso.oval((side*.23,-.20,-.27),(.10,.14,.09),gold)
    return parts

if __name__ == '__main__':
    OUT.mkdir(parents=True, exist_ok=True)
    for hero in COLORS:
        save_glb(hero, build(hero), textured=False)
        print(hero, (OUT / f'{hero}.glb').stat().st_size)
