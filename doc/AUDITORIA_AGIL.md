# 📊 Auditoria Ágil — Sistema de Gestão de Projetos

> Análise de conformidade com o **Manifesto Ágil**, **Scrum** e **Kanban** + gap analysis e roadmap.
> Versão analisada: 0.3.x (Nuxt 3 + Supabase, pasta `nuxt-reference/`).

---

## 1. Manifesto Ágil — 4 Valores

| # | Valor                                                  | Status | Evidência no código                                                                                            | Gap |
|---|--------------------------------------------------------|:-----:|----------------------------------------------------------------------------------------------------------------|-----|
| 1 | **Indivíduos e interações** > processos e ferramentas  | 🟢   | Realtime no Kanban (`useRealtimeKanban`), presença ao vivo, comentários por tarefa.                            | Falta menção em comentários e atribuição rápida no card. |
| 2 | **Software funcionando** > documentação abrangente     | 🟢   | Stack rodável end-to-end (Docker + Supabase + Nuxt). CI/CD ainda não definido.                                 | Adicionar pipeline GitHub Actions + testes E2E. |
| 3 | **Colaboração com cliente** > negociação de contratos  | 🟡   | Papéis (`admin/desenvolvedor/visualizador`) já modelados, mas não há papel `cliente/PO` nem feedback in-app.   | Adicionar papel `produto` e canal de comentário público da tarefa. |
| 4 | **Responder a mudanças** > seguir um plano             | 🟢   | Backlog repriorizável, drag-and-drop livre entre colunas, sprints editáveis.                                   | Falta histórico de mudança de prioridade (audit log). |

**Score geral:** 🟢 **Conformidade alta** — fundamentos cobertos.

---

## 2. 12 Princípios Ágeis

| # | Princípio | Atendido | Onde |
|---|-----------|:-------:|------|
| 1  | Entrega contínua de valor                  | 🟢 | Sprints + Kanban com coluna `concluido` |
| 2  | Aceitar mudanças mesmo tardias             | 🟢 | Tarefas movíveis entre sprints (`associarTarefa`) |
| 3  | Entregas frequentes                        | 🟡 | Sprints existem mas não há cadência forçada nem release tag |
| 4  | Negócio + dev trabalham juntos             | 🟡 | Papel "produto/cliente" ainda não modelado |
| 5  | Indivíduos motivados + ambiente            | 🟢 | Realtime, presença, atribuição clara |
| 6  | Conversa face-a-face                       | ⚪ | Fora de escopo (vídeo) — comentários cobrem o assíncrono |
| 7  | Software funcionando = métrica primária    | 🟢 | Burndown + % concluído por sprint |
| 8  | Ritmo sustentável                          | 🟡 | Falta métrica de **WIP limit** por coluna e alerta de sobrecarga |
| 9  | Excelência técnica                         | 🟡 | RLS + tipagem ok; faltam testes automatizados |
| 10 | Simplicidade                               | 🟢 | UI enxuta, código modular |
| 11 | Times auto-organizáveis                    | 🟢 | Qualquer membro move tarefa, atribui, comenta |
| 12 | Reflexão e ajuste                          | 🔴 | **Sem retrospectiva nem velocity histórico** entre sprints |

**Score:** 7 🟢 / 4 🟡 / 1 🔴.

---

## 3. Scrum — Artefatos & Eventos

| Elemento Scrum         | Implementado? | Observações |
|------------------------|:-------------:|-------------|
| Product Backlog        | 🟢 | Tarefas com `sprint_id is null` (`tarefasDoBacklog`) |
| Sprint Backlog         | 🟢 | `tarefasDaSprint(sprintId)` |
| Incremento             | 🟢 | Coluna `concluido` na sprint |
| Sprint Planning        | 🟢 | Tela `/sprints` com seleção do backlog |
| Daily Scrum            | 🟡 | Não há ritual; presença em tempo real ajuda |
| Sprint Review          | 🟡 | Burndown ajuda mas não há "demo log" |
| Sprint Retrospective   | 🔴 | **Não implementado** — recomendar `retrospectivas` table |
| Definition of Done     | 🔴 | Não há checklist por tarefa nem por projeto |
| Velocity (story points)| 🔴 | Tarefas não têm `pontos`/estimativa |

---

## 4. Kanban — Práticas Centrais

