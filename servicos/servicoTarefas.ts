// servicos/servicoTarefas.ts
export const servicoTarefas = () => {
  const cliente = useSupabaseClient()

  async function listarTarefas(projetoId: string) {
    const { data, error } = await cliente.from('tarefas')
      .select('*, responsavel:usuarios!tarefas_responsavel_id_fkey(id, nome, avatar_url)')
      .eq('projeto_id', projetoId)
      .order('posicao', { ascending: true })
    if (error) throw error
    return data
  }

  async function criarTarefa(payload: any) {
    const { data, error } = await cliente.functions.invoke('criarTarefa', { body: payload })
    if (error) throw error
    return data
  }

  async function atualizarTarefa(id: string, alteracoes: any) {
    const { data, error } = await cliente.from('tarefas').update(alteracoes).eq('id', id).select().single()
    if (error) throw error
    return data
  }

  async function excluirTarefa(id: string) {
    const { error } = await cliente.from('tarefas').delete().eq('id', id)
    if (error) throw error
  }

  async function moverTarefa(tarefa_id: string, coluna: string, posicao: number) {
    const { data, error } = await cliente.functions.invoke('moverTarefaKanban', {
      body: { tarefa_id, coluna, posicao },
    })
    if (error) throw error
    return data
  }

  return { listarTarefas, criarTarefa, atualizarTarefa, excluirTarefa, moverTarefa }
}
