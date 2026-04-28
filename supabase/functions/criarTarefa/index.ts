// supabase/functions/criarTarefa/index.ts
import { cabecalhosCors } from '../_compartilhado/cors.ts'
import { obterUsuario } from '../_compartilhado/cliente.ts'

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: cabecalhosCors })
  try {
    const { supa, user } = await obterUsuario(req)
    const body = await req.json()
    const { projeto_id, titulo, descricao, prioridade, prazo, responsavel_id, sprint_id, tarefa_pai_id, coluna } = body
    if (!projeto_id || !titulo) {
      return new Response(JSON.stringify({ erro: 'projeto_id e titulo são obrigatórios' }), { status: 400, headers: cabecalhosCors })
    }
    const { data, error } = await supa.from('tarefas').insert({
      projeto_id, titulo, descricao,
      prioridade: prioridade ?? 'media',
      prazo, responsavel_id, sprint_id, tarefa_pai_id,
      coluna: coluna ?? 'backlog',
      criado_por: user.id,
    }).select().single()
    if (error) throw error
    return new Response(JSON.stringify(data), { headers: { ...cabecalhosCors, 'Content-Type': 'application/json' } })
  } catch (e) {
    return new Response(JSON.stringify({ erro: String(e) }), { status: 400, headers: cabecalhosCors })
  }
})
