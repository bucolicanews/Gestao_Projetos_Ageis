// servicos/servicoOrganizacao.ts
export const servicoOrganizacao = () => {
  const cliente = useSupabaseClient()

  async function minha() {
    const userId = (await cliente.auth.getUser()).data.user?.id ?? ''
    const { data } = await cliente
      .from('organizacoes')
      .select('*, planos(id, titulo, descricao, preco, recursos)')
      .eq('dono_id', userId)
      .maybeSingle()
    return data as {
      id: string; nome: string; plano: string; plano_id: string | null
      ativo: boolean; status: string; vencimento: string | null
      dono_id: string; criado_em: string
      planos: { id: string; titulo: string; descricao: string; preco: number; recursos: string[] } | null
    } | null
  }

  async function atualizar(id: string, payload: { nome?: string }) {
    const { data, error } = await cliente
      .from('organizacoes')
      .update(payload)
      .eq('id', id)
      .select()
      .single()
    if (error) throw error
    return data
  }

  async function meuPerfil() {
    const { data } = await cliente
      .from('usuarios')
      .select('perfil, organizacao_id')
      .eq('id', (await cliente.auth.getUser()).data.user?.id ?? '')
      .single()
    return data
  }

  return { minha, atualizar, meuPerfil }
}
