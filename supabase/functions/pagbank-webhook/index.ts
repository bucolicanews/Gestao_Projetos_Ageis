// supabase/functions/pagbank-webhook/index.ts
// Recebe notificações de pagamento do PagBank e atualiza o banco
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const STATUS_PAGOS = ['PAID', 'COMPLETED', 'AUTHORIZED']

Deno.serve(async (req) => {
  // PagBank faz GET para verificar a URL — responde 200
  if (req.method === 'GET') {
    return new Response('ok', { status: 200 })
  }

  try {
    const admin = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    )

    const body = await req.json()

    // PagBank envia charges[] com o status atualizado
    const charges: any[] = body.charges ?? body.data?.charges ?? []
    if (!charges.length) {
      return new Response('no charges', { status: 200 })
    }

    for (const charge of charges) {
      const status    = charge.status as string
      const orderId   = charge.id as string
      const referenceId = charge.reference_id as string

      // Busca o pagamento pelo order_id ou pelo reference_id
      const { data: pag } = await admin
        .from('pagbank_payments')
        .select('id, org_id, plano_id, status')
        .or(`pagbank_order_id.eq.${orderId},reference_id.eq.${referenceId}`)
        .maybeSingle()

      if (!pag) continue
      if (pag.status === 'PAID') continue // idempotência

      // Atualiza status do pagamento
      await admin
        .from('pagbank_payments')
        .update({ status, atualizado_em: new Date().toISOString() })
        .eq('id', pag.id)

      // Se pago, ativa a organização e estende vencimento +30 dias
      if (STATUS_PAGOS.includes(status)) {
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
            ...(pag.plano_id ? { plano_id: pag.plano_id } : {}),
          })
          .eq('id', pag.org_id)
      }
    }

    return new Response('ok', { status: 200 })

  } catch (e: any) {
    console.error('pagbank-webhook error:', e.message)
    return new Response(e.message, { status: 500 })
  }
})
