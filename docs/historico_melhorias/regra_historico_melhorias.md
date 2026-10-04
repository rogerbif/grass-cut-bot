# Regra de Histórico de Melhorias (Changelog Perpétuo) 📜🌿

Para manter um histórico detalhado, auditável e perpétuo de todas as modificações, refatorações e novas implementações feitas em **Grass Cut Bot**, aplicamos a regra estrita de registro contínuo definida no `GEMINI.md`.

---

## 1. Diretriz Obrigatória

A cada tarefa concluída de melhoria, refatoração ou adição de conteúdo:
1. O agente deve consolidar o planejamento da melhoria e o relatório do que foi executado em um arquivo markdown dedicado dentro de:
   `docs/historico_melhorias/<numero_ou_nome_da_melhoria>.md`
2. Atualizar o índice mestre em `docs/historico_melhorias/INDICE_MELHORIAS.md`.
3. Atualizar os documentos canônicos relevantes na pasta `docs/`.
4. Incrementar a versão no `project.godot` e realizar o checkpoint no Git.

---

## 2. Estrutura Padrão de um Arquivo de Histórico

Cada registro deve conter:
- **Título da Melhoria e Versão**
- **Objetivo e Contexto**
- **Arquivos Criados e Modificados**
- **Destaques Técnicos da Implementação**
- **Validação e Testes Realizados**
