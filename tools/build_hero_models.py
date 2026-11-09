#!/usr/bin/env python3
"""Build the three original, vertex-painted articulated GLBs. Requires NumPy and Pillow."""
import io
import json
import math
import struct
from pathlib import Path

import numpy as np
from PIL import Image

OUT = Path(__file__).resolve().parents[1] / 'game/project-e/assets/heroes'
TAU = 2 * math.pi
SKIN = {'bas':'F99762','rio':'FDB396','nema':'FEB28B'}
PALETTES = {
    'bas': ('BD343F','661E35','F9D47F','A75D27','ECF1E4','BE8040','35C4C5','A05E2B'),
    'rio': ('574690','30274E','DBCBF2','806EA7','D4DEF2','A899CD','83DFF4','A273BF'),
    'nema': ('397455','203F42','91C77C','457859','E7E6B6','C09A5E','75E0AE','819947'),
}


def rgb(value):
    # Vertex color channels in glTF are linear, including when packed into bytes.
    linear = np.asarray([int(value[k:k+2],16)/255 for k in (0,2,4)])
    return np.where(linear <= .04045, linear/12.92, ((linear+.055)/1.055)**2.4)


def tint(value, other, amount):
    return (1-amount) * value + amount * other


class Part:
    """One draw surface per articulated piece. Mesh vertices are local to its pivot."""
    def __init__(self, name, origin=(0,0,0), parent=None):
        self.name, self.origin, self.parent = name, origin, parent
        self.positions, self.colors, self.triangles = [], [], []

    def surface(self, rows, colors, wrap=True, reverse=False):
        offset = len(self.positions)
        rings, width = len(rows), len(rows[0])
        self.positions.extend(np.reshape(rows,(-1,3)).tolist())
        self.colors.extend(np.broadcast_to(colors, (rings,width,3)).reshape(-1,3).tolist())
        for row in range(rings-1):
            for c in range(width if wrap else width-1):
                a,b = offset + row*width+c, offset+row*width+(c+1)%width
                quad = [(a,a+width,b+width),(a,b+width,b)]
                self.triangles.extend([t[::-1] for t in quad] if reverse else quad)

    def loft(self, levels, color, sides=20, highlight=.04, rotate=0):
        # Ordered from bottom to top, each section (center X,Y,Z,radius X,Z).
        rows, shades = [], []
        for i,(x,y,z,rx,rz) in enumerate(levels):
            row,shade=[],[]
            for k in range(sides):
                angle=k*TAU/sides + rotate
                row.append((x+rx*math.cos(angle), y, z+rz*math.sin(angle)))
                shade.append(color*(.92+.08*i/max(1,len(levels)-1))+highlight*color*max(0,math.cos(angle+2)))
            rows.append(row); shades.append(shade)
        self.surface(rows,shades)

    def oval(self, center, radii, color, sides=14, bands=8):
        x,y,z = center
        rx,ry,rz = radii
        levels=[]
        for j in range(bands+1):
            a=-math.pi/2 + math.pi*j/bands
            levels.append((x,y+ry*math.sin(a),z,rx*max(.0001,math.cos(a)),rz*max(.0001,math.cos(a))))
        self.loft(levels,color,sides)

    def sweep(self, points, widths, depths, color, sides=8, axis=(1,0,0), glint=.10):
        # Taper a volume along an authored 3D path, optionally making a folded ridge.
        points = np.asarray(points,float)
        rows,shades=[],[]
        for i,p in enumerate(points):
            tangent=points[min(len(points)-1,i+1)]-points[max(0,i-1)]
            tangent /= np.linalg.norm(tangent)
            u=np.array(axis,float)
            u-=np.dot(tangent,u)*tangent
            if np.linalg.norm(u)<.001:
                u=np.cross(tangent,(0,0,1) if abs(tangent[2])<.9 else (0,1,0))
            u/=np.linalg.norm(u)
            v=np.cross(u,tangent)
            row,shade=[],[]
            for j in range(sides):
                a=TAU*j/sides
                row.append(p + widths[i]*math.cos(a)*u + depths[i]*math.sin(a)*v)
                shade.append(color*(.82+.18*i/max(1,len(points)-1))+glint*color*max(0,math.cos(a+.25)))
            rows.append(row); shades.append(shade)
        self.surface(rows,shades)

    def line(self, pts, radius, color, axis=(1,0,0)):
        n=len(pts)
        rr=[radius]*n
        rr[0]*=.4; rr[-1]*=.4
        self.sweep(pts,rr,rr,color,6,axis,0)

    def band(self, center, radii, color):
        x,y,z = center; rx,ry,rz=radii
        self.loft([(x,y-ry,z,rx*.93,rz*.94),(x,y-ry*.65,z,rx,rz),
                   (x,y+ry*.64,z,rx,rz),(x,y+ry,z,rx*.93,rz*.94)],color)

    def gem(self, center, radii, color):
        x,y,z=center; w,h,d=radii
        self.loft([(x,y-h,z,.001,.001),(x,y-h*.18,z,w,d),(x,y+h*.38,z,w*.83,d*.83),
                   (x,y+h,z,.004,.004)],color,6,.3,TAU/12)


