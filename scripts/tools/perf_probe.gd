extends CanvasLayer
## Sonda de performance (somente debug/teste): exibe FPS, nós, draw calls e tempos de frame.
## Instanciada pela cena scenes/tools/perf_test.tscn; não faz parte do fluxo normal do jogo.

const REFRESH_INTERVAL: float = 0.5

var extra_text: String = ""

var _label: Label
var _accum: float = 0.0
var _frames: int = 0
var _min_fps: float = 9999.0
var _worst_frame_ms: float = 0.0

func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_label = Label.new()
	_label.position = Vector2(12.0, 90.0)
	_label.add_theme_font_size_override("font_size", 18)
	_label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.4, 1.0))
	_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 1.0))
	_label.add_theme_constant_override("outline_size", 6)
	add_child(_label)

func _process(delta: float) -> void:
	_accum += delta
	_frames += 1
	_worst_frame_ms = maxf(_worst_frame_ms, delta * 1000.0)
	if delta > 0.0:
		_min_fps = minf(_min_fps, 1.0 / delta)
	if _accum < REFRESH_INTERVAL:
		return

	var avg_fps: float = float(_frames) / _accum
	var nodes: int = int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	var draw_calls: int = int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	var prims: int = int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))
	var t_process: float = Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
	var t_physics: float = Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0
	var mem_mb: float = Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0

	var txt: String = "FPS %.1f (min %.1f) | pior frame %.1f ms\n" % [avg_fps, _min_fps, _worst_frame_ms]
	txt += "Nós %d | Draw calls %d | Prims %d\n" % [nodes, draw_calls, prims]
	txt += "Process %.2f ms | Physics %.2f ms | Mem %.0f MB" % [t_process, t_physics, mem_mb]
	if extra_text != "":
		txt += "\n" + extra_text
	_label.text = txt

	_accum = 0.0
	_frames = 0
	_min_fps = 9999.0
	_worst_frame_ms = 0.0
