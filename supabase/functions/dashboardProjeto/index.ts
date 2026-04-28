// supabase/functions/dashboardProjeto/index.ts
// Retorna KPIs ágeis completos de um projeto:
// throughput, lead/cycle time, WIP, CFD, atrasadas, carga por pessoa.
import { cabecalhosCors } from '../_compartilhado/cors.ts'
import { obterUsuario } from '../_compartilhado/cliente.ts'

const COLUNAS = ['backlog', 'a_fazer', 'em_progresso', 'em_revisao', 'concluido'] as const

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: cabecalhosCors })
  try {
    const { supa } = await obterUsuario(req)
    const url = new URL(req.url)
    const projeto_id = url.searchParams.get('projeto_id')
    const dias = Number(url.searchParams.get('dias') ?? '14')
    if (!projeto_id) {
      return new Response(JSON.stringify({ erro: 'projeto_id obrigatório' }),
        { status: 400, headers: { ...cabecalhosCors, 'Content-Type': 'application/json' } })
    }

    const desde = new Date(Date.now() - dias * 86400_000).toISOString()

    const [
      { data: projeto },
      { data: metricas },
      { data: historico },
      { data: sprints },
      { data: membros },
    ] = await Promise.all([
      supa.from('projetos').select('id, nome, descricao, status, wip_limite').eq('id', projeto_id).single(),
      supa.from('v_metricas_tarefa').select('*').eq('projeto_id', projeto_id),
      supa.from('historico_movimentacao').select('*').eq('projeto_id', projeto_id).gte('movido_em', desde),
      supa.from('sprints').select('id, nome, status, data_inicio, data_fim').eq('projeto_id', projeto_id),
      supa.from('membros_projeto').select('usuario_id, papel, usuarios:usuario_id(id, nome, email)').eq('projeto_id', projeto_id),
    ])

    const tarefas = metricas ?? []
    const concluidas = tarefas.filter((t: any) => t.coluna === 'concluido')
    const ativas = tarefas.filter((t: any) => t.coluna !== 'concluido')

    // ---- WIP por coluna
    const wip: Record<string, number> = {}
    for (const c of COLUNAS) wip[c] = tarefas.filter((t: any) => t.coluna === c).length

    // ---- Throughput (concluídas/dia) últimos N dias
    const throughputPorDia: Record<string, number> = {}
    for (let i = dias - 1; i >= 0; i--) {
      const d = new Date(Date.now() - i * 86400_000).toISOString().slice(0, 10)
      throughputPorDia[d] = 0
    }
    for (const t of concluidas) {
      if (!t.concluido_em) continue
      const d = String(t.concluido_em).slice(0, 10)
      if (d in throughputPorDia) throughputPorDia[d]++
    }
    const throughputTotal = Object.values(throughputPorDia).reduce((a, b) => a + b, 0)
    const throughputMedio = +(throughputTotal / dias).toFixed(2)

    // ---- Lead time / Cycle time (média + p50/p90)
    const leadTimes = concluidas.map((t: any) => t.lead_time_horas).filter((x: any) => typeof x === 'number')
    const cycleTimes = concluidas.map((t: any) => t.cycle_time_horas).filter((x: any) => typeof x === 'number')
    const stats = (arr: number[]) => {
      if (!arr.length) return { media: 0, p50: 0, p90: 0, n: 0 }
      const s = [...arr].sort((a, b) => a - b)
      const pct = (p: number) => s[Math.min(s.length - 1, Math.floor((p / 100) * s.length))]
      return {
        media: +(arr.reduce((a, b) => a + b, 0) / arr.length).toFixed(1),
        p50: +pct(50).toFixed(1),
        p90: +pct(90).toFixed(1),
        n: arr.length,
      }
    }

    // ---- Cumulative Flow Diagram (estado por dia, derivado do histórico)
    // Para cada dia, soma quantas tarefas estão em cada coluna ao final do dia.
    // Estratégia: para cada tarefa, reconstrói a coluna no dia X usando o último evento <= fim do dia.
    const cfd: Array<{ data: string } & Record<string, number>> = []
    const eventosPorTarefa = new Map<string, any[]>()
    for (const h of historico ?? []) {
      const arr = eventosPorTarefa.get(h.tarefa_id) ?? []
      arr.push(h)
      eventosPorTarefa.set(h.tarefa_id, arr)
    }
    for (let i = dias - 1; i >= 0; i--) {
      const fim = new Date(Date.now() - i * 86400_000)
      fim.setHours(23, 59, 59, 999)
      const linha: any = { data: fim.toISOString().slice(0, 10) }
      for (const c of COLUNAS) linha[c] = 0
      for (const t of tarefas) {
        if (new Date(t.criado_em) > fim) continue
        const evs = (eventosPorTarefa.get(t.id) ?? [])
          .filter(e => new Date(e.movido_em) <= fim)
          .sort((a, b) => +new Date(a.movido_em) - +new Date(b.movido_em))
        const colNoDia = evs.length ? evs[evs.length - 1].coluna_destino : t.coluna
        linha[colNoDia] = (linha[colNoDia] ?? 0) + 1
      }
      cfd.push(linha)
    }

    // ---- Distribuição por prioridade
    const porPrioridade = tarefas.reduce((acc: Record<string, number>, t: any) => {
      acc[t.prioridade] = (acc[t.prioridade] ?? 0) + 1
      return acc
    }, {})

    // ---- Carga por responsável (apenas tarefas ativas)
    const cargaPorPessoa: Record<string, { nome: string; ativas: number; concluidas: number; pontos: number }> = {}
    const nomePorId = new Map<string, string>()
    for (const m of membros ?? []) {
      const u: any = (m as any).usuarios
      if (u?.id) nomePorId.set(u.id, u.nome ?? u.email ?? 'sem nome')
    }
    for (const t of tarefas) {
      const id = t.responsavel_id ?? '__sem_responsavel__'
      const nome = id === '__sem_responsavel__' ? 'Sem responsável' : (nomePorId.get(id) ?? 'Desconhecido')
      const slot = cargaPorPessoa[id] ?? { nome, ativas: 0, concluidas: 0, pontos: 0 }
      if (t.coluna === 'concluido') slot.concluidas++
      else slot.ativas++
      slot.pontos += t.pontos ?? 0
      cargaPorPessoa[id] = slot
    }

    // ---- Atrasadas e itens "presos" (>72h na mesma coluna sem ser backlog/concluido)
    const atrasadas = ativas.filter((t: any) => t.atrasada)
    const presas = ativas.filter((t: any) =>
      !['backlog', 'concluido'].includes(t.coluna) && (t.idade_coluna_horas ?? 0) > 72
    )

    // ---- WIP limits violados
    const wipLimite = (projeto?.wip_limite ?? {}) as Record<string, number>
    const wipViolacoes = Object.entries(wipLimite)
      .filter(([col, lim]) => (wip[col] ?? 0) > lim)
      .map(([col, lim]) => ({ coluna: col, atual: wip[col], limite: lim }))

    // ---- Saúde geral (score 0-100)
    const totalAtivas = ativas.length || 1
    const fatorAtraso = 1 - Math.min(atrasadas.length / totalAtivas, 1)
    const fatorPresas = 1 - Math.min(presas.length / totalAtivas, 1)
    const fatorWip = wipViolacoes.length === 0 ? 1 : 0.5
    const saude = Math.round(((fatorAtraso + fatorPresas + fatorWip) / 3) * 100)

    return new Response(JSON.stringify({
      projeto,
      periodo_dias: dias,
      totais: {
        tarefas: tarefas.length,
        ativas: ativas.length,
        concluidas: concluidas.length,
        sprints_ativas: (sprints ?? []).filter((s: any) => s.status === 'ativa').length,
        membros: (membros ?? []).length,
      },
      saude_score: saude,
      wip_atual: wip,
      wip_limite: wipLimite,
      wip_violacoes: wipViolacoes,
      throughput: {
        total_periodo: throughputTotal,
        media_dia: throughputMedio,
        por_dia: throughputPorDia,
      },
      lead_time_horas: stats(leadTimes),
      cycle_time_horas: stats(cycleTimes),
      cfd,
      por_prioridade: porPrioridade,
      carga_por_pessoa: cargaPorPessoa,
      atrasadas: atrasadas.map((t: any) => ({ id: t.id, titulo: t.titulo, coluna: t.coluna, prioridade: t.prioridade })),
      presas: presas.map((t: any) => ({
        id: t.id, titulo: t.titulo, coluna: t.coluna,
        idade_horas: Math.round(t.idade_coluna_horas ?? 0),
      })),
      sprints,
    }), { headers: { ...cabecalhosCors, 'Content-Type': 'application/json' } })
  } catch (e) {
    return new Response(JSON.stringify({ erro: String(e) }),
      { status: 400, headers: { ...cabecalhosCors, 'Content-Type': 'application/json' } })
  }
})
