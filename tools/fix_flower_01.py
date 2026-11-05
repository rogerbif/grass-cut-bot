"""Ajusta o modelo flower_01.glb (Flor Silvestre) corrigindo:
1. Miolos (Island 8 e Island 17) com G=1.0 (centro amarelo) e R=0.0 (permanecem nos hits 1 e 2).
2. Pétalas com G=0.0, alternando entre externas (R=0.5, hit 1) e internas (R=1.0, hit 2).
3. Pétalas de desprendimento do hit 1 (Island 0 e Island 2) com B=1.0 e R=0.5.
4. Gradiente de pétala via COLOR.a: base interna da pétala = 0.0 (mais escura) -> ponta = 1.0 (mais clara).
"""
import bpy
import bmesh
import math
import mathutils

def main():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath="assets/models/flower_01.glb")

    petals_obj = bpy.data.objects.get("Flower_Petals")
    if not petals_obj:
        print("ERRO: Flower_Petals nao encontrado")
        return

    me = petals_obj.data
    bm = bmesh.new()
    bm.from_mesh(me)

    islands = []
    seen = set()
    for f in bm.faces:
        if f in seen:
            continue
        isl = []
        q = [f]
        seen.add(f)
        while q:
            curr = q.pop()
            isl.append(curr)
            for e in curr.edges:
                for nxt in e.link_faces:
                    if nxt not in seen:
                        seen.add(nxt)
                        q.append(nxt)
        islands.append(isl)

    print(f"Total de ilhas em Flower_Petals: {len(islands)}")

    # Ilhas de centro
    isl_center_main = 8
    isl_center_small = 17

    cA = sum((f.calc_center_median() for f in islands[isl_center_main]), mathutils.Vector()) / len(islands[isl_center_main])
    cB = sum((f.calc_center_median() for f in islands[isl_center_small]), mathutils.Vector()) / len(islands[isl_center_small])

    ext_main = {0, 2, 7, 3}
    int_main = {1, 6, 5, 4}

    ext_small = {13, 11, 16, 14}
    int_small = {12, 10, 15, 9}

    # Mapa de face_index -> lista de (loop_index, vert_co)
    face_loops = {}
    for p in me.polygons:
        face_loops[p.index] = [(li, me.vertices[me.loops[li].vertex_index].co) for li in p.loop_indices]

    ca = me.color_attributes.get("Color")
    if not ca:
        ca = me.color_attributes.new(name="Color", type="FLOAT_COLOR", domain="CORNER")

    print(f"Atualizando ca.data ({len(ca.data)} entradas)...")

    for i, isl in enumerate(islands):
        is_center = (i == isl_center_main or i == isl_center_small)
        if is_center:
            for f in isl:
                for li, _ in face_loops[f.index]:
                    ca.data[li].color = (0.0, 1.0, 0.0, 1.0)
        else:
            is_main = i < 8
            center = cA if is_main else cB
            is_ext = (i in ext_main) if is_main else (i in ext_small)
            is_detach = (i in (0, 2)) if is_main else False

            r = 0.5 if is_ext else 1.0
            g = 0.0
            b = 1.0 if is_detach else 0.0

            # Distancias dos vertices desta ilha
            all_verts = set(v for f in isl for v in f.verts)
            dists = {v.index: (v.co - center).length for v in all_verts}
            d_min = min(dists.values())
            d_max = max(dists.values())
            span = max(d_max - d_min, 1e-5)

            for f in isl:
                for li, co in face_loops[f.index]:
                    v_idx = me.loops[li].vertex_index
                    d = dists[v_idx]
                    t = max(0.0, min(1.0, (d - d_min) / span))
                    ca.data[li].color = (r, g, b, t)

    bm.free()

    # Exportar
    bpy.ops.export_scene.gltf(
        filepath="assets/models/flower_01.glb",
        export_format="GLB",
        use_selection=False,
        export_apply=True,
        export_yup=True,
        export_vertex_color="ACTIVE",
    )
    print("flower_01.glb exportado com sucesso com novas cores!")

if __name__ == "__main__":
    main()
