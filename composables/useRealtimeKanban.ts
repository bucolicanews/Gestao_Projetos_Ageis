// composables/useRealtimeKanban.ts
// Assina mudanças em tempo real na tabela `tarefas` para um projeto.
// Usa supabase.channel + Postgres Changes (INSERT/UPDATE/DELETE).
import type { RealtimeChannel } from '@supabase/supabase-js'

export function useRealtimeKanban(projetoId: Ref<string | null | undefined> | string) {
  const cliente = useSupabaseClient()
  const usuario = useSupabaseUser()
  const loja = useLojaKanban()

  const idRef = typeof projetoId === 'string' ? ref(projetoId) : projetoId
  let canal: RealtimeChannel | null = null
  const presentes = ref<Array<{ id: string; nome: string }>>([])

  function desconectar() {
    if (canal) { cliente.removeChannel(canal); canal = null }
    presentes.value = []
  }

  function conectar(id: string) {
    desconectar()
    canal = cliente.channel(`kanban:${id}`, {
      config: { presence: { key: usuario.value?.id ?? 'anon' } },
    })

    // Postgres changes -> sincroniza estado da loja
    canal.on(
      'postgres_changes',
      { event: '*', schema: 'public', table: 'tarefas', filter: `projeto_id=eq.${id}` },
      (payload) => {
        const { eventType, new: novo, old: antigo } = payload as any
        if (eventType === 'INSERT') {
          if (!loja.tarefas.find(t => t.id === novo.id)) loja.tarefas.push(novo)
        } else if (eventType === 'UPDATE') {
          const idx = loja.tarefas.findIndex(t => t.id === novo.id)
          if (idx >= 0) loja.tarefas[idx] = { ...loja.tarefas[idx], ...novo }
          else loja.tarefas.push(novo)
        } else if (eventType === 'DELETE') {
          loja.tarefas = loja.tarefas.filter(t => t.id !== antigo.id)
        }
      },
    )

    // Presença -> quem está vendo o quadro
    canal.on('presence', { event: 'sync' }, () => {
      const estado = canal!.presenceState() as Record<string, Array<{ id: string; nome: string }>>
      presentes.value = Object.values(estado).flat()
    })

    canal.subscribe(async (status) => {
      if (status === 'SUBSCRIBED' && usuario.value) {
        await canal!.track({
          id: usuario.value.id,
          nome: usuario.value.user_metadata?.nome ?? usuario.value.email,
        })
      }
    })
  }

  watch(idRef, (id) => { if (id) conectar(id); else desconectar() }, { immediate: true })
  onBeforeUnmount(desconectar)

  return { presentes }
}
