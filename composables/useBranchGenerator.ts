const PREFIXO: Record<string, string> = {
  feature:  'feature',
  bug:      'bugfix',
  melhoria: 'feature',
  techdeb:  'chore',
  spike:    'spike',
}

const COMMIT_TIPO: Record<string, string> = {
  feature:  'feat',
  bug:      'fix',
  melhoria: 'feat',
  techdeb:  'chore',
  spike:    'docs',
}

function slug(texto: string): string {
  return texto
    .toLowerCase()
    .normalize('NFD')
    .replace(/[̀-ͯ]/g, '')
    .replace(/[^a-z0-9\s]/g, '')
    .trim()
    .replace(/\s+/g, '-')
    .slice(0, 40)
    .replace(/-$/, '')
}

export function useBranchGenerator() {
  function gerarBranch(tipo: string, titulo: string): string {
    const prefixo = PREFIXO[tipo] ?? 'feature'
    return `${prefixo}/${slug(titulo)}`
  }

  function gerarCommit(tipo: string, titulo: string): string {
    const t = COMMIT_TIPO[tipo] ?? 'feat'
    return `${t}: ${slug(titulo).replace(/-/g, ' ')}`
  }

  function gerarComandos(branch: string): string {
    return [
      'git checkout develop',
      'git pull origin develop',
      `git checkout -b ${branch}`,
    ].join('\n')
  }

  function gerarPush(branch: string): string {
    return `git push origin ${branch}`
  }

  function gerarSequenciaCommits(tipo: string, titulo: string): string[] {
    const base = slug(titulo).replace(/-/g, ' ')
    const sequencias: Record<string, string[]> = {
      feature: [
        `feat: criar modelo ${base}`,
        `feat: implementar service ${base}`,
        `feat: criar endpoint ${base}`,
        `test: adicionar testes de ${base}`,
      ],
      bug: [
        `fix: identificar causa raiz em ${base}`,
        `fix: corrigir logica de ${base}`,
        `test: verificar correcao de ${base}`,
      ],
      melhoria: [
        `feat: melhorar ${base}`,
        `perf: otimizar ${base}`,
        `test: validar melhoria em ${base}`,
      ],
      techdeb: [
        `refactor: extrair logica de ${base}`,
        `chore: remover codigo duplicado em ${base}`,
        `test: garantir cobertura apos refactor`,
      ],
      spike: [
        `docs: registrar descobertas sobre ${base}`,
        `docs: documentar decisao tecnica de ${base}`,
      ],
    }
    return sequencias[tipo] ?? sequencias.feature
  }

  return { gerarBranch, gerarCommit, gerarComandos, gerarPush, gerarSequenciaCommits }
}
