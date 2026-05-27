// composables/useConfiguracoesSistema.ts
export const useConfiguracoesSistema = () => {
  const cliente = useSupabaseClient()
  const carregando = ref(false)
  const salvando = ref(false)
  const erro = ref<string | null>(null)
  const sucesso = ref(false)

  async function carregar(): Promise<Record<string, string>> {
    carregando.value = true
    erro.value = null
    try {
      const { data, error } = await cliente
        .from('configuracoes_sistema')
        .select('chave, valor')
      if (error) throw error
      return Object.fromEntries((data ?? []).map(r => [r.chave, r.valor ?? '']))
    } catch (e: any) {
      erro.value = e.message
      return {}
    } finally {
      carregando.value = false
    }
  }

  async function salvar(configs: Record<string, string>): Promise<boolean> {
    salvando.value = true
    erro.value = null
    sucesso.value = false
    try {
      const rows = Object.entries(configs).map(([chave, valor]) => ({ chave, valor }))
      const { error } = await cliente
        .from('configuracoes_sistema')
        .upsert(rows, { onConflict: 'chave' })
      if (error) throw error
      sucesso.value = true
      setTimeout(() => sucesso.value = false, 3000)
      return true
    } catch (e: any) {
      erro.value = e.message
      return false
    } finally {
      salvando.value = false
    }
  }

  return { carregando, salvando, erro, sucesso, carregar, salvar }
}
