// servicos/servicoComentarios.ts
export const servicoComentarios = () => {
  const cliente = useSupabaseClient()

  async function listarComentarios(tarefaId: string) {
    const { data, error } = await cliente.from('comentarios')
      .select('*, autor:usuarios!comentarios_autor_id_fkey(id, nome, avatar_url)')
      .eq('tarefa_id', tarefaId)
      .order('criado_em', { ascending: true })
    if (error) throw error
    return data
  }

  async function adicionar(tarefa_id: string, conteudo: string) {
    const { data, error } = await cliente.functions.invoke('adicionarComentario', {
      body: { tarefa_id, conteudo },
    })
    if (error) throw error
    return data
  }

  return { listarComentarios, adicionar }
}
