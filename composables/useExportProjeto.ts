// composables/useExportProjeto.ts
export function useExportProjeto() {
  const cliente = useSupabaseClient()
  const exportando = ref(false)

  async function exportarProjeto(projetoId: string): Promise<void> {
    exportando.value = true
    try {
      const [
        { data: projeto,    error: e1 },
        { data: membros,    error: e2 },
        { data: sprints,    error: e3 },
        { data: tarefas,    error: e4 },
        { data: subTarefas, error: e5 },
        { data: anotacoes },
      ] = await Promise.all([
        cliente.from('projetos')
          .select('nome, descricao, status')
          .eq('id', projetoId)
          .single(),

        cliente.from('membros_projeto')
          .select('papel, usuario:usuarios(email)')
          .eq('projeto_id', projetoId),

        cliente.from('sprints')
          .select('id, nome, objetivo, status, data_inicio, data_fim')
          .eq('projeto_id', projetoId)
          .order('data_inicio', { ascending: true }),

        cliente.from('tarefas')
          .select('id, titulo, descricao, prioridade, coluna, posicao, pontos, prazo, sprint_id, responsavel:usuarios!tarefas_responsavel_id_fkey(email)')
          .eq('projeto_id', projetoId)
          .is('tarefa_pai_id', null)
          .order('posicao', { ascending: true }),

        cliente.from('tarefas')
          .select('id, titulo, descricao, prioridade, coluna, posicao, pontos, prazo, sprint_id, tarefa_pai_id, responsavel:usuarios!tarefas_responsavel_id_fkey(email)')
          .eq('projeto_id', projetoId)
          .not('tarefa_pai_id', 'is', null)
          .order('posicao', { ascending: true }),

        cliente.from('anotacoes_projeto')
          .select('titulo, conteudo, criado_em')
          .eq('projeto_id', projetoId)
          .order('criado_em', { ascending: true }),
      ])

      if (e1) throw e1
      if (e2) throw e2
      if (e3) throw e3
      if (e4) throw e4
      if (e5) throw e5

      // Sprint membros em batch
      const sprintIds = (sprints || []).map((s: any) => s.id)
      const sprintMembrosMap: Record<string, any[]> = {}
      if (sprintIds.length > 0) {
        const { data: sprintMembros } = await cliente
          .from('sprint_membros')
          .select('sprint_id, horas_dia, fator_produtividade, usuario:usuarios(email)')
          .in('sprint_id', sprintIds)
        for (const sm of sprintMembros || []) {
          if (!sprintMembrosMap[sm.sprint_id]) sprintMembrosMap[sm.sprint_id] = []
          sprintMembrosMap[sm.sprint_id].push(sm)
        }
      }

      // Comentários em batch por tarefa
      const tarefaIds = (tarefas || []).map((t: any) => t.id)
      const comentariosMap: Record<string, any[]> = {}
      if (tarefaIds.length > 0) {
        const { data: comentarios } = await cliente
          .from('comentarios')
          .select('tarefa_id, conteudo, criado_em, autor:usuarios(email)')
          .in('tarefa_id', tarefaIds)
          .order('criado_em', { ascending: true })
        for (const c of comentarios || []) {
          if (!comentariosMap[c.tarefa_id]) comentariosMap[c.tarefa_id] = []
          comentariosMap[c.tarefa_id].push(c)
        }
      }

      // Mapas UUID → ref_id legível
      const sprintRefMap: Record<string, string> = {}
      ;(sprints || []).forEach((s: any, i: number) => { sprintRefMap[s.id] = `sprint_${i + 1}` })

      const tarefaRefMap: Record<string, string> = {}
      ;(tarefas || []).forEach((t: any, i: number) => { tarefaRefMap[t.id] = `tarefa_${i + 1}` })

      const subRefMap: Record<string, string> = {}
      ;(subTarefas || []).forEach((s: any, i: number) => { subRefMap[s.id] = `sub_${i + 1}` })

      const subPorTarefa: Record<string, any[]> = {}
      for (const sub of subTarefas || []) {
        if (!subPorTarefa[sub.tarefa_pai_id]) subPorTarefa[sub.tarefa_pai_id] = []
        subPorTarefa[sub.tarefa_pai_id].push(sub)
      }

      const json = {
        _meta: {
          versao: '1.0',
          exportado_em: new Date().toISOString(),
          sistema: 'GESTAO_PROJTOS_VUE',
        },
        projeto: {
          nome: (projeto as any).nome,
          descricao: (projeto as any).descricao || '',
          status: (projeto as any).status,
          membros: (membros || []).map((m: any) => ({
            email: m.usuario?.email || '',
            papel: m.papel,
          })),
        },
        anotacoes: (anotacoes || []).map((a: any, i: number) => ({
          ref_id: `nota_${i + 1}`,
          titulo: a.titulo,
          conteudo: a.conteudo || '',
          criado_em: a.criado_em,
        })),
        sprints: (sprints || []).map((s: any) => ({
          ref_id: sprintRefMap[s.id],
          nome: s.nome,
          objetivo: s.objetivo || '',
          status: s.status,
          data_inicio: s.data_inicio,
          data_fim: s.data_fim,
          membros: (sprintMembrosMap[s.id] || []).map((sm: any) => ({
            email: sm.usuario?.email || '',
            horas_dia: sm.horas_dia,
            fator_produtividade: sm.fator_produtividade,
          })),
        })),
        tarefas: (tarefas || []).map((t: any) => ({
          ref_id: tarefaRefMap[t.id],
          titulo: t.titulo,
          descricao: t.descricao || '',
          prioridade: t.prioridade,
          coluna: t.coluna,
          posicao: t.posicao,
          pontos: (t as any).pontos || 0,
          prazo: t.prazo,
          sprint_ref: t.sprint_id ? (sprintRefMap[t.sprint_id] || null) : null,
          tarefa_pai_ref: null,
          responsavel_email: t.responsavel?.email || null,
          comentarios: (comentariosMap[t.id] || []).map((c: any) => ({
            autor_email: c.autor?.email || '',
            conteudo: c.conteudo,
            criado_em: c.criado_em,
          })),
          sub_tarefas: (subPorTarefa[t.id] || []).map((sub: any) => ({
            ref_id: subRefMap[sub.id],
            titulo: sub.titulo,
            descricao: sub.descricao || '',
            prioridade: sub.prioridade,
            coluna: sub.coluna,
            posicao: sub.posicao,
            pontos: (sub as any).pontos || 0,
            prazo: sub.prazo,
            sprint_ref: sub.sprint_id ? (sprintRefMap[sub.sprint_id] || null) : null,
            responsavel_email: sub.responsavel?.email || null,
          })),
        })),
      }

      _baixarJson(json, (projeto as any).nome)
    } finally {
      exportando.value = false
    }
  }

  function _baixarJson(dados: object, nomeProjeto: string) {
    const slug = nomeProjeto.toLowerCase().replace(/\s+/g, '-').replace(/[^\w-]/g, '')
    const nome = `${slug}-${new Date().toISOString().slice(0, 10)}.json`
    const blob = new Blob([JSON.stringify(dados, null, 2)], { type: 'application/json' })
    const url = URL.createObjectURL(blob)
    const link = document.createElement('a')
    link.href = url
    link.download = nome
    link.click()
    URL.revokeObjectURL(url)
  }

  return { exportando, exportarProjeto }
}
