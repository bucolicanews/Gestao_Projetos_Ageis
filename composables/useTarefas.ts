export const useTarefas = () => {
    const cliente = useSupabaseClient()

    const criarTarefa = async (payload: any) => {
        const { data, error } = await cliente
            .from('tarefas')
            .insert(payload)
            .select()
            .single()

        if (error) throw error
        return data
    }

    const listarTarefas = async (projetoId: string) => {
        if (!projetoId) return []

        const { data, error } = await cliente
            .from('tarefas')
            .select('*')
            .eq('projeto_id', projetoId)

        if (error) throw error
        return data
    }

    return {
        criarTarefa,
        listarTarefas
    }
}