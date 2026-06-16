export const projetosTools = [
  {
    name: 'criar_projeto',
    description: 'Cria um novo projeto no sistema de gestão.',
    inputSchema: {
      type: 'object',
      properties: {
        nome:      { type: 'string', description: 'Nome do projeto' },
        descricao: { type: 'string', description: 'Descrição e objetivo do projeto' },
        proprietario_id: { type: 'string', description: 'UUID do usuário proprietário' },
      },
      required: ['nome', 'proprietario_id'],
    },
  },
  {
    name: 'listar_projetos',
    description: 'Lista todos os projetos de um usuário.',
    inputSchema: {
      type: 'object',
      properties: {
        proprietario_id: { type: 'string', description: 'UUID do usuário' },
      },
      required: ['proprietario_id'],
    },
  },
  {
    name: 'buscar_projeto',
    description: 'Detalhes completos de um projeto incluindo métricas de sprints e tarefas.',
    inputSchema: {
      type: 'object',
      properties: {
        projeto_id: { type: 'string' },
      },
      required: ['projeto_id'],
    },
  },
]

export async function executarProjetosTool(nome, args, db) {
  switch (nome) {
    case 'criar_projeto':    return criarProjeto(args, db)
    case 'listar_projetos':  return listarProjetos(args, db)
    case 'buscar_projeto':   return buscarProjeto(args, db)
    default: return null
  }
}

async function criarProjeto(args, db) {
  const { data, error } = await db
    .from('projetos')
    .insert({ nome: args.nome, descricao: args.descricao, proprietario_id: args.proprietario_id })
    .select()
    .single()
  if (error) throw error
  return { projeto: data, mensagem: `Projeto "${data.nome}" criado com ID ${data.id}` }
}

async function listarProjetos(args, db) {
  const { data, error } = await db
    .from('projetos')
    .select('id, nome, descricao, status, criado_em')
    .eq('proprietario_id', args.proprietario_id)
    .order('criado_em', { ascending: false })
  if (error) throw error
  return { projetos: data, total: data.length }
}

async function buscarProjeto(args, db) {
  const { data: projeto, error } = await db
    .from('projetos')
    .select('*')
    .eq('id', args.projeto_id)
    .single()
  if (error) throw error

  const { data: sprints } = await db.from('sprints').select('id, nome, status').eq('projeto_id', args.projeto_id)
  const { data: tarefas } = await db.from('tarefas').select('id, coluna, pontos').eq('projeto_id', args.projeto_id)

  const concluidas = tarefas?.filter(t => t.coluna === 'concluido').length ?? 0
  return {
    projeto,
    sprints: sprints ?? [],
    resumo: {
      total_tarefas: tarefas?.length ?? 0,
      concluidas,
      total_pontos: tarefas?.reduce((s, t) => s + (t.pontos ?? 0), 0) ?? 0,
    },
  }
}
