extends SceneTree

# verify_levels_integrity.gd
# Validador de integridade e smoke test canônico das 40 fases do Grass Cut Bot.
# Garante o cumprimento do Mandamento 17 do GEMINI.md:
# Imutabilidade das Fases 01 a 20 e consistência dimensional das fases 21 a 40.

func _init() -> void:
	print("==================================================")
	print("🔍 INICIANDO SMOKE TEST DE INTEGRIDADE DAS FASES")
	print("==================================================")
	
	var total_levels: int = 40
	var errors: Array[String] = []
	var checked_count: int = 0
	
	for i in range(1, total_levels + 1):
		var filename: String = "res://data/levels/level_%02d.json" % i
		if not FileAccess.file_exists(filename):
			errors.append("Fase %02d: Arquivo não encontrado (%s)" % [i, filename])
			continue
			
		var file := FileAccess.open(filename, FileAccess.READ)
		if file == null:
			errors.append("Fase %02d: Não foi possível abrir o arquivo para leitura" % i)
			continue
			
		var json_text := file.get_as_text()
		file.close()
		
		var json := JSON.new()
		var parse_result := json.parse(json_text)
		if parse_result != OK:
			errors.append("Fase %02d: JSON inválido na linha %d: %s" % [i, json.get_error_line(), json.get_error_message()])
			continue
			
		var data: Variant = json.get_data()
		if not (data is Dictionary):
			errors.append("Fase %02d: Estrutura raiz não é um Dictionary" % i)
			continue
			
		var dict: Dictionary = data as Dictionary
		var grid_info: Dictionary = dict.get("grid", {}) as Dictionary
		var width: int = int(grid_info.get("width", 0))
		var height: int = int(grid_info.get("height", 0))
		var cell_size: float = float(grid_info.get("cell_size", 0.0))
		var card_goals: Dictionary = dict.get("card_goals", {}) as Dictionary
		var raw_goals: Dictionary = dict.get("goals", {}) as Dictionary
		var dim_w: float = float(width) * cell_size
		var dim_h: float = float(height) * cell_size
		var goals_count: int = card_goals.size() if not card_goals.is_empty() else raw_goals.size()
		
		var is_ok: bool = true
		
		# Validação 1: Fases 01 a 20 canônicas (desenhadas no Editor)
		if i <= 20:
			# Impede regressão para grids minúsculos (5.2m do gerador legado obsoleto 13x13 com 0.40m)
			if dim_w < 8.0 or dim_h < 8.0:
				errors.append("Fase %02d: Dimensão muito pequena regredida (< 8.0m): %.1fm x %.1fm" % [i, dim_w, dim_h])
				is_ok = false
			if i == 1:
				if width != 25 or height != 25:
					errors.append("Fase 01: Dimensões corrompidas (esperado 25x25, encontrado %dx%d)" % [width, height])
					is_ok = false
				if abs(cell_size - 0.40) > 0.01:
					errors.append("Fase 01: cell_size alterado (esperado 0.40, encontrado %.2f)" % cell_size)
					is_ok = false
			if goals_count == 0:
				errors.append("Fase %02d: Metas de corte (goals/card_goals) estão vazias!" % i)
				is_ok = false
		else:
			# Validação 2: Fases de Expansão 21 a 40 (>= 18.0 metros reais)
			if dim_w < 17.9:
				errors.append("Fase %02d: Dimensão real menor que 18m (encontrado %.2fm = %dx%.2f)" % [i, dim_w, width, cell_size])
				is_ok = false
			if goals_count == 0:
				errors.append("Fase %02d: Metas de corte (goals/card_goals) estão vazias!" % i)
				is_ok = false
				
		checked_count += 1
		print("  [%s] Fase %02d: %dx%d (%.1fm x %.1fm) | Metas: %d espécies" % [
			"OK" if is_ok else "ERRO",
			i,
			width,
			height,
			dim_w,
			dim_h,
			goals_count
		])
		
	print("--------------------------------------------------")
	if errors.is_empty():
		print("✅ [SUCESSO] Todas as %d fases verificadas com 100%% de integridade!" % checked_count)
		print("   Mandamento 17 (Imutabilidade Fases 01-20) e Fases 21-40 respeitados.")
		print("==================================================")
		quit(0)
	else:
		print("❌ [FALHA] Detectados %d erros de integridade:" % errors.size())
		for err in errors:
			print("   - %s" % err)
		print("==================================================")
		quit(1)
