// servicos/servicoOrganizacoesAdmin.ts
// Visão develop_admin — acesso total a todas as organizações

export interface OrgAdmin {
  id: string
  nome: string
  plano: string | null
  plano_id: string | null
  status: string
  ativo: boolean
  vencimento: string | null
  telefone: string | null
  email_contato: string | null
  bloqueado_em: string | null
  bloqueado_motivo: string | null
  dono_id: string
  criado_em: string
  planos?: { titulo: string; preco: number } | null
  dono?: { nome: string; email: string } | null
}

export interface OrgAdminInput {
  nome?: string
  plano_id?: string | null
  status?: string
  vencimento?: string | null
  telefone?: string | null
  email_contato?: string | null
  bloqueado_motivo?: string | null
}

export const servicoOrganizacoesAdmin = () => {
  const cliente = useSupabaseClient()

  async function listarTodas(filtros?: { status?: string; plano_id?: string }): Promise<OrgAdmin[]> {
    let query = cliente
      .from('organizacoes')
      .select(`
        *,
        planos ( titulo, preco ),
        dono:usuarios!organizacoes_dono_usuarios_fkey ( nome, email )
      `)
      .order('criado_em', { ascending: false })

    if (filtros?.status && filtros.status !== 'todos') {
      query = query.eq('status', filtros.status)
    }
    if (filtros?.plano_id) {
      query = query.eq('plano_id', filtros.plano_id)
    }

    const { data, error } = await query
    if (error) throw error
    return (data ?? []) as OrgAdmin[]
  }

  async function obter(id: string): Promise<OrgAdmin> {
    const { data, error } = await cliente
      .from('organizacoes')
      .select(`
        *,
        planos ( titulo, preco ),
        dono:usuarios!organizacoes_dono_usuarios_fkey ( nome, email )
      `)
      .eq('id', id)
      .single()
    if (error) throw error
    return data as OrgAdmin
  }

  async function atualizar(id: string, payload: OrgAdminInput): Promise<OrgAdmin> {
    const { data, error } = await cliente
      .from('organizacoes')
      .update(payload)
      .eq('id', id)
      .select()
      .single()
    if (error) throw error
    return data as OrgAdmin
  }

  async function bloquear(id: string, motivo: string): Promise<void> {
    const { error } = await cliente
      .from('organizacoes')
      .update({
        status: 'bloqueado',
        ativo: false,
        bloqueado_em: new Date().toISOString(),
        bloqueado_motivo: motivo,
      })
      .eq('id', id)
    if (error) throw error
  }

  async function desbloquear(id: string): Promise<void> {
    const { error } = await cliente
      .from('organizacoes')
      .update({
        status: 'ativo',
        ativo: true,
        bloqueado_em: null,
        bloqueado_motivo: null,
      })
      .eq('id', id)
    if (error) throw error
  }

  async function listarUsuarios(orgId: string) {
    const { data, error } = await cliente
      .from('usuarios')
      .select('id, nome, email, perfil, criado_em')
      .eq('organizacao_id', orgId)
      .order('criado_em', { ascending: true })
    if (error) throw error
    return data ?? []
  }

  async function registrarMensagem(payload: {
    org_id: string
    tipo: string
    mensagem: string
    status: 'enviado' | 'falhou'
  }): Promise<void> {
    const { data: { user } } = await cliente.auth.getUser()
    const { error } = await cliente
      .from('log_mensagens_org')
      .insert({ ...payload, enviado_por: user?.id })
    if (error) throw error
  }

  async function listarMensagens(orgId: string) {
    const { data, error } = await cliente
      .from('log_mensagens_org')
      .select('*')
      .eq('org_id', orgId)
      .order('enviado_em', { ascending: false })
    if (error) throw error
    return data ?? []
  }

  return {
    listarTodas,
    obter,
    atualizar,
    bloquear,
    desbloquear,
    listarUsuarios,
    registrarMensagem,
    listarMensagens,
  }
}
