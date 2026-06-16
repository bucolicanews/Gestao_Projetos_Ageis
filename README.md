# Sistema de Gestão de Projetos Ágeis

Plataforma SaaS de gestão de projetos com Kanban, Sprints, Backlog e guia de Git Flow integrado. Inclui servidor MCP para uso com Claude, Cursor, Claude Desktop e qualquer LLM compatível com o protocolo MCP.

---

## Stack tecnológica

| Camada | Tecnologia |
|--------|------------|
| Frontend | Nuxt 3 + Vue 3 + TypeScript |
| Estado | Pinia |
| Estilo | Tailwind CSS |
| Drag & Drop | vuedraggable |
| Backend / DB | Supabase (PostgreSQL + Auth + RLS + Realtime) |
| Server routes | Nitro (Nuxt server) |
| Protocolo LLM | MCP — Model Context Protocol |
| Idioma do código | PT-BR |

---

## Estrutura do projeto

```
├── paginas/              # Rotas (pages em PT-BR)
│   ├── index.vue         # Dashboard
│   ├── projetos.vue
│   ├── kanban.vue
│   ├── backlog.vue
│   ├── sprints.vue
│   └── guia-dev.vue      # Guia de Git Flow para desenvolvedores
├── componentes/          # Componentes Vue
│   ├── ModalTarefa.vue   # Inclui aba Git com branch generator
│   ├── GuiaGit.vue       # Branch, commits, PR template
│   ├── GuiaPR.vue        # Pull Request template gerado
│   ├── GuiaRelease.vue   # Wizard de release passo a passo
│   └── ColunaKanban.vue
├── loja/                 # Pinia stores
├── servicos/             # Chamadas ao Supabase
├── composables/
│   └── useBranchGenerator.ts  # Geração de branches e commits
├── mcp/                  # Servidor MCP para LLMs
│   ├── server.js         # Entry point stdio
│   └── tools/
│       ├── sessao.js     # identificar_usuario, meus_projetos
│       ├── projetos.js   # criar, listar, buscar projetos
│       ├── tarefas.js    # criar, mover, listar tarefas
│       ├── sprints.js    # criar, planning, progresso
│       └── git.js        # branch, PR, commits, release
├── supabase/
│   └── migrations/       # 62 migrations versionadas
├── .mcp.json             # Configuração MCP (Claude Code)
├── docker-compose.yml
└── Dockerfile
```

---

## Pré-requisitos

