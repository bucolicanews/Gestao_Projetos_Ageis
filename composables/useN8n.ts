// composables/useN8n.ts
// Envia mensagens para organizações via webhook n8n

export interface N8nPayload {
  org_id: string
  org_nome: string
  telefone: string
  email: string
  mensagem: string
  tipo: string
  [key: string]: any
}

export const useN8n = () => {
  const cliente = useSupabaseClient()
  const enviando = ref(false)
  const erro = ref<string | null>(null)

  async function obterWebhook(chave: string): Promise<string | null> {
    const { data } = await cliente
      .from('configuracoes_sistema')
      .select('valor')
      .eq('chave', chave)
      .single()
    return data?.valor ?? null
  }

  async function enviarMensagem(payload: N8nPayload): Promise<boolean> {
    enviando.value = true
    erro.value = null
    try {
      const webhookUrl = await obterWebhook('n8n_webhook_mensagem')
      if (!webhookUrl) {
        throw new Error('Webhook n8n não configurado. Acesse Configurações.')
      }

      const response = await fetch(webhookUrl, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload),
      })

      if (!response.ok) {
        throw new Error(`n8n retornou ${response.status}: ${response.statusText}`)
      }

      // Registra no log
      await servicoOrganizacoesAdmin().registrarMensagem({
        org_id: payload.org_id,
        tipo: payload.tipo,
        mensagem: payload.mensagem,
        status: 'enviado',
      })

      return true
    } catch (e: any) {
      erro.value = e.message
      // Tenta registrar falha no log
      try {
        await servicoOrganizacoesAdmin().registrarMensagem({
          org_id: payload.org_id,
          tipo: payload.tipo,
          mensagem: payload.mensagem,
          status: 'falhou',
        })
      } catch {}
      return false
    } finally {
      enviando.value = false
    }
  }

  return { enviando, erro, enviarMensagem, obterWebhook }
}
