import bpy
import math
import random

def generate_triangle_grass(output_path: str):
    # Limpa a cena do Blender
    bpy.ops.wm.read_factory_settings(use_empty=True)

    mesh = bpy.data.meshes.new("grass_01_mesh")
    obj = bpy.data.objects.new("grass_01", mesh)
    bpy.context.scene.collection.objects.link(obj)

    # 9 lâminas triangulares dispostas em leque
    NUM_BLADES = 9
    
    verts = []
    faces = []
    uvs = []
    colors = []

    # Semente fixa para reproducibilidade exata
    rng = random.Random(42)

    for i in range(NUM_BLADES):
        # Ângulo ao redor do centro do tufo
        base_angle = (i / float(NUM_BLADES)) * math.tau + rng.uniform(-0.12, 0.12)
        
        # Distância da base até o centro do tufo
        radius_base = rng.uniform(0.015, 0.045)
        base_x = math.cos(base_angle) * radius_base
        base_y = math.sin(base_angle) * radius_base

        # Dimensões da lâmina
        height = rng.uniform(0.46, 0.64)
        width = rng.uniform(0.055, 0.075)
        # Profundidade da dobra em V (quina central que gera facetamento cartoon)
        crease_depth = rng.uniform(0.014, 0.022)
        
        # Inclinação suave para fora (tilt radial)
        tilt_factor = rng.uniform(0.08, 0.16)
        tip_offset_x = math.cos(base_angle) * (height * tilt_factor)
        tip_offset_y = math.sin(base_angle) * (height * tilt_factor)

        # Direções ortogonais locais no plano horizontal (Blender XY)
        # dir_fwd aponta para fora do centro do tufo
        dir_fwd_x = math.cos(base_angle)
        dir_fwd_y = math.sin(base_angle)
        # dir_right é perpendicular
        dir_right_x = -math.sin(base_angle)
        dir_right_y = math.cos(base_angle)

        # 4 vértices por lâmina:
        # V0: Base esquerda (Z = 0.0)
        v0 = (
            base_x - dir_right_x * width * 0.5,
            base_y - dir_right_y * width * 0.5,
            0.0
        )
        # V1: Base quina central (levemente empurrada para frente para formar o V) (Z = 0.0)
        v1 = (
            base_x + dir_fwd_x * crease_depth,
            base_y + dir_fwd_y * crease_depth,
            0.0
        )
        # V2: Base direita (Z = 0.0)
        v2 = (
            base_x + dir_right_x * width * 0.5,
            base_y + dir_right_y * width * 0.5,
            0.0
        )
        # V3: Ponta afiada superior (Z = height)
        v3 = (
            base_x + tip_offset_x,
            base_y + tip_offset_y,
            height
        )

        idx_start = len(verts)
        verts.extend([v0, v1, v2, v3])

        # 2 triângulos facetados formando a lâmina em V
        # Face 1: (v0, v1, v3)
        # Face 2: (v1, v2, v3)
        faces.append((idx_start + 0, idx_start + 1, idx_start + 3))
        faces.append((idx_start + 1, idx_start + 2, idx_start + 3))

        # UVs: (u, v) onde v=0 na raiz e v=1 na ponta (essencial para o shader)
        # Face 1 UVs
        uv_f1 = [
            (0.0, 0.0), # V0
            (0.5, 0.0), # V1
            (0.5, 1.0)  # V3
        ]
        # Face 2 UVs
        uv_f2 = [
            (0.5, 0.0), # V1
            (1.0, 0.0), # V2
            (0.5, 1.0)  # V3
        ]
        uvs.append(uv_f1)
        uvs.append(uv_f2)

        # Vertex Colors (atributos assados para o interactive_grass.gdshader)
        # R: phase (0..1)
        # G: angle normalizado ((angle / tau) + 0.5)
        # B: freq (0..1)
        # A: 1.0
        blade_phase = rng.uniform(0.0, 1.0)
        norm_angle = (math.fmod(base_angle, math.tau) / math.tau) * 0.5 + 0.5
        blade_freq = rng.uniform(0.0, 1.0)
        col = (blade_phase, norm_angle, blade_freq, 1.0)

        # 3 vértices por face
        colors.append([col, col, col])
        colors.append([col, col, col])

    # Cria a malha a partir da geometria calculada
    mesh.from_pydata(verts, [], faces)
    mesh.update()

    # Aplica UVs
    uv_layer = mesh.uv_layers.new(name="UVMap")
    loop_idx = 0
    for face_uv in uvs:
        for uv_coords in face_uv:
            uv_layer.data[loop_idx].uv = uv_coords
            loop_idx += 1

    # Aplica Vertex Colors
    color_layer = mesh.color_attributes.new(name="Color", type='FLOAT_COLOR', domain='CORNER')
    loop_idx = 0
    for face_col in colors:
        for c in face_col:
            color_layer.data[loop_idx].color = c
            loop_idx += 1

    # Cria material base com nomes padrão
    mat = bpy.data.materials.new(name="M_Grass")
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    if bsdf:
        bsdf.inputs["Roughness"].default_value = 0.9
        bsdf.inputs["Base Color"].default_value = (0.22, 0.65, 0.28, 1.0)
    obj.data.materials.append(mat)

    # Recalcula normais para facetamento nítido cartoon
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    bpy.ops.object.shade_flat()

    print(f"Malha gerada com sucesso: {len(mesh.vertices)} vértices, {len(mesh.polygons)} polígonos.")

    # Exporta glTF com guardrails (export_apply=True, export_yup=True)
    bpy.ops.export_scene.gltf(
        filepath=output_path,
        export_format='GLB',
        export_apply=True,
        export_yup=True,
        export_materials='EXPORT',
        export_vertex_color='ACTIVE',
        export_all_vertex_colors=True,
        export_attributes=True
    )
    print(f"Exportado com sucesso para {output_path}")

if __name__ == "__main__":
    import sys
    out_file = "assets/models/grass_01.glb"
    generate_triangle_grass(out_file)
