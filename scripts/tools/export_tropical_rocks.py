import bpy
import bmesh
import math
from mathutils import Matrix, Vector

BLEND_PATH = "C:/Users/User/OneDrive/Documentos/3D_Blender/plants1.blend"

# Catálogo das 5 novas rochas a exportar a partir de plants1.blend
ROCKS_CONFIG = [
    {
        "source_name": "RBg1_GRADIENT_0",
        "output_path": "assets/models/rock_moss.glb",
        "target_width": 0.70,
        "type": "moss",
        "stone_color": (0.28, 0.31, 0.36),     # Ardósia tropical profunda
        "moss_color": (0.16, 0.68, 0.22)       # Verde esmeralda vivo tropical
    },
    {
        "source_name": "RB3_GRADIENT_0",
        "output_path": "assets/models/rock_spire.glb",
        "target_width": 0.68,
        "type": "slate",
        "stone_color": (0.30, 0.33, 0.38),     # Ardósia monólito
        "moss_color": None
    },
    {
        "source_name": "RBg3_GRADIENT_0",
        "output_path": "assets/models/rock_moss_spire.glb",
        "target_width": 0.68,
        "type": "moss",
        "stone_color": (0.28, 0.31, 0.36),
        "moss_color": (0.16, 0.68, 0.22)
    },
    {
        "source_name": "RG1_GRADIENT_0",
        "output_path": "assets/models/rock_sandstone.glb",
        "target_width": 0.72,
        "type": "sandstone",
        "stone_color": (0.85, 0.50, 0.26),     # Terracota arenito solar quente
        "moss_color": None
    },
    {
        "source_name": "RB2_GRADIENT_0",
        "output_path": "assets/models/rock_boulder.glb",
        "target_width": 0.70,
        "type": "slate",
        "stone_color": (0.26, 0.29, 0.34),     # Basalto costeiro polido
        "moss_color": None
    }
]