def badge(mesh, center, normal, radius, gold, glass, dial=False):
    # Bezel and painted glass built in the local tangent frame of the wrist/hat.
    origin=np.array(center)
    n=np.array(normal,float); n/=np.linalg.norm(n)
    right=np.cross((0,1,0),n); right/=np.linalg.norm(right)
    up=np.cross(n,right)
    def sample(x,y,d):
        return origin+radius*(right*x+up*y+n*d)
    def rings(profile,tone):
        rows=[[sample(rad*math.cos(a),rad*math.sin(a),d) for a in np.arange(28)*TAU/28] for rad,d in profile]
        mesh.surface(rows,tone)
    rings([(1,-.18),(1,.02),(.91,.14),(.82,.15),(.76,.045)],gold)
    levels=[(.79,.038),(.66,.072),(.49,.10),(.24,.136),(.005,.151)]
    glass_rows=[]; glass_shades=[]
    for rad,d in levels:
        glass_rows.append([sample(rad*math.cos(a),rad*math.sin(a),d) for a in np.arange(28)*TAU/28])
        glass_shades.append([glass*(.48+.49*(1-rad)+.35*max(0,math.sin(a))) for a in np.arange(28)*TAU/28])
    mesh.surface(glass_rows,glass_shades)
    mesh.line([sample(-.62,.16,.126),sample(-.56,.34,.137),sample(-.39,.49,.141),sample(-.24,.54,.136)],
              radius*.05,rgb('F2FFD9'),(0,0,1))
    for j in range(9 if dial else 3):
        a=.34+j*(TAU*.8/8 if dial else TAU/3)
        m=.55 if j%2==0 else .64
        mesh.line([sample(m*math.cos(a),m*math.sin(a),.132),sample(.735*math.cos(a),.735*math.sin(a),.13)],
                  radius*.023,gold)
    if dial:
        mesh.line([sample(-.19,-.19,.148),sample(.04,.011,.153),sample(.40,.50,.143)],radius*.045,rgb('692F28'))
        mesh.oval(sample(0,0,.151),(radius*.09,)*3,gold,8,5)
    else:
        mesh.line([sample(-.45,.24,.135),sample(-.35,.42,.14),sample(-.13,.48,.135)],radius*.040,rgb('F7F3CD'))


def face_z(x, y):
    return -.414 * math.sqrt(max(.025, 1-(x/.474)**2-((y-.008)/.51)**2))


