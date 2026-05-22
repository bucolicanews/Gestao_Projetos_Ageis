export const servicoNotificacoes = () => {
  const cliente = useSupabaseClient()
  const user = useSupabaseUser()

  async function listar() {
    const { data, error } = await cliente
      .from('notificacoes')
      .select('*')
      .eq('usuario_id', user.value!.id)
      .order('criado_em', { ascending: false })
      .limit(50)
    if (error) throw error
    return data || []
  }

  async function marcarLida(id: string) {
    const { error } = await cliente
      .from('notificacoes')
      .update({ lida: true })
      .eq('id', id)
      .eq('usuario_id', user.value!.id)
    if (error) throw error
  }

  async function marcarTodasLidas() {
    const { error } = await cliente
      .from('notificacoes')
      .update({ lida: true })
      .eq('usuario_id', user.value!.id)
      .eq('lida', false)
    if (error) throw error
  }

  async function criar(payload: {
    usuario_id: string
    tipo: 'tarefa_atribuida' | 'comentario' | 'prazo' | 'subtarefa' | 'convite' | 'geral'
    titulo: string
    mensagem?: string
    tarefa_id?: string
    projeto_id?: string
  }) {
    const { error } = await cliente.from('notificacoes').insert(payload)
    if (error) throw error
  }

  return { listar, marcarLida, marcarTodasLidas, criar }
}
