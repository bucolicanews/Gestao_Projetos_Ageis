// composables/usePagamento.ts
// Invoca Edge Functions de pagamento do lado do cliente

export interface ConfigGateways {
  pagbank_enabled: boolean
  pagbank_env: string
  pagbank_pass_fees_to_customer: boolean
  pagbank_pix_fee_fixed: number
  pagbank_pix_fee_percentage: number
  pagbank_card_fee_fixed: number
  pagbank_card_fee_percentage: number
  stripe_enabled: boolean
  stripe_env: string
  stripe_pass_fees_to_customer: boolean
  stripe_fee_fixed: number
  stripe_fee_percentage: number
  pix_key: string
  pix_name: string
  pix_city: string
}

export const usePagamento = () => {
  const cliente = useSupabaseClient()
  const processando = ref(false)
  const erro = ref<string | null>(null)

  async function carregarGateways(): Promise<ConfigGateways | null> {
    // Usa view pública — sem tokens, sem segredos
    const { data } = await cliente
      .from('config_gateways_publico')
      .select('*')
      .single()
    return data as ConfigGateways | null
  }

  function calcularTaxa(valor: number, fixo: number, pct: number): number {
    if (!fixo && !pct) return valor
    return Math.ceil(((valor + fixo) / (1 - pct / 100)) * 100) / 100
  }

  async function pagarPagBankPix(payload: {
    org_id: string
    plano_id?: string
    amount: number
    cpf?: string
    telefone?: string
  }) {
    processando.value = true
    erro.value = null
    try {
      const { data, error } = await (cliente as any).functions.invoke('create-pagbank-payment', {
        body: {
          org_id:         payload.org_id,
          plano_id:       payload.plano_id,
          amount:         payload.amount,
          payment_method: 'pix',
          metadata: {
            cpf:      payload.cpf || '',
            telefone: payload.telefone || '',
          },
        },
      })
      if (error) throw error
      if (!data.success) throw new Error(data.error)
      return data as { qr_code: string; qr_code_text: string; order_id: string }
    } catch (e: any) {
      erro.value = e.message
      return null
    } finally {
      processando.value = false
    }
  }

  async function pagarPagBankCartao(payload: {
    org_id: string
    plano_id?: string
    amount: number
    cpf?: string
    telefone?: string
  }) {
    processando.value = true
    erro.value = null
    try {
      const { data, error } = await (cliente as any).functions.invoke('create-pagbank-payment', {
        body: {
          org_id:         payload.org_id,
          plano_id:       payload.plano_id,
          amount:         payload.amount,
          payment_method: 'CREDIT_CARD',
          metadata: { cpf: payload.cpf || '', telefone: payload.telefone || '' },
        },
      })
      if (error) throw error
      if (!data.success) throw new Error(data.error)
      if (data.checkout_link) window.open(data.checkout_link, '_blank')
      return data
    } catch (e: any) {
      erro.value = e.message
      return null
    } finally {
      processando.value = false
    }
  }

  async function pagarStripe(payload: {
    org_id: string
    plano_id?: string
    amount: number
  }) {
    processando.value = true
    erro.value = null
    try {
      const { data, error } = await (cliente as any).functions.invoke('create-stripe-session', {
        body: payload,
      })
      if (error) throw error
      if (data.error) throw new Error(data.error)
      if (data.url) window.location.href = data.url
      return data
    } catch (e: any) {
      erro.value = e.message
      return null
    } finally {
      processando.value = false
    }
  }

  async function pollPagamento(orderId: string, maxTentativas = 24): Promise<boolean> {
    for (let i = 0; i < maxTentativas; i++) {
      await new Promise(r => setTimeout(r, 5000))
      const { data } = await cliente
        .from('pagbank_payments')
        .select('status')
        .eq('pagbank_order_id', orderId)
        .maybeSingle()
      if (['PAID', 'COMPLETED', 'AUTHORIZED'].includes(data?.status ?? '')) return true
    }
    return false
  }

  return {
    processando, erro,
    carregarGateways, calcularTaxa,
    pagarPagBankPix, pagarPagBankCartao, pagarStripe,
    pollPagamento,
  }
}
