import { serverSupabaseServiceRole, serverSupabaseUser } from '#supabase/server'

export default defineEventHandler(async (event) => {
  const { plano_id } = await readBody(event)
  if (!plano_id) throw createError({ statusCode: 400, message: 'plano_id obrigatório' })

  const user = await serverSupabaseUser(event)
  if (!user) throw createError({ statusCode: 401, message: 'Não autenticado' })

  const admin = serverSupabaseServiceRole(event)

  const { data: plano, error: planoErr } = await admin
    .from('planos')
    .select('id, gratuito, ativo, dias_trial')
    .eq('id', plano_id)
    .eq('ativo', true)
    .maybeSingle()

  if (planoErr || !plano) throw createError({ statusCode: 404, message: 'Plano não encontrado' })
  if (!plano.gratuito) throw createError({ statusCode: 400, message: 'Este plano não é gratuito' })

  let vencimento: string | null = null
  if (plano.dias_trial && plano.dias_trial > 0) {
    const fim = new Date()
    fim.setDate(fim.getDate() + plano.dias_trial)
    vencimento = fim.toISOString().split('T')[0]
  }

  const { error: updateErr } = await admin
    .from('organizacoes')
    .update({ plano_id, status: 'ativo', vencimento })
    .eq('dono_id', user.id)

  if (updateErr) throw createError({ statusCode: 500, message: updateErr.message })

  return { ok: true, vencimento, dias_trial: plano.dias_trial ?? 0 }
})