| Prática Kanban                      | Status | Gap |
|-------------------------------------|:------:|-----|
| Visualizar o trabalho               | 🟢    | Quadro com 5 colunas pré-definidas |
| Limitar WIP                         | 🔴    | **Sem limite por coluna** — adicionar `wip_limite` em projeto/coluna |
| Gerenciar fluxo                     | 🟡    | Falta **Cumulative Flow Diagram** e **Cycle Time** |
| Tornar políticas explícitas         | 🟡    | Sem campo "DoD" nem "critério da coluna" |
| Loops de feedback                   | 🟢    | Realtime + comentários |
| Melhoria evolutiva (Kaizen)         | 🔴    | Sem métrica histórica de throughput |

---

## 5. Gap Analysis — Indicadores de Produção e Fluxo

O usuário pediu **dashboard com índices de produção e fluxo por projeto**.
Mapeamento de KPIs ágeis padrão x estado atual:

| KPI Ágil                              | Para quê                                  | Implementado? |
|---------------------------------------|-------------------------------------------|:-------------:|
| **Throughput** (tarefas concluídas/período) | Capacidade do time                  | 🔴 → adicionar |
| **Lead Time** (criação → concluído)   | Quanto demora pro valor chegar            | 🔴 → adicionar (precisa histórico) |
| **Cycle Time** (em_progresso → concluído) | Eficiência da execução                | 🔴 → adicionar |
| **WIP atual** por coluna              | Detecta gargalo                           | 🟢 (já temos contagem) |
| **% Concluído** da sprint             | Saúde da sprint                           | 🟢 (`progresso`) |
| **Burndown chart**                    | Tendência sprint                          | 🟢 (`GraficoBurndown`) |
| **Cumulative Flow Diagram (CFD)**     | Estabilidade do fluxo                     | 🔴 → snapshots diários por coluna |
| **Distribuição por prioridade**       | Foco do time                              | 🟡 → fácil somar |
| **Carga por responsável**             | Balanceamento de pessoas                  | 🔴 → agregação por `responsavel_id` |
| **Tarefas atrasadas** (`prazo < hoje`)| Risco                                     | 🔴 → fácil filtrar |
| **Idade da tarefa em coluna**         | Itens "presos"                             | 🔴 → precisa `entrou_em_coluna_em` |
| **Velocity** (pontos concluídos/sprint) | Previsibilidade                          | 🔴 → precisa campo `pontos` |

---

## 6. Roadmap de Conformidade (priorizado)

### 🔥 Alta — entrega imediata (esta versão 0.4)
1. **Migration `0005_metricas.sql`**
   - Tabela `historico_movimentacao` (registra cada `coluna_origem → coluna_destino` com timestamp).
   - Coluna `entrou_coluna_em` em `tarefas` (atualizada por trigger).
   - Coluna `pontos` (estimativa) em `tarefas`.
   - Coluna `wip_limite` (jsonb) em `projetos`.
   - View `v_metricas_tarefa` calculando lead/cycle time por tarefa.
2. **Edge Function `dashboardProjeto`** retornando todos os KPIs acima por projeto.
3. **Página `/projetos/[id]`** com dashboard executivo (cards + CFD + throughput + WIP + atrasadas).

### 🟡 Média — próximo ciclo (0.5)
4. Definition of Done por projeto (campo `dod` jsonb checklist).
5. Tabela `retrospectivas` (o que foi bem / a melhorar / ações).
6. Velocity histórico por sprint (somatório de `pontos` concluídos).
7. WIP limit visual no Kanban com alerta vermelho ao exceder.

### 🟢 Baixa — backlog (0.6+)
8. Audit log de mudança de prioridade.
9. Papel `produto` (PO) e visão "cliente" read-only.
10. CI/CD GitHub Actions + testes E2E Playwright.
11. Releases automáticas marcadas no incremento.

---

## 7. Conclusão

A versão **0.3** já é uma base **ágil sólida**: Manifesto coberto, Scrum/Kanban com fundamentos, RLS, realtime e burndown. Os principais buracos são **métricas históricas** (lead/cycle time, throughput, CFD) e **rituais Scrum** (retrospectiva, DoD, velocity).

A versão **0.4** entregue junto deste documento fecha o gap de **indicadores de produção e fluxo por projeto**, atendendo diretamente ao pedido do usuário.

> _"Você não pode melhorar o que você não mede."_ — princípio Kaizen aplicado ao Manifesto Ágil.
