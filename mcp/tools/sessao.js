export const sessaoTools = [
  {
    name: 'identificar_usuario',
    description: 'Retorna o UUID e dados do usuário pelo email. SEMPRE chame esta tool primeiro antes de qualquer outra operação que precise de proprietario_id ou criado_por.',
    inputSchema: {
      type: 'object',
      properties: {
        email: { type: 'string', description: 'Email cadastrado no sistema' },
      },
      required: ['email'],
    },
  },
  {
    name: 'meus_projetos',
    description: 'Atalho: retorna todos os projetos do usuário pelo email, sem precisar do UUID.',
    inputSchema: {
      type: 'object',
      properties: {
        email: { type: 'string' },
      },
      required: ['email'],
    },
  },
]

export async function executarSessaoTool(nome, args, db) {
  switch (nome) {
    case 'identificar_usuario': return identificarUsuario(args, db)
    case 'meus_projetos':       return meusProjetos(args, db)
    default: return null
  }
}

async function identificarUsuario(args, db) {
  const { data, error } = await db
    .from('usuarios')
    .select('id, nome, email, perfil, criado_em')
    .eq('email', args.email)
    .single()

  if (error || !data) {
    return {
      encontrado: false,
      mensagem: `Usuário com email "${args.email}" não encontrado. Verifique o email ou cadastre-se no app.`,
    }
  }

  return {
    encontrado: true,
    usuario: data,
    instrucao: `Use "${data.id}" como proprietario_id e criado_por em todas as próximas operações desta sessão.`,
  }
}

async function meusProjetos(args, db) {
  const usuario = await identificarUsuario(args, db)
  if (!usuario.encontrado) return usuario

  const { data, error } = await db
    .from('projetos')
    .select('id, nome, descricao, status, criado_em')
    .eq('proprietario_id', usuario.usuario.id)
    .order('criado_em', { ascending: false })

  if (error) throw error

  return {
    usuario: { id: usuario.usuario.id, nome: usuario.usuario.nome },
    projetos: data,
    total: data.length,
    instrucao: data.length === 0
      ? 'Nenhum projeto ainda. Use criar_projeto para começar.'
      : `Use o "id" de cada projeto nas próximas operações.`,
  }
}
