// servicos/servicoPapeis.ts
export const servicoPapeis = () => {
  const cliente = useSupabaseClient()

  async function listar() {
    const { data, error } = await cliente
      .from('papeis_projeto')
      .select('*')
      .order('nome')
    if (error) throw error
    return data || []
  }

  async function criar(payload: { nome: string; descricao?: string; cor?: string }) {
    const { data, error } = await cliente
      .from('papeis_projeto')
      .insert(payload)
      .select()
    if (error) {
      const msg = error.message || error.details || error.hint || `code ${error.code}`
      throw new Error(msg || JSON.stringify(error))
    }
    return data?.[0] ?? null
  }

  async function atualizar(id: string, payload: { nome?: string; descricao?: string; cor?: string }) {
    const { data, error } = await cliente
      .from('papeis_projeto')
      .update(payload)
      .eq('id', id)
      .select()
    if (error) {
      const msg = error.message || error.details || error.hint || `code ${error.code}`
      throw new Error(msg || JSON.stringify(error))
    }
    return data?.[0] ?? null
  }

  async function excluir(id: string) {
    const { error } = await cliente.from('papeis_projeto').delete().eq('id', id)
    if (error) {
      const msg = error.message || error.details || error.hint || `code ${error.code}`
      throw new Error(msg || JSON.stringify(error))
    }
  }

  return { listar, criar, atualizar, excluir }
}
