import bpy

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath="assets/models/flower_08_bed_detach.glb")

print("=== OBJETOS CANTEIRO DETACH ===")
for obj in bpy.data.objects:
    if obj.type == 'MESH':
        mesh = obj.data
        z_coords = [v.co.z for v in mesh.vertices]
        print(f"Obj: {obj.name}, Verts: {len(mesh.vertices)}, Z min: {min(z_coords):.3f}, max: {max(z_coords):.3f}")
