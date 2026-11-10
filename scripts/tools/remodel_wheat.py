import bpy
import bmesh
import math
import os
from mathutils import Vector, Matrix

blend_path = r"C:\Users\User\OneDrive\Documentos\3D_Blender\wheat.blend"
output_glb_path = r"C:\Users\User\OneDrive\Documentos\grass-cut-bot\assets\models\wheat_01.glb"

print("--- Remodelando Espiga de Trigo em Blender ---")
bpy.ops.wm.open_mainfile(filepath=blend_path)

wheat = bpy.data.objects.get("wheat_01")
if not wheat:
    raise RuntimeError("Objeto wheat_01 nao encontrado em wheat.blend!")

me = wheat.data
bm = bmesh.new()
bm.from_mesh(me)

# 1. Remover a gaiola oca obsoleta acima de Z = 0.82m
old_spike_faces = [f for f in bm.faces if any(v.co.z > 0.82 for v in f.verts)]
print(f"Removendo {len(old_spike_faces)} faces da gaiola antiga...")
bmesh.ops.delete(bm, geom=old_spike_faces, context='FACES')

# Limpar vertices soltos
loose_verts = [v for v in bm.verts if len(v.link_faces) == 0]
bmesh.ops.delete(bm, geom=loose_verts, context='VERTS')

# 2. Construir o ráquis central cilíndrico de Z = 0.80m a Z = 1.12m
rachis_steps = 10
rachis_verts = []
for i in range(rachis_steps + 1):
    t = i / float(rachis_steps)
    z = 0.80 + t * 0.32
    radius = 0.009 * (1.0 - t * 0.40)
    ring = []
    for a in range(4):
        ang = a * (math.pi / 2.0)
        v = bm.verts.new((math.cos(ang) * radius, math.sin(ang) * radius, z))
        ring.append(v)
    rachis_verts.append(ring)

for i in range(rachis_steps):
    r0 = rachis_verts[i]
    r1 = rachis_verts[i+1]
    for a in range(4):
        a_next = (a + 1) % 4
        bm.faces.new((r0[a], r0[a_next], r1[a_next], r1[a]))

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
        
        # Inclinação vertical para cima de ~42 graus
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

# 5. Mapear camada UV contínua de 0.0 (solo) a 1.0 (topo da espiga)
bmesh.ops.recalc_face_normals(bm, faces=bm.faces)

uv_layer = bm.loops.layers.uv.verify()
# Obter min e max Z para normalização de UV
all_z = [v.co.z for v in bm.verts]
min_z = min(all_z)
max_z = max(all_z)
height_span = max(max_z - min_z, 0.001)

# Camada de Vertex Colors (Color Layer) para assar gradientes ricos
color_layer = bm.loops.layers.color.verify()

for f in bm.faces:
    for loop in f.loops:
        v = loop.vert
        # UV.y de 1.0 (solo) a 0.0 (topo) alinhado com invert_height = true do trigo
        norm_h = (v.co.z - min_z) / height_span
        # U centrado, V invertido de 1.0 a 0.0
        loop[uv_layer].uv = Vector((0.5, 1.0 - norm_h))
        
        # Color coding:
        # COLOR.r = altura normalizada ou gradiente de luz
        # Grãos da espiga (Z > 0.80): tom dourado rico (0.95, 0.85, 0.3)
        # Fendas e ráquis: tom âmbar mais escuro (0.75, 0.50, 0.1)
        # Caule inferior (Z < 0.80): gradiente de âmbar base para dourado
        if v.co.z > 0.80:
            # Distância ao ráquis central para escurecer as fendas internas
            dist_center = math.sqrt(v.co.x**2 + v.co.y**2)
            crevice_factor = min(dist_center / 0.025, 1.0)
            col_r = 0.70 + 0.30 * crevice_factor
            col_g = 0.55 + 0.35 * crevice_factor
            col_b = 0.10 + 0.25 * crevice_factor
            loop[color_layer] = (col_r, col_g, col_b, 1.0)
        else:
            stem_t = v.co.z / 0.80
            col_r = 0.45 + 0.45 * stem_t
            col_g = 0.30 + 0.45 * stem_t
            col_b = 0.05 + 0.15 * stem_t
            loop[color_layer] = (col_r, col_g, col_b, 1.0)

bm.to_mesh(me)
bm.free()
me.update()

print(f"Malha finalizada: {len(me.vertices)} vertices, {len(me.polygons)} poligonos.")

# 6. Salvar wheat.blend atualizado
bpy.ops.wm.save_mainfile(filepath=blend_path)
print("wheat.blend salvo com sucesso.")

# 7. Exportar glTF canônico para assets/models/wheat_01.glb
# Selecionar apenas o objeto wheat_01
for o in bpy.data.objects:
    o.select_set(False)

wheat.select_set(True)
bpy.context.view_layer.objects.active = wheat

# Forçar materiais limpos com albedo neutro/dourado
mat = bpy.data.materials.get("M_Wheat_Default")
if not mat:
    mat = bpy.data.materials.new("M_Wheat_Default")
mat.use_nodes = True
bsdf = mat.node_tree.nodes.get("Principled BSDF")
bsdf.inputs['Base Color'].default_value = (0.96, 0.77, 0.19, 1.0)
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
