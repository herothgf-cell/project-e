#!/usr/bin/env python3
"""Build five detailed V8 heroes using original geometry and unchanged V5 paint.
The existing face and garment atlas bytes are reused directly from shipped GLBs.
Only mesh geometry, material bindings and UVs are authored here.
"""
import math
import numpy as np
from build_hero_models import Part, rgb, tint, head_art, body_art, badge, save_glb, OUT, TAU

# Body cut, hair base, original face atlas and original garment atlas.
TEMPLATES = {
    'orin': ('nema', 'bas', 'bas', 'nema'),
    'tere': ('bas', 'bas', 'bas', 'rio'),
    'mua': ('nema', 'rio', 'nema', 'nema'),
    'sera': ('rio', 'rio', 'rio', 'rio'),
    'lume': ('nema', 'bas', 'nema', 'bas'),
}
# Cloth, lining, hair, hair shadow, ivory, metal, magic, iris.
PALETTES = {
    'orin': ('A58B4A','304D52','E5D29F','9D783E','F3E7C6','B9904E','B4E3D4','B58A4B'),
    'tere': ('6396B5','304D71','D9E7E9','708EAB','E2EFF4','C5D7D9','8CCCE5','6A9BAD'),
    'mua': ('458B83','254B50','71C6BC','316A73','EFE5CA','C9A064','84DED6','57A398'),
    'sera': ('55467B','292A47','A7A3DB','565681','EEE4F5','BAA2CF','C2A1E8','9E70B9'),
    'lume': ('A65239','593847','DE9C63','92553E','EAD8B2','C4964E','F4A16F','A97C4D'),
}

def scaffold(body_key):
    parts = {}
    def add(name, origin=(0,0,0), parent=None, alias=None):
        parts[alias or name] = Part(name, origin, parent)
    add('Head',(0,2.184,0))
    add('FantasyFace',parent='Head')
    add('HairDetail',parent='Head')
    add('Torso',(0,1.548,0))
    add('Trappings',parent='Torso')
    add('SwingPanel',(0,-.123,0),parent='Torso')
    add('RuneEmblem',parent='Torso')
    add('TeamMark',parent='Torso')
    width = {'bas':.456,'rio':.352,'nema':.388}[body_key]
    for side,label in [(-1,'Left'),(1,'Right')]:
        add(label+'Arm',(side*width,1.754,.010))
        add('LeftWeapon' if side<0 else 'WeaponDetail',(side*.034,-.312,0),label+'Arm',label+'Weapon')
        add(label+'Leg',(side*(.201 if body_key=='bas' else .167),.987,0))
        add('Shin' if side<0 else 'RightShin',(0,-.507,0),label+'Leg',label+'Shin')
    add('Cloth',(0,1.830,.206))
    return parts

def replace_part(parts, name):
    old = parts[name]
    parts[name] = Part(old.name, old.origin, old.parent)
    return parts[name]

def retain_front(mesh):
    # The ranger template's pack is replaced by each new class's own equipment.
    mesh.triangles = [triangle for triangle in mesh.triangles
                      if all(mesh.positions[index][2] < .27 for index in triangle)]

def glove(mesh, side, colors):
    cloth,dark,hair,shadow,ivory,gold,glow,iris = colors
    mesh.loft([(0,-.13,0,.115,.10),(0,.08,0,.135,.12),(0,.14,0,.10,.105)],dark,16)
    mesh.band((0,.08,0),(.145,.033,.13),gold)
    mesh.band((0,.03,0),(.133,.018,.12),ivory)
    # Four bent fingers and the thumb visibly hold the tool.
    for index in range(4):
        x = -.084 + index*.055
        mesh.sweep([(x,-.13,-.03),(x,-.20,-.06),(x,-.22,-.12)],
                   [.025,.026,.018],[.029,.027,.021],ivory,8)
    mesh.oval((side*.13,-.12,-.055),(.055,.075,.050),ivory,12,6)
    badge(mesh,(0,-.02,-.125),(0,0,-1),.065,gold,glow)