def head_art(key, parts, color, accessories=True):
    cloth,dark,hair,shadow,ivory,gold,glow,iris=color
    skin=rgb(SKIN[key])
    ink=rgb('302944'); blush=rgb('E99084')
    head=parts['Head']; face=parts['FantasyFace']; locks=parts['HairDetail']
    head.loft([(0,-.455,-.012,.012,.012),(0,-.405,-.03,.19,.155),(0,-.33,-.014,.335,.284),
               (0,-.235,0,.425,.353),(0,-.09,0,.465,.404),(0,.09,.002,.476,.421),
               (0,.225,.026,.448,.39),(0,.35,.045,.355,.30),(0,.46,.055,.13,.14),(0,.475,.05,.008,.008)],skin,32)
    for s in (-1,1):
        head.oval((s*.448,-.015,0),(.095,.114,.072),skin)
        head.oval((s*.488,-.023,-.043),(.043,.066,.039),blush)
    # Small sculpted nose uses the same cylindrical face projection as the cheeks.
    face.oval((0,-.112,-.388),(.042,.039,.046),skin,12)
    # A sculpted cap reaches the nape while its curved hairline clears both eyes.
    rows=[]; cols=[]
    for j in range(8):
        row=[]; shades=[]
        for k in range(32):
            a=k*TAU/32; front=max(0,-math.sin(a))
            end=2.40-.99*front**2
            t=.008+(end-.008)*j/7
            under_hood=1-.14*(1-front) if key=='nema' else 1
            row.append((under_hood*.493*math.cos(a)*math.sin(t),.037+under_hood*.482*math.cos(t),
                        .044+under_hood*.449*math.sin(a)*math.sin(t)))
            shades.append(tint(hair,shadow,.23+.35*(j/7)-.10*math.cos(2*a)))
        rows.append(row); cols.append(shades)
    locks.surface(rows,cols,reverse=True)
    if key in ('bas','rio'):
        # Layered wind-swept locks run continuously around the nape and crown.
        for tier in (0,1):
            count=11 if tier==0 else 9
            for i in range(count):
                angle=-1.55+3.10*i/(count-1)+(.11 if tier else -.04)
                def point(a,r,y):
                    return np.array((math.sin(a)*r,y,.047+math.cos(a)*r))
                extra=.15 if key=='rio' else 0
                if tier==0:
                    pts=[point(angle-.23,.235,.432),point(angle-.09,.422,.280),point(angle+.05,.475,.044),
                         point(angle+.15,.457,-.127),point(angle+.24,.450,-.244-extra+.040*math.sin(i*2.2))]
                    width=[.045,.135,.148,.100,.004]; depth=[.019,.050,.067,.052,.003]
                else:
                    pts=[point(angle-.34,.109,.491),point(angle-.24,.269,.458),point(angle-.12,.402,.322),
                         point(angle+.14,.475,.163),point(angle+.23,.488,.099+.043*math.sin(i*2.4))]
                    width=[.031,.123,.142,.079,.003]; depth=[.014,.044,.054,.033,.003]
                tangent=(math.cos(angle),0,-math.sin(angle))
                c=tint(hair,shadow,.09+.13*((i+tier)%3))
                locks.sweep(pts,width,depth,c,8,tangent)
                if (i+tier)%2==0:
                    raised=np.array((math.sin(angle)*.040,.025,math.cos(angle)*.040))
                    locks.sweep([pts[1]+raised*.62,pts[2]+raised,pts[3]+raised*.55],
                                [.004,.017,.002],[.005,.013,.004],tint(c,rgb('F2DEC9'),.30),6,tangent)
    # Broad asymmetrical bangs sweep across the forehead like carved brushstrokes.
    patterns={
        'bas':[(-.41,-.44,.03),(-.30,-.40,.16),(-.20,-.34,.15),(-.045,-.27,.075),(.082,-.16,.16),(.20,.02,.185),(.32,.27,.19),(.38,.40,.11)],
        'rio':[(-.40,-.42,-.18),(-.30,-.32,.08),(-.18,-.22,.16),(-.06,-.13,.14),(.08,.015,.18),(.22,.14,.14),(.32,.26,.11),(.40,.42,-.17)],
        'nema':[(-.39,-.41,-.07),(-.28,-.34,.125),(-.14,-.25,.14),(-.04,-.13,.08),(.09,.014,.15),(.21,.15,.13),(.30,.27,.08),(.40,.415,-.08)]
    }
    for i,(x,tip,end) in enumerate(patterns[key]):
        p0=(x*.58+(.083 if key=='bas' else .018),.440,.025)
        p1=(x*.94,.401,-.17*math.sqrt(max(.1,1-(x/.49)**2)))
        p2=(x,.298,-.362*math.sqrt(max(.1,1-(x/.5)**2)))
        p3=(tip,end,face_z(tip,end)-.034)
        tone=tint(hair,shadow,[.16,0,.10,.24][i%4])
        locks.sweep([p0,p1,p2,p3],[.045,.122,.10,.002],[.021,.062,.06,.004],tone,8)
        if i in (1,3,5,7):
            # Slender brush-shaped highlights follow the direction of the cut.
            pp=[np.array(pt) for pt in (p0,p1,p2,p3)]
            ridge=[pp[0]*.35+pp[1]*.65+[.016,.049,-.027], pp[1]*.45+pp[2]*.55+[.012,.032,-.050],
                   pp[2]+[.005,.014,-.054], pp[2]*.46+pp[3]*.54+[.002,.008,-.031]]
            locks.sweep(ridge,[.003,.015,.012,.001],[.003,.006,.005,.001],tint(tone,rgb('FFF2D7'),.29),6)
    for s in (-1,1):
        for i in range(3):
            y=-.24-.08*i if key=='rio' else -.12-.045*i
            z=-.15+.15*i
            locks.sweep([(s*.32,.36,z+.07),(s*.43,.18,z),(s*.45,-.04,z-.02),
                         (s*(.41 if key=='rio' else .52),y,z+.01)],[.07,.10,.094,.003],[.06,.093,.075,.003],tint(hair,shadow,.14*i),8,(0,0,1))
    if not accessories:
        return
    if key=='bas':
        # Overlapping flame-like locks flare past the ear, sweeping up from the crown.
        for side in (-1,1):
            for j in range(7):
                a=-.42+j*.37
                root=(side*.20,.44,.10)
                high=(side*(.35+.055*math.cos(a)),.425-.052*j,.13+.145*math.sin(a))
                elbow=(side*(.46+.046*math.cos(a)),.313-.078*j,-.115+.067*j)
                tip=(side*(.552+(.064 if j in (1,4) else 0)),.395-.085*j,-.10+.075*j)
                locks.sweep([root,high,elbow,tip],[.055,.133,.094,.003],[.055,.072,.056,.003],
                            tint(hair,shadow,.09+(j%3)*.12),8,(0,1,0))
                if j%2==1:
                    locks.line([np.array(high)+[0,.03,-.031],np.array(elbow)+[0,.016,-.044],
                                np.array(tip)*.74+np.array(elbow)*.26+[0,.002,-.016]],.009,tint(hair,rgb('FFDB91'),.59),(0,1,0))
        # A swept tuft with two shorter companions gives the crown a clear profile.
        for x,d in [(-.14,.11),(0,.20),(.13,.10)]:
            locks.sweep([(x,.378,.10),(x-.046,.471,.064),(x-.14,.493+d,.017)],
                        [.09,.113,.002],[.090,.091,.002],hair)
    elif key=='rio':
        hat=locks
        # An irregular, upturned brim and folded cone carry the silhouette from above.
        rows=[]
        for rad,h in [(.43,.329),(.76,.315),(.82,.348),(.785,.377),(.59,.394),(.40,.412)]:
            row=[]
            for a in np.arange(42)*TAU/42:
                wave=(rad/.82)**3*(.125*math.cos(a-.18)+.060*math.cos(2*a+.26))
                row.append((rad*math.cos(a),h+wave,.055+rad*.85*math.sin(a)))
            rows.append(row)
        hat.surface(rows,np.array([dark,dark,gold,cloth,cloth,cloth])[:,None,:])
        hat.line(rows[2]+[rows[2][0]],.016,gold,(0,1,0))
        hat.loft([(-.02,.389,.055,.47,.385),(.005,.51,.082,.393,.342),(.065,.672,.089,.331,.263),
                  (.159,.811,.115,.251,.193),(.272,.853,.147,.173,.132),(.397,.799,.145,.101,.079),
                  (.520,.680,.134,.011,.014)],cloth,22)
        hat.band((.00,.493,.062),(.420,.068,.356),rgb('97643C'))
        hat.band((.01,.532,.065),(.406,.012,.352),gold)
        hat.line([(-.18,.502,-.259),(-.066,.603,-.238),(.075,.634,-.200),(.23,.694,-.121),
                  (.331,.742,.009),(.360,.768,.098)],.017,gold)
        badge(hat,(-.209,.53,-.266),(-.28,.11,-1),.138,gold,glow)
        for s in (-1,1):
            # Curled cheek strands and a narrow braided lock behind the brim.
            locks.sweep([(s*.273,.177,-.245),(s*.442,.094,-.213),(s*.472,-.113,-.125),(s*.435,-.250,-.11),
                         (s*.346,-.262,-.17)], [.09,.131,.117,.060,.006],[.065,.088,.06,.045,.005],hair,10)
            locks.oval((s*.345,-.299,.115),(.093,.122,.082),shadow)
            locks.band((s*.345,-.385,.125),(.084,.018,.075),gold)
            locks.sweep([(s*.346,-.38,.115),(s*.39,-.439,.14),(s*.47,-.48,.15)],
                        [.048,.061,.004],[.045,.043,.003],hair,8)
    else:
        # An open-faced cloth hood with an inset forest-green lining and gold piping.
        rows=[]
        for rx,ry,z,cy in [(.495,.451,-.217,.013),(.527,.482,-.208,.018),(.573,.539,-.126,.033),
                           (.597,.555,.095,.038),(.570,.514,.295,.035),(.433,.397,.449,.021),
                           (.238,.214,.569,-.003),(.015,.014,.661,-.079)]:
            row=[]
            for a in np.arange(36)*TAU/36:
                row.append((rx*math.cos(a),cy+ry*math.sin(a),z-.122*max(0,math.sin(a))+.049*max(0,-math.sin(a))))
            rows.append(row)
        hatcolor=rgb('EAD4AF')
        locks.surface(rows,np.array([dark,cloth,cloth,hatcolor,hatcolor,ivory,ivory,hatcolor])[:,None,:])
        locks.line(rows[1]+[rows[1][0]],.015,gold,(0,0,1))
        for sign in (-1,1):
            center=(sign*.202,.475,-.278)
            badge(locks,center,(sign*.27,.4,-1),.149,gold,rgb('81C8B3'))
            locks.line([(sign*.306,.458,-.216),(sign*.467,.347,-.130),(sign*.552,.239,-.016)],.035,rgb('6A5039'))
        locks.line([(-.08,.473,-.298),(0,.458,-.323),(.08,.473,-.298)],.024,gold)
        for i in range(3):
            leaf=[(.375,.273+i*.03,-.199),(.506+i*.018,.31+i*.039,-.128),(.615-i*.018,.351+i*.058,-.091)]
            locks.sweep(leaf,[.015,.062,.002],[.013,.032,.001],tint(hair,cloth,.16*i),6,(0,1,0))


