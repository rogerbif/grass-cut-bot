import bpy
import bmesh
import math
import os
from mathutils import Vector, Matrix

blend_path = r"C:\Users\User\OneDrive\Documentos\3D_Blender\wheat.blend"
output_glb_path = r"C:\Users\User\OneDrive\Documentos\grass-cut-bot\assets\models\wheat_01.glb"

print("--- Remodelando Espiga e Caule de Trigo em Blender ---")
bpy.ops.wm.open_mainfile(filepath=blend_path)

wheat = bpy.data.objects.get("wheat_01")
if not wheat:
    raise RuntimeError("Objeto wheat_01 nao encontrado em wheat.blend!")

me = wheat.data
bm = bmesh.new()
bm.from_mesh(me)

# 1. Remover a espiga/ráquis antiga (Z >= 0.80m) preservando as folhas laterais abaixo de 0.80m
top_faces = [f for f in bm.faces if any(v.co.z >= 0.80 for v in f.verts)]
print(f"Removendo {len(top_faces)} faces da regiao superior da espiga antiga...")
bmesh.ops.delete(bm, geom=top_faces, context='FACES')

# Limpar vertices soltos
loose_verts = [v for v in bm.verts if len(v.link_faces) == 0]
bmesh.ops.delete(bm, geom=loose_verts, context='VERTS')

# 2. Construir o caule central (colmo) contínuo do solo (Z = 0.0m) até o ápice da espiga (Z = 1.12m)
stem_steps = 32
num_sides = 6
stem_rings = []
for i in range(stem_steps + 1):
    t = i / float(stem_steps)
    z = t * 1.12
    if z <= 0.80:
        u = z / 0.80
        # Diâmetro de ~2.4cm na base afunilando para ~1.8cm na base da espiga
        radius = 0.012 - u * (0.012 - 0.009)
    else:
        u = (z - 0.80) / 0.32
        # Ráquis da espiga afunilando para ~0.9cm no ápice
        radius = 0.009 - u * (0.009 - 0.0045)
    
    ring = []
    for s in range(num_sides):
        ang = s * (2.0 * math.pi / float(num_sides))
        v = bm.verts.new((math.cos(ang) * radius, math.sin(ang) * radius, z))
        ring.append(v)
    stem_rings.append(ring)

# Criar faces quadriláteras do cilindro hexagonal contínuo
for i in range(stem_steps):
    r0 = stem_rings[i]
    r1 = stem_rings[i + 1]
    for s in range(num_sides):
        s_next = (s + 1) % num_sides
        bm.faces.new((r0[s], r0[s_next], r1[s_next], r1[s]))

# Fechamento inferior no solo (Z = 0.0)
v_bottom_center = bm.verts.new((0.0, 0.0, 0.0))
r_base = stem_rings[0]
for s in range(num_sides):
    s_next = (s + 1) % num_sides
    bm.faces.new((v_bottom_center, r_base[s_next], r_base[s]))

# 3. Modelar 11 níveis de espiguetas/grãos 3D em espinha de peixe (herringbone/braided)
num_tiers = 11
spike_start_z = 0.81
spike_height = 0.30

for tier in range(num_tiers):
    t = tier / float(num_tiers - 1)
    base_z = spike_start_z + t * spike_height
    # Curva de perfil: suave na base, bojudo no meio, afilado na ponta
    profile = math.sin(t * math.pi * 0.88 + 0.18)
    grain_len = 0.054 * (0.85 + 0.35 * profile)
    grain_width = 0.034 * (0.75 + 0.50 * profile)
    grain_thick = 0.024 * (0.75 + 0.45 * profile)
    
    tier_rot = (tier % 2) * math.radians(25.0) - math.radians(12.5)
    
    for side in [-1, 1]:
        ang = (0.0 if side == -1 else math.pi) + tier_rot
        dir_x = math.cos(ang)
        dir_y = math.sin(ang)
        perp_x = -dir_y
        perp_y = dir_x
        
        # Inclinação vertical para cima de ~41 graus
        tilt = math.radians(41.0)
        slant_h = math.cos(tilt) * grain_len
        slant_z = math.sin(tilt) * grain_len
        
        attach_z = base_z + (0.012 if side == 1 else 0.0)
        bx = dir_x * 0.007
        by = dir_y * 0.007
        
        tx = bx + dir_x * slant_h
        ty = by + dir_y * slant_h
        tz = attach_z + slant_z
        
        # Ponto de barriga central (ápice volumétrico do grão)
        cx = bx + dir_x * slant_h * 0.52
        cy = by + dir_y * slant_h * 0.52
        cz = attach_z + slant_z * 0.48
        
        v_base = bm.verts.new((bx, by, attach_z))
        v_tip = bm.verts.new((tx, ty, tz))
        v_side1 = bm.verts.new((cx + perp_x * grain_width, cy + perp_y * grain_width, cz + 0.005))
        v_side2 = bm.verts.new((cx - perp_x * grain_width, cy - perp_y * grain_width, cz + 0.005))
        v_belly_out = bm.verts.new((cx + dir_x * grain_thick, cy + dir_y * grain_thick, cz + 0.008))
        v_belly_in = bm.verts.new((cx - dir_x * grain_thick * 0.35, cy - dir_y * grain_thick * 0.35, cz))
        
        # 8 facetas triangulares formando o grão volumoso facetado
        # Face externa (capta luz Toon e projeta sombra)
        bm.faces.new((v_base, v_side1, v_belly_out))
        bm.faces.new((v_base, v_belly_out, v_side2))
        bm.faces.new((v_belly_out, v_side1, v_tip))
        bm.faces.new((v_belly_out, v_tip, v_side2))
        # Face interna (apoio no ráquis)
        bm.faces.new((v_base, v_belly_in, v_side1))
        bm.faces.new((v_base, v_side2, v_belly_in))
        bm.faces.new((v_tip, v_side1, v_belly_in))
        bm.faces.new((v_tip, v_belly_in, v_side2))
        
        # Aristas estilizadas superiores (cerdas douradas finas nos níveis do topo)
        if tier >= 7:
            awn_len = 0.040 + (tier - 7) * 0.015
            atx = tx + dir_x * 0.008
            aty = ty + dir_y * 0.008
            atz = tz + awn_len
            v_awn = bm.verts.new((atx, aty, atz))
            bm.faces.new((v_tip, v_awn, v_side1))
            bm.faces.new((v_tip, v_side2, v_awn))

