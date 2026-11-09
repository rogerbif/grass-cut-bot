import bpy

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath="assets/models/flower_08_bed.glb")

stem = bpy.data.objects.get("Flower_Stem")
petals = bpy.data.objects.get("Flower_Petals")
leaves = bpy.data.objects.get("Flower_Leaves")

print("STEM vertices count:", len(stem.data.vertices))
for v in stem.data.vertices[:10]:
    print(f"  v {v.index}: ({v.co.x:.3f}, {v.co.y:.3f}, {v.co.z:.3f})")

print("PETALS vertices count:", len(petals.data.vertices))
for v in petals.data.vertices[:10]:
    print(f"  v {v.index}: ({v.co.x:.3f}, {v.co.y:.3f}, {v.co.z:.3f})")
