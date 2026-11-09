---
name: publicar-versao
description: >-
  Automatiza o processo completo de subir uma nova versão do Grass Cut Bot para o Google Play Console e/ou itch.io. Executa o bump de versão SemVer, compilação de AAB (Android) e/ou Web (HTML5), upload via Google Play API / Butler CLI e sincronização com o GitHub.
---

# Atalho de Publicação Automatizada: Grass Cut Bot 🚀🤖

Quando o usuário solicitar o envio, publicação ou geração de uma nova versão do jogo (ex: `/publicar-versao`, "subir nova versão", "publicar no Google Play", "subir para o itch.io", "publicar em ambos"):

Execute o seguinte fluxo automatizado:

## 1. Identificação de Escopo & Plataformas Alvo
- **Destino (`-Target`):**
  - `GooglePlay` (Padrão): Compila e publica apenas no Google Play Console.
  - `Itch`: Compila e publica apenas a versão Web (HTML5) no itch.io via Butler CLI.
  - `All` (ou switch `-Itch`): Compila e publica em **ambas** as plataformas simultaneamente.
- **Faixa Google Play:** `internal` (Teste Interno padrão) ou `alpha` (Teste Fechado).
- **Tipo de Bump Padrão:** `Patch` (+1) ou `Minor` (quando há novos subsistemas).

## 2. Preparação das Notas da Versão (Release Notes)
*(Necessário ao publicar no Google Play)*
- Sintetize as alterações recentes nas tags canônicas bilíngues:
  - `<pt-BR>`: Resumo em tópicos das melhorias para os jogadores brasileiros.
  - `<en-US>`: Resumo correspondente em inglês para a audiência global.

## 3. Disparo do Script de Publicação

### Publicar no Google Play:
```powershell
.\publish.ps1 -Bump Patch -Track internal -NotesPt "Novidades da versão..." -NotesEn "What's new in this version..."
```

### Publicar em ambos (Google Play + itch.io):
```powershell
.\publish.ps1 -Target All -Bump Patch -Track internal -NotesPt "Novidades..." -NotesEn "What's new..."
# Ou com o atalho:
.\publish.ps1 -Itch -Bump Patch
```

### Publicar apenas no itch.io (HTML5):
```powershell
.\publish.ps1 -Target Itch -Bump Patch
```
*(Ou diretamente via script utilitário sem alterar o SemVer: `.\scripts\tools\publish_itch.ps1`)*

## 4. O que o pipeline executa automaticamente:
1. Incrementa os números de versão em `scripts/core/game_version.gd`, `project.godot` e `export_presets.cfg`.
2. **Para Google Play:**
   - Garante Target SDK 36 e Min SDK 24.
   - Compila o `.aab` assinado com o keystore de release.
   - Envia para a Google Play Developer API via Conta de Serviço com as release notes.
3. **Para itch.io:**
   - Compila o pacote WebAssembly/WebGL2 usando o preset `grasscutbot_Web` para `build/web/index.html`.
   - Limpa arquivos temporários e resíduos `.import`.
   - Faz o push com **Butler CLI** para o canal `bifgames/grass-cut-bot:html5` associado à `--userversion`.
4. Registra o commit semântico no Git e executa `git push origin main`.

## 5. Apresentação Obrigatória ao Usuário
Sempre confirme no chat a versão gerada, os destinos publicados e, se houver Google Play, exiba as notas da versão nas tags:
```html
<pt-BR>
Insira as notas da versão no idioma pt-BR
</pt-BR>

<en-US>
Insert the version notes in en-US here
</en-US>
```
