// supabase/functions/create-pagbank-payment/index.ts
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { cabecalhosCors } from '../_compartilhado/cors.ts'

const PAGBANK_URLS = {
  sandbox:  'https://sandbox.api.pagseguro.com',
  producao: 'https://api.pagseguro.com',
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: cabecalhosCors })
  }

  try {
    // Autentica usuário
    const supa = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_ANON_KEY')!,
      { global: { headers: { Authorization: req.headers.get('Authorization') || '' } } }
    )
    const { data: { user }, error: authErr } = await supa.auth.getUser()
    if (authErr || !user) throw new Error('Não autenticado')

    // Usa service_role para ler config e escrever pagamentos
    const admin = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    )

    const body = await req.json()
    const { org_id, plano_id, amount, payment_method, metadata = {} } = body

    if (!org_id || !amount || !payment_method) {
      throw new Error('Campos obrigatórios: org_id, amount, payment_method')
    }

    // Busca configuração PagBank
    const { data: cfg, error: cfgErr } = await admin
      .from('configuracoes_pagamentos')
      .select('pagbank_enabled, pagbank_env, pagbank_token_sandbox, pagbank_token_producao, pagbank_pass_fees_to_customer, pagbank_pix_fee_fixed, pagbank_pix_fee_percentage, pagbank_card_fee_fixed, pagbank_card_fee_percentage')
      .single()
    if (cfgErr || !cfg) throw new Error('Configuração de pagamento não encontrada')
    if (!cfg.pagbank_enabled) throw new Error('PagBank não está habilitado')

    const token = cfg.pagbank_env === 'producao' ? cfg.pagbank_token_producao : cfg.pagbank_token_sandbox
    if (!token) throw new Error(`Token PagBank (${cfg.pagbank_env}) não configurado`)

    // Busca dados da org
    const { data: org } = await admin
      .from('organizacoes')
      .select('nome, email_contato, dono:usuarios!organizacoes_dono_usuarios_fkey(nome, email)')
      .eq('id', org_id)
      .single()
    if (!org) throw new Error('Organização não encontrada')

    // Calcula valor final com taxa (se configurado)
    let valorFinal = amount
    if (cfg.pagbank_pass_fees_to_customer) {
      const feeFixed = payment_method === 'pix' ? Number(cfg.pagbank_pix_fee_fixed) : Number(cfg.pagbank_card_fee_fixed)
      const feePct   = payment_method === 'pix' ? Number(cfg.pagbank_pix_fee_percentage) : Number(cfg.pagbank_card_fee_percentage)
      valorFinal = Math.ceil(((amount + feeFixed) / (1 - feePct / 100)) * 100) / 100
    }
    const valorCentavos = Math.round(valorFinal * 100)

    const referenceId = `SUB_${org_id.substring(0, 8)}_${Date.now()}`
    const baseUrl = PAGBANK_URLS[cfg.pagbank_env as 'sandbox' | 'producao']
    const webhookUrl = `${Deno.env.get('SUPABASE_URL')}/functions/v1/pagbank-webhook`

    const nomeCliente = (org.dono as any)?.nome || org.nome
    const emailCliente = (org.dono as any)?.email || org.email_contato || 'contato@email.com'
    const taxId = (metadata.cpf || '').replace(/\D/g, '') || '00000000000'
    const nomeFormatado = nomeCliente.includes(' ') ? nomeCliente : `${nomeCliente} Cliente`

    let pagbankResponse: any
    let endpoint: string

    if (payment_method === 'pix') {
      endpoint = `${baseUrl}/orders`
      const expiracao = new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString().replace('.000Z', 'Z')
      const payload = {
        reference_id: referenceId,
        customer: { name: nomeFormatado, email: emailCliente, tax_id: taxId },
        items: [{ name: 'Assinatura Gestão Ágil', quantity: 1, unit_amount: valorCentavos }],
        qr_codes: [{ amount: { value: valorCentavos }, expiration_date: expiracao }],
        notification_urls: [webhookUrl],
      }
      const res = await fetch(endpoint, {
        method: 'POST',
        headers: { 'Authorization': `Bearer ${token}`, 'Content-Type': 'application/json', 'x-api-version': '4.0' },
        body: JSON.stringify(payload),
      })
      pagbankResponse = await res.json()
      if (!res.ok) throw new Error(`PagBank: ${pagbankResponse?.error_messages?.[0]?.description || res.statusText}`)

    } else {
      endpoint = `${baseUrl}/checkouts`
      const expiracao = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString().replace('.000Z', 'Z')
      const telNum = (metadata.telefone || '').replace(/\D/g, '')
      const phone = telNum.length >= 10
        ? [{ country: '55', area: telNum.substring(0, 2), number: telNum.substring(2), type: 'MOBILE' }]
        : undefined
      const payload: any = {
        reference_id: referenceId,
        expiration_date: expiracao,
        customer: { name: nomeFormatado, email: emailCliente, tax_id: taxId, ...(phone ? { phones: phone } : {}) },
        items: [{ reference_id: `ITEM_${referenceId}`, name: 'Assinatura Gestão Ágil', quantity: 1, unit_amount: valorCentavos }],
        notification_urls: [webhookUrl],
      }
      const res = await fetch(endpoint, {
        method: 'POST',
        headers: { 'Authorization': `Bearer ${token}`, 'Content-Type': 'application/json', 'x-api-version': '4.0' },
        body: JSON.stringify(payload),
      })
      pagbankResponse = await res.json()
      if (!res.ok) throw new Error(`PagBank: ${pagbankResponse?.error_messages?.[0]?.description || res.statusText}`)
    }

    // Extrai resultado
    const orderId      = pagbankResponse.id
    const qrCode       = pagbankResponse.qr_codes?.[0]?.links?.find((l: any) => l.rel === 'QRCODE.PNG')?.href ?? null
    const qrCodeText   = pagbankResponse.qr_codes?.[0]?.text ?? null
    const checkoutLink = pagbankResponse.links?.find((l: any) => l.rel === 'PAY')?.href ?? null

    // Salva no banco
    await admin.from('pagbank_payments').insert({
      org_id,
      plano_id: plano_id || null,
      pagbank_order_id: orderId,
      reference_id: referenceId,
      status: 'PENDING',
      amount: valorFinal,
      payment_method,
      qr_code: qrCode,
      qr_code_text: qrCodeText,
      checkout_link: checkoutLink,
    })

    return new Response(JSON.stringify({
      success: true,
      qr_code: qrCode,
      qr_code_text: qrCodeText,
      checkout_link: checkoutLink,
      order_id: orderId,
    }), { headers: { ...cabecalhosCors, 'Content-Type': 'application/json' } })

  } catch (e: any) {
    return new Response(JSON.stringify({ success: false, error: e.message }), {
      status: 400,
      headers: { ...cabecalhosCors, 'Content-Type': 'application/json' },
    })
  }
})
