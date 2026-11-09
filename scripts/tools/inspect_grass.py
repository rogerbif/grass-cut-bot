import bpy
import mathutils

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath="assets/models/grass_01.glb")

for obj in bpy.data.objects:
    if obj.type == 'MESH':
        bbox = [mathutils.Vector(corner) for corner in obj.bound_box]
        print(f"Grass {obj.name}: Z min {min(b.z for b in bbox):.3f} to {max(b.z for b in bbox):.3f}")
