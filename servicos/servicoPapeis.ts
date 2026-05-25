// servicos/servicoPapeis.ts
export interface Papel {
  id: string
  nome: string
  descricao: string | null
  cor: string
  permissoes: string[]
  criado_em: string
}

export type PapelPayload = {
  nome: string
  descricao?: string
  cor?: string
  permissoes?: string[]
}

export const servicoPapeis = () => {
  const cliente = useSupabaseClient()

  async function listar(): Promise<Papel[]> {
    const { data, error } = await cliente
      .from('papeis_projeto')
      .select('*')
      .order('nome')
    if (error) throw error
    return (data || []).map(p => ({ ...p, permissoes: p.permissoes ?? [] }))
  }

  async function criar(payload: PapelPayload): Promise<Papel> {
    const { data, error } = await cliente
      .from('papeis_projeto')
      .insert(payload)
      .select()
    if (error) {
      throw new Error(error.message || error.details || error.hint || `code ${error.code}`)
    }
    return data?.[0] ?? null
  }

  async function atualizar(id: string, payload: PapelPayload): Promise<Papel> {
    const { data, error } = await cliente
      .from('papeis_projeto')
      .update(payload)
      .eq('id', id)
      .select()
    if (error) {
      throw new Error(error.message || error.details || error.hint || `code ${error.code}`)
    }
    return data?.[0] ?? null
  }

  async function excluir(id: string): Promise<void> {
    const { error } = await cliente.from('papeis_projeto').delete().eq('id', id)
    if (error) {
      throw new Error(error.message || error.details || error.hint || `code ${error.code}`)
    }
  }

  return { listar, criar, atualizar, excluir }
}

export const PERMISSOES_DISPONIVEIS = [
  // Projetos
  { chave: 'criar_projeto',       label: 'Criar projetos',              grupo: 'Projetos' },
  { chave: 'editar_projeto',      label: 'Editar projetos',             grupo: 'Projetos' },
  { chave: 'excluir_projeto',     label: 'Excluir projetos',            grupo: 'Projetos' },
  // Tarefas
  { chave: 'criar_tarefa',        label: 'Criar tarefas',               grupo: 'Tarefas'  },
  { chave: 'editar_tarefa',       label: 'Editar tarefas',              grupo: 'Tarefas'  },
  { chave: 'excluir_tarefa',      label: 'Excluir tarefas',             grupo: 'Tarefas'  },
  { chave: 'comentar',            label: 'Comentar em tarefas',         grupo: 'Tarefas'  },
  // Equipe
  { chave: 'convidar_usuario',    label: 'Convidar usuários',           grupo: 'Equipe'   },
  { chave: 'gerenciar_usuarios',  label: 'Gerenciar usuários',          grupo: 'Equipe'   },
  { chave: 'promover_admin',      label: 'Promover Administradores',    grupo: 'Equipe'   },
  // Sprints
  { chave: 'gerenciar_sprint',    label: 'Gerenciar sprints',           grupo: 'Sprints'  },
  { chave: 'aprovar_demanda',     label: 'Aprovar demandas',            grupo: 'Sprints'  },
  // Relatórios
  { chave: 'ver_relatorios',      label: 'Visualizar relatórios',       grupo: 'Relatórios' },
  { chave: 'ver_logs',            label: 'Visualizar logs e auditorias',grupo: 'Relatórios' },
  // Sistema
  { chave: 'configuracoes_globais', label: 'Configurações globais',     grupo: 'Sistema'  },
  { chave: 'acessar_faturamento', label: 'Acessar faturamento',         grupo: 'Sistema'  },
  { chave: 'excluir_organizacao', label: 'Excluir organização',         grupo: 'Sistema'  },
] as const
