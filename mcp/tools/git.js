const PREFIXO = { feature: 'feature', bug: 'bugfix', melhoria: 'feature', techdeb: 'chore', spike: 'spike' }
const COMMIT_TIPO = { feature: 'feat', bug: 'fix', melhoria: 'feat', techdeb: 'chore', spike: 'docs' }

function slug(texto) {
  return texto.toLowerCase()
    .normalize('NFD').replace(/[̀-ͯ]/g, '')
    .replace(/[^a-z0-9\s]/g, '').trim()
    .replace(/\s+/g, '-').slice(0, 40).replace(/-$/, '')
}

export const gitTools = [
  {
    name: 'gerar_branch',
    description: 'Gera nome de branch e comandos git para iniciar desenvolvimento de uma tarefa.',
    inputSchema: {
      type: 'object',
      properties: {
        tarefa_id: { type: 'string', description: 'UUID da tarefa (para buscar tipo e título)' },
      },
      required: ['tarefa_id'],
    },
  },
  {
    name: 'gerar_pr_template',
    description: 'Gera template completo de Pull Request a partir dos dados da tarefa.',
    inputSchema: {
      type: 'object',
      properties: {
        tarefa_id: { type: 'string' },
      },
      required: ['tarefa_id'],
    },
  },
  {
    name: 'gerar_commit_sugerido',
    description: 'Gera sequência de commits sugeridos para uma tarefa seguindo Conventional Commits.',
    inputSchema: {
      type: 'object',
      properties: {
        tarefa_id: { type: 'string' },
      },
      required: ['tarefa_id'],
    },
  },
  {
    name: 'iniciar_release',
    description: 'Gera guia passo a passo para criar uma release: branch, homologação, merge, tag, deploy.',
    inputSchema: {
      type: 'object',
      properties: {
        versao: { type: 'string', description: 'Versão semântica. Ex: v1.5.0' },
        sprint_id: { type: 'string', description: 'Sprint que originou a release (opcional)' },
      },
      required: ['versao'],
    },
  },
]

export async function executarGitTool(nome, args, db) {
  switch (nome) {
    case 'gerar_branch':          return gerarBranch(args, db)
    case 'gerar_pr_template':     return gerarPRTemplate(args, db)
    case 'gerar_commit_sugerido': return gerarCommitSugerido(args, db)
    case 'iniciar_release':       return iniciarRelease(args, db)
    default: return null
  }
}

async function buscarTarefa(tarefa_id, db) {
  const { data, error } = await db
    .from('tarefas')
    .select('id, titulo, tipo_tarefa, descricao, criterio_aceite, pontos')
    .eq('id', tarefa_id)
    .single()
  if (error) throw error
  return data
}

async function gerarBranch(args, db) {
  const t = await buscarTarefa(args.tarefa_id, db)
  const prefixo = PREFIXO[t.tipo_tarefa] ?? 'feature'
  const branch = `${prefixo}/${slug(t.titulo)}`

  return {
    branch,
    comandos: [
      'git checkout develop',
      'git pull origin develop',
      `git checkout -b ${branch}`,
    ],
    push: `git push origin ${branch}`,
    mensagem: `Branch gerada para "${t.titulo}"`,
    proximos_passos: [
      `Execute os comandos acima para criar a branch`,
      'Use mover_tarefa com coluna "em_progresso" quando iniciar',
      'Faça commits frequentes com gerar_commit_sugerido',
    ],
  }
}

