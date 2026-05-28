export const servicoNotificacoes = () => {
  const cliente = useSupabaseClient()
  const user = useSupabaseUser()

  async function listar() {
    const { data, error } = await cliente
      .from('notificacoes')
      .select('*')
      .eq('usuario_id', user.value!.id)
      .eq('arquivada', false)
      .order('criado_em', { ascending: false })
      .limit(50)
    if (error) throw error
    return data || []
  }

  async function listarArquivadas() {
    const { data, error } = await cliente
      .from('notificacoes')
      .select('*')
      .eq('usuario_id', user.value!.id)
      .eq('arquivada', true)
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
      .eq('arquivada', false)
    if (error) throw error
  }

  async function arquivar(id: string) {
    const { error } = await cliente
      .from('notificacoes')
      .update({ arquivada: true, lida: true })
      .eq('id', id)
      .eq('usuario_id', user.value!.id)
    if (error) throw error
  }

  async function arquivarTodasLidas() {
    const { error } = await cliente
      .from('notificacoes')
      .update({ arquivada: true })
      .eq('usuario_id', user.value!.id)
      .eq('lida', true)
      .eq('arquivada', false)
    if (error) throw error
  }

  async function excluir(id: string) {
    const { error } = await cliente
      .from('notificacoes')
      .delete()
      .eq('id', id)
      .eq('usuario_id', user.value!.id)
    if (error) throw error
  }

  async function criar(payload: {
    usuario_id: string
    tipo: 'tarefa_atribuida' | 'comentario' | 'prazo' | 'subtarefa' | 'convite' | 'geral' | 'cobranca'
    titulo: string
    mensagem?: string
    tarefa_id?: string
    projeto_id?: string
  }) {
    const { error } = await cliente.from('notificacoes').insert(payload)
    if (error) throw error
  }

  return {
    listar, listarArquivadas,
    marcarLida, marcarTodasLidas,
    arquivar, arquivarTodasLidas,
    excluir,
    criar,
  }
}
