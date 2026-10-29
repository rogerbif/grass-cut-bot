# Melhoria 156: Correção do Logo na Tela de Loading Web com Inlining Base64

## 📌 Contexto & Motivação
Na tela de carregamento web (`web_shell/shell.html`), a imagem do logo do jogo (`<img class="bot-icon" src="index.icon.png" alt="Grass Cut Bot">`) exibia ícone de imagem quebrada no navegador. Isso ocorria porque a referência relativa `index.icon.png` dependia de requisição de rede assíncrona adicional ao servidor web, sujeita a latência, políticas de roteamento ou problemas de cache do navegador durante o boot inicial.

---

## 🛠️ Alterações Implementadas

### 1. Inlining do Ícone Oficial em Base64 Data URI (`web_shell/shell.html`)
- Convertido o ícone oficial em alta definição `assets/brand/icon_192.png` diretamente para uma string **Base64 Data URI** (`data:image/png;base64,...`).
- A tag `<img>` em `web_shell/shell.html` agora embute os bytes da imagem diretamente dentro do HTML da página.
- **Vantagens:**
  - **Zero requisições HTTP adicionais:** A imagem carrega instantaneamente no primeiro milissegundo de parsing do DOM.
  - **Imunidade contra 404 e cache:** Impossível haver caminho incorreto, falha de rota ou cache mismatch em qualquer ambiente (localhost, itch.io, GitHub Pages, etc.).
  - A animação `pulse-glow` e o acabamento em cantos arredondados (28px) são exibidos com nitidez total desde o primeiro instante do loading.

### 2. Re-exportação Web
- Executada a exportação completa de release Web (`build/web/index.html`), gerando a nova compilação com o HTML atualizado.

---

## 🏷️ Versão & Validação
- **Game SemVer:** Incrementado para `v0.12.85-alpha`.
- **Godot Headless Import & Test:** 0 warnings e 0 erros.
- **Exportação Web:** Build atualizada com sucesso em `build/web/`.
