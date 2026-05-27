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
  const svcOrg = servicoOrganizacoesAdmin()
  const enviando = ref(false)
  const erro = ref<string | null>(null)

  async function obterWebhookUrl(): Promise<string> {
    const { data } = await cliente
      .from('configuracoes_sistema')
      .select('chave, valor')
      .in('chave', ['n8n_modo', 'n8n_webhook_url_teste', 'n8n_webhook_url_producao'])
    const map = Object.fromEntries((data ?? []).map((r: any) => [r.chave, r.valor ?? '']))
    const modo = map['n8n_modo'] ?? 'teste'
    return modo === 'producao'
      ? map['n8n_webhook_url_producao']
      : map['n8n_webhook_url_teste']
  }

  async function enviarMensagem(payload: N8nPayload): Promise<boolean> {
    enviando.value = true
    erro.value = null
    try {
      const url = await obterWebhookUrl()
      if (!url) {
        throw new Error('URL do webhook n8n não configurada. Acesse Configurações.')
      }

      const response = await fetch(url, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload),
      })

      if (!response.ok) {
        throw new Error(`n8n retornou ${response.status}: ${response.statusText}`)
      }

      // Registra no log
      await svcOrg.registrarMensagem({
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
        await svcOrg.registrarMensagem({
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

  return { enviando, erro, enviarMensagem, obterWebhookUrl }
}
