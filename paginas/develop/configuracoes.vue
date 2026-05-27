<template>
  <div>
    <div v-if="verificando" class="flex items-center justify-center h-40 text-slate-400">
      Verificando permissões...
    </div>

    <template v-else-if="isDevelopAdmin">
      <div class="flex justify-between items-center mb-6">
        <div>
          <h1 class="text-2xl font-bold">🔧 Configurações</h1>
          <p class="text-sm text-slate-500 mt-0.5">Webhooks n8n e templates de mensagem</p>
        </div>
        <button class="botao-primario" :disabled="cfg.salvando.value" @click="salvar">
          {{ cfg.salvando.value ? 'Salvando...' : '💾 Salvar tudo' }}
        </button>
      </div>

      <div v-if="cfg.carregando.value" class="text-slate-400 text-sm py-8 text-center">Carregando...</div>

      <template v-else>
        <!-- Feedback -->
        <div v-if="cfg.sucesso.value" class="mb-4 p-3 bg-green-50 border border-green-100 rounded-lg text-sm text-green-700">
          ✓ Configurações salvas com sucesso.
        </div>
        <div v-if="cfg.erro.value" class="mb-4 p-3 bg-red-50 border border-red-100 rounded-lg text-sm text-perigo">
          {{ cfg.erro.value }}
        </div>

        <div class="flex flex-col gap-6">

          <!-- Webhooks n8n -->
          <div class="cartao">
            <h2 class="font-semibold text-base mb-1">Webhooks n8n</h2>
            <p class="text-xs text-slate-400 mb-4">
              Cole a URL do webhook do n8n para cada evento. Deixe em branco para desativar.
            </p>

            <div class="flex flex-col gap-4">
              <div v-for="wh in webhooks" :key="wh.chave">
                <label class="text-sm font-medium text-slate-700 mb-1 block">
                  {{ wh.label }}
                  <span class="text-xs font-normal text-slate-400 ml-1">{{ wh.desc }}</span>
                </label>
                <input
                  v-model="form[wh.chave]"
                  type="url"
                  :placeholder="wh.placeholder"
                  class="w-full border border-slate-200 rounded-lg px-3 py-2 text-sm font-mono focus:outline-none focus:ring-2 focus:ring-primaria"
                />
              </div>
            </div>
          </div>

          <!-- Templates de mensagem -->
          <div class="cartao">
            <h2 class="font-semibold text-base mb-1">Templates de Mensagem</h2>
            <p class="text-xs text-slate-400 mb-4">
              Variáveis disponíveis:
              <code class="bg-slate-100 px-1 rounded">{nome}</code>
              <code class="bg-slate-100 px-1 rounded ml-1">{plano}</code>
              <code class="bg-slate-100 px-1 rounded ml-1">{vencimento}</code>
              <code class="bg-slate-100 px-1 rounded ml-1">{dias}</code>
            </p>

            <div class="flex flex-col gap-5">
              <div v-for="tpl in templates" :key="tpl.chave">
                <label class="text-sm font-medium text-slate-700 mb-1 block">
                  {{ tpl.label }}
                </label>
                <textarea
                  v-model="form[tpl.chave]"
                  rows="3"
                  :placeholder="tpl.placeholder"
                  class="w-full border border-slate-200 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-primaria resize-none"
                />
                <!-- Preview interpolado -->
                <div v-if="form[tpl.chave]" class="mt-1 p-2 bg-slate-50 rounded text-xs text-slate-500 border border-slate-100">
                  <span class="text-[10px] text-slate-400 font-semibold uppercase tracking-wide block mb-0.5">Preview:</span>
                  {{ interpolar(form[tpl.chave]) }}
                </div>
              </div>
            </div>
          </div>

          <!-- Rodapé: botão salvar -->
          <div class="flex justify-end">
            <button class="botao-primario" :disabled="cfg.salvando.value" @click="salvar">
              {{ cfg.salvando.value ? 'Salvando...' : '💾 Salvar tudo' }}
            </button>
          </div>

        </div>
      </template>
    </template>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ layout: 'default' })

const { isDevelopAdmin, verificando } = useDevelopAdmin()
const cfg = useConfiguracoesSistema()

const form = reactive<Record<string, string>>({})

const webhooks = [
  { chave: 'n8n_webhook_mensagem',            label: '💬 Mensagem manual',         desc: 'disparo manual pela UI',         placeholder: 'https://n8n.exemplo.com/webhook/...' },
  { chave: 'n8n_webhook_vencimento_iminente', label: '⚠ Vencimento iminente',      desc: 'X dias antes do vencimento',     placeholder: 'https://n8n.exemplo.com/webhook/...' },
  { chave: 'n8n_webhook_dia_vencimento',      label: '📅 Dia do vencimento',        desc: 'no dia em que vence',            placeholder: 'https://n8n.exemplo.com/webhook/...' },
  { chave: 'n8n_webhook_apos_vencimento',     label: '🔴 Após vencimento',          desc: 'após a data de vencimento',      placeholder: 'https://n8n.exemplo.com/webhook/...' },
  { chave: 'n8n_webhook_confirmacao',         label: '✅ Confirmação de envio',      desc: 'webhook de resposta do n8n',     placeholder: 'https://n8n.exemplo.com/webhook/...' },
]

const templates = [
  { chave: 'msg_vencimento_iminente', label: '⚠ Template — Vencimento iminente', placeholder: 'Olá {nome}! Seu plano {plano} vence em {dias} dias...' },
  { chave: 'msg_dia_vencimento',      label: '📅 Template — Dia do vencimento',  placeholder: 'Olá {nome}! Hoje é o último dia do seu plano {plano}...' },
  { chave: 'msg_apos_vencimento',     label: '🔴 Template — Após vencimento',    placeholder: 'Olá {nome}! Seu plano {plano} venceu...' },
]

function interpolar(texto: string): string {
  return texto
    .replace(/{nome}/g, 'Empresa Exemplo')
    .replace(/{plano}/g, 'Pro')
    .replace(/{vencimento}/g, '30/06/2026')
    .replace(/{dias}/g, '7')
}

async function salvar() {
  await cfg.salvar({ ...form })
}

onMounted(async () => {
  const dados = await cfg.carregar()
  Object.assign(form, dados)
})
</script>
