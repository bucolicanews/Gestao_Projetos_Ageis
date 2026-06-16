export const tarefasTools = [
  {
    name: 'criar_tarefa',
    description: 'Cria uma tarefa no backlog do projeto. Use para quebrar funcionalidades em itens acionáveis.',
    inputSchema: {
      type: 'object',
      properties: {
        projeto_id:      { type: 'string' },
        sprint_id:       { type: 'string', description: 'Opcional — atribuir a uma sprint' },
        titulo:          { type: 'string' },
        descricao:       { type: 'string' },
        tipo_tarefa:     { type: 'string', enum: ['feature', 'bug', 'melhoria', 'techdeb', 'spike'], default: 'feature' },
        prioridade:      { type: 'string', enum: ['baixa', 'media', 'alta', 'urgente'], default: 'media' },
        criterio_aceite: { type: 'string', description: 'Critérios de aceite (Given/When/Then)' },
        pontos:          { type: 'number', description: 'Story points Fibonacci: 1,2,3,5,8,13,21' },
        estimativa_horas:{ type: 'number' },
        criado_por:      { type: 'string', description: 'UUID do usuário criador' },
      },
      required: ['projeto_id', 'titulo', 'criado_por'],
    },
  },
  {
    name: 'criar_subtarefa',
    description: 'Cria uma subtarefa vinculada a uma tarefa pai. Use para detalhar implementação técnica.',
    inputSchema: {
      type: 'object',
      properties: {
        tarefa_pai_id: { type: 'string' },
        projeto_id:    { type: 'string' },
        titulo:        { type: 'string' },
        descricao:     { type: 'string' },
        criado_por:    { type: 'string' },
      },
      required: ['tarefa_pai_id', 'projeto_id', 'titulo', 'criado_por'],
    },
  },
  {
    name: 'listar_backlog',
    description: 'Lista tarefas do backlog (sem sprint). Útil para planejar próxima sprint.',
    inputSchema: {
      type: 'object',
      properties: {
        projeto_id: { type: 'string' },
        tipo_tarefa:{ type: 'string', enum: ['feature', 'bug', 'melhoria', 'techdeb', 'spike'] },
        prioridade: { type: 'string', enum: ['baixa', 'media', 'alta', 'urgente'] },
      },
      required: ['projeto_id'],
    },
  },
  {
    name: 'listar_tarefas_sprint',
    description: 'Lista todas as tarefas de uma sprint com status e pontos.',
    inputSchema: {
      type: 'object',
      properties: {
        sprint_id: { type: 'string' },
      },
      required: ['sprint_id'],
    },
  },
  {
    name: 'mover_tarefa',
    description: 'Move tarefa entre colunas do Kanban seguindo o Git Flow.',
    inputSchema: {
      type: 'object',
      properties: {
        tarefa_id: { type: 'string' },
        coluna: {
          type: 'string',
          enum: ['backlog', 'a_fazer', 'em_progresso', 'em_revisao', 'ci_testes', 'homologacao', 'concluido'],
          description: 'backlog→a_fazer(branch criada)→em_progresso(dev)→em_revisao(PR)→ci_testes→homologacao→concluido',
        },
      },
      required: ['tarefa_id', 'coluna'],
    },
  },
  {
    name: 'atualizar_tarefa',
    description: 'Atualiza campos de uma tarefa existente.',
    inputSchema: {
      type: 'object',
      properties: {
        tarefa_id:       { type: 'string' },
        titulo:          { type: 'string' },
        descricao:       { type: 'string' },
        criterio_aceite: { type: 'string' },
        pontos:          { type: 'number' },
        prioridade:      { type: 'string', enum: ['baixa', 'media', 'alta', 'urgente'] },
        dor_ok:          { type: 'boolean' },
        dod_ok:          { type: 'boolean' },
      },
      required: ['tarefa_id'],
    },
  },
]

export async function executarTarefasTool(nome, args, db) {
  switch (nome) {
    case 'criar_tarefa':         return criarTarefa(args, db)
    case 'criar_subtarefa':      return criarSubtarefa(args, db)
    case 'listar_backlog':       return listarBacklog(args, db)
    case 'listar_tarefas_sprint':return listarTarefasSprint(args, db)
    case 'mover_tarefa':         return moverTarefa(args, db)
    case 'atualizar_tarefa':     return atualizarTarefa(args, db)
    default: return null
  }
}

