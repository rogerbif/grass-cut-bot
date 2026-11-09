# Implementação: Pipeline de Publicação Automatizada no itch.io (HTML5) via Butler CLI 🚀🌐

**Data:** 09/11/2026  
**Versão Canônica:** `v0.12.158-alpha`  
**Escopo:** Infraestrutura, CI/CD, Automação de Exportação Web, Integração itch.io Butler CLI.

---

## 1. Contexto & Motivação

O **itch.io** é a principal plataforma aberta para jogos independentes e testes imediatos em navegadores. Diferente da Google Play Store (que utiliza pacotes binários `.aab` para Android), o itch.io permite distribuição direta da versão Web (HTML5/WebAssembly) jogável no próprio browser através de iframe/canvas.

Como o itch.io não oferece endpoint REST simples para upload de builds, a ferramenta oficial e canônica recomendada pela plataforma é o **Butler CLI** (`butler`). O Butler gerencia canais (`html5`), tags de versão (`--userversion`) e calcula diffs binários incrementais de alta performance (`wharf`).

Esta melhoria conecta a exportação Web do Godot 4 (`grasscutbot_Web`) à esteira de entrega contínua do projeto, permitindo publicar versões na Google Play, no itch.io ou em ambos simultaneamente com um único comando.

---

## 2. Componentes Criados & Alterados

### 2.1. Instalador Automatizado do Butler (`scripts/tools/setup_butler.ps1`)
- Baixa automaticamente a versão Windows 64-bit mais recente do Butler CLI direto dos releases oficiais do GitHub (`itchio/butler`).
- Extrai e configura o executável em `$env:LOCALAPPDATA\itch-butler`.
- Registra o diretório no `PATH` do usuário do Windows de forma permanente e imediata na sessão ativa.
- Orienta o desenvolvedor a realizar o comando `butler login` (uma única vez) para vincular a conta do itch.io.

### 2.2. Script Especializado de Publicação itch.io (`scripts/tools/publish_itch.ps1`)
- **Parâmetros:**
  - `-ProjectSlug`: `bifgames/grass-cut-bot` (padrão oficial).
  - `-Channel`: `html5` (versão Web jogável no navegador).
  - `-UserVersion`: Lê dinamicamente do `scripts/core/game_version.gd` ou recebe override manual.
  - `-SkipExport`: Permite reenviar a pasta `build/web` existente sem recompilar.
- **Fluxo:**
  1. Detecta o executável do Godot 4.7.x.
  2. Executa a exportação headless do preset `grasscutbot_Web` para `build/web/index.html`.
  3. Realiza higienização removendo arquivos `.import` residuais.
  4. Localiza o executável do Butler CLI (no PATH ou em `$env:LOCALAPPDATA\itch-butler\butler.exe`).
  5. Dispara `butler push "build/web" "$ProjectSlug:$Channel" --userversion "$UserVersion"`.
  6. Exibe status com o link público direto: `https://bifgames.itch.io/grass-cut-bot`.

### 2.3. Integração Mestre (`publish.ps1` e `scripts/tools/publish_version.ps1`)
- Novos parâmetros:
  - `-Target GooglePlay|Itch|All`: Permite selecionar o escopo do deploy (padrão: `GooglePlay`).
  - `-Itch`: Switch facilitador que ativa o deploy no itch.io mantendo o Google Play ativo (`Target = "All"`).
- Exemplos de novos fluxos de uso:
  ```powershell
  # Publica apenas no itch.io com bump de Patch:
  .\publish.ps1 -Target Itch -Bump Patch

  # Publica em ambos (Google Play + itch.io) com 1 comando:
  .\publish.ps1 -Itch -Bump Patch

  # Re-publica a versão atual sem bump no itch.io:
  .\publish.ps1 -Bump None -Target Itch
  ```

### 2.4. Atualização de Documentação Canônica & Skill
- `docs/05_arquitetura_e_desenvolvimento/PORTABILIDADE_WEB.md`: Adicionada Seção 7 detalhando o pipeline do itch.io com Butler CLI, canais canônicos e boas práticas.
- `.agent/skills/publicar-versao/SKILL.md`: Atualizada para cobrir `-Target Itch|All` e `-Itch`.

---

## 3. Verificação & Validação

- [x] Preset Web (`grasscutbot_Web`) exportado headless com 100% de sucesso para `build/web/index.html`.
- [x] `setup_butler.ps1` validado: instalou com sucesso o `butler.exe` v15.32.0 em `$env:LOCALAPPDATA\itch-butler` e configurou o PATH do sistema.
- [x] Verificação do Butler: `butler -V` executando perfeitamente.
- [x] `publish_itch.ps1` implementado com tratamento defensivo de versão, compilação Web, limpeza de `.import` e push com `--userversion`.
- [x] Script raiz `publish.ps1` integrado com opções `-Target Itch`, `-Target All` e `-Itch`.
