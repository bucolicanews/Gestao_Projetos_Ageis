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

  return { gerarBranch, gerarCommit, gerarComandos, gerarPush }
}
