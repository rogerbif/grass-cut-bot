---
name: publicar-versao
description: >-
  Automatiza o processo completo de subir uma nova versão do Grass Cut Bot para o Google Play Console. Executa o bump de versão SemVer, compilação do Android App Bundle (.aab), injeção das notas de versão bilíngues (<pt-BR> e <en-US>), upload via Google Play API e sincronização com o GitHub. Use quando o usuário pedir para subir, publicar ou gerar uma nova versão para a Google Play.
---

# Atalho de Publicação Automatizada: Grass Cut Bot 🚀🤖

Quando o usuário solicitar o envio, publicação ou geração de uma nova versão do jogo para a Google Play Store (ex: `/publicar-versao`, "subir nova versão", "publicar no Google Play"):

Execute o seguinte fluxo automatizado:

## 1. Identificação de Escopo & Faixa de Lançamento
- **Faixa Padrão:** `internal` (Teste Interno). Se o usuário solicitar closed testing ou teste fechado, use `alpha`.
- **Tipo de Bump Padrão:** `Patch` (+1). Se houver grande volume de novos subsistemas, use `Minor`.

## 2. Preparação das Notas da Versão (Release Notes)
- Sintetize as alterações recentes mais relevantes nas tags canônicas bilíngues:
  - `<pt-BR>`: Resumo em tópicos das melhorias para os jogadores brasileiros.
  - `<en-US>`: Resumo correspondente em inglês para a audiência global.

## 3. Disparo do Script de Publicação
Execute no terminal o atalho oficial:
```powershell
.\publish.ps1 -Bump Patch -Track internal -NotesPt "Novidades da versão..." -NotesEn "What's new in this version..."
```
Ou alternativamente, para apenas re-publicar sem bump de versão:
```powershell
.\publish.ps1 -Bump None -Track internal
```

O script automaticamente:
1. Incrementa os números de versão em `scripts/core/game_version.gd`, `project.godot` e `export_presets.cfg`.
2. Garante o Target SDK 36 e Min SDK 24.
3. Desabilita as tarefas de clean do Gradle para mitigar bloqueios de concorrência com o OneDrive.
4. Compila o `.aab` assinado com o keystore de release.
5. Abre a sessão de edição na Google Play Developer API via Conta de Serviço, faz o streaming do bundle, aplica as release notes e comita as alterações.
6. Registra o commit semântico no Git e executa `git push origin main`.

## 4. Apresentação Obrigatória ao Usuário
Sempre exiba no chat as notas da versão nas tags correspondentes exigidas pelo Mandamento Invariante 18:
```html
<pt-BR>
Insira as notas da versão no idioma pt-BR
</pt-BR>

<en-US>
Insert the version notes in en-US here
</en-US>
```
E confirme a versão gerada, o Version Code e a faixa de destino publicada.
