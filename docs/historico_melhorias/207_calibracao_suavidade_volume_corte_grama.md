# Melhoria 207: Calibração de Suavidade e Atenuação do Som de Corte de Grama 🌿🔉

**Data:** 09/11/2026  
**Versão Canônica:** `v0.12.158-alpha`  
**Escopo:** Sonoplastia, Game Feel, Mixagem de Áudio, Conforto Auditivo Mobile.

---

## 1. Contexto & Motivação

Durante o loop principal de gameplay de **Grass Cut Bot**, o cortador ceifa dezenas de tufos de grama em rápida sucessão. O efeito sonoro de corte (`res://assets/audio/sfx/Grass-cut.ogg`) era disparado a `0.0 dB` (ganho total/unitário). 

Em sessões prolongadas de jogo e especialmente ao usar fones de ouvido em dispositivos mobile, o volume elevado do corte contínuo gerava fadiga auditiva e competia desnecessariamente com a trilha sonora de gameplay (`-2.5 dB`) e com os feedbacks sonoros de recompensas de moedas (`-3.5 dB`).

Para conferir uma experiência muito mais relaxante, tátil e suave ("satisfying"), o volume do efeito de corte de grama foi atenuado em 50% em amplitude linear.

---

## 2. Detalhes Técnicos da Calibração

- **Atenuação Matemática (dB):**
  - A redução de 50% em amplitude linear corresponde a:
    $$\Delta\text{dB} = 20 \cdot \log_{10}(0.5) \approx -6.02\,\text{dB}$$
  - O ganho base do player de corte foi calibrado para `-6.0 dB` (anteriormente `0.0 dB`).
- **Arquivos Alterados:**
  - `scripts/core/audio_manager.gd`: No método `play_cut_sfx(is_special)`, o canal padrão de corte de vegetação (`SFX_GRASS_CUT`) agora define `player.volume_db = -6.0`.
  - `docs/04_sistemas_e_gameplay/SISTEMA_DE_AUDIO_E_SFX.md`: Atualizada a documentação de referência canônica com a nova calibração em `-6.0 dB`.

---

## 3. Verificação & Validação

- Testes de áudio automatizados executados via cena dedicada `tests/test_audio_manager.tscn` no Godot Headless 4.7.2 com 100% de sucesso.
- O equilíbrio da mixagem geral garante que a trilha sonora continue audível e o pingo de moedas continue com presença clara, enquanto o corte de grama atua como um feedback textural macio de fundo.
