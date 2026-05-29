// composables/usePermissoesProjeto.ts
// Carrega permissões do usuário atual em todos os projetos via uma única query.
// Admin/develop_admin recebem wildcard '*' — têm tudo.

export function usePermissoesProjeto() {
  const cliente      = useSupabaseClient()
  const usuarioAtual = useSupabaseUser()

  // projeto_id → string[] de permissões
  const permissoesPorProjeto = ref<Record<string, string[]>>({})
  const carregado = ref(false)

  async function carregar() {
    if (!usuarioAtual.value) return

    // Admin/develop_admin têm wildcard — sem precisar buscar papeis
    const { data: eu } = await cliente
      .from('usuarios')
      .select('perfil')
      .eq('id', usuarioAtual.value.id)
      .single()

    if (eu?.perfil === 'admin' || eu?.perfil === 'develop_admin') {
      // Marca como wildcard em todos os projetos registrando globalmente
      permissoesPorProjeto.value = { '*': ['*'] }
      carregado.value = true
      return
    }

    // Busca membros_projeto do usuário com papel e suas permissões
    const { data: membros } = await cliente
      .from('membros_projeto')
      .select('projeto_id, papel, papeis_projeto!membros_projeto_papel_fkey(permissoes)')
      .eq('usuario_id', usuarioAtual.value.id)

    const mapa: Record<string, string[]> = {}
    for (const m of membros || []) {
      const perms = (m as any).papeis_projeto?.permissoes ?? []
      mapa[m.projeto_id] = perms
    }

    permissoesPorProjeto.value = mapa
    carregado.value = true
  }

  function temPermissao(projetoId: string, chave: string): boolean {
    // Wildcard global (admin/develop_admin)
    if (permissoesPorProjeto.value['*']?.includes('*')) return true
    const perms = permissoesPorProjeto.value[projetoId] ?? []
    return perms.includes('*') || perms.includes(chave)
  }

  // Carrega automaticamente quando o usuário estiver disponível
  watch(usuarioAtual, (u) => { if (u) carregar() }, { immediate: true })

  return { permissoesPorProjeto, carregado, temPermissao, carregar }
}
