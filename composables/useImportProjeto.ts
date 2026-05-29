// composables/useImportProjeto.ts

export interface RelatorioImportacao {
  projetoId: string
  projetoNome: string
  sprintsCriadas: number
  tarefasCriadas: number
  subTarefasCriadas: number
  comentariosCriados: number
  anotacoesCriadas: number
  membrosCriados: number
  warnings: string[]
  erros: string[]
}

const COLUNAS_VALIDAS   = ['backlog', 'a_fazer', 'em_progresso', 'em_revisao', 'concluido']
const PRIORIDADES_VALIDAS = ['baixa', 'media', 'alta', 'urgente']
const STATUS_PROJETO_VALIDOS = ['ativo', 'pausado', 'concluido', 'arquivado']
const STATUS_SPRINT_VALIDOS  = ['planejada', 'ativa', 'concluida']

export function useImportProjeto() {
  const cliente  = useSupabaseClient()
  const usuario  = useSupabaseUser()
  const importando = ref(false)

  // ─── Validação ────────────────────────────────────────────────────────────

  function validar(json: any): string[] {
    const erros: string[] = []

    if (!json._meta?.versao)   erros.push('Campo _meta.versao ausente')
    if (!json.projeto?.nome)   erros.push('Campo projeto.nome ausente')
    if (!Array.isArray(json.sprints))  erros.push('Campo sprints deve ser array')
    if (!Array.isArray(json.tarefas))  erros.push('Campo tarefas deve ser array')

    if (json.projeto?.status && !STATUS_PROJETO_VALIDOS.includes(json.projeto.status))
      erros.push(`status de projeto inválido: "${json.projeto.status}"`)

    for (const s of json.sprints || []) {
      if (!s.ref_id) erros.push(`Sprint sem ref_id: "${s.nome}"`)
      if (!s.nome)   erros.push('Sprint sem nome')
      if (s.status && !STATUS_SPRINT_VALIDOS.includes(s.status))
        erros.push(`Status de sprint inválido: "${s.status}" em "${s.nome}"`)
    }

    for (const t of json.tarefas || []) {
      if (!t.ref_id)  erros.push(`Tarefa sem ref_id: "${t.titulo}"`)
      if (!t.titulo)  erros.push('Tarefa sem título')
      if (t.coluna && !COLUNAS_VALIDAS.includes(t.coluna))
        erros.push(`Coluna inválida: "${t.coluna}" em "${t.titulo}"`)
      if (t.prioridade && !PRIORIDADES_VALIDAS.includes(t.prioridade))
        erros.push(`Prioridade inválida: "${t.prioridade}" em "${t.titulo}"`)
    }

    return erros
  }

  // ─── Resolução de emails → IDs ────────────────────────────────────────────

  async function resolverEmails(json: any): Promise<Map<string, string>> {
    const emails = new Set<string>()

    for (const m of json.projeto?.membros || [])        emails.add(m.email)
    for (const s of json.sprints || [])
      for (const m of s.membros || [])                  emails.add(m.email)
    for (const t of json.tarefas || []) {
      if (t.responsavel_email)                          emails.add(t.responsavel_email)
      for (const c of t.comentarios  || [])             emails.add(c.autor_email)
      for (const sub of t.sub_tarefas || [])
        if (sub.responsavel_email)                      emails.add(sub.responsavel_email)
    }

    const lista = [...emails].filter(Boolean)
    if (lista.length === 0) return new Map()

    const { data } = await cliente
      .from('usuarios')
      .select('id, email')
      .in('email', lista)

    const mapa = new Map<string, string>()
    for (const u of data || []) mapa.set(u.email, u.id)
    return mapa
  }

  // ─── Import principal ─────────────────────────────────────────────────────

  async function importarProjeto(jsonString: string): Promise<RelatorioImportacao> {
    importando.value = true
    const warnings: string[] = []

    try {
      // 1. Parse
      let json: any
      try { json = JSON.parse(jsonString) }
      catch { throw new Error('JSON inválido — verifique o formato do arquivo') }

      // 2. Validação
      const errosValidacao = validar(json)
      if (errosValidacao.length > 0)
        throw new Error(`Erros de validação:\n${errosValidacao.join('\n')}`)

      const userId = usuario.value?.id
      if (!userId) throw new Error('Usuário não autenticado')

      // 3. Resolve emails → IDs
      const emailParaId = await resolverEmails(json)
      const emailsNaoEncontrados = new Set<string>()

      function resolverEmail(email: string | null | undefined): string | null {
        if (!email) return null
        const id = emailParaId.get(email)
        if (!id && !emailsNaoEncontrados.has(email)) {
          emailsNaoEncontrados.add(email)
          warnings.push(`Usuário não encontrado no sistema: ${email} — campo ignorado`)
        }
        return id || null
      }

      // 4. Cria projeto
      const { data: projeto, error: errProjeto } = await cliente
        .from('projetos')
        .insert({
          nome: json.projeto.nome,
          descricao: json.projeto.descricao || null,
          status: STATUS_PROJETO_VALIDOS.includes(json.projeto.status)
            ? json.projeto.status
            : 'ativo',
          proprietario_id: userId,
        })
        .select('id, nome')
        .single()
      if (errProjeto) throw errProjeto

      const projetoId = projeto.id

      // 5. Membros do projeto
      let membrosCriados = 0
      const membrosPayload = (json.projeto.membros || [])
        .map((m: any) => {
          const uid = resolverEmail(m.email)
          if (!uid) return null
          return { projeto_id: projetoId, usuario_id: uid, papel: m.papel || 'membro' }
        })
        .filter(Boolean)

      if (membrosPayload.length > 0) {
        const { error } = await cliente.from('membros_projeto').insert(membrosPayload)
        if (error) warnings.push(`Erro ao inserir membros: ${error.message}`)
        else membrosCriados = membrosPayload.length
      }

      // 6. Sprints
      const sprintUuidMap: Record<string, string> = {} // ref_id → UUID real
      let sprintsCriadas = 0

      for (const s of json.sprints || []) {
        const { data: sprint, error } = await cliente
          .from('sprints')
          .insert({
            projeto_id:  projetoId,
            nome:        s.nome,
            objetivo:    s.objetivo || null,
            status:      STATUS_SPRINT_VALIDOS.includes(s.status) ? s.status : 'planejada',
            data_inicio: s.data_inicio || null,
            data_fim:    s.data_fim    || null,
          })
          .select('id')
          .single()

        if (error) { warnings.push(`Erro ao criar sprint "${s.nome}": ${error.message}`); continue }

        sprintUuidMap[s.ref_id] = sprint.id
        sprintsCriadas++

        // Sprint membros
        const spMembros = (s.membros || [])
          .map((sm: any) => {
            const uid = resolverEmail(sm.email)
            if (!uid) return null
            return {
              sprint_id:           sprint.id,
              usuario_id:          uid,
              horas_dia:           sm.horas_dia ?? 6,
              fator_produtividade: sm.fator_produtividade ?? 0.8,
            }
          })
          .filter(Boolean)

        if (spMembros.length > 0) {
          const { error: errSM } = await cliente.from('sprint_membros').insert(spMembros)
          if (errSM) warnings.push(`Erro ao inserir membros da sprint "${s.nome}": ${errSM.message}`)
        }
      }

      // 7. Tarefas pai
      const tarefaUuidMap: Record<string, string> = {} // ref_id → UUID real
      let tarefasCriadas = 0

      for (const t of json.tarefas || []) {
        const sprintId = t.sprint_ref ? (sprintUuidMap[t.sprint_ref] || null) : null
        const responsavelId = resolverEmail(t.responsavel_email)

        const { data: tarefa, error } = await cliente
          .from('tarefas')
          .insert({
            projeto_id:    projetoId,
            sprint_id:     sprintId,
            tarefa_pai_id: null,
            titulo:        t.titulo,
            descricao:     t.descricao || null,
            prioridade:    PRIORIDADES_VALIDAS.includes(t.prioridade) ? t.prioridade : 'media',
            coluna:        COLUNAS_VALIDAS.includes(t.coluna) ? t.coluna : 'backlog',
            posicao:       t.posicao ?? 0,
            prazo:         t.prazo || null,
            responsavel_id: responsavelId,
            criado_por:    userId,
          })
          .select('id')
          .single()

        if (error) { warnings.push(`Erro ao criar tarefa "${t.titulo}": ${error.message}`); continue }

        tarefaUuidMap[t.ref_id] = tarefa.id
        tarefasCriadas++
      }

      // 8. Sub-tarefas
      let subTarefasCriadas = 0

      for (const t of json.tarefas || []) {
        const tarefaPaiId = tarefaUuidMap[t.ref_id]
        if (!tarefaPaiId) continue

        for (const sub of t.sub_tarefas || []) {
          const sprintId      = sub.sprint_ref ? (sprintUuidMap[sub.sprint_ref] || null) : null
          const responsavelId = resolverEmail(sub.responsavel_email)

          const { error } = await cliente
            .from('tarefas')
            .insert({
              projeto_id:    projetoId,
              sprint_id:     sprintId,
              tarefa_pai_id: tarefaPaiId,
              titulo:        sub.titulo,
              descricao:     sub.descricao || null,
              prioridade:    PRIORIDADES_VALIDAS.includes(sub.prioridade) ? sub.prioridade : 'media',
              coluna:        COLUNAS_VALIDAS.includes(sub.coluna) ? sub.coluna : 'a_fazer',
              posicao:       sub.posicao ?? 0,
              prazo:         sub.prazo || null,
              responsavel_id: responsavelId,
              criado_por:    userId,
            })

          if (error) warnings.push(`Erro ao criar sub-tarefa "${sub.titulo}": ${error.message}`)
          else subTarefasCriadas++
        }
      }

      // 9. Comentários
      let comentariosCriados = 0

      for (const t of json.tarefas || []) {
        const tarefaId = tarefaUuidMap[t.ref_id]
        if (!tarefaId || !t.comentarios?.length) continue

        const comentariosPayload = t.comentarios.map((c: any) => ({
          tarefa_id: tarefaId,
          conteudo:  c.conteudo,
          autor_id:  resolverEmail(c.autor_email) || userId,
        }))

        const { error } = await cliente.from('comentarios').insert(comentariosPayload)
        if (error) warnings.push(`Erro ao inserir comentários da tarefa "${t.titulo}": ${error.message}`)
        else comentariosCriados += comentariosPayload.length
      }

      // 10. Anotações
      let anotacoesCriadas = 0

      if (json.anotacoes?.length > 0) {
        const anotacoesPayload = json.anotacoes.map((a: any) => ({
          projeto_id: projetoId,
          titulo:     a.titulo,
          conteudo:   a.conteudo || null,
          criado_por: userId,
        }))

        const { error } = await cliente.from('anotacoes_projeto').insert(anotacoesPayload)
        if (error) warnings.push(`Erro ao inserir anotações: ${error.message}`)
        else anotacoesCriadas = anotacoesPayload.length
      }

      return {
        projetoId,
        projetoNome: projeto.nome,
        sprintsCriadas,
        tarefasCriadas,
        subTarefasCriadas,
        comentariosCriados,
        anotacoesCriadas,
        membrosCriados,
        warnings,
        erros: [],
      }
    } catch (err: any) {
      return {
        projetoId:         '',
        projetoNome:       '',
        sprintsCriadas:    0,
        tarefasCriadas:    0,
        subTarefasCriadas: 0,
        comentariosCriados: 0,
        anotacoesCriadas:  0,
        membrosCriados:    0,
        warnings,
        erros: [err.message || 'Erro desconhecido'],
      }
    } finally {
      importando.value = false
    }
  }

  // ─── Leitura de arquivo ───────────────────────────────────────────────────

  function lerArquivoJson(): Promise<string> {
    return new Promise((resolve, reject) => {
      const input = document.createElement('input')
      input.type = 'file'
      input.accept = '.json'
      input.onchange = (e: any) => {
        const file = e.target.files?.[0]
        if (!file) return reject(new Error('Nenhum arquivo selecionado'))
        const reader = new FileReader()
        reader.onload  = (ev) => resolve(ev.target?.result as string)
        reader.onerror = () => reject(new Error('Erro ao ler arquivo'))
        reader.readAsText(file)
      }
      input.click()
    })
  }

  return { importando, importarProjeto, lerArquivoJson }
}
