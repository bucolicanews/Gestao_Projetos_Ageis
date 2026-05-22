// servicos/servicoSubTarefas.ts
// Subtarefas usam a própria tabela 'tarefas' com tarefa_pai_id (auto-referência).
export const servicoSubTarefas = () => {
  const cliente = useSupabaseClient()
  const user = useSupabaseUser()

  async function listar(tarefaPaiId: string) {
    const { data, error } = await cliente
      .from('tarefas')
      .select('*, responsavel:usuarios!tarefas_responsavel_id_fkey(id, nome), filhos:tarefas!tarefa_pai_id(id)')
      .eq('tarefa_pai_id', tarefaPaiId)
      .order('posicao', { ascending: true })
    if (error) throw error
    return (data || []).map((t: any) => ({
      ...t,
      subtarefas_count: t.filhos?.length || 0,
      filhos: undefined,
    }))
  }

  async function criar(payload: {
    titulo: string
    tarefa_pai_id: string
    projeto_id: string
    sprint_id?: string | null
    coluna?: string
    prioridade?: string
  }) {
    const { data, error } = await cliente
      .from('tarefas')
      .insert({
        coluna: 'a_fazer',
        prioridade: 'media',
        posicao: 0,
        ...payload,
        criado_por: user.value!.id,
      })
      .select()
      .single()
    if (error) throw error
    return data
  }

  async function atualizar(id: string, alteracoes: any) {
    const { data, error } = await cliente
      .from('tarefas')
      .update(alteracoes)
      .eq('id', id)
      .select()
      .single()
    if (error) throw error
    return data
  }

  async function excluir(id: string) {
    const { error } = await cliente.from('tarefas').delete().eq('id', id)
    if (error) throw error
  }

  async function alternarColunaById(id: string, concluida: boolean) {
    return atualizar(id, { coluna: concluida ? 'concluido' : 'a_fazer' })
  }

  return { listar, criar, atualizar, excluir, alternarColunaById }
}
