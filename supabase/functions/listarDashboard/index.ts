import { cabecalhosCors } from '../_compartilhado/cors.ts'
import { obterUsuario } from '../_compartilhado/cliente.ts'

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: cabecalhosCors })
  }

  try {
    const { supa, user } = await obterUsuario(req)

    const [{ data: projetos }, { data: tarefas }, { data: sprints }] =
      await Promise.all([
        supa.from('projetos').select('id, nome, status'),
        supa.from('tarefas').select('id, titulo, coluna, prioridade, projeto_id, responsavel_id'),
        supa.from('sprints').select('id, nome, status, projeto_id'),
      ])

    const tarefasPorColuna = (tarefas ?? []).reduce((acc, t) => {
      acc[t.coluna] = (acc[t.coluna] ?? 0) + 1
      return acc
    }, {} as Record<string, number>)

    return new Response(
      JSON.stringify({
        usuario_id: user.id,
        totais: {
          projetos: projetos?.length ?? 0,
          tarefas: tarefas?.length ?? 0,
          sprints_ativas: (sprints ?? []).filter(s => s.status === 'ativa').length,
        },
        tarefas_por_coluna: tarefasPorColuna,
        minhas_tarefas: (tarefas ?? []).filter(t => t.responsavel_id === user.id),
        projetos,
        sprints,
      }),
      {
        headers: {
          ...cabecalhosCors,
          'Content-Type': 'application/json',
        },
      }
    )
  } catch (e) {
    return new Response(
      JSON.stringify({ erro: String(e) }),
      { status: 400, headers: cabecalhosCors }
    )
  }
})