# 4. Grão terminal apical no topo
top_z = spike_start_z + spike_height + 0.008
v_tb = bm.verts.new((0.0, 0.0, top_z))
v_tt = bm.verts.new((0.0, 0.0, top_z + 0.065))
v_tf = bm.verts.new((0.0, 0.020, top_z + 0.028))
v_tback = bm.verts.new((0.0, -0.020, top_z + 0.028))
v_tl = bm.verts.new((-0.020, 0.0, top_z + 0.028))
v_tr = bm.verts.new((0.020, 0.0, top_z + 0.028))

bm.faces.new((v_tb, v_tf, v_tl))
bm.faces.new((v_tb, v_tr, v_tf))
bm.faces.new((v_tb, v_tback, v_tr))
bm.faces.new((v_tb, v_tl, v_tback))
bm.faces.new((v_tt, v_tl, v_tf))
bm.faces.new((v_tt, v_tf, v_tr))
bm.faces.new((v_tt, v_tr, v_tback))
bm.faces.new((v_tt, v_tback, v_tl))

# Suavizar normais em todas as faces
for f in bm.faces:
    f.smooth = True

bmesh.ops.recalc_face_normals(bm, faces=bm.faces)

# 5. Mapear camada UV contínua e Cores de Vértice (Gradiente 30% mais escuro e base escura)
uv_layer = bm.loops.layers.uv.verify()
color_layer = bm.loops.layers.color.verify()

all_z = [v.co.z for v in bm.verts]
min_z = min(all_z)
max_z = max(all_z)
height_span = max(max_z - min_z, 0.001)

for f in bm.faces:
    for loop in f.loops:
        v = loop.vert
        norm_h = max(0.0, min(1.0, (v.co.z - min_z) / height_span))
        # UV.y de 1.0 (solo) a 0.0 (topo) alinhado com invert_height = true
        loop[uv_layer].uv = Vector((0.5, 1.0 - norm_h))
        
        # COLOR.r é a altura canônica estrita para o shader (0.0 no solo até 1.0 no topo)
        # COLOR.g e COLOR.b adicionam leve oclusão de ambiente nas fendas
        if v.co.z > 0.80:
            dist_c = math.sqrt(v.co.x**2 + v.co.y**2)
            crevice = min(dist_c / 0.025, 1.0)
            col_r = norm_h
            col_g = 0.50 + 0.35 * crevice
            col_b = 0.10 + 0.25 * crevice
            loop[color_layer] = (col_r, col_g, col_b, 1.0)
        else:
            col_r = norm_h
            col_g = 0.35 + 0.45 * norm_h
            col_b = 0.05 + 0.20 * norm_h
            loop[color_layer] = (col_r, col_g, col_b, 1.0)

bm.to_mesh(me)
bm.free()
me.update()

print(f"Malha finalizada: {len(me.vertices)} vertices, {len(me.polygons)} poligonos.")

# 6. Salvar wheat.blend atualizado
bpy.ops.wm.save_mainfile(filepath=blend_path)
print("wheat.blend salvo com sucesso.")

# 7. Exportar glTF canônico para assets/models/wheat_01.glb
for o in bpy.data.objects:
    o.select_set(False)

wheat.select_set(True)
bpy.context.view_layer.objects.active = wheat

# Material Blender fosco 30% mais escuro
mat = bpy.data.materials.get("M_Wheat_Default")
if not mat:
    mat = bpy.data.materials.new("M_Wheat_Default")
mat.use_nodes = True
bsdf = mat.node_tree.nodes.get("Principled BSDF")
# Cor 30% mais escura: (0.67, 0.54, 0.13, 1.0)
bsdf.inputs['Base Color'].default_value = (0.67, 0.54, 0.13, 1.0)
bsdf.inputs['Roughness'].default_value = 0.90
wheat.data.materials.clear()
wheat.data.materials.append(mat)

# Exportação glTF com export_apply=True e export_yup=True (Mandamento 12)
bpy.ops.export_scene.gltf(
    filepath=output_glb_path,
    use_selection=True,
    export_apply=True,
    export_yup=True,
    export_format='GLB'
)
print(f"Export glTF concluido: {output_glb_path}")
