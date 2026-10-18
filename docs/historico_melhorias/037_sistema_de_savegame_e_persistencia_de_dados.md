# Melhoria 037: Sistema de SaveGame, Persistência Resiliente e Avaliação de Estrelas 💾⭐

Este documento detalha o desenvolvimento e integração do **Sistema de SaveGame e Persistência de Dados** do **Grass Cut Bot**, garantindo armazenamento seguro e automático de progresso de fases, avaliação de estrelas (1 a 3), histórico de moedas, melhorias da oficina mecânica e preferências de áudio/vibração do usuário.

---

## 1. Contexto e Motivação

Até a versão anterior, o jogo não possuía camada de persistência local em disco. Moedas obtidas, upgrades comprados na oficina, fases liberadas no arquipélago 3D e opções de áudio e vibração eram reinicializados a cada fechamento do aplicativo.

Além disso, o arquipélago 3D utilizava regras "mock" de fases desbloqueadas e estrelas fictícias. Havia a necessidade de:
1. Criar um **SaveManager** desacoplado via Autoload global com escrita atômica contra quedas de bateria/app no mobile.
2. Manter backup automático de segurança (`user://savegame.bak`) com recuperação transparente caso o JSON principal seja corrompido.
3. Implementar o sistema real de avaliação de 1 a 3 estrelas (Star Rating) baseado no tempo restante de fase.
4. Integrar o arquipélago 3D do Menu Principal para refletir com fidelidade as ilhas desbloqueadas e as estrelas reais conquistadas.
5. Persistir opções de áudio e feedback tátil (haptics) e disponibilizar um botão de reset total com dupla confirmação no modal de configurações.

---

## 2. Arquitetura do `SaveManager` (`res://scripts/core/save_manager.gd`)

O `SaveManager` foi registrado como o primeiro Autoload do motor em `project.godot`:

```ini
[autoload]

SaveManager="*res://scripts/core/save_manager.gd"
GameManager="*res://scripts/core/game_manager.gd"
UpgradeManager="*res://scripts/core/upgrade_manager.gd"
```

### 2.1 Estrutura Serializada (`user://savegame.json`)

```json
{
	"version": "1.0",
	"saved_at": 1729278000,
	"settings": {
		"music_enabled": true,
		"sfx_enabled": true,
		"vib_enabled": true
	},
	"player": {
		"total_coins": 250,
		"max_unlocked_level": 4,
		"last_played_level": 1
	},
	"upgrades": {
		"radius_level": 2,
		"power_level": 1,
		"speed_level": 2,
		"multiplier_level": 1
	},
	"levels": {
		"1": {
			"completed": true,
			"stars": 3,
			"best_time_left": 55.0,
			"high_score_coins": 80
		}
	}
}
```

### 2.2 Escrita Atômica Anti-Corrupção e Backup Contínuo

Para evitar que o arquivo de dados seja corrompido em caso de fechamento forçado ou queda de energia no Android:
1. Os dados JSON são gravados primeiramente em arquivo temporário `user://savegame.tmp`.
2. Se o arquivo `user://savegame.json` atual existir, seu conteúdo é espelhado no backup `user://savegame.bak`.
3. Os dados válidos são consolidados no `user://savegame.json` e o `.tmp` é purgado.
4. Caso a leitura do JSON falhe por erro de sintaxe, o sistema automaticamente busca o `.bak` e restaura a sessão anterior sem falhas ou perda de progresso.

---

## 3. Critério de Estrelas e Registro de Vitória

Integrado ao ciclo de vitória em `GameManager.gd` (`_check_victory()`):

$$\text{Taxa de Sobra} = \frac{\text{Tempo Restante}}{\text{Tempo Limite da Fase}}$$

- ⭐ **1 Estrela:** Vitória garantida ao bater todas as metas dentro do tempo.
- ⭐⭐ **2 Estrelas:** $\text{Taxa de Sobra} \ge 25\%$ do tempo total.
- ⭐⭐⭐ **3 Estrelas:** $\text{Taxa de Sobra} \ge 50\%$ do tempo total (*Desempenho Mestre*).

Os recordes são cumulativos: jogar uma fase novamente nunca reduz o número de estrelas já conquistadas (`maxi(prev_stars, stars)`).

---

## 4. Integrações nos Menus e HUD

1. **Top HUD & Victory Modal (`hud.gd` e `hud.tscn`):**
   - Novo nó `StarsLabel` no painel de vitória exibindo graficamente o resultado (ex: `⭐⭐⭐` ou `⭐⭐☆`).
   - Sinal `GameManager.level_won(coins_earned, stars_earned)`.

2. **Arquipélago do Menu Principal (`main_menu.gd`):**
   - Ilhas bloqueadas exibem o cadeado `🔒` e ignoram cliques.
   - Ilhas desbloqueadas mostram a numeração e as estrelas reais (`SaveManager.get_level_stars(i)`).
   - Inicia focado na última fase jogada (`last_played_level`).

3. **Modal de Configurações (`settings_modal.gd`):**
   - Chaves de Áudio (Música e FX) e Vibração restauradas a partir do save.
   - `GameManager` respeita `vib_enabled` antes de emitir pulsos táteis (`Input.vibrate_handheld`).
   - Botão **Salvar Localmente** grava os dados sob demanda e exibe toast de confirmação.
   - Botão **Resetar Progresso** com confirmação preventiva de 2 etapas (temporizador de 4s para evitar exclusões acidentais).

---

## 5. Verificação e Testes Automatizados

Foi desenvolvido o script `tests/test_save_manager.gd` e executado diretamente no motor Godot 4.7.1, validando:
- [x] Teste 1: Valores padrão puros e reset geral.
- [x] Teste 2: Getters e Setters de configurações.
- [x] Teste 3: Curva de estrelas (1, 2 e 3) e avanço de destravamento de fases.
- [x] Teste 4: Gravação atômica em disco e recarga íntegra.
- [x] Teste 5: Recuperação automática e resiliência via backup (`.bak`) após injeção proposital de JSON quebrado.
- [x] Zero warnings e zero erros na inicialização de `main_menu.tscn`.
