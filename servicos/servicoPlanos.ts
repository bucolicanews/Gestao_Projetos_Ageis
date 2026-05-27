// servicos/servicoPlanos.ts
export interface Plano {
  id: string
  titulo: string
  descricao: string | null
  imagem_url: string | null
  preco: number
  recursos: string[]
  dias_trial: number
  max_usuarios: number
  gratuito: boolean
  ativo: boolean
  criado_em: string
  atualizado_em: string
}

export type PlanoInput = Omit<Plano, 'id' | 'criado_em' | 'atualizado_em'>

export const servicoPlanos = () => {
  const cliente = useSupabaseClient()

  async function listar(): Promise<Plano[]> {
    const { data, error } = await cliente
      .from('planos')
      .select('*')
      .order('preco', { ascending: true })
    if (error) throw error
    return (data ?? []) as Plano[]
  }

  async function obter(id: string): Promise<Plano> {
    const { data, error } = await cliente
      .from('planos')
      .select('*')
      .eq('id', id)
      .single()
    if (error) throw error
    return data as Plano
  }

  async function criar(payload: PlanoInput): Promise<Plano> {
    const { data, error } = await cliente
      .from('planos')
      .insert(payload)
      .select()
      .single()
    if (error) throw error
    return data as Plano
  }

  async function atualizar(id: string, payload: Partial<PlanoInput>): Promise<Plano> {
    const { data, error } = await cliente
      .from('planos')
      .update(payload)
      .eq('id', id)
      .select()
      .single()
    if (error) throw error
    return data as Plano
  }

  async function excluir(id: string): Promise<void> {
    const { error } = await cliente
      .from('planos')
      .delete()
      .eq('id', id)
    if (error) throw error
  }

  async function alternarAtivo(id: string, ativo: boolean): Promise<void> {
    const { error } = await cliente
      .from('planos')
      .update({ ativo })
      .eq('id', id)
    if (error) throw error
  }

  return { listar, obter, criar, atualizar, excluir, alternarAtivo }
}
