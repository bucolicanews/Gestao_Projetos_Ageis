// supabase/functions/stripe-webhook/index.ts
// Recebe notificações de pagamento do Stripe e atualiza o banco
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import Stripe from 'npm:stripe'

Deno.serve(async (req) => {
  try {
    const admin = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    )

    // Busca webhook secret conforme ambiente
    const { data: cfg } = await admin
      .from('configuracoes_pagamentos')
      .select('stripe_env, stripe_secret_key, stripe_secret_key_test, stripe_webhook_secret, stripe_webhook_secret_test')
      .single()

    if (!cfg) throw new Error('Config não encontrada')

    const secretKey     = cfg.stripe_env === 'live' ? cfg.stripe_secret_key      : cfg.stripe_secret_key_test
    const webhookSecret = cfg.stripe_env === 'live' ? cfg.stripe_webhook_secret  : cfg.stripe_webhook_secret_test

    const stripe    = new Stripe(secretKey)
    const signature = req.headers.get('stripe-signature') || ''
    const rawBody   = await req.text()

    let event: Stripe.Event
    try {
      event = await stripe.webhooks.constructEventAsync(rawBody, signature, webhookSecret)
    } catch {
      return new Response('Assinatura inválida', { status: 400 })
    }

    if (
      event.type === 'checkout.session.completed' ||
      event.type === 'checkout.session.async_payment_succeeded'
    ) {
      const session = event.data.object as Stripe.Checkout.Session
      const sessionId = session.id
      const orgId     = session.metadata?.org_id || session.client_reference_id
      const planoId   = session.metadata?.plano_id || null

      // Idempotência
      const { data: pag } = await admin
        .from('stripe_payments')
        .select('id, status')
        .eq('stripe_session_id', sessionId)
        .maybeSingle()

      if (pag && pag.status === 'completed') {
        return new Response('already processed', { status: 200 })
      }

      // Atualiza status do pagamento
      if (pag) {
        await admin
          .from('stripe_payments')
          .update({ status: 'completed' })
          .eq('id', pag.id)
      } else {
        await admin.from('stripe_payments').insert({
          org_id:           orgId,
          plano_id:         planoId || null,
          stripe_session_id: sessionId,
          status:           'completed',
          amount:           (session.amount_total || 0) / 100,
        })
      }

      // Ativa organização e estende vencimento +30 dias
      if (orgId) {
        const vencimento = new Date()
        vencimento.setDate(vencimento.getDate() + 30)

        await admin
          .from('organizacoes')
          .update({
            status: 'ativo',
            ativo: true,
            vencimento: vencimento.toISOString().split('T')[0],
            bloqueado_em: null,
            bloqueado_motivo: null,
            ...(planoId ? { plano_id: planoId } : {}),
          })
          .eq('id', orgId)
      }
    }

    return new Response('ok', { status: 200 })

  } catch (e: any) {
    console.error('stripe-webhook error:', e.message)
    return new Response(e.message, { status: 500 })
  }
})
