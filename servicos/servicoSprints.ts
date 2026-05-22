// servicos/servicoSprints.ts
export const servicoSprints = () => {
  const cliente = useSupabaseClient()

  async function listar(projetoId: string) {
    const { data, error } = await cliente.from('sprints')
      .select('*')
      .eq('projeto_id', projetoId)
      .order('data_inicio', { ascending: false })
    if (error) throw error
    return data
  }

  async function obter(id: string) {
    const { data, error } = await cliente.from('sprints').select('*').eq('id', id).single()
    if (error) throw error
    return data
  }

  async function criar(payload: any) {
    const { data, error } = await cliente.from('sprints').insert(payload).select().single()
    if (error) throw error
    return data
  }

  async function atualizar(id: string, alt: any) {
    const { data, error } = await cliente.from('sprints').update(alt).eq('id', id).select().single()
    if (error) throw error
    return data
  }

  async function excluir(id: string) {
    const { error } = await cliente.from('sprints').delete().eq('id', id)
    if (error) throw error
  }

  // -------- Tarefas <-> Sprint --------
  async function tarefasDaSprint(sprintId: string) {
    const { data, error } = await cliente.from('tarefas')
      .select('*, responsavel:usuarios!tarefas_responsavel_id_fkey(id, nome)')
      .eq('sprint_id', sprintId)
      .order('coluna')
    if (error) throw error
    return data
  }

  async function tarefasDoBacklog(projetoId: string, sprintAtualId?: string) {
    let query = cliente.from('tarefas')
      .select('*, responsavel:usuarios!tarefas_responsavel_id_fkey(id, nome), sprint:sprints(id, nome)')
      .eq('projeto_id', projetoId)
      .is('tarefa_pai_id', null)
      .order('posicao', { ascending: true })

    if (sprintAtualId) {
      // Show tasks not yet in this sprint: unassigned OR in another sprint
      query = query.or(`sprint_id.is.null,sprint_id.neq.${sprintAtualId}`)
    } else {
      query = query.is('sprint_id', null)
    }

    const { data, error } = await query
    if (error) throw error
    return data || []
  }

  async function throughputSprint(sprintId: string) {
    const { data, error } = await cliente
      .from('tarefas')
      .select('concluido_em')
      .eq('sprint_id', sprintId)
      .eq('coluna', 'concluido')
      .not('concluido_em', 'is', null)
    if (error) throw error
    return data || []
  }

  async function associarTarefa(tarefaId: string, sprintId: string | null) {
    const { error } = await cliente.from('tarefas').update({ sprint_id: sprintId }).eq('id', tarefaId)
    if (error) throw error
  }

  // -------- Burndown --------
  async function snapshots(sprintId: string) {
    const { data, error } = await cliente.from('snapshots_sprint')
      .select('*')
      .eq('sprint_id', sprintId)
      .order('data')
    if (error) throw error
    return data
  }

  async function registrarSnapshotHoje(sprintId: string) {
    const { error } = await cliente.rpc('registrar_snapshot_sprint', { _sprint_id: sprintId })
    if (error) throw error
  }

  // -------- Sprint Membros (capacity planning) --------
  async function listarMembros(sprintId: string) {
    const { data, error } = await cliente.from('sprint_membros')
      .select('*, usuario:usuarios(id, nome, avatar_url)')
      .eq('sprint_id', sprintId)
    if (error) throw error
    return data || []
  }

  async function salvarMembro(sprintId: string, usuarioId: string, horas_dia = 6, fator_produtividade = 0.8) {
    const { data, error } = await cliente.from('sprint_membros')
      .upsert({ sprint_id: sprintId, usuario_id: usuarioId, horas_dia, fator_produtividade }, { onConflict: 'sprint_id,usuario_id' })
      .select()
      .single()
    if (error) throw error
    return data
  }

  async function removerMembro(sprintId: string, usuarioId: string) {
    const { error } = await cliente.from('sprint_membros')
      .delete()
      .eq('sprint_id', sprintId)
      .eq('usuario_id', usuarioId)
    if (error) throw error
  }

  // -------- Velocity --------
  async function velocityProjeto(projetoId: string) {
    const { data, error } = await cliente.from('velocity_historico')
      .select('*, sprint:sprints(nome, data_inicio, data_fim)')
      .eq('projeto_id', projetoId)
      .order('gravado_em', { ascending: true })
    if (error) throw error
    return data || []
  }

  async function velocityMedia(projetoId: string): Promise<number> {
    const { data, error } = await cliente.from('v_velocity_projeto')
      .select('velocity_media')
      .eq('projeto_id', projetoId)
      .single()
    if (error) return 0
    return Number((data as any)?.velocity_media || 0)
  }

  return {
    listar, obter, criar, atualizar, excluir,
    tarefasDaSprint, tarefasDoBacklog, associarTarefa,
    snapshots, registrarSnapshotHoje, throughputSprint,
    listarMembros, salvarMembro, removerMembro,
    velocityProjeto, velocityMedia,
  }
}
