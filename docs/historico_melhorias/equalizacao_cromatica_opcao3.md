# Registro de Melhoria: Calibração de Cores e Restauração da Paleta Canônica Mobile 🌿🎨

- **Data:** 03/11/2026
- **Versão:** `v0.12.96-alpha`
- **Autor:** Antigravity AI & Roger Bif
- **Status:** Concluído e Validado

---

## 1. Contexto & Diagnóstico da Discrepância
Após a tentativa anterior de equalização com valores RGB diretos da imagem de mockup, o jogo apresentou um aspecto superexposto e "lavado" no gameplay (chão em tom verde-amarelado neon e falésias em areia pálida). 

### Por que isso aconteceu?
No Godot 3D, a cor base (albedo) sofre multiplicação pela iluminação da cena:
$$\text{Luz Direcional (1.0)} + \text{Luz Ambiente (0.85)} = 1.85\times \text{ brilho}$$
Ao aplicar o valor final do pixel do mockup (`#99EA3F`) diretamente no material antes da iluminação, a luz de $1.85\times$ superexpunha o gramado para um verde-limão estourado, destruindo o contraste com o trigo e fazendo a falésia parecer bege/creme.

---

## 2. Restauração da Paleta Canônica Mobile

| Elemento | Configuração do Material | Cor Visual Final Lit | Efeito no Jogo |
| :--- | :--- | :--- | :--- |
| **Solo da Ilha (Grama)** | `ground_base_color = Color(0.408, 0.698, 0.173)` com `brightness = 0.95` | 🟢 Verde Campo Suave & Sólido | Piso firme e nítido que dá destaque imediato à vegetação e ao robô. |
| **Falésia da Ilha** | `CLIFF_COLOR = Color(0.745, 0.427, 0.25)` | 🏖️ Terracota / Terra Quente | Linha de costa bem definida contra a água do mar e a espuma branca. |
| **Grama Verde** | Topo `Color(0.28, 0.81, 0.10)` / Base `(0.12, 0.44, 0.05)` | 🌿 Esmeralda Vibrante | Gradiente foliar que se destaca claramente do piso. |
| **Trigo Maduro** | Topo `Color(0.98, 0.82, 0.28)` / Base `(0.50, 0.34, 0.10)` | 🌾 Dourado Solar Rico | Alto contraste contra o chão verde, leitura imediata de alvo 2x. |
| **Ambiente & Céu** | Céu `Color(0.68, 0.85, 0.90)`, Amb `Color(0.85, 0.92, 0.88)`, Energy `0.85` | 🟦 Azul Tropical Acolhedor | Sem estouro de brancos ou superexposição. |

---

## 3. Arquitetura Mantida
- O recurso unificado `assets/environments/shared_environment.tres` permanece ativo em `main.tscn` e `main_menu.tscn`, garantindo consistência entre telas.
- O modelo da ilha do Menu (`island_node.tscn`) e a malha do Gameplay (`island_mesh_builder.gd`) compartilham os mesmos tons calibrados.
- Preservada a correção Web Single-Threaded (`threads: false`), que permite carregar normalmente no itch.io sem tela preta.
