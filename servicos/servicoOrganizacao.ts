// servicos/servicoOrganizacao.ts
export const servicoOrganizacao = () => {
  const cliente = useSupabaseClient()

  async function minha() {
    const { data } = await cliente
      .from('organizacoes')
      .select('*')
      .single()
    return data as { id: string; nome: string; plano: string; ativo: boolean; dono_id: string; criado_em: string } | null
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
