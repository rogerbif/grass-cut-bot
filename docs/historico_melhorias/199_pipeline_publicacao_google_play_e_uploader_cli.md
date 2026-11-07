# Melhoria 199: Pipeline de Publicação Automatizada no Google Play Console & Script de Upload CLI (`v0.12.150-alpha`)

## 1. Resumo Executivo
- **Título da Entrega:** Pipeline de Publicação Automatizada no Google Play Console, Autenticação via Google Developer API e Script de Upload CLI com Bypass de Bloqueios do Windows/OneDrive.
- **Versão SemVer Alcançada:** `v0.12.150-alpha` (Version Code `1350`).
- **Data de Conclusão:** 07 de Novembro de 2026.
- **Status:** Concluído com Sucesso e Publicação Ao Vivo Verificada no Google Play Console.

---

## 2. Objetivos e Motivação
Para simplificar o ciclo contínuo de deploy e publicação de novas versões do **Grass Cut Bot** na Google Play Store, foi implementado um pipeline de exportação e publicação direta a partir do terminal/IDE, dispensando o upload manual de arquivos `.aab` pelo navegador.

A solução abrange:
1. Resolução de conformidade com os novos requisitos do Google Play Console (Target SDK 36 obrigatório - Android 16).
2. Tratamento de bloqueios de arquivos e pastas no Windows/OneDrive durante a compilação Gradle do Godot.
3. Criação de ferramenta CLI em Node.js (`scripts/tools/play_store_uploader/upload.js`) utilizando a biblioteca oficial `googleapis` e Conta de Serviço do Google Cloud (`androidpublisher.googleapis.com`).
4. Automação ponta a ponta via PowerShell (`scripts/tools/build_android_aab.ps1`) com suporte à flag `-Publish` e seleção de faixa (`internal`, `alpha`).

---

## 3. Implementações Realizadas

### A. Resolução de Requisitos da Google Play e Gradle
- **Target SDK 36 (Android 16):**
  - Atualizado `export_presets.cfg` com `gradle_build/target_sdk="36"`.
  - Configurado `android/build/gradle.properties` com `android.suppressUnsupportedCompileSdk=36` para compatibilidade com o AGP (Android Gradle Plugin) integrado.
- **Proteção contra Locks do OneDrive:**
  - Desativação global de tarefas `:clean` no `android/build/build.gradle` (`tasks.matching { it.name == 'clean' }.all { enabled = false }`).
  - Limpeza forçada de pastas de build e assets legados em `scripts/tools/build_android_aab.ps1` usando comandos nativos Windows (`cmd.exe /c rmdir /s /q`).

### B. Módulo de Upload Google Play API (`scripts/tools/play_store_uploader/`)
- Módulo autônomo baseado em Node.js e `googleapis` (versão 144+).
- **Fluxo do Script (`upload.js`):**
  1. Autentica via JWT com a chave privada da Conta de Serviço (`play_service_account.json`).
  2. Cria uma nova sessão de edição (`edits.insert`) para o pacote `com.bifgames.grasscutbot`.
  3. Realiza o streaming do bundle `.aab` (`edits.bundles.upload`) e obtém o `versionCode` retornado pela API.
  4. Configura a faixa de distribuição desejada (`internal`, `alpha`, etc.) e anexa as notas da versão bilíngues (`<pt-BR>` e `<en-US>`).
  5. Efetua o commit atômico da sessão (`edits.commit`).

### C. Integração com o Script de Build PowerShell
- Em `scripts/tools/build_android_aab.ps1`:
  - Adicionados os parâmetros `[switch]$Publish` e `[string]$Track = "internal"`.
  - Ao compilar com `-Publish`, o script exporta o `.aab` e em seguida dispara o upload para o Google Play Console automaticamente.

### D. Segurança e Git
- Inclusão rigorosa de `play_service_account.json`, `*service_account*.json` e arquivos de keystore no `.gitignore`.
- Preservação estrita dos guardrails do `GEMINI.md`.

---

## 4. Verificação e Testes
- **Build do AAB:** Executado via `Godot_v4.7.2-stable_win64_console.exe --headless --export-release grasscutbot build/release/grass_cut_bot.aab`. O arquivo foi gerado com 47.42 MB, assinado com o keystore oficial `upload-keystore.jks`.
- **Upload para Google Play:**
  - Comando executado: `node scripts/tools/play_store_uploader/upload.js --track=internal`
  - Resposta da API:
    ```
    >>> [SUCESSO] VERSÃO PUBLICADA COM SUCESSO NO GOOGLE PLAY! <<<
    Versão: 1350
    Faixa: internal
    ```
- **Verificação no Google Play Console:** Versão 1350 (`0.12.150-alpha`) ativa na faixa de Teste Interno com notas da versão em português e inglês.

---

## 5. Arquivos Afetados
- `scripts/tools/build_android_aab.ps1`: Suporte a `-Publish` e `-Track`.
- `scripts/tools/play_store_uploader/package.json`: Definição de dependências do uploader.
- `scripts/tools/play_store_uploader/upload.js`: Código da ferramenta de publicação Google Play API.
- `.gitignore`: Proteção de credenciais de serviço e keystores.
- `export_presets.cfg`: Target SDK 36 e version code 1350.
- `project.godot`: Versão `0.12.150-alpha`.
- `scripts/core/game_version.gd`: PATCH = 150.
