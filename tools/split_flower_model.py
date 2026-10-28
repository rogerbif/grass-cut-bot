"""Divide os modelos de flor (flower_02..08) em 3 malhas (caule, folhas, petalas), pinta o vertex color
e gera as pecas-detrito do hit 1 (2 petalas + 1 folha).

Uso (Blender 5.2 headless):
  blender -b --python tools/split_flower_model.py -- <pasta_origem_glb> <pasta_saida_glb> [--preview <pasta_png>] [nomes...]

Vertex color (COLOR_0, float linear):
  R: estagio da despetalacao (0 = fixo, 0.5 = petalas externas/hit 1, 1.0 = internas/hit 2)
  G: 1.0 no miolo (usa center_color)
  B: 1.0 nas pecas que se desprendem no hit 1 (2 petalas + 1 folha)
  A: gradiente escuro (0, base) -> claro (1, ponta)
"""
import bpy
import bmesh
import math
import sys
import os
import json
from mathutils import Vector

# Configuracao por especie. Indices = ilhas de malha na ordem de bmesh (deterministica).
CONFIG = {
    "flower_02_rose": {
        "stem": [0, 1, 2, 3, 4, 11, 12, 13],
        "leaves": [5, 6, 7, 8, 9, 10, 14, 32, 33],
        "center_r": 0.03, "outer_mode": "radius",
        "detach_petals": [40, 15], "detach_leaf": 9,
    },
    "flower_03_daisy": {
        "stem": [10, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
        "leaves": [11, 12, 13, 14, 164, 165, 166, 167, 168, 169, 170],
        "center_r": 0.1, "center_min_n": 40, "outer_mode": "radius",
        "detach_petals": "auto", "detach_leaf": 13,
    },
    "flower_04_sunflower": {
        "stem": [0],
        "leaves": [1, 2, 3, 4, 135],
        "center_r": 0.08, "center_min_n": 20, "outer_mode": "radius",
        "detach_petals": "auto", "detach_leaf": 1,
    },
    "flower_05_bell": {
        "stem": [i for i in range(0, 26)],
        "leaves": [26, 27, 28, 29, 30],
        "center_r": 0.0, "outer_mode": "angle",
        "detach_petals": "auto", "detach_leaf": 27,
    },
    "flower_06_corolla": {
        "stem": [2],
        "leaves": [0, 1, 3, 4, 5],
        "center_r": 0.0, "outer_mode": "angle",
        "detach_petals": "auto", "detach_leaf": 0,
    },
    "flower_07_tulip": {
        "stem": [2],
        "leaves": [0, 1, 3, 4, 5],
        "center_r": 0.0, "outer_mode": "angle",
        "detach_petals": "auto", "detach_leaf": 0,
    },
    "flower_08_bed": {
        "stem": [0, 1, 2, 3, 4, 5, 6, 7, 8],
        "leaves": [9, 10, 11],
        "center_r": 0.0, "outer_mode": "radius",
        "detach_petals": [15, 17], "detach_leaf": 11,
    },
}


def parse_args():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    src_dir, out_dir = argv[0], argv[1]
    preview = None
    names = []
    i = 2
    while i < len(argv):
        if argv[i] == "--preview":
            preview = argv[i + 1]
            i += 2
        else:
            names.append(argv[i])
            i += 1
    return src_dir, out_dir, preview, names or list(CONFIG.keys())


def build_islands(bm):
    seen = set()
    islands = []
    for v in bm.verts:
        if v.index in seen:
            continue
        stack = [v]
        seen.add(v.index)
        ids = []
        while stack:
            c = stack.pop()
            ids.append(c.index)
            for e in c.link_edges:
                w = e.other_vert(c)
                if w.index not in seen:
                    seen.add(w.index)
                    stack.append(w)
        islands.append(ids)
    return islands


def process(name, src_dir, out_dir, preview_dir):
    cfg = CONFIG[name]
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=os.path.join(src_dir, name + ".glb"))
    src = [o for o in bpy.data.objects if o.type == 'MESH'][0]
    mat_stem = src.data.materials[0]
    mat_pet = src.data.materials[1]

    bm0 = bmesh.new()
    bm0.from_mesh(src.data)
    bm0.verts.ensure_lookup_table()
    isl = build_islands(bm0)
    info = []
    for i, ids in enumerate(isl):
        fs = set(f for k in ids for f in bm0.verts[k].link_faces)
        mi = min(f.material_index for f in fs)
        c = sum((bm0.verts[k].co for k in ids), Vector()) / len(ids)
        info.append({"i": i, "mat": mi, "n": len(ids), "c": c, "r": math.hypot(c.x, c.y),
                     "ang": math.atan2(c.y, c.x)})
    m1v = [bm0.verts[k].co for d in info if d["mat"] == 1 for k in isl[d["i"]]]
    zlo = min(p.z for p in m1v)
    zhi = max(p.z for p in m1v)
    top = [p for p in m1v if p.z >= zlo + 0.6 * (zhi - zlo)]
    hx = sum(p.x for p in top) / len(top)
    hy = sum(p.y for p in top) / len(top)
    for d in info:
        if d["mat"] == 1:
            d["r"] = math.hypot(d["c"].x - hx, d["c"].y - hy)
            d["ang"] = math.atan2(d["c"].y - hy, d["c"].x - hx)
    pos2isl = {}
    for i, ids in enumerate(isl):
        for k in ids:
            pos2isl[tuple(round(x, 5) for x in bm0.verts[k].co)] = i

    stem_ids = list(cfg["stem"])
    leaf_ids = list(cfg["leaves"])
    mat1 = [d for d in info if d["mat"] == 1 and d["i"] not in leaf_ids and d["i"] not in stem_ids]
    center_ids = [d["i"] for d in mat1 if cfg["center_r"] > 0 and d["r"] < cfg["center_r"] and d["n"] >= cfg.get("center_min_n", 0)]
    petal_infos = [d for d in mat1 if d["i"] not in center_ids]
    if cfg["outer_mode"] == "radius":
        rs = sorted(d["r"] for d in petal_infos)
        med = rs[len(rs) // 2]
        outer = [d["i"] for d in petal_infos if d["r"] >= med]
    else:
        srt = sorted(petal_infos, key=lambda d: d["ang"])
        outer = [d["i"] for k, d in enumerate(srt) if k % 2 == 0]
    inner = [d["i"] for d in petal_infos if d["i"] not in outer]
    if cfg["detach_petals"] == "auto":
        cand = [d for d in petal_infos if d["i"] in outer and (cfg["outer_mode"] == "angle" or (d["n"] <= 30 and d["r"] <= 0.5))]
        cand.sort(key=lambda d: (-d["r"] if cfg["outer_mode"] == "angle" else (-d["n"], -d["r"])))
        det_p = [d["i"] for d in cand[:2]]
    else:
        det_p = list(cfg["detach_petals"])
    det_leaf = cfg["detach_leaf"]
    # garante que as peças soltas estao no estagio 1 (externas)
    for p in det_p:
        if p in inner:
            inner.remove(p)
        if p not in outer:
            outer.append(p)
    print("CLASS", name, "stem", len(stem_ids), "leaves", len(leaf_ids), "center", len(center_ids),
          "outer", len(outer), "inner", len(inner), "detach", det_p, det_leaf)

    # extremos para gradiente
    def part_bounds(ids):
        pts = [bm0.verts[k].co for i in ids for k in isl[i]]
        return (min(p.z for p in pts), max(p.z for p in pts),
                min(math.hypot(p.x, p.y) for p in pts), max(math.hypot(p.x, p.y) for p in pts))

    def make(oname, ids, material, colorfn=None, recenter=False):
        bm = bmesh.new()
        bm.from_mesh(src.data)
        bm.verts.ensure_lookup_table()
        keep = set(k for i in ids for k in isl[i])
        bmesh.ops.delete(bm, geom=[v for v in bm.verts if v.index not in keep], context='VERTS')
        bm.verts.ensure_lookup_table()
        while len(bm.loops.layers.color) > 0:
            bm.loops.layers.color.remove(bm.loops.layers.color[0])
        while len(bm.loops.layers.float_color) > 0:
            bm.loops.layers.float_color.remove(bm.loops.layers.float_color[0])
        offset = Vector()
        if recenter:
            offset = sum((v.co for v in bm.verts), Vector()) / len(bm.verts)
            for v in bm.verts:
                v.co -= offset
        if colorfn:
            lay = bm.loops.layers.float_color.new("Color")
            for f in bm.faces:
                for l in f.loops:
                    co = l.vert.co + offset
                    key = tuple(round(x, 5) for x in co)
                    l[lay] = colorfn(pos2isl[key], co)
        if not recenter:
            # Prevencao de Z-fighting contra o solo plano (Y=0.0 no Godot)
            for v in bm.verts:
                if v.co.z < 0.003:
                    v.co.z = 0.003
        me = bpy.data.meshes.new(oname)
        bm.to_mesh(me)
        bm.free()
        me.materials.clear()
        me.materials.append(material)
        for p in me.polygons:
            p.material_index = 0
        if colorfn:
            me.color_attributes.active_color = me.color_attributes["Color"]
            me.color_attributes.render_color_index = 0
        ob = bpy.data.objects.new(oname, me)
        bpy.context.scene.collection.objects.link(ob)
        return ob, offset

    def norm(v, lo, hi):
        return 0.0 if hi - lo < 1e-6 else max(0.0, min(1.0, (v - lo) / (hi - lo)))

    sb = part_bounds(stem_ids)
    lb = part_bounds(leaf_ids)
    pb = part_bounds([d["i"] for d in mat1])

    def col_stem(i, co):
        return (0.0, 0.0, 0.0, norm(co.z, sb[0], sb[1]))

    def col_leaf(i, co):
        return (0.0, 0.0, 1.0 if i == det_leaf else 0.0, norm(co.z, lb[0], lb[1]))

    def col_pet(i, co):
        if i in center_ids:
            r, g = 0.0, 1.0
        else:
            r, g = (0.5 if i in outer else 1.0), 0.0
        b = 1.0 if i in det_p else 0.0
        rn = norm(math.hypot(co.x - hx, co.y - hy), 0.0, pb[3])
        a = 0.5 * norm(co.z, pb[0], pb[1]) + 0.5 * rn
        return (r, g, b, a)

    objs = [
        make("Flower_Stem", stem_ids, mat_stem, col_stem)[0],
        make("Flower_Leaves", leaf_ids, mat_stem, col_leaf)[0],
        make("Flower_Petals", [d["i"] for d in mat1], mat_pet, col_pet)[0],
    ]
    for o in bpy.data.objects:
        o.select_set(o in objs)
    bpy.ops.export_scene.gltf(filepath=os.path.join(out_dir, name + ".glb"), export_format='GLB',
                              use_selection=True, export_apply=True, export_yup=True,
                              export_vertex_color='ACTIVE')

    pieces = []
    offsets = {}
    for pn, ids, mat in (("Piece_Petal_A", [det_p[0]], mat_pet), ("Piece_Petal_B", [det_p[1]], mat_pet),
                         ("Piece_Leaf", [det_leaf], mat_stem)):
        o, off = make(pn, ids, mat, None, True)
        pieces.append(o)
        offsets[pn] = [round(off.x, 4), round(off.z, 4), round(-off.y, 4)]
    for o in bpy.data.objects:
        o.select_set(o in pieces)
    bpy.ops.export_scene.gltf(filepath=os.path.join(out_dir, name + "_detach.glb"), export_format='GLB',
                              use_selection=True, export_apply=True, export_yup=True,
                              export_vertex_color='NONE')
    print("OFFSETS", name, json.dumps(offsets))

    if preview_dir:
        render_preview(name, objs, preview_dir, center_ids, outer, inner, det_p, det_leaf, isl, pos2isl)


def render_preview(name, objs, preview_dir, center_ids, outer, inner, det_p, det_leaf, isl, pos2isl):
    """Render workbench com vertex color (R/G/B/A) convertido em cor de diagnostico."""
    os.makedirs(preview_dir, exist_ok=True)
    palette = {"stem": (0.35, 0.22, 0.08), "leaf": (0.15, 0.55, 0.15), "outer": (1.0, 0.3, 0.6),
               "inner": (0.7, 0.2, 0.9), "center": (1.0, 0.85, 0.0), "detach": (0.1, 0.8, 1.0)}
    for ob in bpy.data.objects:
        ob.hide_render = ob not in objs
    names = ["stem", "leaf", "outer", "inner", "center", "detach"]
    for o in objs:
        me = o.data
        lay = me.color_attributes["Color"]
        me.materials.clear()
        for k in names:
            m = bpy.data.materials.new("pv_" + k)
            m.diffuse_color = palette[k] + (1.0,)
            me.materials.append(m)
        for poly in me.polygons:
            r, g, b, a = lay.data[poly.loop_start].color
            if o.name == "Flower_Stem":
                k = "stem"
            elif o.name == "Flower_Leaves":
                k = "detach" if b > 0.5 else "leaf"
            else:
                k = "center" if g > 0.5 else ("detach" if b > 0.5 else ("outer" if r < 0.75 else "inner"))
            poly.material_index = names.index(k)
        me.update()
    scn = bpy.context.scene
    scn.render.engine = 'BLENDER_WORKBENCH'
    scn.display.shading.light = 'FLAT'
    scn.display.shading.color_type = 'MATERIAL'
    scn.render.resolution_x = 512
    scn.render.resolution_y = 512
    scn.render.film_transparent = False
    world = bpy.data.worlds.new("w")
    world.color = (0.12, 0.12, 0.14)
    scn.world = world
    cam = bpy.data.cameras.new("cam")
    cam.type = 'ORTHO'
    cam.ortho_scale = 2.6
    co = bpy.data.objects.new("cam", cam)
    scn.collection.objects.link(co)
    scn.camera = co
    for tag, loc, rot in (("side", (0, -6, 0.9), (math.radians(90), 0, 0)),
                          ("top", (0, 0, 6), (0, 0, 0))):
        co.location = loc
        co.rotation_euler = rot
        scn.render.filepath = os.path.join(preview_dir, "%s_%s.png" % (name, tag))
        bpy.ops.render.render(write_still=True)


def main():
    src_dir, out_dir, preview_dir, names = parse_args()
    os.makedirs(out_dir, exist_ok=True)
    for n in names:
        process(n, src_dir, out_dir, preview_dir)


main()