- Node.js 20+
- npm 10+
- [Supabase CLI](https://supabase.com/docs/guides/cli) — `npm install -g supabase`
- Docker (opcional, para deploy)

---

## Instalação

### 1. Clonar e instalar dependências

```bash
git clone <url-do-repositorio>
cd GESTAO_PROJTOS_VUE
npm install
```

### 2. Configurar variáveis de ambiente

```bash
cp env.dev .env
```

Edite `.env` com suas credenciais Supabase:

```env
SUPABASE_URL=http://127.0.0.1:54321          # local
SUPABASE_ANON_KEY=sua_anon_key
SUPABASE_SERVICE_ROLE_KEY=sua_service_role_key  # necessária para o MCP
```

### 3. Subir Supabase local

```bash
npx supabase start
npx supabase db reset    # aplica todas as migrations + seed
```

Após o `start`, o CLI exibe as chaves:

```
API URL:          http://127.0.0.1:54321
anon key:         eyJ...
service_role key: eyJ...   ← copie esta para o .mcp.json
```

### 4. Rodar o frontend

```bash
npm run dev
# http://localhost:3000
```

### 5. Docker (opcional)

```bash
docker compose up --build
```

---

## Kanban — Colunas e Git Flow

As colunas do Kanban seguem o fluxo profissional de Git Flow:

| Coluna | ID interno | O que fazer |
|--------|-----------|-------------|
| Backlog | `backlog` | Refinamento e priorização |
| Pronto para Dev | `a_fazer` | Criar branch com o guia Git |
| Em Desenvolvimento | `em_progresso` | Commits frequentes na branch |
| Code Review | `em_revisao` | Abrir PR com template gerado |
| CI / Testes | `ci_testes` | Pipeline: lint → build → testes |
| Homologação | `homologacao` | Validação em staging com PO |
| Concluído | `concluido` | Merge realizado, branch deletada |

---

## Autenticação e papéis

Login via e-mail/senha pelo Supabase Auth.

| Papel | Permissões |
|-------|-----------|
| `admin` | Gerencia projetos, equipe e planos |
| `desenvolvedor` | Cria e edita tarefas |
| `visualizador` | Somente leitura |

---

## MCP — Integração com LLMs

O servidor MCP permite que qualquer LLM compatível (Claude, Cursor, Windsurf, etc.) acesse e manipule o sistema diretamente — criando projetos, tarefas, sprints e gerando guias de Git Flow.

### 20 tools disponíveis

**Sessão / Autenticação**
| Tool | Descrição |
|------|-----------|
| `identificar_usuario` | Retorna UUID do usuário pelo email — chame sempre primeiro |
| `meus_projetos` | Lista projetos do usuário pelo email |

**Projetos**
| Tool | Descrição |
|------|-----------|
| `criar_projeto` | Cria novo projeto |
| `listar_projetos` | Lista projetos por usuário |
| `buscar_projeto` | Detalhes + métricas de um projeto |

**Tarefas**
| Tool | Descrição |
|------|-----------|
| `criar_tarefa` | Cria tarefa no backlog com tipo, critério de aceite e story points |
| `criar_subtarefa` | Subtarefa vinculada a uma tarefa pai |
| `listar_backlog` | Tarefas sem sprint, prontas para planning |
| `listar_tarefas_sprint` | Tarefas de uma sprint com status por coluna |
| `mover_tarefa` | Move entre colunas Kanban + retorna orientação do passo |
| `atualizar_tarefa` | Atualiza qualquer campo de uma tarefa |

**Sprints**
| Tool | Descrição |
|------|-----------|
| `criar_sprint` | Cria sprint com objetivo e datas |
| `adicionar_tarefa_sprint` | Move tarefa do backlog para a sprint |
| `listar_sprints` | Sprints do projeto com status |
| `progresso_sprint` | Pontos, percentual, tarefas pendentes |
| `calcular_capacidade` | `devs × horas × dias × produtividade` |

**Git Flow**
| Tool | Descrição |
|------|-----------|
| `gerar_branch` | Nome da branch + 3 comandos git prontos para copiar |
| `gerar_pr_template` | Descrição completa do PR gerada da tarefa |
| `gerar_commit_sugerido` | Sequência de commits Conventional Commits |
| `iniciar_release` | Wizard completo: branch → homologação → main → tag → deploy |

---

## Conectar o MCP

### Claude Code (recomendado)

O arquivo `.mcp.json` já está configurado na raiz do projeto. Abra o Claude Code dentro desta pasta — o servidor MCP carrega automaticamente.

```json
{
  "mcpServers": {
    "gestao-projetos": {
      "command": "node",
      "args": ["C:\\caminho\\para\\GESTAO_PROJTOS_VUE\\mcp\\server.js"],
      "env": {
        "SUPABASE_URL": "http://127.0.0.1:54321",
        "SUPABASE_SERVICE_ROLE_KEY": "sua_service_role_key"
      }
    }
  }
}
```

### Claude Desktop

Adicione ao arquivo `claude_desktop_config.json`:

- **Windows:** `%APPDATA%\Claude\claude_desktop_config.json`
- **macOS:** `~/Library/Application Support/Claude/claude_desktop_config.json`

```json
{
  "mcpServers": {
    "gestao-projetos": {
      "command": "node",
      "args": ["/caminho/absoluto/GESTAO_PROJTOS_VUE/mcp/server.js"],
      "env": {
        "SUPABASE_URL": "http://127.0.0.1:54321",
        "SUPABASE_SERVICE_ROLE_KEY": "sua_service_role_key"
      }
    }
  }
}
```

### Cursor / Windsurf / Outros

Settings → MCP Servers → adicionar entrada com o mesmo bloco acima.

> **Requisito:** Supabase local deve estar rodando (`npx supabase start`) antes de iniciar o MCP server.

---

## Como usar com uma LLM

### Prompt inicial (cole no início de cada sessão)

```
Você tem acesso ao sistema de gestão de projetos via MCP (gestao-projetos).

Meu email cadastrado é: seu@email.com

Regras:
1. Sempre chame identificar_usuario com meu email antes de qualquer operação
2. Use o UUID retornado como proprietario_id e criado_por em todas as chamadas
3. Ao criar tarefas, inclua criterio_aceite e story points sempre que possível
4. Ao mover tarefas para em_progresso, chame gerar_branch automaticamente
5. Ao mover para em_revisao, chame gerar_pr_template automaticamente

[DESCREVA O QUE VOCÊ QUER FAZER]
```

### Exemplos de uso

**Planejar um projeto do zero:**
```
Meu email é joao@empresa.com. Quero criar um app de delivery de farmácias.
Quebre em features, crie as tarefas com critérios de aceite e monte a Sprint 1.
```

**Iniciar desenvolvimento de uma tarefa:**
```
Meu email é joao@empresa.com. Quero começar a trabalhar na tarefa de 
cadastro de clientes. Gere a branch e os commits sugeridos.
```

**Ver progresso da sprint:**
```
Meu email é joao@empresa.com. Qual o progresso atual da Sprint 1 
do projeto FrotaApp? Quais tarefas ainda estão pendentes?
```

**Criar uma release:**
```
Meu email é joao@empresa.com. A Sprint 1 terminou. 
Gere o guia de release para a versão v1.0.0.
```

### Fluxo completo de uma sessão

```
Você: "Meu email é joao@empresa.com. Quero planejar um app de frotas."

LLM chama:
  1. identificar_usuario("joao@empresa.com")         → UUID obtido
  2. criar_projeto("FrotaApp", "Gestão de veículos") → projeto_id
  3. criar_tarefa("Cadastro de veículos", "feature")  → tarefa_id_1
  4. criar_tarefa("Rastreamento GPS", "feature")      → tarefa_id_2
  5. criar_tarefa("Relatório de km", "feature")       → tarefa_id_3
  6. calcular_capacidade(num_devs=2)                  → 96h disponíveis
  7. criar_sprint("Sprint 1 — MVP")                  → sprint_id
  8. adicionar_tarefa_sprint(sprint_id, tarefa_id_1)
  9. adicionar_tarefa_sprint(sprint_id, tarefa_id_2)

LLM responde:
  "Projeto FrotaApp criado com 3 features. Sprint 1 planejada com
   2 tarefas (capacidade: 96h). Para começar:
   
   git checkout develop
   git pull origin develop
   git checkout -b feature/cadastro-veiculos"
```

Na próxima sessão, qualquer LLM chama `meus_projetos(email)` e retoma exatamente o estado atual.

---

## Guia do Desenvolvedor (in-app)

Acesse `/guia-dev` no app para referência completa sempre disponível:

- **Branches** — estrutura, nomenclatura, regras
- **Commits** — Conventional Commits com exemplos
- **Pull Request** — template e checklist
- **CI Pipeline** — etapas obrigatórias
- **Release** — fluxo completo com SemVer

---

## Comandos úteis

```bash
# Desenvolvimento
npm run dev                    # Frontend em http://localhost:3000

# Supabase
npx supabase start             # Inicia banco local
npx supabase stop              # Para banco local
npx supabase db reset          # Reaplica migrations + seed
npx supabase status            # Exibe URLs e chaves

# MCP (teste manual)
echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0"}}}' \
  | SUPABASE_URL=http://127.0.0.1:54321 \
    SUPABASE_SERVICE_ROLE_KEY=sua_key \
    node mcp/server.js

# Docker
docker compose up --build      # Sobe tudo em container
docker compose down            # Para containers
```

---

## Convenção de branches

```
main          → produção, sempre estável
develop       → integração contínua
feature/*     → nova funcionalidade
bugfix/*      → correção não-urgente
hotfix/*      → emergência em produção
release/*     → preparo de versão
```

## Convenção de commits

```
feat:     nova funcionalidade
fix:      correção de bug
refactor: sem mudança de comportamento
test:     testes
docs:     documentação
chore:    manutenção e configuração
perf:     performance
ci:       pipeline CI
```

---

## Papéis dos agentes (Claude Code)

O projeto usa agentes especializados para cada fase do desenvolvimento:

| Agente | Fase |
|--------|------|
| `planner` | Quebrar ideias em tasks e definir branches |
| `coder` | Implementar com commits atômicos |
| `pr-manager` | Abrir PR com descrição completa |
| `ci-validator` | Verificar lint, build e testes |
| `reviewer` | Code review completo |
| `tester` | QA e testes de regressão |
| `release-manager` | Release, homologação e tag |
| `deploy-guard` | Deploy e healthcheck |
| `monitor-agent` | Monitoramento e hotfix |

---

## Licença

Privado — uso interno.