def cape(mesh, width, length, cloth, lining, metal):
    rows = []
    colors = []
    for row in range(7):
        v = row / 6
        vertices, shades = [], []
        for column in range(13):
            u = column / 12 * 2 - 1
            vertices.append((u*width*(.62+.38*v), -length*v + .065*u*u,
                             .08+.28*v+.045*math.cos(u*math.pi*3)*v))
            shades.append(tint(cloth,lining,.18+.18*math.cos(u*math.pi*3)))
        rows.append(vertices)
        colors.append(shades)
    mesh.surface(rows,colors,False)
    mesh.line(rows[-1],.018,metal,(0,0,1))
    for index in [0,-1]:
        mesh.line([row[index] for row in rows],.014,metal,(0,0,1))

def clothing(key, parts, colors):
    cloth,dark,hair,shadow,ivory,gold,glow,iris = colors
    trim = parts['Trappings']
    if key != 'tere':
        retain_front(trim)
    # Shoulder edge, waist buckle and visible stitched hems unify the art family.
    for side in [-1,1]:
        trim.line([(side*.09,.29,-.14),(side*.20,.15,-.23),(side*.27,-.08,-.23)],.016,gold)
        for row in range(3):
            trim.oval((side*.15,.09-row*.095,-.25),(.017,.019,.016),gold,8,5)
    badge(trim,(0,-.15,-.255),(0,0,-1),.080,gold,glow)
    if key == 'orin':
        # Open sand mantle, teal scarf, leather cross-belt and a feathered clasp.
        trim.loft([(0,.19,.02,.27,.20),(0,.31,.02,.32,.22),(0,.38,.02,.19,.17)],dark,24)
        trim.sweep([(-.23,.27,-.15),(-.13,.17,-.26),(.05,.12,-.29),(.22,.15,-.24)],
                   [.07,.09,.08,.025],[.03,.04,.035,.015],cloth)
        trim.sweep([(.24,.20,-.15),(.12,.02,-.27),(-.20,-.26,-.21)],
                   [.042,.044,.042],[.022,.025,.024],rgb('78593B'))
        for side in [-1,1]:
            trim.oval((side*.31,-.26,-.06),(.10,.14,.095),rgb('8A623A'))
            trim.band((side*.31,-.22,-.06),(.105,.02,.10),gold)
        cape(replace_part(parts,'Cloth'),.52,.84,cloth,dark,gold)
    elif key == 'tere':
        # Layered ice cuirass, raised collar and articulated silver shoulder leaves.
        trim.loft([(0,-.08,-.02,.30,.25),(0,.11,-.02,.40,.27),(0,.23,0,.38,.25)],ivory,24)
        trim.loft([(0,.22,0,.24,.19),(0,.37,0,.29,.22),(0,.43,0,.25,.20)],dark,20)
        for side in [-1,1]:
            for index in range(3):
                trim.gem((side*(.11+index*.075),.14-index*.09,-.28),(.035,.10,.027),glow)
            shoulder=parts['LeftArm' if side<0 else 'RightArm']
            shoulder.loft([(0,-.06,0,.25,.24),(side*.04,.06,.01,.29,.24),(side*.05,.18,.02,.18,.15)],ivory,16)
            shoulder.band((0,-.04,0),(.26,.025,.25),gold)
            shoulder.gem((side*.10,.14,-.12),(.085,.19,.075),glow)
        badge(trim,(0,.04,-.30),(0,0,-1),.11,gold,glow)
        cape(replace_part(parts,'Cloth'),.76,1.05,cloth,dark,gold)
    elif key == 'mua':
        # Cream painter's apron with metal wave embroidery and asymmetric sash.
        trim.sweep([(0,-.16,-.24),(0,-.39,-.29),(0,-.65,-.29)],
                   [.21,.24,.22],[.018,.02,.018],ivory,10)
        for offset in [-.05,.05]:
            points=[(x,-.40+offset+.035*math.sin(x*16),-.318) for x in np.linspace(-.18,.18,12)]
            trim.line(points,.012,cloth,(0,0,1))
        trim.sweep([(-.27,.23,-.15),(-.13,.06,-.27),(.19,-.17,-.24)],
                   [.065,.065,.06],[.025,.025,.022],cloth)
        for index,color in enumerate([glow,rgb('EFB27F'),rgb('BCA1D8')]):
            trim.oval((-.14+index*.13,-.56,-.32),(.035,.05,.015),color,10,5)
        cape(replace_part(parts,'Cloth'),.43,.65,dark,cloth,gold)
    elif key == 'sera':
        # Fitted crescent corset and a short, asymmetrically split violet cloak.
        trim.loft([(0,-.20,0,.31,.225),(0,.08,0,.30,.22)],dark,20)
        for side in [-1,1]:
            trim.line([(side*.21,.07,-.18),(side*.11,-.05,-.24),(side*.20,-.18,-.21)],.018,gold)
        for row in range(3):
            trim.line([(-.075,.04-row*.07,-.24),(.075,-.02-row*.07,-.24)],.012,ivory)
        cloak=replace_part(parts,'Cloth')
        cape(cloak,.56,.60,cloth,dark,gold)
        cloak.sweep([(-.26,-.30,.25),(-.39,-.65,.37),(-.52,-.85,.42)],
                    [.12,.11,.005],[.03,.025,.002],cloth)
        badge(trim,(.22,.19,-.18),(.4,0,-1),.085,gold,glow)
    elif key == 'lume':
        # Apron, brass toggle closures, side flasks and padded alchemy collar.
        trim.loft([(0,.23,0,.24,.19),(0,.31,0,.32,.23),(0,.38,0,.26,.20)],ivory,22)
        trim.sweep([(0,-.15,-.25),(0,-.38,-.28),(0,-.62,-.27)],
                   [.17,.21,.20],[.024,.028,.02],rgb('795244'),10)
        for row in range(3):
            trim.line([(-.12,.13-row*.09,-.25),(.12,.13-row*.09,-.25)],.018,gold)
        for side in [-1,1]:
            trim.oval((side*.32,-.23,-.06),(.10,.16,.10),glow)
            trim.band((side*.32,-.08,-.06),(.075,.025,.075),gold)
            trim.line([(side*.26,.14,-.16),(side*.33,-.28,-.08)],.025,dark)
        cape(replace_part(parts,'Cloth'),.62,.78,cloth,dark,gold)

