import { cabecalhosCors } from '../_compartilhado/cors.ts'
import { obterUsuario } from '../_compartilhado/cliente.ts'

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: cabecalhosCors })
  }

  try {
    const { supa, user } = await obterUsuario(req)

    const [
      { data: projetos },
      { data: tarefas },
      { data: sprints },
    ] = await Promise.all([
      supa.from('projetos').select('id, nome, status, descricao'),
      supa.from('tarefas').select(
        'id, titulo, coluna, prioridade, projeto_id, responsavel_id, pontos, prazo, dor_ok, sprint_id, concluido_em'
      ),
      supa.from('sprints').select('id, nome, status, projeto_id, data_inicio, data_fim, sp_planejados'),
    ])

    const tarefasLista = tarefas ?? []
    const sprintsLista = sprints ?? []
    const projetosLista = projetos ?? []

    // ---- Totais globais ----
    const hoje = new Date().toISOString().slice(0, 10)
    const spTotal = tarefasLista.reduce((a: number, t: any) => a + (t.pontos || 0), 0)
    const spConcluidos = tarefasLista
      .filter((t: any) => t.coluna === 'concluido')
      .reduce((a: number, t: any) => a + (t.pontos || 0), 0)
    const atrasadas = tarefasLista.filter(
      (t: any) => t.prazo && t.prazo < hoje && t.coluna !== 'concluido'
    )

    // ---- Tarefas por coluna ----
    const tarefasPorColuna = tarefasLista.reduce((acc: Record<string, number>, t: any) => {
      acc[t.coluna] = (acc[t.coluna] ?? 0) + 1
      return acc
    }, {} as Record<string, number>)

    // ---- Sprints ativas com progresso ----
    const sprintsAtivas = sprintsLista.filter((s: any) => s.status === 'ativa')
    const sprintsComProgresso = sprintsAtivas.map((s: any) => {
      const tarefasSprint = tarefasLista.filter((t: any) => t.sprint_id === s.id)
      const total = tarefasSprint.length
      const concluidas = tarefasSprint.filter((t: any) => t.coluna === 'concluido').length
      const spConc = tarefasSprint
        .filter((t: any) => t.coluna === 'concluido')
        .reduce((a: number, t: any) => a + (t.pontos || 0), 0)
      const projeto = projetosLista.find((p: any) => p.id === s.projeto_id)
      return {
        ...s,
        projeto_nome: projeto?.nome ?? '',
        tarefas_total: total,
        tarefas_concluidas: concluidas,
        sp_concluidos: spConc,
        progresso_percent: total ? Math.round((concluidas / total) * 100) : 0,
        dias_restantes: s.data_fim
          ? Math.max(0, Math.ceil((new Date(s.data_fim).getTime() - Date.now()) / 86400000))
          : null,
      }
    })

    // ---- Projetos enriquecidos com sprint ativa ----
    const projetosEnriquecidos = projetosLista.map((p: any) => {
      const sprintAtiva = sprintsComProgresso.find((s: any) => s.projeto_id === p.id) ?? null
      const tarefasProjeto = tarefasLista.filter((t: any) => t.projeto_id === p.id)
      return {
        ...p,
        sprint_ativa: sprintAtiva,
        total_tarefas: tarefasProjeto.length,
        tarefas_concluidas: tarefasProjeto.filter((t: any) => t.coluna === 'concluido').length,
        tarefas_atrasadas: tarefasProjeto.filter(
          (t: any) => t.prazo && t.prazo < hoje && t.coluna !== 'concluido'
        ).length,
      }
    })

    return new Response(
      JSON.stringify({
        usuario_id: user.id,
        totais: {
          projetos: projetosLista.length,
          tarefas: tarefasLista.length,
          sprints_ativas: sprintsAtivas.length,
          sp_planejados: spTotal,
          sp_concluidos: spConcluidos,
          atrasadas: atrasadas.length,
        },
        tarefas_por_coluna: tarefasPorColuna,
        minhas_tarefas: tarefasLista.filter((t: any) => t.responsavel_id === user.id),
        tarefas_atrasadas: atrasadas.slice(0, 10),
        projetos: projetosEnriquecidos,
        sprints_ativas: sprintsComProgresso,
      }),
      {
        headers: { ...cabecalhosCors, 'Content-Type': 'application/json' },
      }
    )
  } catch (e) {
    return new Response(
      JSON.stringify({ erro: String(e) }),
      { status: 400, headers: cabecalhosCors }
    )
  }
})