async function criarTarefa(args, db) {
  const { data, error } = await db
    .from('tarefas')
    .insert({
      projeto_id:       args.projeto_id,
      sprint_id:        args.sprint_id ?? null,
      titulo:           args.titulo,
      descricao:        args.descricao,
      tipo_tarefa:      args.tipo_tarefa ?? 'feature',
      prioridade:       args.prioridade ?? 'media',
      criterio_aceite:  args.criterio_aceite,
      pontos:           args.pontos ?? null,
      estimativa_horas: args.estimativa_horas ?? null,
      criado_por:       args.criado_por,
      coluna:           'backlog',
    })
    .select()
    .single()
  if (error) throw error
  return {
    tarefa: data,
    mensagem: `Tarefa "${data.titulo}" criada (ID: ${data.id})`,
    proximos_passos: [
      'Use criar_subtarefa para detalhar implementação',
      'Use adicionar_tarefa_sprint para incluir em uma sprint',
      'Use gerar_branch quando iniciar desenvolvimento',
    ],
  }
}

async function criarSubtarefa(args, db) {
  const { data, error } = await db
    .from('sub_tarefas')
    .insert({
      tarefa_pai_id: args.tarefa_pai_id,
      projeto_id:    args.projeto_id,
      titulo:        args.titulo,
      descricao:     args.descricao,
      criado_por:    args.criado_por,
    })
    .select()
    .single()
  if (error) throw error
  return { subtarefa: data, mensagem: `Subtarefa "${data.titulo}" criada` }
}

async function listarBacklog(args, db) {
  let query = db
    .from('tarefas')
    .select('id, titulo, tipo_tarefa, prioridade, pontos, criterio_aceite, dor_ok')
    .eq('projeto_id', args.projeto_id)
    .is('sprint_id', null)
    .order('prioridade', { ascending: false })

  if (args.tipo_tarefa) query = query.eq('tipo_tarefa', args.tipo_tarefa)
  if (args.prioridade)  query = query.eq('prioridade', args.prioridade)

  const { data, error } = await query
  if (error) throw error
  return {
    backlog: data,
    total: data.length,
    pontos_total: data.reduce((s, t) => s + (t.pontos ?? 0), 0),
  }
}

async function listarTarefasSprint(args, db) {
  const { data, error } = await db
    .from('tarefas')
    .select('id, titulo, tipo_tarefa, coluna, prioridade, pontos, dor_ok, dod_ok, responsavel_id')
    .eq('sprint_id', args.sprint_id)
    .order('coluna')
  if (error) throw error

  const por_coluna = data.reduce((acc, t) => {
    acc[t.coluna] = (acc[t.coluna] || [])
    acc[t.coluna].push(t)
    return acc
  }, {})

  return {
    tarefas: data,
    total: data.length,
    por_coluna,
    pontos_concluidos: data.filter(t => t.coluna === 'concluido').reduce((s, t) => s + (t.pontos ?? 0), 0),
  }
}

async function moverTarefa(args, db) {
  const { data, error } = await db
    .from('tarefas')
    .update({ coluna: args.coluna, atualizado_em: new Date().toISOString() })
    .eq('id', args.tarefa_id)
    .select('id, titulo, coluna')
    .single()
  if (error) throw error

  const guia = {
    a_fazer:      'Crie a branch com gerar_branch. Dev pode iniciar.',
    em_progresso: 'Commits frequentes na branch. Use gerar_commit_sugerido.',
    em_revisao:   'Abra o PR. Use gerar_pr_template para a descrição.',
    ci_testes:    'Pipeline rodando. Aguardar CI verde antes de avançar.',
    homologacao:  'Deploy em staging. PO valida as funcionalidades.',
    concluido:    'Merge realizado. Branch deletada. DoD completo.',
  }

  return {
    tarefa: data,
    mensagem: `Tarefa movida para "${args.coluna}"`,
    orientacao: guia[args.coluna] ?? '',
  }
}

async function atualizarTarefa(args, db) {
  const { tarefa_id, ...campos } = args
  const { data, error } = await db
    .from('tarefas')
    .update({ ...campos, atualizado_em: new Date().toISOString() })
    .eq('id', tarefa_id)
    .select()
    .single()
  if (error) throw error
  return { tarefa: data, mensagem: 'Tarefa atualizada' }
}