def cape(part, key, cloth, gold):
    # Folded cloth with a scalloped hem, contrasting lining and a continuous braid.
    width,length={'bas':(.74,1.23),'rio':(.40,1.32),'nema':(.47,.81)}[key]
    for layer in range(2 if key=='rio' else 1):
        side=(-1,1)[layer]
        profiles=[(0,.64,.018),(.22,.90,.10),(.55,1.02,.20),(.88,1.13,.27),(1,1.14,.29)]
        rows=[]; shades=[]
        for t,w,back in profiles:
            row=[]; shade=[]
            for i in range(21):
                u=i/10-1
                x=u*width*w if key!='rio' else side*(.12+.49*t+.22*t*t)+u*width*.51
                edge=(.025 if key=='rio' else .10)*math.cos(u*math.pi*2)**2 + .065*u
                y=-length*t + edge*t**6
                z=back+(.15*t if key=='rio' else 0)+.035*math.cos(u*math.pi*3) + .035*(1-u*u)
                row.append((x,y,z))
                shade.append(cloth*(.73+.23*(.5+.5*math.cos(u*math.pi*3))+.08*(1-t)))
            rows.append(row); shades.append(shade)
        part.surface(rows,shades,False)
        part.line(rows[-1],.019,gold,(0,0,1))
        if key=='rio':
            for v in (.69,.82):
                x=side*(.12+.49*v+.22*v*v)
                y=-length*v+.030
                z=.062+.44*v
                pts=[(x-.109,y+.049,z),(x,y-.021,z+.019),(x+.109,y+.05,z)]
                part.line(pts,.011,gold,(0,0,1))
        if key=='bas':
            # Hammer-star field mark stitched on the draped back of the cape.
            logo=[(0,-.446,.204),(-.049,-.558,.225),(-.157,-.596,.239),(-.061,-.639,.243),
                  (0,-.779,.256),(.061,-.639,.243),(.157,-.596,.239),(.049,-.558,.225),(0,-.446,.204)]
            part.line([(x,y,z+.055) for x,y,z in logo],.016,gold,(0,0,1))
            for side_sign in (-1,1):
                part.line([(side_sign*.136,-.763,.297),(side_sign*.222,-.741,.294),(side_sign*.332,-.639,.264)],
                          .016,gold,(0,0,1))
        for edge in (0,20):
            part.line([row[edge] for row in rows],.014,gold,(0,0,1))


def disc(part,x,y,z,f,gold,ivory,glow):
    # Open, tapered crescent blades surround a floating azure crystal.
    for k in range(3):
        a=k*TAU/3
        pts=[];w=[];d=[]
        for j in range(11):
            t=j/10
            ang=a+t*1.91
            r=(.276+.038*t)*f
            pts.append((x+r*math.cos(ang),y+r*math.sin(ang),z-.025*t))
            w.append(f*(.008+.057*math.sin(math.pi*t)**.75))
            d.append(f*(.004+.038*math.sin(math.pi*t)))
        part.sweep(pts,w,d,ivory,8,(0,0,1))
        part.line(pts,.012*f,gold,(0,0,1))
        cx,cy=x+.271*f*math.cos(a),y+.271*f*math.sin(a)
        part.gem((cx,cy,z-.035),(.043*f,.064*f,.037*f),glow)
        part.line([(x+.084*f*math.cos(a-.3),y+.084*f*math.sin(a-.3),z),
                   (x+.21*f*math.cos(a+.23),y+.21*f*math.sin(a+.23),z),(cx,cy,z)],.017*f,gold,(0,0,1))
    part.gem((x,y,z),(.075*f,.117*f,.056*f),glow)


