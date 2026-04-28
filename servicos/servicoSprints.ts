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

  async function tarefasDoBacklog(projetoId: string) {
    const { data, error } = await cliente.from('tarefas')
      .select('id, titulo, prioridade')
      .eq('projeto_id', projetoId)
      .is('sprint_id', null)
    if (error) throw error
    return data
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

  return {
    listar, obter, criar, atualizar, excluir,
    tarefasDaSprint, tarefasDoBacklog, associarTarefa,
    snapshots, registrarSnapshotHoje,
  }
}
