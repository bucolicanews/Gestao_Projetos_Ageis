// supabase/functions/create-stripe-session/index.ts
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import Stripe from 'npm:stripe'
import { cabecalhosCors } from '../_compartilhado/cors.ts'

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: cabecalhosCors })
  }

  try {
    const supa = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_ANON_KEY')!,
      { global: { headers: { Authorization: req.headers.get('Authorization') || '' } } }
    )
    const { data: { user }, error: authErr } = await supa.auth.getUser()
    if (authErr || !user) throw new Error('Não autenticado')

    const admin = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    )

    const { org_id, plano_id, amount } = await req.json()
    if (!org_id || !amount) throw new Error('Campos obrigatórios: org_id, amount')

    // Busca config Stripe
    const { data: cfg } = await admin
      .from('configuracoes_pagamentos')
      .select('stripe_enabled, stripe_env, stripe_secret_key, stripe_secret_key_test, stripe_pass_fees_to_customer, stripe_fee_fixed, stripe_fee_percentage')
      .single()
    if (!cfg?.stripe_enabled) throw new Error('Stripe não está habilitado')

    const secretKey = cfg.stripe_env === 'live' ? cfg.stripe_secret_key : cfg.stripe_secret_key_test
    if (!secretKey) throw new Error(`Chave Stripe (${cfg.stripe_env}) não configurada`)

    // Busca dados da org
    const { data: org } = await admin
      .from('organizacoes')
      .select('nome, email_contato, dono:usuarios!organizacoes_dono_usuarios_fkey(nome, email)')
      .eq('id', org_id)
      .single()
    if (!org) throw new Error('Organização não encontrada')

    // Calcula valor com taxa (se aplicável)
    let valorFinal = amount
    if (cfg.stripe_pass_fees_to_customer) {
      const feeFixed = Number(cfg.stripe_fee_fixed)
      const feePct   = Number(cfg.stripe_fee_percentage)
      valorFinal = Math.ceil(((amount + feeFixed) / (1 - feePct / 100)) * 100) / 100
    }
    const valorCentavos = Math.round(valorFinal * 100)

    const stripe = new Stripe(secretKey)
    const origin = req.headers.get('origin') || Deno.env.get('SUPABASE_URL')!
    const emailCliente = (org.dono as any)?.email || org.email_contato

    const session = await stripe.checkout.sessions.create({
      payment_method_types: ['card'],
      line_items: [{
        price_data: {
          currency: 'brl',
          product_data: { name: 'Assinatura Gestão Ágil' },
          unit_amount: valorCentavos,
        },
        quantity: 1,
      }],
      mode: 'payment',
      success_url: `${origin}/?payment=success`,
      cancel_url:  `${origin}/?payment=cancel`,
      customer_email: emailCliente || undefined,
      client_reference_id: org_id,
      metadata: {
        org_id,
        plano_id: plano_id || '',
        original_amount: String(amount),
      },
    })

    // Salva no banco
    await admin.from('stripe_payments').insert({
      org_id,
      plano_id: plano_id || null,
      stripe_session_id: session.id,
      status: 'pending',
      amount: valorFinal,
      checkout_url: session.url,
    })

    return new Response(JSON.stringify({ url: session.url }), {
      headers: { ...cabecalhosCors, 'Content-Type': 'application/json' },
    })

  } catch (e: any) {
    return new Response(JSON.stringify({ error: e.message }), {
      status: 400,
      headers: { ...cabecalhosCors, 'Content-Type': 'application/json' },
    })
  }
})
