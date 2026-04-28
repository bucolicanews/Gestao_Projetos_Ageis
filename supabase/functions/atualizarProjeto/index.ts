// supabase/functions/atualizarProjeto/index.ts
import { cabecalhosCors } from '../_compartilhado/cors.ts'
import { obterUsuario } from '../_compartilhado/cliente.ts'

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: cabecalhosCors })
  try {
    const { supa } = await obterUsuario(req)
    const { id, nome, descricao, status } = await req.json()
    if (!id) return new Response(JSON.stringify({ erro: 'id obrigatório' }), { status: 400, headers: cabecalhosCors })
    const { data, error } = await supa.from('projetos')
      .update({ nome, descricao, status })
      .eq('id', id).select().single()
    if (error) throw error
    return new Response(JSON.stringify(data), { headers: { ...cabecalhosCors, 'Content-Type': 'application/json' } })
  } catch (e) {
    return new Response(JSON.stringify({ erro: String(e) }), { status: 400, headers: cabecalhosCors })
  }
})
