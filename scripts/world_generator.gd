extends MeshInstance3D
class_name WorldGenerator

## Grid resolution. Higher values add detail but cost more to generate.
@export_range(32, 256, 8) var resolution: int = 160
@export_range(40.0, 240.0, 10.0) var world_size: float = 120.0
@export_range(2.0, 40.0, 1.0) var height_scale: float = 20.0

var current_seed: int = 1


func generate_world(seed_value: int) -> void:
	current_seed = seed_value
	var noise := FastNoiseLite.new()
	noise.seed = seed_value
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise.fractal_octaves = 5
	noise.fractal_lacunarity = 2.0
	noise.fractal_gain = 0.48
	noise.frequency = 0.018

	var detail := FastNoiseLite.new()
	detail.seed = seed_value + 7919
	detail.noise_type = FastNoiseLite.TYPE_SIMPLEX
	detail.fractal_type = FastNoiseLite.FRACTAL_FBM
	detail.fractal_octaves = 3
	detail.frequency = 0.065

	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_material(_terrain_material())

	var half_size := world_size * 0.5
	var step_size := world_size / float(resolution - 1)

	for z in range(resolution):
		for x in range(resolution):
			var px := -half_size + float(x) * step_size
			var pz := -half_size + float(z) * step_size
			var broad := noise.get_noise_2d(px, pz)
			var fine := detail.get_noise_2d(px, pz)
			var edge_distance := max(abs(px), abs(pz)) / half_size
			var island_falloff := clamp(1.0 - pow(edge_distance, 3.2), 0.0, 1.0)
			var elevation := (broad * 0.82 + fine * 0.18) * height_scale
			elevation = elevation * island_falloff - 1.5
			var position := Vector3(px, elevation, pz)
			surface.set_color(_terrain_color(elevation))
			surface.add_vertex(position)

	for z in range(resolution - 1):
		for x in range(resolution - 1):
			var top_left := z * resolution + x
			var top_right := top_left + 1
			var bottom_left := top_left + resolution
			var bottom_right := bottom_left + 1
			surface.add_index(top_left)
			surface.add_index(bottom_left)
			surface.add_index(top_right)
			surface.add_index(top_right)
			surface.add_index(bottom_left)
			surface.add_index(bottom_right)

	surface.generate_normals()
	mesh = surface.commit()
	create_trimesh_collision()


func _terrain_material() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.roughness = 0.96
	return material


func _terrain_color(height: float) -> Color:
	if height < -1.0:
		return Color(0.76, 0.70, 0.49)
	if height < 2.0:
		return Color(0.31, 0.48, 0.28)
	if height < 7.0:
		return Color(0.24, 0.39, 0.23)
	if height < 12.0:
		return Color(0.36, 0.37, 0.34)
	return Color(0.82, 0.83, 0.80)
