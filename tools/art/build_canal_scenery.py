"""Build the original vertex-painted M01 scenery meshes (Python 3, standard library)."""
from array import array
from math import cos, pi, sin, sqrt
from pathlib import Path
from random import Random
import json
import struct

OUT = Path(__file__).resolve().parents[2] / 'game/project-e/assets/environment'
TAU = 2 * pi


def rgb(value):
    return tuple(int(value[i:i + 2], 16) / 255 for i in (0, 2, 4))


def blend(a, b, t):
    return tuple(x * (1 - t) + y * t for x, y in zip(a, b))


def add(a, b):
    return tuple(x + y for x, y in zip(a, b))


def sub(a, b):
    return tuple(x - y for x, y in zip(a, b))


def cross(a, b):
    return (a[1]*b[2]-a[2]*b[1], a[2]*b[0]-a[0]*b[2], a[0]*b[1]-a[1]*b[0])


def norm(v):
    length = sqrt(sum(x*x for x in v)) or 1
    return tuple(x / length for x in v)


def scale(v, factor):
    return tuple(x * factor for x in v)


class Surface:
    def __init__(self, seed):
        self.random = Random(seed)
        self.pos, self.normals = [], []
        self.colors = bytearray()
        self.indices = array('H')

    def v(self, p, n, c):
        self.pos.extend(p)
        self.normals.extend(norm(n))
        # glTF stores linear vertex color, unlike the artist-facing palette above.
        self.colors.extend([round(255 * ((x/12.92) if x <= .04045 else ((x + .055)/1.055)**2.4)) for x in c] + [255])
        return len(self.pos)//3 - 1

    def tri(self, a, b, c):
        self.indices.extend((a, b, c))

    def rings(self, rings):
        for first, second in zip(rings, rings[1:]):
            for i in range(len(first)):
                j = (i+1) % len(first)
                self.tri(first[i], second[i], first[j]); self.tri(first[j], second[i], second[j])

    def oval(self, center, size, bottom, top, sides=13, bands=6, rugged=.1):
        """Irregular layered elliptical mass; paint light toward the upper-left crown."""
        phase = self.random.random() * TAU
        rings = []
        for j in range(bands+1):
            b = (j / bands-.5) * pi
            ring = []
            for i in range(sides):
                a = TAU * i/sides + phase
                r = 1 + rugged * (.55*sin(3*a+.4) + .26*cos(5*a+3*b) + .19*cos(7*a-2*b))
                n = (cos(a)*cos(b), sin(b), sin(a)*cos(b))
                p = add(center, tuple(n[k]*size[k]*(r if k != 1 else 1) for k in range(3)))
                value = max(0, min(1, .44 + .40*n[1] - .27*n[0] - .1*n[2] + .035*sin(5*a + b)))
                ring.append(self.v(p, n, blend(bottom, top, value)))
            rings.append(ring)
        self.rings(rings)

    def stem(self, points, radii, bark, light, sides=7):
        rings = []
        for k, (p, r) in enumerate(zip(points, radii)):
            direction = norm(sub(points[min(k+1,len(points)-1)], points[max(0,k-1)]))
            u = norm(cross(direction, (0,0,1) if abs(direction[2]) < .85 else (1,0,0)))
            v = norm(cross(u,direction))
            ring = []
            for i in range(sides):
                a = TAU*i/sides
                outward = add(scale(u, cos(a)), scale(v, sin(a)))
                c = blend(bark,light,.26+.45*max(0,-outward[0])+.22*k/(len(points)-1))
                ring.append(self.v(add(p,scale(outward,r)),outward,c))
            rings.append(ring)
        self.rings(rings)

    def leaf(self, p, a, length, width, lift, color):
        axis=(cos(a),0,sin(a)); lateral=(-sin(a),0,cos(a))
        mid=add(p,scale(axis,.55*length)); end=add(add(p,scale(axis,length)),(0,lift,0))
        ridge=add(mid,(0,lift*.55+.12*width,0)); mid=add(mid,(0,lift*.45,0))
        pts=(p,add(mid,scale(lateral,width)),ridge,add(mid,scale(lateral,-width)),end)
        ids=[self.v(q,(-.12,.96,.12),blend(color,rgb('ecedb0'), t)) for q,t in zip(pts,(0,.04,.19,0,.09))]
        for a,b,c in ((0,1,2),(0,2,3),(2,1,4),(3,2,4)): self.tri(ids[a],ids[b],ids[c])

    def wedge(self, x0, x1, y0, y1, z, depth, color):
        pts = [(x0,y0,z-depth), (x1,y0,z-depth), (x1,y1,z-depth), (x0,y1,z-depth),
               (x0,y0,z+depth), (x1,y0,z+depth), (x1,y1,z+depth), (x0,y1,z+depth)]
        self.block(pts,color)

    def block(self, pts, color):
        for inds in ((3,2,1,0),(4,5,6,7),(7,6,2,3),(0,1,5,4),(3,0,4,7),(1,2,6,5)):
            a,b,c,d=[pts[i] for i in inds]
            n=norm(cross(sub(b,a),sub(c,a)))
            tint=blend(color,rgb('fff1c2'),.14*max(n[1],0))
            vs=[self.v(q,n,tint) for q in (a,b,c,d)]
            self.tri(*vs[:3]); self.tri(vs[0],vs[2],vs[3])

    def glb(self, name):
        data = bytearray(); views = []; accessors = []
        def pack(buf, kind, component, count, **extra):
            data.extend(b'\0' * (-len(data)%4)); offset=len(data); data.extend(buf)
            views.append(dict(buffer=0,byteOffset=offset,byteLength=len(buf)))
            accessors.append(dict(bufferView=len(views)-1,componentType=component,count=count,type=kind,**extra))
        count = len(self.pos)//3
        pack(array('f',self.pos).tobytes(),'VEC3',5126,count,min=[min(self.pos[i::3]) for i in range(3)],max=[max(self.pos[i::3]) for i in range(3)])
        pack(array('f',self.normals).tobytes(),'VEC3',5126,count)
        pack(self.colors,'VEC4',5121,count,normalized=True)
        pack(self.indices.tobytes(),'SCALAR',5123,len(self.indices))
        data.extend(b'\0' * (-len(data)%4))
        root=dict(asset=dict(version='2.0',generator='Project E · Canal Atelier'),scene=0,scenes=[dict(nodes=[0])],nodes=[dict(name=name,mesh=0)],
                  meshes=[dict(name=name,primitives=[dict(attributes={'POSITION':0,'NORMAL':1,'COLOR_0':2},indices=3,material=0)])],
                  materials=[dict(doubleSided=True,pbrMetallicRoughness=dict(metallicFactor=0,roughnessFactor=.92))],
                  accessors=accessors,bufferViews=views,buffers=[dict(byteLength=len(data))])
        spec=json.dumps(root,separators=(',',':')).encode(); spec+=b' '*(-len(spec)%4)
        (OUT/(name+'.glb')).write_bytes(struct.pack('<4sII','glTF'.encode(),2,28+len(spec)+len(data))+struct.pack('<I4s',len(spec),b'JSON')+spec+struct.pack('<I4s',len(data),b'BIN\0')+data)
        print(name, count, 'vertices', len(self.indices)//3, 'triangles')


def ground(s):
    r=s.random
    s.oval((0,-.17,0),(1.85,.46,1.48),rgb('3f6c72'),rgb('9baf87'),16,5,.20)
    s.oval((-.12,.07,0),(1.57,.32,1.28),rgb('416f60'),rgb('9dac67'),14,5,.19)
    for a in (0,.8,2.1,3.4,4.0,5.5):
        s.oval((1.47*cos(a),-.12,1.16*sin(a)),(.44,.31,.35),rgb('526f79'),rgb('a9b6a2'),7,4,.2)
    for i in range(24):
        p=(r.uniform(-1.2,1.2),.25,r.uniform(-.8,.8)); color=r.choice([rgb('497e63'),rgb('7d9e63'),rgb('b1b97a')])
        for j in range(4): s.leaf(p,r.random()*TAU,r.uniform(.15,.38),r.uniform(.04,.12),r.uniform(.14,.35),color)


def tree(warm):
    s=Surface(15 if warm else 63); r=s.random; ground(s)
    dark=rgb('5b5147'); warm_bark=rgb('a38560')
    s.stem([(0,.14,0),(.14,.85,-.12),(-.02,1.72,.03),(.32,2.66,.02)],[.40,.24,.19,.055],dark,warm_bark)
    for k in range(5):
        a=k*TAU/5+.36
        s.stem([(.14,.62,0),(.37*cos(a),.31,.32*sin(a)),(.98*cos(a),.24,.79*sin(a))],[.18,.13,.005],dark,warm_bark)
    palettes=[('506f5a','b6c976'),('527c58','c9cf7f'),('66845b','d6d382')] if warm else [('325e62','83b497'),('416e65','a4c18b'),('366a65','8bbda0')]
    # Lithographic canopies rise in offset tiers, revealing the crooked trunk below.
    for index,(x,y,z,rad) in enumerate([(-.85,1.50,.32,.91),(.84,1.64,.14,.85),(-.52,2.10,-.50,1.03),(.58,2.34,-.32,.91),(-.07,2.88,.08,1.04)]):
        s.stem([(.10,.82,0),(.55*x,1.12+.25*(y-1),.62*z),(x,y,z)],[.17,.12,.035],dark,warm_bark)
        bottom,top=map(rgb,palettes[index%3]); s.oval((x,y,z),(rad,.67*rad,.88*rad),bottom,top,16,6,.16)
        for j in range(5):
            a=TAU*j/5+r.random()*.28
            px=x+cos(a)*rad*.58; pz=z+sin(a)*rad*.50; py=y+.16+(.15 if j==2 else 0)
            s.oval((px,py,pz),(.53*rad,.37*rad,.51*rad),bottom,top,10,5,.16)
            for q in range(5):
                sa=r.random()*TAU; dx=r.uniform(-.28,.28); dz=r.uniform(-.24,.24)
                h=.37*rad*sqrt(max(.05,1-(dx/(.53*rad))**2-(dz/(.51*rad))**2))
                s.leaf((px+dx,py+h+.013,pz+dz),sa,r.uniform(.16,.32),.065,-.05,blend(top,rgb('ffe4a4'),r.uniform(.02,.16)))
    s.glb('amber_fig' if warm else 'jade_willow')


def cloister():
    s=Surface(88); r=s.random; stones=list(map(rgb,['a8ac92','c1bfa2','b0baa0','d3c9aa','95a994']))
    # Individual voussoirs give the two openings readable arches and keystones.
    for x in (-1.72,0,1.72):
        s.wedge(x-.33,x+.33,-.40,.04,0,.44,stones[0]); s.wedge(x-.26,x+.26,.04,.2,0,.38,stones[3]);
        s.wedge(x-.19,x+.19,.2,.98,0,.31,stones[1]); s.wedge(x-.29,x+.29,.98,1.17,0,.36,stones[3]);
    for x in (-.86,.86):
        for i in range(9):
            a=pi*i/9+.014; b=pi*(i+1)/9-.014; key=(i==4); inner=.61 if not key else .56; outer=.89 if not key else .98
            xy=[(x+rad*cos(t),1.13+rad*sin(t)) for rad,t in ((outer,a),(outer,b),(inner,b),(inner,a))]
            pts=[(xx,yy,zz) for zz in (-.32-(.04 if key else 0),.32+(.04 if key else 0)) for xx,yy in xy]
            s.block(pts,stones[(i+int(x>0))%len(stones)])
    for i in range(6):
        x=-1.76+i*.59; h=2.07+r.random()*.05
        s.wedge(x,x+.57,1.93,h,0,.39,r.choice(stones)); s.oval((x+.29,h+.016,-.075),(.36,.065,.33),rgb('67876a'),rgb('abb878'),8,3,.15)
    vine=rgb('688860'); light=rgb('99b370')
    for i in range(21):
        x=r.uniform(-1.87,1.87); h=r.uniform(.23,1.05); z=r.choice((-.36,.36)); end=(x+r.uniform(-.18,.18),2.06-h,z)
        s.stem([(x,2.09,z*.6),(x+.05,1.99,z),end],[.038,.03,.008],vine,light,5)
        for j in range(5):
            v=j/5; p=(x*(1-v)+end[0]*v,2.04-h*v,z); s.leaf(p,r.uniform(0,TAU),r.uniform(.11,.23),.065,-.09,blend(vine,light,r.random()))
    # A pointed guild pennant and painted rosette repeat on the canal piers.
    azure=rgb('466e90'); gilt=rgb('dcbd80')
    for side in (-1,1):
        x=-1.72 if side==1 else 1.72; z=.38*side
        ids=[s.v(q,(0,0,side),c) for q,c in (
            ((x-.18,1.42,z),azure),((x+.18,1.42,z),azure),
            ((x+.17,.81,z+.035*side),azure),((x,.64,z+.02*side),gilt),
            ((x-.17,.81,z+.035*side),azure))]
        for a,b,c in ((0,1,2),(0,2,3),(0,3,4)): s.tri(ids[a],ids[b],ids[c])
        ids=[s.v((x+dx,1.12+dy,z+.04*side),(0,0,side),gilt) for dx,dy in ((0,.13),(.07,0),(0,-.12),(-.07,0))]
        s.tri(ids[0],ids[1],ids[2]); s.tri(ids[0],ids[2],ids[3])
        s.stem([(x-.23,1.44,z),(x+.23,1.44,z)],[.035,.035],gilt,gilt,5)
    for i in range(14):
        x,z=r.uniform(-1.63,1.63),r.uniform(-.26,.26); y=2.15+r.uniform(0,.09)
        for j in range(5):
            a=j*TAU/5; s.leaf((x,y,z),a,.095,.042,.038,rgb('f2e7bd'))
        s.oval((x,y+.022,z),(.03,.022,.03),rgb('b98244'),rgb('e9b964'),6,3)
    s.glb('ivy_cloister')


def bank():
    s=Surface(817); r=s.random
    colors=list(map(rgb,['446c67','65867a','81998a','78966b','93ac74']))
    shape=[(1.0,.35),(.72,.8),(.30,.93),(-.12,.89),(-.49,1),(-.90,.72),(-1,.15),(-.94,-.57),(-.59,-.91),(-.18,-.85),(.22,-1),(.72,-.70),(.94,-.36)]
    # A scalloped bank, with distinct strata and one gently domed grass surface.
    rings=[]
    for j,(rad,h) in enumerate(((.88,-.52),(1.02,-.27),(.98,-.065),(.92,.08),(.80,.19),(.18,.24))):
        ring=[]
        for i,(x,z) in enumerate(shape):
            paint=blend(colors[min(j,4)],colors[min(j+1,4)],.28+.25*cos(i*1.3))
            off=.04*sin(i*3.12)
            ring.append(s.v((x*rad*3.4,h+off,z*rad*1.9),(x*.44,.40+j*.18,z*.8),paint))
        rings.append(ring)
    s.rings(rings)
    center=s.v((0,.24,0),(0,1,0),colors[-1])
    for i in range(len(shape)): s.tri(rings[-1][i],center,rings[-1][(i+1)%len(shape)])
    for i in range(20):
        a=r.random()*TAU; x=cos(a)*r.uniform(2.72,3.06); z=sin(a)*r.uniform(1.46,1.71)
        s.oval((x,-.17,z),(r.uniform(.13,.36),r.uniform(.13,.32),r.uniform(.15,.38)),rgb('526f72'),rgb('a3ad96'),8,4,.22)
        if i%2==0:
            for j in range(7): s.leaf((x*.85,.09,z*.89),r.random()*TAU,r.uniform(.18,.46),r.uniform(.04,.10),r.uniform(.15,.38),rgb('8aa377'))
    s.glb('garden_bank')


def medallion():
    s=Surface(498); gold=rgb('b29a6e'); jade=rgb('809d96')
    def top_face(points, color):
        ids=[s.v((x,0,z),(0,1,0),color) for x,z in points]
        for j in range(1,len(ids)-1): s.tri(ids[0],ids[j+1],ids[j])
    for outer,inner,material in ((.95,.90,gold),(.83,.79,jade),(.32,.285,gold)):
        for j in range(48):
            if (outer==.83 and j%12 < 3): continue
            a=TAU*j/48; b=TAU*(j+1)/48
            top_face([(r*cos(t),r*sin(t)) for r,t in ((inner,a),(outer,a),(outer,b),(inner,b))],material)
    for j in range(8):
        a=TAU*j/8
        top_face([(r*cos(a+t),r*sin(a+t)) for r,t in ((.15,0),(.39,-.16),(.72,0),(.39,.16))],jade if j%2==0 else gold)
    s.glb('guild_mosaic')


def quay():
    s=Surface(373); cream=rgb('acae95'); edge=rgb('d5c7a6'); copper=rgb('96694d'); gold=rgb('cf9a60')
    for x in (-1.29,1.29):
        s.wedge(x-.15,x+.15,-.12,.05,0,.17,cream)
        s.wedge(x-.11,x+.11,.05,.49,0,.11,copper)
        s.wedge(x-.16,x+.16,.48,.55,0,.15,gold)
        s.stem([(x,.55,0),(x,.64,0),(x,.71,0)],[.12,.10,.015],copper,gold,8)
    s.wedge(-1.27,1.27,.27,.34,0,.045,rgb('9d7755'))
    s.wedge(-1.27,1.27,.40,.45,0,.055,rgb('b38861'))
    for x in (-.88,-.44,0,.44,.88):
        s.stem([(x-.08,.29,0),(x+.10,.43,0)],[.022,.022],copper,gold,5)
    s.glb('quay_rail')


def wheel():
    s=Surface(711)
    timber=list(map(rgb,['805442','9c634a','995f44','bd8156']))
    copper=rgb('bd805c'); brass=rgb('d9ad73')
    # z faces the camera. Two segmented rims hold oak paddles and iron spokes.
    for i in range(16):
        a=TAU*i/16; b=TAU*(i+1)/16
        for z in (-.32,.32):
            xy=[(r*cos(t), r*sin(t)) for r,t in ((1.19,a),(1.19,b),(.97,b),(.97,a))]
            s.block([(x,y,zz) for zz in (z-.06,z+.06) for x,y in xy],copper if i%4==0 else timber[i%4])
            if i%2==0:
                s.stem([(0,0,z),(.99*cos(a),.99*sin(a),z)], [.097,.064],timber[0],brass,7)
                s.oval((1.08*cos(a),1.08*sin(a),z*1.21),(.047,.047,.035),copper,brass,7,4)
        xy=[(r*cos(t),r*sin(t)) for r,t in ((1.30,a),(1.31,a+.14),(1.04,a+.16),(1.04,a+.03))]
        s.block([(x,y,z) for z in (-.40,.40) for x,y in xy],timber[(i+1)%4])
    s.stem([(0,0,-.61),(0,0,.57)],[.17,.17],timber[1],brass,12)
    for z in (-.45,.45): s.oval((0,0,z),(.27,.27,.14),copper,brass,14,6)
    s.glb('copper_millwheel')


def lathe(surface, levels, sides=16):
    rings = []
    for y, radius, tint in levels:
        ring = []
        for i in range(sides):
            a = (i + .5) * TAU / sides
            ring.append(surface.v((radius*cos(a),y,radius*sin(a)), (cos(a),.18,sin(a)), tint))
        rings.append(ring)
    surface.rings(rings)


def pennant(s, angle, radius, top, size):
    """Pointed enameled guild shield with brass edge and raised diamond boss."""
    def patch(points, at, tint):
        ids = [s.v((at*cos(angle)-x*size*sin(angle),top+y*size,at*sin(angle)+x*size*cos(angle)),
                   (cos(angle),0,sin(angle)),tint) for x,y in points]
        for j in range(1,len(ids)-1):
            s.tri(ids[0],ids[j],ids[j+1])
    patch([(-.32,0),(.32,0),(.30,-.59),(0,-.85),(-.30,-.59)],radius, rgb('c69a55'))
    patch([(-.26,-.05),(.26,-.05),(.24,-.56),(0,-.76),(-.24,-.56)],radius+.008, rgb('284a80'))
    patch([(0,-.13),(.13,-.38),(0,-.63),(-.13,-.38)], radius+.016, rgb('efe2b9'))
    patch([(0,-.25),(.066,-.38),(0,-.51),(-.066,-.38)], radius+.024, rgb('45758f'))


def crystal_cluster():
    s = Surface(606)
    def shard(x,z,start,width,height,tilt):
        palette = list(map(rgb,['4c75b3','63a7ca','95d6dd','c5e9e6','669dc6','4877b2']))
        cap = (x+tilt,height+start,z)
        low = (x-.06*tilt,start,z)
        mid = [(x+width*cos(TAU*i/6)+tilt*.35,start+height*.48,z+width*.79*sin(TAU*i/6)) for i in range(6)]
        upper = [(x+width*.70*cos(TAU*i/6)+tilt*.70,start+height*.76,z+width*.54*sin(TAU*i/6)) for i in range(6)]
        def facet(points, tint):
            a,b,c = points[:3]
            face_normal = norm(cross(sub(b,a),sub(c,a)))
            ids=[s.v(v,face_normal,tint) for v in points]
            for j in range(1,len(ids)-1): s.tri(ids[0],ids[j],ids[j+1])
        for i in range(6):
            j=(i+1)%6
            facet([low,mid[i],mid[j]],blend(palette[i],rgb('294b79'),.30))
            facet([mid[i],upper[i],upper[j],mid[j]],palette[i])
            facet([upper[i],cap,upper[j]],blend(palette[i],rgb('feeed5'),.36))
    shard(0,0,0,.36,.94,.10)
    shard(-.27,.035,.01,.16,.53,-.14)
    shard(.25,.12,.01,.14,.44,.12)
    s.glb('crown_crystal')


def sentinel():
    s = Surface(219)
    slate, ivory, blue, copper, gold = map(rgb,['465861','cecbb6','3c6192','976947','cfa66c'])
    lathe(s,[(0,.91,slate),(.09,1.02,slate),(.20,.95,ivory),(.27,.89,gold),
             (.33,.80,slate),(.46,.76,ivory),(.52,.66,ivory),(1.04,.51,blue),
             (1.12,.51,slate),(1.22,.66,copper),(1.30,.71,gold),(1.34,.55,slate),
             (1.68,.46,slate),(1.74,.71,copper),(1.84,.87,gold),(1.94,.88,slate),
             (2.02,.70,copper),(2.04,.61,blue),(2.04,.01,blue)])
    for i in range(4):
        a=pi*.25+i*pi*.5
        xy=lambda r,y:(r*cos(a),y,r*sin(a))
        # Four forked counterweights curve out from a recessed socket; the
        # gilded feathers leave a clear central window around the cut crystal.
        s.stem([xy(.57,.28),xy(.79,.59),xy(.75,1.02),xy(.48,1.28)],[.14,.11,.085,.13],copper,gold,8)
        s.stem([xy(.55,1.63),xy(.83,1.89),xy(.91,2.14),xy(.78,2.42),xy(.69,2.49)],[.15,.17,.12,.07,.012],copper,gold,8)
        s.oval(xy(.86,1.98),(.10,.14,.10),blue,rgb('6997aa'),8,4)
        s.oval(xy(.57,.45),(.10,.13,.10),copper,gold,8,4)
        pennant(s,pi*.5*i,.72,1.38,.98)
    s.glb('sentinel_crown')


def observatory():
    s=Surface(923)
    slate,ivory,blue,copper,gold=map(rgb,['445661','d9d4b9','426492','986645','d4ad72'])
    lathe(s,[(0,1.72,slate),(.10,1.91,slate),(.26,1.85,ivory),(.32,1.64,gold),(.40,1.55,blue),
             (.45,1.43,ivory),(.59,1.39,ivory),(.69,1.20,copper),(.76,1.20,gold),(.76,.05,slate)],24)
    lathe(s,[(.7,.74,slate),(.82,.81,copper),(.89,.83,gold),(1.02,.68,slate),(1.04,.08,blue)])
    for i in range(4):
        a=TAU*i/4+pi*.25
        xy=lambda r,y:(r*cos(a),y,r*sin(a))
        s.stem([xy(1.25,.49),xy(1.46,1.08),xy(1.37,1.54),xy(1.14,1.80)],[.26,.235,.19,.045],slate,ivory,8)
        s.oval(xy(1.43,1.13),(.22,.15,.22),copper,gold,9,4)
        pennant(s,TAU*i/4,1.43,1.04,.84)
    # Oblique armillary orbits cross behind and in front of the floating crystal.
    for azimuth,tilt,radius in ((.2,.81,1.30),(2.14,1.06,1.24)):
        points=[]
        for j in range(49):
            a=j*TAU/48
            dx=radius*cos(a); dz=radius*sin(a)*cos(tilt); dy=radius*sin(a)*sin(tilt)
            points.append((dx*cos(azimuth)-dz*sin(azimuth),1.85+dy,dx*sin(azimuth)+dz*cos(azimuth)))
        s.stem(points,[.064]*len(points),copper,gold,7)
        for k in (0,12,24,36): s.oval(points[k],(.10,.10,.10),gold,ivory,8,4)
    s.glb('core_observatory')


def gatehouse():
    s=Surface(877); r=s.random
    ivory,limestone,slate,azure,timber,copper,gold=map(rgb,['ddd0ae','bdbda4','4e6771','385c80','6c5247','975e42','cb9866'])
    # Stone plinth, a shaded passage, slatted shutters and stepped door mouldings.
    s.wedge(-1.53,1.53,-.18,.26,0,1.04,slate)
    s.wedge(-1.45,1.45,.26,.43,0,1.00,ivory)
    s.wedge(-1.32,1.32,.43,2.14,0,.88,limestone)
    for side in (-1,1):
        z=.90*side
        s.wedge(-.52,.52,.43,1.67,z,.02,timber)
        for x in (-.59,.59):
            s.wedge(x-.14,x+.14,.41,.56,z,.12,ivory)
            s.wedge(x-.1,x+.1,.56,1.59,z,.08,ivory)
            s.wedge(x-.15,x+.15,1.55,1.69,z,.12,slate)
        for i in range(9):
            a=i*pi/9+.008; b=(i+1)*pi/9-.008
            xy=[(d*cos(t),1.59+d*sin(t)) for d,t in ((.63,a),(.63,b),(.45,b),(.45,a))]
            s.block([(x,y,zz) for zz in (z-.10,z+.10) for x,y in xy],gold if i==4 else ivory)
        for x in (-1.03,1.03):
            s.wedge(x-.19,x+.19,.93,1.58,z,.03,slate)
            s.wedge(x-.22,x+.22,.88,.96,z,.09,ivory)
            for y in (1.03,1.18,1.33,1.48):
                s.wedge(x-.15,x+.15,y,y+.05,z+side*.035,.025,azure)
    s.wedge(-1.58,1.58,2.03,2.18,0,1.07,timber)
    # Curved clay tiles overlap downslope. They hold their silhouette in a
    # normal combat camera, including the scalloped edge against the cornice.
    palette=list(map(rgb,['ac5c42','bd6d4c','c97850','ab6849','d18b60','ad6046']))
    for side in (-1,1):
        for row in range(4):
            run0=.015+row*.29
            for col in range(11):
                x=-1.66+col*.303
                tile_color=r.choice(palette)
                rings=[]
                for run in (run0,run0+.36):
                    arc=[]
                    for k in range(5):
                        theta=pi*k/4
                        dx=.15*cos(theta)
                        y=3.03-run*.79+.065*sin(theta)
                        arc.append(s.v((x+.15+dx,y,side*run),(cos(theta)*.32,.75,side*.62),tile_color))
                    rings.append(arc)
                for k in range(4):
                    a,b=rings[0][k:k+2];c,d=rings[1][k:k+2]
                    if side>0: s.tri(a,b,c);s.tri(b,d,c)
                    else: s.tri(a,c,b);s.tri(b,c,d)
    s.stem([(-1.72,3.05,0),(1.72,3.05,0)],[.095,.095],copper,rgb('d38a60'),9)
    for end in (-1,1):
        x=end*1.46
        points=[(x,2.13,-1.01),(x,2.99,0),(x,2.13,1.01)]
        ids=[s.v(q,(end,0,0),ivory) for q in points]; s.tri(*ids)
        s.stem([(x,2.16,-.97),(x,2.98,0),(x,2.16,.97)],[.052,.052,.052],timber,copper,5)
        s.stem([(x,2.20,0),(x,2.82,0)],[.04,.04],timber,copper,5)
    p=(-1.17,1.99,1.04)
    for i in range(4):
        x=p[0]+i*.092; drop=r.uniform(.28,.71)
        s.stem([(x,2.03,1.0),(x+.08,1.92,1.03),(x-.01,2.0-drop,1.04)],[.033,.026,.008],rgb('4f7457'),rgb('82905b'),6)
        for j in range(5): s.leaf((x,1.99-drop*j/5,1.04),r.random()*TAU,.14,.061,-.09,rgb('79965c'))
    s.glb('terracotta_gatehouse')


if __name__=='__main__':
    OUT.mkdir(parents=True,exist_ok=True)
    tree(True); tree(False); cloister(); wheel(); sentinel(); bank(); quay(); medallion(); crystal_cluster(); observatory(); gatehouse()
