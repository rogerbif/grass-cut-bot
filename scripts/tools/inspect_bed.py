import bpy

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath="assets/models/flower_08_bed.glb")

print("=== OBJETOS CANTEIRO ===")
for obj in bpy.data.objects:
    if obj.type == 'MESH':
        mesh = obj.data
        z_coords = [v.co.z for v in mesh.vertices]
        print(f"Obj: {obj.name}, Verts: {len(mesh.vertices)}, Z min: {min(z_coords):.3f}, max: {max(z_coords):.3f}")
        ca = mesh.color_attributes[0] if mesh.color_attributes else None
        if ca:
            alphas = [ca.data[i].color[3] for i in range(len(ca.data))]
            print(f"  Alpha min: {min(alphas):.3f}, max: {max(alphas):.3f}")
