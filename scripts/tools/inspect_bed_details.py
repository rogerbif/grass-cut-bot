import bpy
import mathutils

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath="assets/models/flower_08_bed.glb")

for obj in bpy.data.objects:
    if obj.type == 'MESH':
        print(f"--- {obj.name} ---")
        for i, m in enumerate(obj.data.materials):
            print(f"  Mat {i}: {m.name}")
        # Bounding box
        bbox = [obj.matrix_world @ mathutils.Vector(corner) for corner in obj.bound_box]
        print(f"  BBox Z: {min(b.z for b in bbox):.3f} to {max(b.z for b in bbox):.3f}")
        print(f"  BBox X: {min(b.x for b in bbox):.3f} to {max(b.x for b in bbox):.3f}")
        print(f"  BBox Y: {min(b.y for b in bbox):.3f} to {max(b.y for b in bbox):.3f}")
