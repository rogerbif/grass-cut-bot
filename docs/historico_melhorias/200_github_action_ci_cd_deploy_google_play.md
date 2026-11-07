# Melhoria 200: GitHub Action CI/CD para Build e Publicação Automatizada no Google Play (`v0.12.151-alpha`)

## 1. Resumo Executivo
- **Título da Entrega:** Implementação de Pipeline de Integração Contínua (CI/CD) via GitHub Actions para compilação automatizada do Android App Bundle (`.aab`) e upload direto para o Google Play Console.
- **Versão SemVer Alcançada:** `v0.12.151-alpha` (Version Code `1351`).
- **Data de Conclusão:** 07 de Novembro de 2026.
- **Status:** Concluído e Pronto para Uso no GitHub.

---

## 2. Objetivos e Motivação
Possibilitar que novos builds e lançamentos para a Google Play Store sejam disparados de forma 100% remota através da interface web do GitHub (ou por tags de versão `v*`), sem depender do poder computacional ou da presença local da máquina de desenvolvimento.

---

## 3. Implementação da GitHub Action (`.github/workflows/deploy_google_play.yml`)

### A. Gatilhos (Triggers)
- **Manual (`workflow_dispatch`):**
  - Permite escolher a faixa de publicação (`internal`, `alpha`, `beta`, `production`).
  - Permite definir Release Notes customizadas em Português (`release_notes_pt`) e Inglês (`release_notes_en`).
- **Automático (`push: tags: ['v*']`):**
  - Disparado ao criar uma tag de versão no repositório, direcionando automaticamente para o Teste Interno.

### B. Ambiente e Etapas de Execução (Ubuntu Runner)
1. **Ambiente Base:** Ubuntu Latest com Git LFS.
2. **Java & Android SDK:** Java JDK 17 (Temurin) e SDK Platforms 36 / Build Tools 36.
3. **Godot Engine 4.7.2 Headless & Export Templates:**
   - Download automatizado dos binários oficiais Linux e export templates de `github.com/godotengine/godot/releases`.
   - Registro em `/usr/local/bin/godot` e `~/.local/share/godot/export_templates/4.7.2.stable/`.
4. **Restauração Segura de Segredos:**
   - Decodificação do keystore de release (`ANDROID_KEYSTORE_BASE64`) para `upload-keystore.jks`.
   - Extração da credencial da Google Service Account (`PLAY_SERVICE_ACCOUNT_JSON`) para `play_service_account.json`.
5. **Configuração e Compilação:**
   - Instalação e ajuste do Android Build Template com injeção de `android.suppressUnsupportedCompileSdk=36` no `gradle.properties`.
   - Exportação do bundle em `build/release/grass_cut_bot.aab`.
6. **Preservação de Artefatos:**
   - O arquivo `.aab` é anexado aos artefatos do workflow (`actions/upload-artifact@v4`) com retenção de 14 dias para download direto.
7. **Publicação no Google Play Console:**
   - Execução do módulo Node.js `upload.js` via Google Developer API (`androidpublisher.googleapis.com`), aplicando as notas de versão e comitando na faixa selecionada.

---

## 4. Configuração dos Segredos no Repositório GitHub
Para que o workflow execute, o repositório deve conter as seguintes Secrets em `Settings > Secrets and variables > Actions`:
1. `PLAY_SERVICE_ACCOUNT_JSON`: Conteúdo integral do arquivo `play_service_account.json`.
2. `ANDROID_KEYSTORE_BASE64`: String Base64 do keystore `upload-keystore.jks`.
3. `KEYSTORE_PASSWORD`: Senha do keystore (`grasscutbot2026`).
4. `KEYSTORE_USER`: Alias da chave (`grasscutbot`).

---

## 5. Arquivos Afetados
- `.github/workflows/deploy_google_play.yml`: Workflow oficial de CI/CD.
- `scripts/tools/play_store_uploader/upload.js`: Suporte a variáveis de ambiente e argumentos de notas de versão personalizadas.
- `project.godot`: Versão `0.12.151-alpha`.
- `scripts/core/game_version.gd`: PATCH = 151.
- `export_presets.cfg`: Version code `1351`, version name `"0.12.151-alpha"`.
