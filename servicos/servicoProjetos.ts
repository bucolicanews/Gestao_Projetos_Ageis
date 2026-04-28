// servicos/servicoProjetos.ts
export const servicoProjetos = () => {
  const cliente = useSupabaseClient()

  async function listarProjetos() {
    const { data, error } = await cliente.from('projetos').select('*').order('criado_em', { ascending: false })
    if (error) throw error
    return data
  }

  async function obterProjeto(id: string) {
    const { data, error } = await cliente.from('projetos').select('*').eq('id', id).single()
    if (error) throw error
    return data
  }

  async function criarProjeto(payload: { nome: string; descricao?: string }) {
    const { data, error } = await cliente.functions.invoke('criarProjeto', { body: payload })
    if (error) throw error
    return data
  }

  async function atualizarProjeto(payload: { id: string; nome?: string; descricao?: string; status?: string }) {
    const { data, error } = await cliente.functions.invoke('atualizarProjeto', { body: payload })
    if (error) throw error
    return data
  }

  async function excluirProjeto(id: string) {
    const { error } = await cliente.from('projetos').delete().eq('id', id)
    if (error) throw error
  }

  return { listarProjetos, obterProjeto, criarProjeto, atualizarProjeto, excluirProjeto }
}