def headwear(key, hair, colors):
    cloth,dark,tone,shadow,ivory,gold,glow,iris = colors
    if key == 'orin':
        # Open oval hood allows the textured face and carved fringe to remain visible.
        rows=[]
        for rx,ry,z in [(.51,.49,-.14),(.55,.53,-.08),(.58,.56,.10),(.46,.44,.39),(.03,.03,.65)]:
            rows.append([(rx*math.cos(a),.025+ry*math.sin(a),z-.10*max(0,math.sin(a))) for a in np.arange(36)*TAU/36])
        hair.surface(rows,np.array([dark,cloth,cloth,cloth,ivory])[:,None,:])
        hair.line(rows[1]+[rows[1][0]],.018,gold,(0,0,1))
        for index in range(3):
            hair.sweep([(.32,.35,-.08),(.48+index*.04,.58+index*.06,.03),(.61+index*.045,.81-index*.015,.12)],
                       [.028,.095,.002],[.017,.034,.002],ivory if index%2==0 else glow,8,(0,0,1))
        badge(hair,(.37,.29,-.23),(.45,.15,-1),.10,gold,glow)
    elif key == 'tere':
        # A broad swept silver crest, side locks and a low crystal circlet.
        for side in [-1,1]:
            for index in range(3):
                hair.sweep([(side*.16,.37,.04),(side*(.28+index*.04),.46,.08+index*.06),(side*.53,.27-index*.06,.21+index*.09)],
                           [.065,.115,.003],[.04,.06,.002],tint(tone,shadow,index*.12),8,(0,1,0))
        hair.line([(-.44,.19,-.19),(-.27,.25,-.34),(0,.29,-.42),(.27,.25,-.34),(.44,.19,-.19)],.035,gold)
        hair.gem((0,.31,-.44),(.08,.14,.035),glow)
        for side in [-1,1]:
            hair.gem((side*.39,.20,-.24),(.06,.10,.035),glow)
    elif key == 'mua':
        # Soft tilted beret and paintbrush pin over sea-green bobbed hair.
        hair.loft([(-.06,.32,.04,.49,.40),(-.12,.42,.07,.58,.44),(-.12,.54,.08,.43,.34),(-.09,.58,.08,.04,.04)],dark,32)
        hair.band((0,.32,.04),(.49,.025,.40),gold)
        hair.oval((-.12,.59,.08),(.05,.045,.045),cloth)
        hair.line([(.27,.38,-.32),(.43,.59,-.25)],.025,gold)
        hair.sweep([(.42,.58,-.25),(.48,.68,-.22)],[.055,.005],[.03,.002],ivory)
        for side in [-1,1]:
            hair.sweep([(side*.39,.10,.11),(side*.47,-.15,.12),(side*.34,-.35,.10)],
                       [.12,.14,.04],[.10,.11,.035],tone,10,(0,0,1))
    elif key == 'sera':
        # A high flowing ponytail and moon brooch distinguish the duelist's outline.
        for index in range(4):
            hair.sweep([(.10,.35,.33),(.32,.36,.50),(.56,-.05,.52),(.53+index*.04,-.53,.43),(.34+index*.05,-.78,.42)],
                       [.07,.12,.12,.08,.003],[.05,.075,.08,.06,.002],tint(tone,shadow,index*.15),8,(0,1,0))
        hair.band((.23,.34,.41),(.14,.038,.12),gold)
        badge(hair,(-.34,.23,-.28),(-.5,.1,-1),.10,gold,glow)
        hair.line([(-.43,.19,-.20),(-.51,.04,-.13),(-.48,-.15,-.10)],.015,gold)
    elif key == 'lume':
        # Wide curled felt brim with a rounded crown, brass goggles and a cork plume.
        rows=[]
        for radius,height in [(.43,.32),(.68,.31),(.71,.35),(.65,.40),(.41,.42)]:
            rows.append([(radius*math.cos(a),height+.055*math.cos(a*2),.04+radius*.82*math.sin(a)) for a in np.arange(36)*TAU/36])
        hair.surface(rows,np.array([dark,dark,gold,cloth,cloth])[:,None,:])
        hair.line(rows[2]+[rows[2][0]],.016,gold,(0,1,0))
        hair.loft([(0,.40,.04,.43,.35),(-.04,.63,.07,.39,.31),(-.07,.76,.08,.25,.22),(-.08,.80,.08,.02,.02)],cloth,28)
        hair.band((-.01,.46,.05),(.435,.048,.35),dark)
        for side in [-1,1]:
            badge(hair,(side*.16,.48,-.31),(side*.2,.1,-1),.115,gold,glow)
        hair.line([(-.05,.48,-.34),(.05,.48,-.34)],.018,gold)
        hair.sweep([(.31,.55,.08),(.46,.81,.12),(.42,.96,.18)],[.04,.065,.003],[.03,.04,.002],ivory)

