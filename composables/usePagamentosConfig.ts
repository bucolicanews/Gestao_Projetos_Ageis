// composables/usePagamentosConfig.ts

export interface PagamentosConfig {
  id: string
  pagbank_enabled: boolean
  pagbank_env: 'sandbox' | 'producao'
  pagbank_token_sandbox: string
  pagbank_token_producao: string
  pagbank_pass_fees_to_customer: boolean
  pagbank_pix_fee_fixed: number
  pagbank_pix_fee_percentage: number
  pagbank_card_fee_fixed: number
  pagbank_card_fee_percentage: number
  stripe_enabled: boolean
  stripe_env: 'test' | 'live'
  stripe_secret_key: string
  stripe_secret_key_test: string
  stripe_webhook_secret: string
  stripe_webhook_secret_test: string
  stripe_pass_fees_to_customer: boolean
  stripe_fee_percentage: number
  stripe_fee_fixed: number
  pix_key: string
  pix_name: string
  pix_city: string
}

export const usePagamentosConfig = () => {
  const cliente = useSupabaseClient()
  const carregando = ref(false)
  const salvando = ref(false)
  const erro = ref<string | null>(null)
  const sucesso = ref(false)
  let configId = ''

  async function carregar(): Promise<PagamentosConfig | null> {
    carregando.value = true
    erro.value = null
    try {
      const { data, error } = await cliente
        .from('configuracoes_pagamentos')
        .select('*')
        .single()
      if (error) throw error
      configId = data.id
      return data as PagamentosConfig
    } catch (e: any) {
      erro.value = e.message
      return null
    } finally {
      carregando.value = false
    }
  }

  async function salvar(config: Partial<PagamentosConfig>): Promise<boolean> {
    if (!configId) return false
    salvando.value = true
    erro.value = null
    sucesso.value = false
    try {
      const { id: _id, ...campos } = config as any
      const { error } = await cliente
        .from('configuracoes_pagamentos')
        .update({ ...campos, atualizado_em: new Date().toISOString() })
        .eq('id', configId)
      if (error) throw error
      sucesso.value = true
      setTimeout(() => { sucesso.value = false }, 3000)
      return true
    } catch (e: any) {
      erro.value = e.message
      return false
    } finally {
      salvando.value = false
    }
  }

  function calcularTaxaFinal(valor: number, taxaFixa: number, taxaPct: number): number {
    if (!taxaFixa && !taxaPct) return valor
    return Math.ceil(((valor + taxaFixa) / (1 - taxaPct / 100)) * 100) / 100
  }

  return { carregando, salvando, erro, sucesso, carregar, salvar, calcularTaxaFinal }
}
