# Roadmap de Melhorias Futuras: Grass Cut Bot 🌿🤖

Este documento contém o planejamento de evolução do jogo organizado por impacto na experiência do jogador (*Juicy Game Feel*, retenção casual e qualidade técnica mobile).

---

## 🚀 Prioridade P1: Essencial e Próximos Passos Imediatos

1. **Sistema de Áudio e Sound Design Satisfying**
   - SFX de corte orgânico contínuo (som "crocante" / *crisp grass slicing sound*) modulando pitch levemente a cada tufo consecutivo ceifado.
   - SFX de choque metálico seco com rochas (*metallic thud + sparks*).
   - Jingle festivo de vitória de fase com moedas tinindo.
   - SFX de tique-taque tenso nos últimos 10 segundos do cronômetro.
   - Trilha sonora alegre e relaxante (música arcade lo-fi/casual em loop suave).

2. ~~**Persistência de Dados e SaveGame (`SaveManager`)**~~ *(Concluído na [Melhoria 037](historico_melhorias/037_sistema_de_savegame_e_persistencia_de_dados.md))*
   - Criação de Autoload `SaveManager` serializando em JSON (`user://savegame.json`).
   - Salvar progresso de fases liberadas, estrelas (1 a 3), melhor tempo em cada estágio, moedas totais e níveis de melhorias da oficina.
   - Escrita atômica com backup automático de integridade (`savegame.bak`).

3. **Efeito Visual de Solo Aparado (Gramado Ceifado)**
   - Adicionar decalque suave ou malha de piso mostrando a passagem da lâmina em faixas (estilo corte de gramado com faixas contrastantes).
   - Animação de tocos de grama aparados rente ao solo.

4. **Modelos 3D e Animações da Serra Refinados**
   - Melhoria visual da serra circular: lâmina metálica chanfrada com dentes afiados desenhados em 3D Low Poly, tampa superior de motor estilizada com respiradouros e porca central.

---

## 🎨 Prioridade P2: Conteúdo, Variedade e Fases

5. **Expansão das Fases 4 a 10**
   - Níveis com formatos de ilhas não retangulares (formato de L, ilhas ovais, canteiros divididos por caminhos estreitos).
   - Desafios com múltiplas metas misturadas (ex: 40 gramas, 20 trigos e 15 flores).
   - Introdução de obstáculos variados (troncos caídos, tocos de árvore, pedras musgosas).

6. **Novas Espécies Vegetais e Bônus**
   - **Arbusto Denso:** Exige corte contínuo ou nível 3 de potência.
   - **Flor Dourada Rara:** Surge aleatoriamente concedendo 25 moedas bônus se ceifada antes de murchar.
   - **Cogumelo Turbo:** Ao ser cortado, concede 4 segundos de corte acelerado e raio expandido instantaneamente.

7. **Menu Principal e Seletor de Fases (Level Select)**
   - Tela inicial elegante em portrait com botão "Jogar", acesso direto à Oficina e botão de Configurações.
   - Mapa ou lista de seleção de fases com avaliação de 1 a 3 estrelas (baseada no tempo de conclusão).

---

## 📱 Prioridade P3: Portabilidade Android e Publicação

8. **Preset de Exportação Android (`export_presets.cfg`)**
   - Configuração de Keystore de debug e release.
   - Ícones adaptativos Android (Adaptive Icons foreground e background).
   - Splash screen personalizada com fundo verde escuro e logo do robô cortador.
   - Otimização do APK/AAB com compressão de texturas ASTC/ETC2 e compilação limpa.

9. **Polimento de Configurações e Acessibilidade**
   - Menu in-game de Configurações: alternância de vibração (haptics ligada/desligada), volume de música e volume de SFX.
   - Opção de sensibilidade do joystick virtual.
