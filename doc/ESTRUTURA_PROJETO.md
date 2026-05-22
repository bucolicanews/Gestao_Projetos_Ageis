# Estrutura Padrão de Projeto

Todo projeto deve ter no mínimo esta estrutura de pastas e arquivos.

```
PROJETO/
│
├── 01-CLIENTE/
│   ├── dados-cliente.md
│   ├── contrato.md
│   ├── requisitos.md
│   └── reunioes/
│
├── 02-GERENCIA/
│   ├── planejamento.md
│   ├── roadmap.md
│   ├── riscos.md
│   ├── cronograma.md
│   └── indicadores.md
│
├── 03-EQUIPE/
│   ├── gerente-projeto.md
│   ├── product-owner.md
│   ├── scrum-master.md
│   ├── desenvolvedores/
│   │   ├── dev-backend.md
│   │   ├── dev-frontend.md
│   │   ├── dev-mobile.md
│   │   └── devops.md
│   └── qa-testes.md
│
├── 04-PRODUTO/
│   ├── visao-produto.md
│   ├── arquitetura/
│   ├── wireframes/
│   ├── banco-dados/
│   └── documentacao-tecnica/
│
├── 05-BACKLOG/
│   ├── product-backlog.md
│   ├── historias-usuario/
│   ├── tarefas/
│   ├── bugs/
│   └── melhorias/
│
├── 06-SPRINTS/
│   ├── sprint-01/
│   │   ├── planejamento.md
│   │   ├── tarefas.md
│   │   ├── daily.md
│   │   ├── review.md
│   │   └── retrospectiva.md
│   │
│   ├── sprint-02/
│   └── sprint-03/
│
├── 07-DESENVOLVIMENTO/
│   ├── frontend/
│   ├── backend/
│   ├── mobile/
│   ├── api/
│   └── microsservicos/
│
├── 08-TESTES/
│   ├── testes-unitarios/
│   ├── testes-integracao/
│   ├── testes-carga/
│   └── relatorios/
│
├── 09-DEPLOY/
│   ├── homologacao/
│   ├── producao/
│   ├── docker/
│   ├── kubernetes/
│   └── pipelines-ci-cd/
│
├── 10-DOCUMENTACAO/
│   ├── api/
│   ├── manuais/
│   ├── onboarding/
│   └── changelog.md
│
├── 11-FINANCEIRO/
│   ├── custos.md
│   ├── horas.md
│   ├── faturamento.md
│   └── pagamentos.md
│
└── 12-ARQUIVOS-GERAIS/
    ├── anexos/
    ├── imagens/
    ├── atas/
    └── referencias/
```

## Fluxo Ágil (Scrum)

```
BACKLOG → SPRINT PLANNING → SPRINT ATIVA → REVIEW → RETROSPECTIVA → PRÓXIMA SPRINT
```

### Ciclo de uma tarefa

```
Backlog (product-backlog)
  ↓  Sprint Planning — selecionar e estimar
Sprint (sprint_id associado)
  ↓  Kanban — mover pelas colunas
A Fazer → Em Progresso → Em Revisão → Concluído
  ↓  Sprint Review — demonstrar entregáveis
  ↓  Retrospectiva — melhorias de processo
```

### Sprint = coleção de tarefas com prazo fixo

- Duração típica: 1–4 semanas
- Tarefas vêm do backlog e são associadas via `sprint_id`
- Kanban reflete o estado das tarefas dentro da sprint
- Burndown mede progresso diário (snapshots)
- Ao final: review + retrospectiva → próxima sprint

## Regras mínimas por projeto

| Área | Obrigatório |
|---|---|
| 01-CLIENTE | dados-cliente.md + requisitos.md |
| 02-GERENCIA | planejamento.md + cronograma.md |
| 03-EQUIPE | Pelo menos gerente + 1 desenvolvedor |
| 05-BACKLOG | product-backlog.md com histórias de usuário |
| 06-SPRINTS | Uma pasta por sprint executada |
| 10-DOCUMENTACAO | changelog.md atualizado |
