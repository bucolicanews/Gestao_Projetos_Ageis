// supabase/functions/adicionarComentario/index.ts
import { cabecalhosCors } from '../_compartilhado/cors.ts'
import { obterUsuario } from '../_compartilhado/cliente.ts'

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: cabecalhosCors })
  try {
    const { supa, user } = await obterUsuario(req)
    const { tarefa_id, conteudo } = await req.json()
    if (!tarefa_id || !conteudo?.trim()) {
      return new Response(JSON.stringify({ erro: 'tarefa_id e conteudo obrigatórios' }), { status: 400, headers: cabecalhosCors })
    }
    const { data, error } = await supa.from('comentarios').insert({
      tarefa_id, conteudo, autor_id: user.id,
    }).select().single()
    if (error) throw error
    return new Response(JSON.stringify(data), { headers: { ...cabecalhosCors, 'Content-Type': 'application/json' } })
  } catch (e) {
    return new Response(JSON.stringify({ erro: String(e) }), { status: 400, headers: cabecalhosCors })
  }
})