def equipment(key, p, s, color):
    cloth,dark,hair,shadow,ivory,gold,glow,iris=color
    skin=rgb(SKIN[key])
    if key=='bas':
        if s<0:
            p.loft([(0,-.423,-.055,.122,.12),(0,-.398,-.05,.160,.148),(0,-.187,0,.138,.119),(0,-.07,0,.12,.118)],dark,14)
            p.band((0,-.18,-.012),(.15,.040,.135),gold)
            for i in range(4):
                p.oval(((i-1.5)*.067,-.380,-.149),(.040,.089,.059),rgb('8F6049'),10,5)
            p.oval((-.114,-.359,-.112),(.068,.085,.075),rgb('AD7853'))
            return
        f=1.39
        levels=[(0,-.52,-.12,.12,.15),(0,-.48,-.13,.244,.215),(0,-.29,-.077,.261,.232),
                (0,-.19,-.037,.232,.20),(0,-.075,0,.179,.156)]
        p.loft([(x,y,z,rx*f,rz*f) for x,y,z,rx,rz in levels],dark,16)
        for y,r in [(-.124,.21),(-.297,.263),(-.457,.239)]:
            p.band((0,y,-.07 if y>-.20 else -.12),(r*f,.026,r*.89*f),gold)
        # Ridged ivory plates over an articulated dark inner glove.
        for i in (-1,0,1):
            x=i*.103*f
            p.sweep([(x,-.13,-.149),(x*1.22,-.23,-.236),(x*1.24,-.36,-.306),
                     (x,-.47,-.292)],[.028,.072,.079,.040],[.031,.066,.056,.032],ivory)
        for i in range(4):
            x=(i-1.5)*.095*f
            p.oval((x,-.486,-.228+.01*i),(.058*f,.092,.099),gold,10)
        p.oval((s*.199,-.421,-.144),(.103,.128,.102),ivory,12)
        # Three knuckle plates per finger overlap across the clenched fist.
        for j in range(3):
            for i in range(4):
                x=(i-1.5)*.133
                p.oval((x,-.40-j*.078,-.315-.038*math.sin(i)),(.077,.097,.104),ivory,10,6)
        badge(p,(s*.160,-.22,-.320),(s*.34,.26,-1),.216,gold,glow,True)
        p.oval((s*.216,-.427,-.25),(.119,.162,.091),gold,12)
        p.oval((s*.230,-.445,-.32),(.101,.115,.077),ivory,10)
        for side in (-1,1):
            p.sweep([(side*.12,-.29,-.292),(side*.154,-.239,-.260),(side*.162,-.145,-.186)],
                    [.013,.021,.007],[.012,.022,.009],gold,6)
        if s>0:
            for i in range(3):
                p.sweep([(s*.21*f,-.43+i*.084,-.039),(s*.268*f,-.388+i*.084,.004),
                         (s*.29*f,-.285+i*.078,.055)],[.036,.061,.004],[.043,.051,.003],ivory,8,(0,0,1))
    else:
        p.loft([(0,-.330,-.051,.069,.06),(0,-.284,-.032,.11,.109),(0,-.130,0,.132,.119),
                (0,-.071,.006,.112,.104)],(ivory if key=='nema' else cloth),14)
        p.band((0,-.228,-.024),(.133,.021,.12),gold)
        p.oval((0,-.375,-.051),(.102,.120,.086),skin)
        for i in range(4):
            p.oval(((i-1.5)*.039,-.418,-.086),(.026,.052,.034),skin,8,5)
        if key=='rio':
            disc(p,s*.115,-.355,-.18,1.10,gold,ivory,glow)
        elif s>0:
            p.sweep([(.044,-.656,-.090),(.039,-.358,-.095),(.099,-.122,-.127),(.142,.031,-.139)],
                    [.028,.045,.047,.017],[.031,.047,.05,.020],gold)
            for i,flip in enumerate((-1,1)):
                a=[(.08,-.168,-.135),(.106+flip*.108,-.063,-.140),(.115+flip*.16,.065+i*.044,-.155)]
                p.sweep(a,[.016,.072,.003],[.022,.034,.003],tint(hair,glow,.25*i),8)
            p.gem((.139,.052,-.150),(.055,.077,.044),glow)


