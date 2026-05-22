// supabase/functions/criarProjeto/index.ts
import { cabecalhosCors } from '../_compartilhado/cors.ts'
import { obterUsuario } from '../_compartilhado/cliente.ts'

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: cabecalhosCors })
  try {
    const { supa, user } = await obterUsuario(req)
    const { nome, descricao } = await req.json()
    if (!nome || typeof nome !== 'string') {
      return new Response(JSON.stringify({ erro: 'nome obrigatório' }), { status: 400, headers: cabecalhosCors })
    }
    const { data, error } = await supa.from('projetos').insert({
      nome, descricao, proprietario_id: user.id,
    }).select().single()
    if (error) throw error
    return new Response(JSON.stringify(data), { status: 200, headers: { ...cabecalhosCors, 'Content-Type': 'application/json' } })
  } catch (e) {
    return new Response(JSON.stringify({ erro: String(e) }), { status: 400, headers: cabecalhosCors })
  }
})