def weapons(key, parts, colors):
    cloth,dark,hair,shadow,ivory,gold,glow,iris = colors
    left,right = replace_part(parts,'LeftWeapon'),replace_part(parts,'RightWeapon')
    for side,hand in [(-1,left),(1,right)]:
        glove(hand,side,colors)
    if key == 'orin':
        for side in [-1,1]:
            start=np.array((side*.09,-.12,-.05))
            end=np.array((side*.26,-.02,-.72))
            right.sweep([start,start*.5+end*.5,end],[.09,.10,.17],[.09,.10,.17],gold,18)
            right.sweep([end+[0,0,-.005],end+[0,0,-.04]],[.125,.125],[.125,.125],dark,18)
            for index in range(3):
                point=start*(.7-index*.22)+end*(.3+index*.22)
                right.sweep([point,point+[0,0,-.035]],[.12,.12],[.12,.12],ivory,16)
            badge(right,(side*.26,.02,-.76),(0,0,-1),.075,gold,glow)
        left.oval((0,-.15,-.06),(.15,.20,.15),dark)
        badge(left,(0,-.12,-.205),(0,0,-1),.115,gold,glow)
    elif key == 'tere':
        for index in [-1,0,1]:
            x=index*.23
            left.gem((x,-.10,-.24),(.19,.63-abs(index)*.08,.09),ivory)
            left.gem((x,-.10,-.34),(.14,.55-abs(index)*.08,.045),glow)
            left.line([(x,-.61+abs(index)*.08,-.37),(x,.42-abs(index)*.08,-.37)],.022,gold)
            left.oval((x,.04,-.39),(.035,.035,.014),ivory,10,5)
        badge(left,(0,-.10,-.405),(0,0,-1),.14,gold,glow)
        right.sweep([(0,-.17,0),(0,-.16,-.49)],[.055,.055],[.055,.055],dark,12)
        right.gem((0,-.16,-.62),(.18,.20,.30),glow)
        right.band((0,-.13,-.41),(.10,.045,.10),gold)
    elif key == 'mua':
        right.sweep([(-.43,-.17,-.05),(.61,-.17,-.05)],[.045,.045],[.045,.045],gold,14)
        right.sweep([(.49,-.17,-.05),(.63,-.17,-.05)],[.10,.10],[.10,.10],dark,14)
        right.sweep([(.61,-.17,-.05),(.80,-.17,-.05),(.94,-.17,-.05)],[.11,.10,.003],[.11,.10,.003],ivory,18)
        right.sweep([(.81,-.17,-.05),(.94,-.17,-.05)],[.065,.003],[.065,.003],glow,14)
        left.loft([(0,-.41,0,.17,.16),(0,-.33,0,.25,.23),(0,-.08,0,.26,.24),(0,.04,0,.22,.20)],dark,22)
        left.band((0,.035,0),(.24,.025,.22),gold)
        left.band((0,-.30,0),(.25,.024,.23),gold)
        badge(left,(0,-.15,-.245),(0,0,-1),.12,gold,glow)
        for index in range(3):
            left.line([((index-1)*.11,-.02,.02),((index-1)*.15,.31,.04)],.023,gold)
            left.oval(((index-1)*.15,.32,.04),(.045,.07,.04),[glow,ivory,cloth][index],10,5)
    elif key == 'sera':
        for side,hand in [(-1,left),(1,right)]:
            angles=np.linspace(-1.75,1.75,16)
            points=[(side*(.14+.34*math.cos(angle)),-.14+.48*math.sin(angle),-.12) for angle in angles]
            widths=[.003+.075*math.sin(math.pi*index/15) for index in range(16)]
            hand.sweep(points,widths,[.025]*16,ivory,8,(0,1,0))
            hand.line([(x,y,z-.026) for x,y,z in points],.012,gold,(0,0,1))
            hand.line([(-side*.09,-.14,0),(side*.24,-.14,-.12)],.045,dark)
            badge(hand,(side*.22,-.14,-.15),(0,0,-1),.08,gold,glow)
    elif key == 'lume':
        left.oval((0,-.15,-.09),(.27,.33,.26),glow,24,14)
        left.loft([(0,.04,-.09,.17,.16),(0,.25,-.09,.08,.08),(0,.32,-.09,.08,.08)],ivory,18)
        left.band((0,.30,-.09),(.10,.042,.10),gold)
        left.band((0,-.25,-.09),(.27,.032,.26),gold)
        left.band((0,-.06,-.09),(.28,.026,.27),dark)
        badge(left,(0,-.14,-.355),(0,0,-1),.13,gold,ivory)
        for side in [-1,1]:
            left.line([(side*.13,.05,-.24),(side*.19,-.31,-.25)],.021,gold)
        right.oval((0,-.13,-.07),(.14,.18,.14),glow,18,10)
        right.band((0,.03,-.07),(.085,.03,.085),gold)
        right.line([(0,.06,-.07),(.04,.16,-.05),(.09,.18,-.03)],.02,ivory)

def build(key):
    body_key,hair_key,face_key,tunic_key = TEMPLATES[key]
    colors=list(map(rgb,PALETTES[key]))
    parts=scaffold(body_key)
    head_art(hair_key,parts,colors,accessories=False)
    body_art(body_key,parts,colors)
    clothing(key,parts,colors)
    headwear(key,parts['HairDetail'],colors)
    weapons(key,parts,colors)
    return parts

if __name__ == '__main__':
    for hero,(_,_,face,tunic) in TEMPLATES.items():
        save_glb(hero,build(hero),texture_sources={'face':face,'tunic':tunic})
        print(hero,(OUT/f'{hero}.glb').stat().st_size)
