// servicos/servicoEquipe.ts
export const servicoEquipe = () => {
  const cliente = useSupabaseClient()


  async function listarMembros() {
    const { data: membros, error } = await cliente
      .from('membros_projeto')
      .select('id, usuario_id, papel')
    if (error) throw error
    if (!membros?.length) return []

    const ids = membros.map((m: any) => m.usuario_id)
    const { data: usuarios, error: err2 } = await cliente
      .from('usuarios')
      .select('id, nome, email, avatar_url')
      .in('id', ids)
    if (err2) throw err2

    const mapa: Record<string, any> = {}
    for (const u of (usuarios || [])) mapa[u.id] = u

    return membros.map((m: any) => ({ ...m, usuarios: mapa[m.usuario_id] ?? null }))
  }
  async function listarMembrosPorID(projetoId: string) {
    const { data: membros, error } = await cliente
      .from('membros_projeto')
      .select('id, usuario_id, papel')
      .eq('projeto_id', projetoId)
    if (error) throw error
    if (!membros?.length) return []

    const ids = membros.map((m: any) => m.usuario_id)
    const { data: usuarios, error: err2 } = await cliente
      .from('usuarios')
      .select('id, nome, email, avatar_url')
      .in('id', ids)
    if (err2) throw err2

    const mapa: Record<string, any> = {}
    for (const u of (usuarios || [])) mapa[u.id] = u

    return membros.map((m: any) => ({ ...m, usuarios: mapa[m.usuario_id] ?? null }))
  }

  async function listarTodos() {
    const { data, error } = await cliente.from('usuarios').select('id, nome, email, avatar_url').order('nome')
    if (error) throw error
    return data || []
  }

  async function adicionarMembro(projeto_id: string, usuario_id: string, papel = 'desenvolvedor') {
    const { error } = await cliente.from('membros_projeto').insert({ projeto_id, usuario_id, papel })
    if (error) throw error
  }

  async function removerMembro(id: string) {
    const { error } = await cliente.from('membros_projeto').delete().eq('id', id)
    if (error) throw error
  }
  return { listarMembros, listarTodos, adicionarMembro, removerMembro, listarMembrosPorID }
}
