import bpy

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath="assets/models/wheat_01.glb")

print("=== OBJETOS TRIGO ===")
for obj in bpy.data.objects:
    if obj.type == 'MESH':
        mesh = obj.data
        print(f"Obj: {obj.name}, Verts: {len(mesh.vertices)}, Materials: {[m.name for m in mesh.materials]}")
        print(f"  Color attributes: {[c.name for c in mesh.color_attributes]}")
        print(f"  UV layers: {[u.name for u in mesh.uv_layers]}")
        z_coords = [v.co.z for v in mesh.vertices]
        print(f"  Z min: {min(z_coords):.3f}, max: {max(z_coords):.3f}")
