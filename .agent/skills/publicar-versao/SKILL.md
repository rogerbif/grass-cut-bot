---
name: publicar-versao
description: >-
  Automatiza o processo completo de subir uma nova versão do Grass Cut Bot simultaneamente para o Google Play Console (Android AAB) e itch.io (Web HTML5). Executa o bump de versão SemVer, compilação de AAB e Web, upload via Google Play API / Butler CLI e sincronização com o GitHub.
---

# Atalho de Publicação Automatizada: Grass Cut Bot 🚀🤖

Quando o usuário solicitar o envio, publicação ou atualização de uma nova versão do jogo (ex: `/publicar-versao`, `/publicar-atualizacao`, "subir nova versão", "publicar atualização", "atualizar tanto no android quanto no itch.io"):

Execute o seguinte fluxo automatizado:

## 1. Identificação de Escopo & Plataformas Alvo
- **Destino Padrão (`-Target All`):** Atualiza **SIMULTANEAMENTE** no **Google Play Console (Android AAB)** e no **itch.io (Web HTML5)**.
- **Opções Específicas de Destino:**
  - `All` (Padrão): Deploy duplo (Google Play + itch.io).
  - `GooglePlay`: Compila e publica exclusivamente no Google Play Console.
  - `Itch`: Compila e publica exclusivamente a versão Web (HTML5) no itch.io via Butler CLI.
- **Faixa Google Play:** `internal` (Teste Interno padrão) ou `alpha` (Teste Fechado).
- **Tipo de Bump Padrão:** `Patch` (+1) ou `Minor` (quando há novos subsistemas).

## 2. Preparação das Notas da Versão (Release Notes)
- Sintetize as alterações recentes nas tags canônicas bilíngues:
  - `<pt-BR>`: Resumo em tópicos das melhorias para os jogadores brasileiros.
  - `<en-US>`: Resumo correspondente em inglês para a audiência global.

## 3. Disparo do Script de Publicação

### Publicação Padrão Dupla (Android + itch.io):
```powershell
.\publish.ps1 -Bump Patch -Track internal -NotesPt "Novidades da versão..." -NotesEn "What's new in this version..."
```

### Publicar apenas em uma plataforma específica (se solicitado):
```powershell
# Apenas Google Play:
.\publish.ps1 -Target GooglePlay -Bump Patch -Track internal -NotesPt "..." -NotesEn "..."

# Apenas itch.io (HTML5):
.\publish.ps1 -Target Itch -Bump Patch
```

## 4. O que o pipeline executa automaticamente:
1. Incrementa os números de versão em `scripts/core/game_version.gd`, `project.godot` e `export_presets.cfg`.
2. **Deploy Google Play (Android):**
   - Garante Target SDK 36 e Min SDK 24.
   - Compila o `.aab` assinado com o keystore de release.
   - Envia para a Google Play Developer API via Conta de Serviço com as release notes bilíngues.
3. **Deploy itch.io (HTML5 Web):**
   - Compila o pacote WebAssembly/WebGL2 usando o preset `grasscutbot_Web` para `build/web/index.html`.
   - Limpa arquivos temporários e resíduos `.import`.
   - Faz o push com **Butler CLI** para o canal `bifgames/grass-cut-bot:html5` associado à `--userversion`.
4. Registra o commit semântico no Git e executa `git push origin main`.

## 5. Apresentação Obrigatória ao Usuário
Sempre confirme no chat a versão gerada, os destinos publicados (Google Play + itch.io) e exiba as notas da versão nas tags:
```html
<pt-BR>
Insira as notas da versão no idioma pt-BR
</pt-BR>

<en-US>
Insert the version notes in en-US here
</en-US>
```
