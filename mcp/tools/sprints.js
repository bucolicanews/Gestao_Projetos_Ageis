export const sprintsTools = [
  {
    name: 'criar_sprint',
    description: 'Cria uma nova sprint para o projeto.',
    inputSchema: {
      type: 'object',
      properties: {
        projeto_id:  { type: 'string' },
        nome:        { type: 'string', description: 'Ex: Sprint 1 — MVP Cadastros' },
        objetivo:    { type: 'string', description: 'O que deve estar pronto ao final desta sprint' },
        data_inicio: { type: 'string', description: 'YYYY-MM-DD' },
        data_fim:    { type: 'string', description: 'YYYY-MM-DD' },
        capacidade_horas: { type: 'number', description: 'Horas disponíveis da equipe (devs × horas/dia × dias × produtividade)' },
      },
      required: ['projeto_id', 'nome'],
    },
  },
  {
    name: 'adicionar_tarefa_sprint',
    description: 'Adiciona uma tarefa do backlog a uma sprint.',
    inputSchema: {
      type: 'object',
      properties: {
        sprint_id: { type: 'string' },
        tarefa_id: { type: 'string' },
      },
      required: ['sprint_id', 'tarefa_id'],
    },
  },
  {
    name: 'listar_sprints',
    description: 'Lista todas as sprints de um projeto com progresso.',
    inputSchema: {
      type: 'object',
      properties: {
        projeto_id: { type: 'string' },
      },
      required: ['projeto_id'],
    },
  },
  {
    name: 'progresso_sprint',
    description: 'Retorna progresso detalhado de uma sprint: pontos, colunas, velocity, tarefas pendentes.',
    inputSchema: {
      type: 'object',
      properties: {
        sprint_id: { type: 'string' },
      },
      required: ['sprint_id'],
    },
  },
  {
    name: 'calcular_capacidade',
    description: 'Calcula capacidade de sprint com base na equipe. Fórmula: devs × horas_dia × dias × fator_produtividade.',
    inputSchema: {
      type: 'object',
      properties: {
        num_devs:       { type: 'number', description: 'Número de desenvolvedores' },
        horas_por_dia:  { type: 'number', description: 'Horas produtivas por dia (padrão: 6)' },
        dias_sprint:    { type: 'number', description: 'Duração da sprint em dias (padrão: 10)' },
        produtividade:  { type: 'number', description: 'Fator de produtividade 0-1 (padrão: 0.8)' },
      },
      required: ['num_devs'],
    },
  },
]

export async function executarSprintsTool(nome, args, db) {
  switch (nome) {
    case 'criar_sprint':           return criarSprint(args, db)
    case 'adicionar_tarefa_sprint':return adicionarTarefaSprint(args, db)
    case 'listar_sprints':         return listarSprints(args, db)
    case 'progresso_sprint':       return progressoSprint(args, db)
    case 'calcular_capacidade':    return calcularCapacidade(args)
    default: return null
  }
}

async function criarSprint(args, db) {
  const { data, error } = await db
    .from('sprints')
    .insert({
      projeto_id:       args.projeto_id,
      nome:             args.nome,
      objetivo:         args.objetivo,
      data_inicio:      args.data_inicio,
      data_fim:         args.data_fim,
      capacidade_horas: args.capacidade_horas,
      status:           'planejada',
    })
    .select()
    .single()
  if (error) throw error
  return {
    sprint: data,
    mensagem: `Sprint "${data.nome}" criada (ID: ${data.id})`,
    proximos_passos: ['Use adicionar_tarefa_sprint para popular a sprint com tarefas do backlog'],
  }
}

async function adicionarTarefaSprint(args, db) {
  const { data, error } = await db
    .from('tarefas')
    .update({ sprint_id: args.sprint_id, coluna: 'a_fazer', atualizado_em: new Date().toISOString() })
    .eq('id', args.tarefa_id)
    .select('id, titulo, pontos')
    .single()
  if (error) throw error
  return {
    tarefa: data,
    mensagem: `"${data.titulo}" adicionada à sprint. Pronta para desenvolvimento.`,
    orientacao: 'Use gerar_branch quando o dev iniciar o desenvolvimento desta tarefa.',
  }
}

async function listarSprints(args, db) {
  const { data, error } = await db
    .from('sprints')
    .select('id, nome, objetivo, status, data_inicio, data_fim, sp_planejados, capacidade_horas')
    .eq('projeto_id', args.projeto_id)
    .order('criado_em', { ascending: false })
  if (error) throw error
  return { sprints: data, total: data.length }
}

async function progressoSprint(args, db) {
  const { data: sprint, error: se } = await db
    .from('sprints')
    .select('*')
    .eq('id', args.sprint_id)
    .single()
  if (se) throw se

  const { data: tarefas } = await db
    .from('tarefas')
    .select('id, titulo, coluna, pontos, dod_ok, tipo_tarefa, prioridade')
    .eq('sprint_id', args.sprint_id)

  const total = tarefas?.length ?? 0
  const concluidas = tarefas?.filter(t => t.coluna === 'concluido').length ?? 0
  const pontosConcluidos = tarefas?.filter(t => t.coluna === 'concluido').reduce((s, t) => s + (t.pontos ?? 0), 0) ?? 0
  const pontosTotal = tarefas?.reduce((s, t) => s + (t.pontos ?? 0), 0) ?? 0

  const pendentes = tarefas?.filter(t => t.coluna !== 'concluido') ?? []

  return {
    sprint,
    progresso: {
      tarefas_total: total,
      tarefas_concluidas: concluidas,
      percentual: total ? Math.round((concluidas / total) * 100) : 0,
      pontos_concluidos: pontosConcluidos,
      pontos_total: pontosTotal,
    },
    tarefas_pendentes: pendentes.map(t => ({ id: t.id, titulo: t.titulo, coluna: t.coluna, pontos: t.pontos })),
  }
}

function calcularCapacidade(args) {
  const devs = args.num_devs
  const horas = args.horas_por_dia ?? 6
  const dias = args.dias_sprint ?? 10
  const prod = args.produtividade ?? 0.8
  const capacidade = devs * horas * dias * prod

  return {
    capacidade_horas: capacidade,
    formula: `${devs} devs × ${horas}h/dia × ${dias} dias × ${prod} produtividade`,
    recomendacao: `Planeje tarefas com estimativa total próxima de ${Math.round(capacidade)}h. Não exceda 90%.`,
  }
}
