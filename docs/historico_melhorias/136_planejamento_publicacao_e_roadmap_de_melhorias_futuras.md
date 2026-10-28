# Melhoria 136: Planejamento Estratégico de Publicação, Dimensionamento de Fases e Consolidação do Roadmap 📋🚀

## 1. Resumo Executivo
- **Solicitação do Usuário:** "Qual próximos passos de melhoria para o nosso game, quantas fases acha que sejam necessárias para publicar" seguido por "Primeiro coloque todas as sugestões em melhorias futuras e atualize a documentação".
- **Objetivo:** Estabelecer a estratégia oficial de publicação para o mercado mobile (Google Play Store e App Store), dimensionar a quantidade necessária de fases por marco (MVP vs Lançamento Global), mapear todos os próximos passos de melhoria categorizados em 4 pilares e sincronizar toda a documentação canônica do projeto.
- **Resultado:**
  - **Dimensionamento de Fases Estabelecido:**
    - **MVP / Soft Launch:** 20 fases (escopo atual 100% completo, balanceado e com suporte ao Ciclo Mestre para retenção infinita).
    - **Lançamento Global Oficial (Full Release):** 30 a 40 fases (garantindo entre 1h e 1h30 de jogabilidade única antes do New Game+).
    - **Live-Ops:** 50+ fases (atualizações sazonais e mundos temáticos).
  - **4 Pilares de Melhorias Consolidados:**
    1. *Metagame & Coleção:* Herbário Botânico interativo na `TabCollection` e Pinturas de Chassi (Skins) na Oficina/Loja.
    2. *Variabilidade de Biomas (Custo Zero de Performance):* 4 mundos temáticos (Jardim Tropical, Golden Hour / Pôr do Sol, Noite Estrelada e Outono Dourado) modulados por sky, luz e cor de mar.
    3. *Gameplay Dinâmico & Gimmicks:* Power-ups de campo (Turbo Nitro, Ímã de Moedas, Sobrecarga Relâmpago) e Rochas Rachadas destrutíveis por lâminas de alto Tier.
    4. *Pipeline de Lojas & Android:* Testes em hardware real (60 FPS e haptics em `Input.vibrate_handheld(15)`), kit de screenshots 9:16 e feature graphic 1024x500.

---

## 2. Detalhes do Planejamento e Estratégia

### A. Análise de Retenção e Fases para Publicação
No segmento de jogos hiper-casuais e arcades mobile, um soft launch com 20 fases é amplamente aceito para medir retenção D1 (Day 1) e D7 (Day 7). Graças à implementação prévia do **Ciclo Mestre**, o jogador que conclui a Fase 20 reinicia na Fase 1 mantendo todas as moedas e upgrades da lâmina, impedindo bloqueios de conteúdo. Para o lançamento comercial definitivo, a expansão para 30 a 40 fases consolida a narrativa de progressão através de 4 biomas atmosféricos distintos.

### B. O Herbário Botânico (`TabCollection`)
Transformação da aba ociosa em uma enciclopédia viva de exploração vegetal:
- 7 variantes cosméticas de grama comum.
- Trigo maduro de 2 hits.
- 6 espécies nobres de flores com despetalação progressiva.
- Métricas acumuladas de tufos ceifados por espécie e conquistas com recompensas em moedas.

### C. Variação Atmosférica sem Perda de Performance
Em vez de recriar geometrias pesadas, a variedade visual dos mundos explora parâmetros globais da Godot 4:
- Fases 01 a 10: Sol alto, céu ciano vibrante e mar turquesa.
- Fases 11 a 20: Luz dourada inclinada, sombras quentes e mar âmbar.
- Fases 21 a 30: Céu noturno escuro com estrelas, água azul marinho e vaga-lumes.
- Fases 31 a 40: Céu suave de outono, tons terracota e mar lilás.

---

## 3. Documentação Atualizada

- `docs/MELHORIAS_FUTURAS.md`: Reestruturação completa com a matriz de publicação, os 4 pilares de melhoria, conceito do Bot Arquiteto e histórico de conquistas.
- `docs/01_visao_geral_e_gdd/GDD_OFICIAL.md`: Adição da seção canônica 7 (*Estratégia de Publicação Mobile & Roadmap de Expansão*).
- `docs/03_level_design_e_fases/ESTRUTURA_DAS_FASES.md`: Inclusão da seção canônica 5 com o roteiro de fases 21 a 40 e a distribuição em 4 mundos.
- `docs/historico_melhorias/INDICE_MELHORIAS.md`: Indexação da Melhoria 136 no catálogo mestre.
- `project.godot` & `export_presets.cfg`: Bump de versão SemVer para `0.12.60-alpha` (código 1260).

---

## 4. Próximos Passos Recomendados
1. Implementação da interface do Herbário Botânico em `TabCollection`.
2. Criação do sistema de iluminação e céu por bioma para alternância automática conforme o número da fase.
3. Geração e validação do bloco de Fases 21 a 30 utilizando o pipeline automatizado de Autotile e JSON.
