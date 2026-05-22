// servicos/servicoTarefas.ts
export const servicoTarefas = () => {
  const cliente = useSupabaseClient()
  const user = useSupabaseUser()

  async function listarTarefas(projetoId: string) {
    const { data, error } = await cliente.from('tarefas')
      .select('*, responsavel:usuarios!tarefas_responsavel_id_fkey(id, nome, avatar_url), filhos:tarefas!tarefa_pai_id(id), sprint:sprints(id,nome)')
      .eq('projeto_id', projetoId)
      .is('tarefa_pai_id', null)
      .order('posicao', { ascending: true })
    if (error) throw error
    return (data || []).map((t: any) => ({
      ...t,
      subtarefas_count: t.filhos?.length || 0,
      filhos: undefined,
    }))
  }

  async function criarTarefa(payload: any) {
    const { data, error } = await cliente
      .from('tarefas')
      .insert({
        prioridade: 'media',
        posicao: 0,
        ...payload,
        criado_por: user.value?.id,
      })
      .select('*, responsavel:usuarios!tarefas_responsavel_id_fkey(id, nome, avatar_url)')
      .single()
    if (error) throw error

    // Notifica responsável se for diferente do criador
    if (data.responsavel_id && data.responsavel_id !== user.value?.id) {
      servicoNotificacoes().criar({
        usuario_id: data.responsavel_id,
        tipo: 'tarefa_atribuida',
        titulo: `Tarefa atribuída a você: "${data.titulo}"`,
        tarefa_id: data.id,
        projeto_id: data.projeto_id,
      }).catch(() => {})
    }

    return { ...data, subtarefas_count: 0 }
  }

  async function atualizarTarefa(id: string, alteracoes: any) {
    const antes = await cliente.from('tarefas').select('responsavel_id, titulo').eq('id', id).single()
    const { data, error } = await cliente.from('tarefas').update(alteracoes).eq('id', id).select().single()
    if (error) throw error

    // Notifica novo responsável se mudou
    const responsavelMudou = alteracoes.responsavel_id &&
      alteracoes.responsavel_id !== antes.data?.responsavel_id &&
      alteracoes.responsavel_id !== user.value?.id
    if (responsavelMudou) {
      servicoNotificacoes().criar({
        usuario_id: alteracoes.responsavel_id,
        tipo: 'tarefa_atribuida',
        titulo: `Tarefa atribuída a você: "${antes.data?.titulo || data.titulo}"`,
        tarefa_id: id,
        projeto_id: data.projeto_id,
      }).catch(() => {})
    }

    return data
  }

  async function excluirTarefa(id: string) {
    const { error } = await cliente.from('tarefas').delete().eq('id', id)
    if (error) throw error
  }

  async function moverTarefa(tarefa_id: string, coluna: string, posicao: number) {
    const { data, error } = await cliente
      .from('tarefas')
      .update({ coluna, posicao })
      .eq('id', tarefa_id)
      .select()
      .single()
    if (error) throw error
    return data
  }

  async function listarBacklog(projetoId: string) {
    const { data, error } = await cliente
      .from('tarefas')
      .select('*, responsavel:usuarios!tarefas_responsavel_id_fkey(id, nome, avatar_url)')
      .eq('projeto_id', projetoId)
      .is('sprint_id', null)
      .is('tarefa_pai_id', null)
      .order('posicao', { ascending: true })
    if (error) throw error
    return (data || []).map((t: any) => ({ ...t, subtarefas_count: 0 }))
  }

  async function listarComSprint(projetoId: string) {
    const { data, error } = await cliente
      .from('tarefas')
      .select('*, responsavel:usuarios!tarefas_responsavel_id_fkey(id, nome), sprint:sprints(id, nome)')
      .eq('projeto_id', projetoId)
      .is('tarefa_pai_id', null)
      .order('posicao', { ascending: true })
    if (error) throw error
    return data || []
  }

  return { listarTarefas, listarBacklog, listarComSprint, criarTarefa, atualizarTarefa, excluirTarefa, moverTarefa }
}
