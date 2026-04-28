// servicos/servicoEquipe.ts
export const servicoEquipe = () => {
  const cliente = useSupabaseClient()


  async function listarMembros() {
    const { data, error } = await cliente.from('membros_projeto')
      .select(`
        id,
        usuario_id,
        papel,
        usuarios (
          id,
          nome,
          email,
          avatar_url,
          perfil
        )
      `)
      if (error) throw error
    

    return data
  }
  async function listarMembrosPorID(projetoId: string) {
    const { data, error } = await cliente.from('membros_projeto')
      .select(`
        id,
        usuario_id,
        papel,
        usuarios (
          id,
          nome,
          email,
          avatar_url,
          perfil
        )
      `)
      .eq('projeto_id', projetoId)
    if (error) throw error
    console.log('Membros do projeto:', data)
    return data
  }

  async function adicionarMembro(projeto_id: string, usuario_id: string, papel = 'desenvolvedor') {
    const { error } = await cliente.from('membros_projeto').insert({ projeto_id, usuario_id, papel })
    if (error) throw error
  }

  async function removerMembro(id: string) {
    const { error } = await cliente.from('membros_projeto').delete().eq('id', id)
    if (error) throw error
  }
  console.log('Listando membros...'+listarMembros)
  return { listarMembros, adicionarMembro, removerMembro, listarMembrosPorID }
}