def body_art(key,p,color):
    cloth,dark,hair,shadow,ivory,gold,glow,iris=color
    t=p['Trappings']; coat=p['Torso']; chest=p['RuneEmblem']
    t.oval((0,-.434,.004),(.336,.237,.203),dark,16)
    t.oval((0,.357,.003),(.151,.136,.144),rgb(SKIN[key]))
    shoulder={'bas':.421,'rio':.315,'nema':.341}[key]
    coat.loft([(0,-.52,.008,.06,.04),(0,-.444,.01,.370,.237),(0,-.262,.012,.320,.216),
            (0,-.091,0,.282,.201),(0,.098,.0,.332,.23),(0,.237,.02,shoulder,.245),
            (0,.312,.018,.24,.16),(0,.337,0,.138,.135)],(ivory if key=='nema' else cloth))
    t.loft([(0,-.395,.01,.302,.210),(0,-.419,.006,.37,.242),(0,-.363,.003,.367,.234)],gold)
    t.band((0,-.149,.002),(.314,.057,.226),dark)
    t.band((0,-.113,.002),(.317,.014,.230),gold)
    t.band((0,.297,.006),(.227,.043,.189),dark)
    chest.gem((0,.145,-.245),(.063,.078,.033),gold)
    p['TeamMark'].gem((0,.144,-.274),(.042,.054,.021),rgb('FFFFFF'))
    if key=='bas':
        # A fitted cuirass: fluted ivory breastplate, red tabard and brass fasteners.
        coat.loft([(0,-.125,-.015,.265,.214),(0,-.042,-.013,.325,.252),(0,.134,-.010,.389,.257),
                (0,.206,.002,.395,.240),(0,.260,.012,.300,.191)],ivory,20)
        for s in (-1,1):
            t.line([(s*.293,.193,-.178),(s*.253,.109,-.218),(s*.142,.005,-.258),(s*.082,-.036,-.268)],.016,gold)
            t.oval((s*.253,.158,-.203),(.029,.030,.025),gold,10)
        coat.sweep([(0,-.172,-.203),(0,-.299,-.243),(0,-.466,-.242),(-.032,-.615,-.229)],
                [.137,.154,.123,.017],[.031,.044,.034,.005],cloth,8)
        t.oval((0,-.153,-.217),(.090,.070,.032),gold)
    elif key=='rio':
        # Layered bell skirt with a split pale front and a gold picot hem.
        coat.loft([(0,-.669,.024,.448,.301),(0,-.609,.017,.455,.31),(0,-.374,.008,.389,.26),
                (0,-.202,0,.302,.205)],cloth,24)
        t.band((0,-.615,.023),(.453,.018,.312),gold)
        for s in (-1,1):
            a=[(s*.092,-.235,-.20),(s*.122,-.405,-.249),(s*.159,-.588,-.286),(s*.171,-.642,-.272)]
            coat.sweep(a,[.049,.066,.078,.047],[.018,.026,.026,.014],ivory)
            t.line([(x+s*.054,y,z-.016) for x,y,z in a],.011,gold)
    else:
        coat.loft([(0,-.564,.009,.418,.251),(0,-.530,.004,.412,.267),(0,-.206,0,.312,.222)],ivory,22)
        t.band((0,-.521,.018),(.412,.016,.269),cloth)
        t.sweep([(.23,.26,-.095),(.16,.131,-.237),(0,-.044,-.246),(-.245,-.24,-.136)],
                [.047,.050,.048,.045],[.031,.022,.024,.023],rgb('856346'))
        for s in (-1,1):
            t.oval((s*.304,-.238,-.040),(.128,.136,.123),rgb('986B43'),14)
            t.band((s*.304,-.233,-.038),(.128,.021,.123),gold)
            for i in range(3):
                x=s*(.080+.083*i)
                t.sweep([(x*.7,.276,-.11),(x,.182,-.214),(x*1.19,.072-.040*(i%2),-.248)],
                        [.049,.084,.004],[.024,.044,.005],tint(hair,cloth,.31+.12*i),8)
    if key=='nema':
        t.loft([(0,-.373,.281,.182,.115),(0,-.29,.301,.320,.155),(0,.155,.32,.330,.187),
                (0,.256,.319,.232,.133)],dark,16)
        t.band((0,.111,.311),(.343,.037,.188),gold)
        leather=rgb('895539')
        t.loft([(0,-.311,.379,.244,.143),(0,-.259,.402,.283,.150),(0,.081,.392,.304,.180),
                (0,.147,.385,.242,.142)],leather,16)
        # Box flap, twin keeper straps and a rolled field blanket across the top.
        t.sweep([(0,.123,.449),(0,.085,.591),(0,-.057,.589),(0,-.121,.562)],
                [.199,.229,.212,.116],[.036,.040,.035,.012],rgb('A97145'),8)
        for s in (-1,1):
            x=s*.139
            t.line([(x,.115,.520),(x,.080,.608),(x,-.213,.585)],.021,rgb('5D4233'))
            t.line([(x-.038,-.102,.598),(x+.038,-.102,.598),(x+.037,-.171,.596),
                    (x-.037,-.171,.596),(x-.038,-.102,.598)],.012,gold,(0,0,1))
        t.sweep([(-.331,.225,.372),(-.291,.228,.374),(.278,.228,.374),(.331,.225,.372)],
                [.071,.117,.117,.067],[.071,.119,.119,.067],rgb('C6B087'),16,(0,1,0))
        for x in (-.178,.178):
            t.sweep([(x-.018,.228,.374),(x+.018,.228,.374)],[.122,.122],[.124,.124],leather,14,(0,1,0))
        for s in (-1,1):
            x=s*.241
            t.sweep([(x,-.196,.397),(x+s*.101,.299,.38),(x+s*.295,.736,.346)],
                    [.055,.083,.035],[.071,.081,.035],gold)
            t.gem((x+s*.303,.788,.349),(.080,.133,.064),glow)
    elif key=='bas':
        # Folded red neckerchief crosses the articulated breastplate.
        t.loft([(0,.218,.009,.232,.176),(0,.265,.002,.289,.202),(0,.321,.003,.274,.196),
                (0,.349,.004,.211,.160)],rgb('B53537'),22)
        t.sweep([(-.199,.274,-.123),(-.071,.228,-.219),(.069,.190,-.241),(.125,.125,-.22)],
                [.077,.086,.061,.008],[.043,.051,.035,.006],rgb('CD4340'))
        t.oval((0,.029,.301),(.35,.153,.159),gold)
        for s in (-1,1):
            t.gem((s*.25,.157,.324),(.065,.085,.065),glow)
    for s,side in [(-1,'Left'),(1,'Right')]:
        upper=p[side+'Arm']; lower=p[side+'Weapon']; leg=p[side+'Leg']; boot=p[side+'Shin']
        shoulder_r=.220 if key=='bas' else .158
        upper.oval((0,-.165,0),(.134,.227,.14),dark)
        upper.loft([(0,-.095,0,shoulder_r*.91,shoulder_r*.88),(0,-.057,0,shoulder_r*1.10,shoulder_r*1.04),
                    (s*.014,.048,0,shoulder_r,shoulder_r*.92),(s*.02,.123,0,.103,.113),
                    (s*.02,.139,0,.026,.024)],ivory,16)
        upper.band((0,-.072,0),(shoulder_r*1.09,.018,shoulder_r*1.04),gold)
        # Fluting reflects the same sunburst/leaf/starlight motifs as the kit.
        for j in (-1,0,1):
            x=s*(.018+j*shoulder_r*.25)
            upper.sweep([(x,.084,-shoulder_r*.51),(x+s*.015,.047,-shoulder_r*.82),
                         (x+s*.024,-.012,-shoulder_r*.988),(x+s*.02,-.043,-shoulder_r*.99)],
                        [.005,.026,.022,.004],[.005,.012,.011,.003],gold,6)
        for x in (-.072,.072):
            upper.oval((x,-.050,-shoulder_r*.95),(.015,.015,.012),gold,8,4)
        equipment(key,lower,s,color)
        leg.loft([(0,-.557,.001,.106,.106),(0,-.482,-.004,.120,.128),(0,-.29,0,.155,.158),
                  (0,-.123,0,.161,.155),(0,.052,.004,.131,.139)],(rgb(SKIN[key]) if key in ('nema','rio') else rgb('624837')),18)
        if key!='bas':
            leg.loft([(0,-.281,.01,.159,.160),(0,-.239,.00,.168,.166),(0,-.073,.004,.165,.158),
                      (0,.066,.005,.134,.137)],rgb('55583A') if key=='nema' else rgb('E4D6CB'),18)
            leg.band((0,-.252,.005),(.163,.018,.167),gold if key=='nema' else ivory)
        if key=='rio':
            leg.loft([(0,-.553,0,.122,.122),(0,-.419,-.001,.143,.145),(0,-.367,-.001,.152,.142)],
                     dark,18)
            leg.band((0,-.381,.004),(.155,.025,.15),cloth)
            leg.band((0,-.401,.003),(.150,.011,.149),gold)
        if key=='nema':
            boot.band((0,.015,0),(.152,.076,.15),ivory)
        boot.oval((0,-.006,.002),(.146,.092,.14),dark,14,6)
        boot.loft([(0,-.411,-.048,.144,.159),(0,-.299,0,.139,.14),(0,-.201,.019,.137,.125),
                   (0,-.048,.003,.156,.147),(0,.007,0,.132,.122)],(rgb('674739') if key=='bas' else (dark if key=='rio' else rgb('536740'))),16)
        boot.band((0,-.073,.0),(.16,.032,.145),gold)
        boot.oval((0,-.376,-.092),(.17,.120,.237),dark)
        boot.loft([(0,-.460,-.102,.13,.18),(0,-.440,-.091,.174,.235),(0,-.399,-.091,.172,.233)],gold,16)
        boot.oval((0,-.355,-.201),(.150,.086,.147),(rgb('76513B') if key=='bas' else (dark if key=='rio' else rgb('58673F'))),14,6)
        boot.line([(-.107,-.335,-.234),(0,-.301,-.257),(.107,-.335,-.234)],.012,gold)
        boot.oval((s*.124,-.16,-.054),(.035,.067,.044),gold,10,5)
        boot.band((0,-.169,0),(.15,.026,.139),rgb('795A43'))
        boot.line([(-.020,-.145,-.154),(.050,-.139,-.153),(.049,-.192,-.153),(-.022,-.196,-.153),
                   (-.020,-.145,-.154)],.009,gold,(0,0,1))
    # Separate overlapping coat panels hang from the belt and follow through on a turn.
    panel=p['SwingPanel']
    for side in (-1,1):
        l={'bas':.56,'rio':.63,'nema':.48}[key]
        row_list=[]; cols=[]
        for v in (0,.24,.51,.82,1):
            row=[]; shade=[]
            for j in range(9):
                u=j/8
                x=side*(.025+.14*u+(.020+.138*u)*v)
                y= -l*v + (.07 if key!='rio' else .13)*(u-.42)**2*v**3
                z= -.247-.060*v - .018*math.sin(math.pi*u) + .018*u
                row.append((x,y,z)); shade.append(cloth)
            row_list.append(row);cols.append(shade)
        panel.surface(row_list,cols,False)
    cape(p['Cloth'],key,cloth,gold)


