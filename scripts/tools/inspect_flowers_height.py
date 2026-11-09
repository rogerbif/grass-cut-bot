import bpy
import mathutils

for fname in ["flower_02_rose.glb", "flower_03_daisy.glb", "flower_04_sunflower.glb", "flower_07_tulip.glb"]:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath="assets/models/" + fname)
    zs = []
    for obj in bpy.data.objects:
        if obj.type == 'MESH':
            zs.extend([v.co.z for v in obj.data.vertices])
    print(f"{fname}: Z min {min(zs):.3f} to {max(zs):.3f}")
