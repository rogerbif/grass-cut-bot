# Histórico de Melhorias: 101 - Enquadramento da Câmera de Vitória Idêntico ao Menu Home 🎬🤖

**Data:** 25 de Outubro de 2026  
**Versão:** `v0.12.26-alpha`  
**Escopo:** Câmera 3D de Gameplay (`scripts/camera/isometric_camera.gd`), Game Feel, Transição de Fim de Fase e Consistência Visual com a Home.

---

## 1. Contexto e Motivação

Durante o encerramento vitorioso de uma fase, o Cutter Bot executa uma coreografia de saltos com *squash & stretch*, fogos de artifício e alternância de expressões alegres nos olhos (estrelas e corações), virando o chassi para $+Z$ para comemorar de frente.

No entanto, a câmera isométrica mantinha um enquadramento provisório muito elevado e próximo (`Vector3(0.0, 1.85, 2.85)` com `look_at()` forçado a um pitch íngreme de aproximadamente $-26.6^\circ$). Essa discrepância angular quebrava a continuidade estética com o Menu Principal (Home), onde o robô é apresentado em um ângulo cinematográfico e acolhedor (pitch suave de $-8^\circ$ e offset `(0, 1.25, 4.0)`).

A solicitação exigiu padronizar a câmera de vitória na fase para utilizar rigorosamente o mesmo enquadramento, distância focal, altura e angulação da tela Home.

---

## 2. Parâmetros Canônicos Comparados

| Parâmetro de Câmera | Menu Principal (Home) (`menu_camera.gd`) | Gameplay Vitória Anterior | Novo Gameplay Vitória (`v0.12.26-alpha`) |
| :--- | :--- | :--- | :--- |
| **Offset Relativo** | `Vector3(0.0, 1.25, 4.0)` | `Vector3(0.0, 1.85, 2.85)` | `Vector3(0.0, 1.25, 4.0)` ✅ |
| **Pitch Angular** | `-8.0°` (`Vector3(-8.0, 0, 0)`) | `~ -26.6°` (via `look_at`) | `-8.0°` (`Vector3(-8.0, 0, 0)`) ✅ |
| **Yaw / Roll** | `0.0°` / `0.0°` | `0.0°` / `0.0°` | `0.0°` / `0.0°` ✅ |
| **Campo de Visão (FOV)** | `48.0°` | `48.0°` | `48.0°` ✅ |
| **Transição** | Cúbica Suave (`TRANS_CUBIC`, 0.65s) | Cúbica (`TRANS_CUBIC`, 0.85s) | Cúbica Suave Paralela (`TRANS_CUBIC`, 0.85s) ✅ |

---

## 3. Implementação Técnica

### A. Constantes Canônicas e Controle de Rotação em `isometric_camera.gd`
Adicionadas as constantes espelhadas da Home e a variável de rastreamento de rotação:
```gdscript
const VICTORY_OFFSET: Vector3 = Vector3(0.0, 1.25, 4.0)
const VICTORY_ROTATION: Vector3 = Vector3(-8.0, 0.0, 0.0)

var _current_offset: Vector3 = Vector3(0.0, 7.2, 8.5)
var _current_rotation: Vector3 = Vector3.ZERO
```

### B. Interpolação Simultânea Sem Pop Visual (`transition_to_victory_cam`)
Ao disparar `level_won`, a câmera captura a posição e rotação relativas imediatas e cria um tween simultâneo desacelerado com curva cúbica:
```gdscript
func transition_to_victory_cam() -> void:
	if _in_victory_cam or target == null:
		return
	_in_victory_cam = true
	
	if _victory_tween != null and _victory_tween.is_valid():
		_victory_tween.kill()

	_current_offset = global_position - target.global_position
	_current_rotation = rotation_degrees

	_victory_tween = create_tween().set_parallel(true)
	# Transiciona com suavidade cúbica para o enquadramento e angulação exatos da tela Home
	_victory_tween.tween_property(self, "_current_offset", VICTORY_OFFSET, 0.85).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_victory_tween.tween_property(self, "_current_rotation", VICTORY_ROTATION, 0.85).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
```

### C. Acompanhamento Estável no `_physics_process`
Durante o estado de vitória, a posição da câmera acompanha a posição de mundo do robô somada ao `_current_offset` tweenado, aplicando a rotação `_current_rotation` diretamente sem rotações descontroladas ou oscilações de `look_at()`:
```gdscript
	if _in_victory_cam:
		# Enquadramento heroico idêntico à visão do bot na tela Home (offset 0, 1.25, 4.0 e pitch -8 deg)
		global_position = target.global_position + _current_offset
		rotation_degrees = _current_rotation
		return
```

### D. Restauração Completa em Reinício (`reset_cam`)
Ao transicionar novamente para `GameState.PLAYING`, a câmera restaura imediatamente a orientação isométrica de jogo com `look_at_from_position(target.global_position + offset, target.global_position, Vector3.UP)` e armazena os ângulos em `_current_rotation`.

---

## 4. Validação e Qualidade

1. **Zero Warnings:** Compilação com `--headless --editor --quit` validada com 0 warnings e 0 erros.
2. **Suíte de Testes:** Suíte de persistência e SaveGame aprovada com 100% de sucesso.
3. **Consistência Visual:** A celebração do Cutter Bot na fase possui a mesma perspectiva acolhedora, proporção do robô na tela (hero close-up) e espaço livre na parte superior e inferior para os novos elementos de UI desobstruída (estrelas em arco e bottom bar).