def make_parts(key):
    p={}
    def add(name,xyz=(0,0,0),parent=None,nick=None):
        part=Part(name,xyz,parent)
        p[nick or name]=part
    add('Head',(0,2.184,0));add('FantasyFace',parent='Head');add('HairDetail',parent='Head')
    add('Torso',(0,1.548,0));add('Trappings',parent='Torso');add('SwingPanel',(0,-.123,0),parent='Torso');add('RuneEmblem',parent='Torso');add('TeamMark',parent='Torso')
    wide={'bas':.456,'rio':.352,'nema':.388}[key]
    for s,side in [(-1,'Left'),(1,'Right')]:
        add(side+'Arm',(s*wide,1.754,.010))
        add('WeaponDetail' if s>0 else 'LeftWeapon',(s*.034,-.312,0),side+'Arm',side+'Weapon')
        add(side+'Leg',(s*(.201 if key=='bas' else .167),.987,0))
        add('Shin' if s<0 else 'RightShin',(0,-.507,0),side+'Leg',side+'Shin')
    add('Cloth',(0,1.830,.206))
    colors=list(map(rgb,PALETTES[key]))
    head_art(key,p,colors);body_art(key,p,colors)
    return p


def cylindrical_paint(key, section):
    # Wrap the front illustration around the cheeks/chest with a color-matched back.
    # The front half reproduces an orthographic projection; UVs at the nape meet.
    source=Image.open(OUT/f'{key}-{section}.webp').convert('RGB')
    w,h=1024,512
    yy,xx=np.mgrid[0:h,0:w]
    v=(yy+.5)/h
    angle=((xx+.5)/w-.5)*TAU
    if section=='face':
        radius=np.interp(v,[0,.09,.17,.28,.41,.60,.74,.86,.94,1],
                         [.03,.27,.37,.44,.475,.463,.420,.329,.17,.013])
        front=.5+radius*np.sin(angle)/.95
        back=np.mean(np.asarray(source)[16:48,8:46],axis=(0,1))
    else:
        radius=np.interp(v,[0,.11,.35,.52,.78,1],[.21,.38,.35,.30,.35,.40])
        front=.5+radius*np.sin(angle)/.77
        back=np.mean(np.asarray(source)[32:140,0:18],axis=(0,1))
    src=np.asarray(source)
    col=src[np.clip((v*source.height).astype(int),0,source.height-1),
            np.clip((front*source.width).astype(int),0,source.width-1)]
    blend=np.clip((1.60-np.abs(angle))/.41,0,1)[...,None]
    atlas=np.uint8(np.clip(col*blend+back*(1-blend),0,255))
    out=io.BytesIO()
    Image.fromarray(atlas).save(out,format='JPEG',quality=94,subsampling=0)
    return out.getvalue()