def export_all_rocks():
    for cfg in ROCKS_CONFIG:
        bpy.ops.wm.read_factory_settings(use_empty=True)
        bpy.ops.wm.open_mainfile(filepath=BLEND_PATH)

        src_obj = bpy.data.objects.get(cfg["source_name"])
        if not src_obj:
            print(f"ERRO: Objeto {cfg['source_name']} não encontrado!")
            continue

        # Desvincular de pais mantendo a orientação de mundo original
        mw = src_obj.matrix_world.copy()
        src_obj.parent = None
        src_obj.matrix_world = mw
        bpy.context.view_layer.update()

        # Isolar apenas este objeto: deletar todos os outros
        for o in list(bpy.data.objects):
            if o != src_obj:
                bpy.data.objects.remove(o, do_unlink=True)

        # Aplicar transformação de rotação mantendo a orientação anatômica ereta
        bpy.context.view_layer.objects.active = src_obj
        src_obj.select_set(True)
        bpy.ops.object.transform_apply(location=False, rotation=True, scale=False)

        # Obter dimensões horizontais atuais
        verts_co = [v.co for v in src_obj.data.vertices]
        min_x = min(v.x for v in verts_co)
        max_x = max(v.x for v in verts_co)
        min_y = min(v.y for v in verts_co)
        max_y = max(v.y for v in verts_co)
        current_width = max(max_x - min_x, max_y - min_y)
        scale_fac = cfg["target_width"] / max(current_width, 0.001)

        # Aplicar escala uniforme
        m_scale = Matrix.Diagonal((scale_fac, scale_fac, scale_fac, 1.0))
        src_obj.matrix_world = m_scale @ src_obj.matrix_world
        bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)

        # Centralizar em X=0, Y=0 e assentar base exatamente em Z=0.0
        verts_co = [v.co for v in src_obj.data.vertices]
        min_x = min(v.x for v in verts_co)
        max_x = max(v.x for v in verts_co)
        min_y = min(v.y for v in verts_co)
        max_y = max(v.y for v in verts_co)
        min_z = min(v.z for v in verts_co)

        center_offset = Vector((-(min_x + max_x) * 0.5, -(min_y + max_y) * 0.5, -min_z))
        for v in src_obj.data.vertices:
            v.co += center_offset
        src_obj.data.update()

        # Resetar e aplicar localização para garantir pivô limpo na origem (0, 0, 0)
        src_obj.location = (0.0, 0.0, 0.0)
        src_obj.rotation_euler = (0.0, 0.0, 0.0)
        src_obj.scale = (1.0, 1.0, 1.0)
        bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)

        # Inspecionar UVs e identificar faces de musgo se aplicável
        has_moss = (cfg["type"] == "moss")
        mat = src_obj.data.materials[0] if len(src_obj.data.materials) > 0 else None
        img = None
        pixels = None
        img_w, img_h = (256, 256)
        if mat and mat.node_tree:
            for n in mat.node_tree.nodes:
                if n.type == 'TEX_IMAGE' and n.image:
                    img = n.image
                    pixels = list(img.pixels)
                    img_w, img_h = img.size
                    break

        uv_layer = src_obj.data.uv_layers.active.data if src_obj.data.uv_layers.active else None

        # Limpar todos os atributos de cor legados
        while len(src_obj.data.color_attributes) > 0:
            src_obj.data.color_attributes.remove(src_obj.data.color_attributes[0])

        color_attr = src_obj.data.color_attributes.new(name="Color", type='FLOAT_COLOR', domain='CORNER')

        z_coords = [v.co.z for v in src_obj.data.vertices]
        z_min = min(z_coords)
        z_max = max(z_coords)
        z_range = max(z_max - z_min, 0.001)

        stone_base = cfg["stone_color"]
        moss_col = cfg["moss_color"]

        moss_count = 0
        for poly in src_obj.data.polygons:
            is_face_moss = False
            if has_moss and uv_layer and pixels:
                first_loop = poly.loop_indices[0]
                uv = uv_layer[first_loop].uv
                px = int(uv.x * img_w) % img_w
                py = int(uv.y * img_h) % img_h
                idx = (py * img_w + px) * 4
                g_val = pixels[idx + 1]
                r_val = pixels[idx]
                if g_val > r_val + 0.08 and g_val > 0.30:
                    is_face_moss = True
                    moss_count += 1

            for loop_idx in poly.loop_indices:
                vert_idx = src_obj.data.loops[loop_idx].vertex_index
                v_z = src_obj.data.vertices[vert_idx].co.z
                height_t = (v_z - z_min) / z_range
                shade = 0.72 + 0.28 * height_t

                if is_face_moss and moss_col:
                    r = moss_col[0] * shade
                    g = moss_col[1] * shade
                    b = moss_col[2] * shade
                else:
                    r = stone_base[0] * shade
                    g = stone_base[1] * shade
                    b = stone_base[2] * shade

                color_attr.data[loop_idx].color = (r, g, b, 1.0)

        print(f"Objeto {cfg['source_name']}: total polys={len(src_obj.data.polygons)}, moss_polys={moss_count}")

        src_obj.data.color_attributes.active_color = color_attr
        src_obj.data.update()

        # Material conectado com Vertex Color para o glTF (Mandamento 13)
        clean_mat = bpy.data.materials.new(name="Mat_Rock")
        clean_mat.use_nodes = True
        bsdf = clean_mat.node_tree.nodes.get("Principled BSDF")
        col_node = clean_mat.node_tree.nodes.new(type="ShaderNodeVertexColor")
        col_node.layer_name = "Color"
        clean_mat.node_tree.links.new(col_node.outputs["Color"], bsdf.inputs["Base Color"])
        bsdf.inputs["Roughness"].default_value = 0.95
        src_obj.data.materials.clear()
        src_obj.data.materials.append(clean_mat)

        # Renomear malha para padrão
        src_obj.name = "rock_export"

        # Exportar glTF
        bpy.ops.export_scene.gltf(
            filepath=cfg["output_path"],
            export_format='GLB',
            export_apply=True,
            export_yup=True,
            export_vertex_color='ACTIVE'
        )
        print(f"✅ Exportado com sucesso: {cfg['output_path']}")

export_all_rocks()
