// composables/useFinanceiro.ts
export interface MetricasFinanceiras {
  totalOrgs: number
  orgsAtivas: number
  totalPlanos: number
  planosAtivos: number
  mrrPotencial: number
  orgsPorPlano: { plano_id: string | null; titulo: string; preco: number; total: number }[]
  orgsRecentes: { id: string; nome: string; plano: string; ativo: boolean; criado_em: string }[]
}

export const useFinanceiro = () => {
  const cliente = useSupabaseClient()
  const carregando = ref(false)
  const erro = ref<string | null>(null)
  const metricas = ref<MetricasFinanceiras | null>(null)

  async function carregar() {
    carregando.value = true
    erro.value = null
    try {
      const [orgsRes, planosRes] = await Promise.all([
        cliente.from('organizacoes').select('id, nome, plano, plano_id, ativo, criado_em').order('criado_em', { ascending: false }),
        cliente.from('planos').select('id, titulo, preco, ativo'),
      ])

      if (orgsRes.error) throw orgsRes.error
      if (planosRes.error) throw planosRes.error

      const orgs = orgsRes.data ?? []
      const planos = planosRes.data ?? []

      // MRR potencial: soma preco dos planos vinculados a orgs ativas
      let mrrPotencial = 0
      const orgsPorPlanoMap = new Map<string, { titulo: string; preco: number; total: number }>()

      // Inicializa todos os planos no mapa
      for (const p of planos) {
        orgsPorPlanoMap.set(p.id, { titulo: p.titulo, preco: Number(p.preco), total: 0 })
      }

      for (const org of orgs) {
        if (org.plano_id && org.ativo) {
          const entrada = orgsPorPlanoMap.get(org.plano_id)
          if (entrada) {
            entrada.total++
            mrrPotencial += entrada.preco
          }
        }
      }

      const orgsPorPlano = [
        // Orgs sem plano vinculado
        {
          plano_id: null,
          titulo: 'Sem plano',
          preco: 0,
          total: orgs.filter(o => !o.plano_id).length,
        },
        ...Array.from(orgsPorPlanoMap.entries()).map(([id, v]) => ({
          plano_id: id,
          ...v,
        })),
      ].filter(p => p.plano_id === null || p.total > 0 || planos.find(pl => pl.id === p.plano_id))

      metricas.value = {
        totalOrgs: orgs.length,
        orgsAtivas: orgs.filter(o => o.ativo).length,
        totalPlanos: planos.length,
        planosAtivos: planos.filter(p => p.ativo).length,
        mrrPotencial,
        orgsPorPlano,
        orgsRecentes: orgs.slice(0, 10) as any,
      }
    } catch (e: any) {
      erro.value = e.message
    } finally {
      carregando.value = false
    }
  }

  return { carregando, erro, metricas, carregar }
}