def unwrap_cylinder(pos,normals,faces,section):
    if section=='face':
        v=.5-pos[:,1]/.94
        angle=np.arctan2(pos[:,0],.02-pos[:,2])
    else:
        v=(.337-pos[:,1])/.99
        angle=np.arctan2(pos[:,0],.01-pos[:,2])
    uv=np.column_stack((.5-angle/TAU,np.clip(v,.002,.998)))
    # Split the narrow back seam so no triangle interpolates across the face.
    pos=list(pos); normals=list(normals); uv=list(uv); faces=faces.copy()
    split={}
    for i,triangle in enumerate(faces):
        us=[uv[j][0] for j in triangle]
        if max(us)-min(us)<.5: continue
        for k,j in enumerate(triangle):
            if uv[j][0]>.5: continue
            if j not in split:
                split[j]=len(pos)
                pos.append(pos[j]); normals.append(normals[j]); uv.append([uv[j][0]+1,uv[j][1]])
            faces[i,k]=split[j]
    return np.asarray(pos),np.asarray(normals),np.asarray(uv),faces


def existing_paint(key, section):
    """Reuse an original embedded atlas byte-for-byte, without raster processing."""
    content = (OUT / f'{key}.glb').read_bytes()
    json_length = struct.unpack_from('<I', content, 12)[0]
    document = json.loads(content[20:20 + json_length])
    binary_start = 20 + json_length + 8
    image = next(image for image in document['images'] if image['name'] == key + '_' + section)
    view = document['bufferViews'][image['bufferView']]
    start = binary_start + view.get('byteOffset', 0)
    return content[start:start + view['byteLength']]


def save_glb(key, parts, textured=True, texture_sources=None):
    nodes=[]; meshes=[]; accessors=[]; views=[]; data=bytearray()
    names=list(parts)
    imgs=[]; textures=[]; materials=[{'name':'Painted','doubleSided':True,
                            'pbrMetallicRoughness':{'metallicFactor':0,'roughnessFactor':.88}}]
    mat_for={}
    for section in (('face','tunic') if textured else ()):
        source_key = texture_sources.get(section, key) if texture_sources else key
        if texture_sources:
            chunk = existing_paint(source_key, section)
        else:
            if section=='tunic' and not (OUT/f'{key}-tunic.webp').exists(): continue
            chunk = cylindrical_paint(key, section)
        views.append(dict(buffer=0,byteOffset=len(data),byteLength=len(chunk)))
        data.extend(chunk)
        while len(data)%4: data.append(0)
        idx=len(imgs)
        imgs.append({'name':key+'_'+section,'mimeType':'image/jpeg','bufferView':len(views)-1})
        textures.append({'source':idx})
        mat_for[section]=len(materials)
        materials.append({'name':key+'_'+section,'doubleSided':True,'pbrMetallicRoughness':{
            'metallicFactor':0,'roughnessFactor':.90,'baseColorTexture':{'index':idx}}})
    def accessor(arr,typ,dim,component,normalized=False,bounds=False):
        while len(data)%4: data.append(0)
        flat=np.ascontiguousarray(arr,dtype=typ)
        raw=flat.tobytes()
        view=len(views)
        views.append(dict(buffer=0,byteOffset=len(data),byteLength=len(raw)))
        data.extend(raw)
        a=dict(bufferView=view,componentType=component,count=len(arr),type=dim)
        if normalized: a['normalized']=True
        if bounds: a.update(min=flat.min(axis=0).tolist(),max=flat.max(axis=0).tolist())
        accessors.append(a)
        return len(accessors)-1
    for part in parts.values():
        v=np.array(part.positions)
        f=np.asarray(part.triangles)
        # Remove coincident seams from the normal computation without joining color islands.
        normal=np.zeros_like(v)
        face=np.cross(v[f[:,1]]-v[f[:,0]],v[f[:,2]]-v[f[:,0]])
        for ix in range(3): np.add.at(normal,f[:,ix],face)
        normal/=np.maximum(np.linalg.norm(normal,axis=1,keepdims=True),1e-12)
        normal[np.linalg.norm(normal,axis=1)<.5]=(0,1,0)
        rgba=np.column_stack((np.clip(part.colors,0,1),np.ones(len(v))))
        section='face' if part.name in ('Head','FantasyFace') else ('tunic' if part.name in ('Torso','SwingPanel') else '')
        uv=None
        if section in mat_for:
            offset=np.asarray(part.origin) if part.name=='SwingPanel' else np.zeros(3)
            v,normal,uv,f=unwrap_cylinder(v+offset,normal,f,section)
            v-=offset
        attrib={'POSITION':accessor(v,'<f4','VEC3',5126,bounds=True),
                'NORMAL':accessor(normal,'<f4','VEC3',5126)}
        if uv is not None:
            attrib['TEXCOORD_0']=accessor(uv,'<f4','VEC2',5126)
        else:
            attrib['COLOR_0']=accessor(np.rint(rgba*255),'u1','VEC4',5121,True)
        index=accessor(f.flatten(),'<u2','SCALAR',5123)
        node={'name':part.name,'mesh':len(meshes),'translation':list(part.origin)}
        child=[i for i,k in enumerate(names) if parts[k].parent==part.name]
        if child: node['children']=child
        nodes.append(node)
        meshes.append({'name':part.name,'primitives':[{'attributes':attrib,'indices':index,'material':mat_for.get(section,0)}]})
    while len(data)%4:data.append(0)
    doc={'asset':{'version':'2.0','generator':'Project E original character studio'},'scene':0,
         'scenes':[{'name':key.title()+'Art','nodes':[i for i,k in enumerate(names) if parts[k].parent is None]}],
         'nodes':nodes,'meshes':meshes,'materials':materials,'images':imgs,'textures':textures,'buffers':[{'byteLength':len(data)}],
         'bufferViews':views,'accessors':accessors}
    js=json.dumps(doc,separators=(',',':')).encode()
    js+=b' '*(-len(js)%4)
    content=struct.pack('<I4s',len(js),b'JSON')+js+struct.pack('<I4s',len(data),b'BIN\0')+data
    (OUT/f'{key}.glb').write_bytes(struct.pack('<4sII',b'glTF',2,len(content)+12)+content)


if __name__=='__main__':
    OUT.mkdir(parents=True,exist_ok=True)
    for hero in PALETTES:
        save_glb(hero,make_parts(hero))
        print(hero,(OUT/f'{hero}.glb').stat().st_size)
