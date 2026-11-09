import bpy

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath="assets/models/flower_07_tulip.glb")

petals = bpy.data.objects.get("Flower_Petals")
if petals:
    mesh = petals.data
    z_coords = [v.co.z for v in mesh.vertices]
    print(f"Petals Z min: {min(z_coords):.3f}, max: {max(z_coords):.3f}, diff: {max(z_coords) - min(z_coords):.3f}")
    ca = mesh.color_attributes[0]
    for i in range(10):
        v_idx = mesh.loops[i].vertex_index
        co = mesh.vertices[v_idx].co
        col = ca.data[i].color
        print(f"Loop {i}: Vert {v_idx} z={co.z:.3f} col=({col[0]:.2f}, {col[1]:.2f}, {col[2]:.2f}, {col[3]:.2f})")
