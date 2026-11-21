import bpy
import os

models_dir = r"C:\Users\User\OneDrive\Documentos\grass-cut-bot\assets\models"
files = ["flower_02_rose.glb", "flower_03_daisy.glb", "flower_04_sunflower.glb"]

print("--- OTIMIZACAO DE FLORES NOBRES VIA BLENDER ---")

for f in files:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    glb_path = os.path.join(models_dir, f)
    bpy.ops.import_scene.gltf(filepath=glb_path)
    
    total_verts_before = 0
    total_faces_before = 0
    
    mesh_objs = [obj for obj in bpy.context.scene.objects if obj.type == 'MESH']
    for obj in mesh_objs:
        total_verts_before += len(obj.data.vertices)
        total_faces_before += len(obj.data.polygons)
        
        # Otimiza pétalas densas
        if "Petal" in obj.name or len(obj.data.vertices) > 500:
            current_v = len(obj.data.vertices)
            ratio = 320.0 / float(current_v)
            if ratio < 1.0:
                mod = obj.modifiers.new(name="Decimate", type='DECIMATE')
                mod.ratio = max(0.18, ratio)
                mod.use_collapse_triangulate = True
                bpy.context.view_layer.objects.active = obj
                bpy.ops.object.modifier_apply(modifier=mod.name)
        # Otimiza folhas se excessivas
        elif "Leave" in obj.name and len(obj.data.vertices) > 250:
            current_v = len(obj.data.vertices)
            ratio = 160.0 / float(current_v)
            mod = obj.modifiers.new(name="Decimate", type='DECIMATE')
            mod.ratio = ratio
            mod.use_collapse_triangulate = True
            bpy.context.view_layer.objects.active = obj
            bpy.ops.object.modifier_apply(modifier=mod.name)
            
    total_verts_after = 0
    total_faces_after = 0
    for obj in mesh_objs:
        total_verts_after += len(obj.data.vertices)
        total_faces_after += len(obj.data.polygons)
        
    print(f"{f}: Vertices {total_verts_before} -> {total_verts_after} (-{(1.0 - total_verts_after/total_verts_before)*100:.1f}%), Faces {total_faces_before} -> {total_faces_after}")
    
    # Seleciona todos os objetos para export
    for obj in bpy.data.objects:
        obj.select_set(True)
    
    # Exporta glTF canônico respeitando Mandamento 12
    bpy.ops.export_scene.gltf(
        filepath=glb_path,
        export_apply=True,
        export_yup=True,
        export_format='GLB'
    )
    print(f"Salvo: {glb_path}")

print("OTIMIZACAO DE FLORES CONCLUIDA COM SUCESSO!")
