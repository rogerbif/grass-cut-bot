# Sistema de SaveGame e Persistência de Dados 💾🛡️

Este documento detalha o sistema de salvamento contínuo, a estrutura do arquivo de dados, o mecanismo anti-corrupção atômico e a avaliação de estrelas (Star Rating) em **Grass Cut Bot**.

---

## 1. Arquitetura do `SaveManager`

O `SaveManager` opera como um **Autoload global** (`res://scripts/core/save_manager.gd`) com `process_mode = PROCESS_MODE_ALWAYS`, garantindo que salvamentos e carregamentos possam ocorrer mesmo com o jogo pausado.

### Caminhos de Arquivo no Disco:
- **Arquivo Primário:** `user://savegame.json`
- **Arquivo Temporário (Staging):** `user://savegame.tmp`
- **Arquivo de Backup (Resiliência):** `user://savegame.bak`

---

## 2. Escrita Atômica e Mecanismo Anti-Corrupção

Para prevenir perda ou corrupção de dados caso o jogo feche inesperadamente ou fique sem bateria no dispositivo móvel, o salvamento utiliza o padrão atômico em 3 etapas:

1. **Gravação Temporária:** Os dados são serializados e gravados primeiro em `user://savegame.tmp`.
2. **Cópia de Segurança:** O arquivo atual `user://savegame.json` (se existente) é renomeado para `user://savegame.bak`.
3. **Substituição Atômica:** O arquivo temporário `.tmp` é renomeado para `user://savegame.json`.
4. **Fallback Automático no Carregamento:** Se o arquivo primário estiver corrompido ou inacessível, o `SaveManager` carrega automaticamente o backup `.bak`. Caso nenhum exista, gera os dados padrão iniciais.

### Gatilhos de Salvamento Automático:
- Conclusão de fase (`GameManager.level_won`).
- Compra de upgrades na oficina (`UpgradeManager.upgrade_purchased`).
- Modificação de preferências de áudio/vibração no `SettingsModal`.
- Interrupções de ciclo de vida móvel (`NOTIFICATION_APPLICATION_FOCUS_OUT`, `NOTIFICATION_APPLICATION_PAUSED` e `NOTIFICATION_WM_CLOSE_REQUEST`).

---

## 3. Esquema de Dados do Save (`savegame.json`)

```json
{
  "version": "1.0",
  "saved_at": 1729272000,
  "settings": {
    "music_enabled": true,
    "sfx_enabled": true,
    "vib_enabled": true
  },
  "player": {
    "total_coins": 5970,
    "max_unlocked_level": 4,
    "last_played_level": 4
  },
  "upgrades": {
    "blade_level": 3,
    "blade_xp": 45.0,
    "radius_level": 3,
    "power_level": 1,
    "speed_level": 3,
    "multiplier_level": 1
  },
  "levels": {
    "1": {
      "unlocked": true,
      "stars": 3,
      "best_time": 42.5,
      "completed_at": 1729272100
    },
    "2": {
      "unlocked": true,
      "stars": 3,
      "best_time": 55.0,
      "completed_at": 1729272200
    },
    "3": {
      "unlocked": true,
      "stars": 2,
      "best_time": 71.2,
      "completed_at": 1729272300
    },
    "4": {
      "unlocked": true,
      "stars": 0,
      "best_time": 0.0,
      "completed_at": 0
    }
  }
}
```

---

## 4. Avaliação de Estrelas (Star Rating ⭐)

Ao bater todas as metas de corte, o desempenho do jogador no estágio é classificado com base na eficiência temporal em relação ao `time_limit` da fase:

| Classificação | Requisito Temporal | Interpretação no Gameplay |
| :---: | :--- | :--- |
| **⭐⭐⭐ (3 Estrelas)** | Tempo Restante $\ge 50\%$ do limite inicial | Execução perfeita com corte veloz e pouca perda de inércia. |
| **⭐⭐ (2 Estrelas)** | Tempo Restante $\ge 20\%$ do limite inicial | Bom desempenho, conclusão com folga confortável. |
| **⭐ (1 Estrela)** | Tempo Restante $> 0\%$ (dentro do limite) | Conclusão no limite do cronômetro. |

As estrelas conquistadas são salvas persistentemente e renderizadas nos pinos do arquipélago 3D na **Visão Mapa** do Menu Inicial.

---

## 5. Reset de Dados e Recuperação

O `SaveManager` expõe o método `reset_save()` que apaga os registros persistentes, restaura as preferências padrão e notifica todos os subsistemas (`save_reset.emit()`).
Na interface de Configurações (`SettingsModal`), o reset exige dupla confirmação para prevenir apagamento acidental.
