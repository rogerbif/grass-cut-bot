import bpy
import sys

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath="assets/models/flower_07_tulip.glb")

print("=== OBJETOS TULIPA ===")
for obj in bpy.data.objects:
    print(f"Obj: {obj.name}, type: {obj.type}")
    if obj.type == 'MESH':
        mesh = obj.data
        has_vc = len(mesh.color_attributes) > 0
        print(f"  Verts: {len(mesh.vertices)}, Color attributes: {[c.name for c in mesh.color_attributes]}")
        if has_vc:
            ca = mesh.color_attributes[0]
            # Print sample colors (r, g, b, a)
            colors = [ca.data[i].color for i in range(min(5, len(ca.data)))]
            print(f"  Sample colors: {[(round(c[0],2), round(c[1],2), round(c[2],2), round(c[3],2)) for c in colors]}")
            # Min and max of alpha
            alphas = [ca.data[i].color[3] for i in range(len(ca.data))]
            print(f"  Alpha min: {min(alphas)}, max: {max(alphas)}")