async function gerarPRTemplate(args, db) {
  const t = await buscarTarefa(args.tarefa_id, db)
  const prefixo = COMMIT_TIPO[t.tipo_tarefa] ?? 'feat'
  const tituloCommit = `${prefixo}: ${slug(t.titulo).replace(/-/g, ' ')}`

  const linhas = [
    `## O que foi feito`,
    t.descricao || `Implementa: ${t.titulo}`,
    '',
    t.criterio_aceite ? `## Critérios de aceite\n${t.criterio_aceite}\n` : '',
    `## Checklist`,
    `- [ ] Testes passando`,
    `- [ ] Build sem erros`,
    `- [ ] Review solicitado (mín. 1 aprovação)`,
    `- [ ] Testado localmente`,
    t.pontos ? `\n**Story Points:** ${t.pontos}` : '',
  ].filter(l => l !== null)

  return {
    titulo_pr: tituloCommit,
    descricao: linhas.join('\n'),
    regras: [
      'PR aponta para develop — NUNCA para main',
      'Mínimo 1 approval + CI verde antes do merge',
      'Delete a branch após o merge',
    ],
  }
}

async function gerarCommitSugerido(args, db) {
  const t = await buscarTarefa(args.tarefa_id, db)
  const base = slug(t.titulo).replace(/-/g, ' ')
  const tipo = t.tipo_tarefa

  const sequencias = {
    feature:  [`feat: criar modelo ${base}`, `feat: implementar service ${base}`, `feat: criar endpoint ${base}`, `test: adicionar testes de ${base}`],
    bug:      [`fix: identificar causa raiz em ${base}`, `fix: corrigir logica de ${base}`, `test: verificar correcao de ${base}`],
    melhoria: [`feat: melhorar ${base}`, `perf: otimizar ${base}`, `test: validar melhoria em ${base}`],
    techdeb:  [`refactor: extrair logica de ${base}`, `chore: remover codigo duplicado`, `test: garantir cobertura apos refactor`],
    spike:    [`docs: registrar descobertas sobre ${base}`, `docs: documentar decisao tecnica de ${base}`],
  }

  return {
    tarefa: t.titulo,
    sequencia: sequencias[tipo] ?? sequencias.feature,
    lembrete: 'Commits pequenos e frequentes. Nunca "projeto pronto" como único commit.',
    referencia: {
      'feat': 'nova funcionalidade',
      'fix': 'correção de bug',
      'refactor': 'sem mudança de comportamento',
      'test': 'testes',
      'docs': 'documentação',
      'chore': 'manutenção',
      'perf': 'performance',
      'ci': 'pipeline CI',
    },
  }
}

async function iniciarRelease(args, db) {
  const v = args.versao

  let tarefas_sprint = []
  if (args.sprint_id) {
    const { data } = await db.from('tarefas').select('titulo, coluna, pontos').eq('sprint_id', args.sprint_id)
    tarefas_sprint = data ?? []
  }

  const pendentes = tarefas_sprint.filter(t => t.coluna !== 'concluido')

  return {
    versao: v,
    aviso: pendentes.length > 0 ? `⚠️ ${pendentes.length} tarefas ainda não concluídas na sprint` : null,
    passos: [
      {
        passo: 1,
        titulo: 'Criar branch de release',
        comandos: ['git checkout develop', 'git pull origin develop', `git checkout -b release/${v}`],
      },
      {
        passo: 2,
        titulo: 'Homologação com PO',
        acao: 'Deploy em staging. PO valida funcionalidades. Somente bugfixes nesta branch.',
      },
      {
        passo: 3,
        titulo: 'Merge para main',
        comandos: ['git checkout main', `git merge release/${v}`, 'git push origin main'],
      },
      {
        passo: 4,
        titulo: 'Criar tag',
        comandos: [`git tag ${v}`, `git push origin ${v}`],
      },
      {
        passo: 5,
        titulo: 'Sync develop',
        comandos: ['git checkout develop', 'git merge main', 'git push origin develop'],
      },
      {
        passo: 6,
        titulo: 'Deploy produção',
        acao: 'Pipeline CI/CD dispara ao push na main. Monitore logs e métricas.',
      },
    ],
    semver: {
      MAJOR: 'quebra compatibilidade',
      MINOR: 'nova funcionalidade compatível',
      PATCH: 'correção de bug',
    },
  }
}
