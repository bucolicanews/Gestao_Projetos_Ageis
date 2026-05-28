// servicos/servicoOrganizacao.ts
export const servicoOrganizacao = () => {
  const cliente = useSupabaseClient()

  async function minha() {
    const userId = (await cliente.auth.getUser()).data.user?.id ?? ''
    // Get org_id from user record (works for both owners and members)
    const { data: u } = await cliente
      .from('usuarios')
      .select('organizacao_id')
      .eq('id', userId)
      .single()
    if (!u?.organizacao_id) return null
    const { data } = await cliente
      .from('organizacoes')
      .select('*, planos(id, titulo, descricao, preco, recursos)')
      .eq('id', u.organizacao_id)
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
    const userId = (await cliente.auth.getUser()).data.user?.id ?? ''
    const { data } = await cliente
      .from('usuarios')
      .select('perfil, organizacao_id')
      .eq('id', userId)
      .single()
    if (!data) return null

    // Fetch custom role name from first project membership
    let nomePapel = ''
    const { data: membro } = await cliente
      .from('membros_projeto')
      .select('papel')
      .eq('usuario_id', userId)
      .limit(1)
      .maybeSingle()
    const ehUuid = (v: string) => /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(v)
    if (membro?.papel) {
      if (ehUuid(membro.papel)) {
        const { data: papel } = await cliente
          .from('papeis_projeto')
          .select('nome')
          .eq('id', membro.papel)
          .maybeSingle()
        nomePapel = papel?.nome || ''
      } else {
        nomePapel = membro.papel
      }
    }

    return { ...data, nomePapel }
  }

  return { minha, atualizar, meuPerfil }
}
