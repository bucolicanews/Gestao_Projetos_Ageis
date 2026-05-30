<template>
  <div>
    <div v-if="verificando" class="flex items-center justify-center h-40 text-slate-400">
      Verificando permissões...
    </div>

    <template v-else-if="isDevelopAdmin">
      <div class="mb-6">
        <div class="flex items-center justify-between gap-3">
          <h1 class="text-2xl font-bold">🔧 Configurações</h1>
          <button class="botao-primario" :disabled="cfg.salvando.value" @click="salvar">
            {{ cfg.salvando.value ? 'Salvando...' : '💾 Salvar' }}
          </button>
        </div>
        <p class="text-sm text-slate-500 mt-0.5">Webhook n8n e regras de notificação</p>
      </div>

      <div v-if="cfg.carregando.value" class="text-slate-400 text-sm py-8 text-center">Carregando...</div>

      <template v-else>
        <div v-if="cfg.sucesso.value" class="mb-4 p-3 bg-green-50 border border-green-100 rounded-xl text-sm text-green-700 flex items-center gap-2">
          <span>✓</span> Configurações salvas.
        </div>
        <div v-if="cfg.erro.value" class="mb-4 p-3 bg-red-50 border border-red-100 rounded-xl text-sm text-perigo">
          {{ cfg.erro.value }}
        </div>

        <div class="flex flex-col gap-6">

          <!-- ── Webhook n8n ── -->
          <div class="cartao">
            <div class="flex items-start justify-between mb-4">
              <div>
                <h2 class="font-semibold text-base mb-0.5">🔗 Webhook n8n</h2>
                <p class="text-xs text-slate-400">
                  Campo <code class="bg-slate-100 px-1 rounded">tipo</code> no payload identifica a ação — filtre no n8n.
                </p>
              </div>
              <!-- Toggle modo -->
              <div class="flex items-center gap-1 p-1 bg-slate-100 rounded-xl shrink-0 ml-4">
                <button type="button"
                  class="px-3 py-1.5 text-xs font-semibold rounded-lg transition"
                  :class="form.n8n_modo === 'teste' ? 'bg-white shadow text-amber-600' : 'text-slate-500 hover:text-slate-700'"
                  @click="form.n8n_modo = 'teste'">
                  🧪 Teste
                </button>
                <button type="button"
                  class="px-3 py-1.5 text-xs font-semibold rounded-lg transition"
                  :class="form.n8n_modo === 'producao' ? 'bg-white shadow text-green-600' : 'text-slate-500 hover:text-slate-700'"
                  @click="form.n8n_modo = 'producao'">
                  🚀 Produção
                </button>
              </div>
            </div>

            <div class="flex flex-col gap-4">
              <div>
                <label class="text-sm font-medium text-slate-700 mb-1 flex items-center gap-2 block">
                  <span class="text-amber-500">🧪</span> URL de Teste
                  <span class="text-[10px] text-slate-400 font-normal">/webhook-test/ — escuta ativa no editor n8n</span>
                </label>
                <input v-model="form.n8n_webhook_url_teste" type="url"
                  placeholder="https://seu-n8n.com/webhook-test/projetosageis"
                  class="w-full border border-slate-200 rounded-xl px-3 py-2 text-sm font-mono focus:outline-none focus:ring-2 focus:ring-amber-400"
                  :class="form.n8n_modo === 'teste' ? 'border-amber-300 bg-amber-50' : ''" />
              </div>
              <div>
                <label class="text-sm font-medium text-slate-700 mb-1 flex items-center gap-2 block">
                  <span class="text-green-500">🚀</span> URL de Produção
                  <span class="text-[10px] text-slate-400 font-normal">/webhook/ — workflow publicado e ativo</span>
                </label>
                <input v-model="form.n8n_webhook_url_producao" type="url"
                  placeholder="https://seu-n8n.com/webhook/projetosageis"
                  class="w-full border border-slate-200 rounded-xl px-3 py-2 text-sm font-mono focus:outline-none focus:ring-2 focus:ring-green-400"
                  :class="form.n8n_modo === 'producao' ? 'border-green-300 bg-green-50' : ''" />
              </div>
            </div>

            <!-- Modo ativo -->
            <div class="mt-3 flex items-center gap-2 text-xs"
              :class="form.n8n_modo === 'producao' ? 'text-green-600' : 'text-amber-600'">
              <span>{{ form.n8n_modo === 'producao' ? '🚀' : '🧪' }}</span>
              <span class="font-semibold">Modo ativo: {{ form.n8n_modo === 'producao' ? 'Produção' : 'Teste' }}</span>
              <span class="text-slate-400">— envios usarão a URL {{ form.n8n_modo === 'producao' ? 'de produção' : 'de teste' }}</span>
            </div>

            <!-- Exemplo de payload -->
            <div class="mt-4 rounded-xl bg-slate-50 border border-slate-200 p-4">
              <p class="text-[10px] font-semibold uppercase tracking-wide text-slate-400 mb-2">Payload enviado ao n8n</p>
              <pre class="text-xs text-slate-600 overflow-x-auto leading-relaxed">{{ payloadExemplo }}</pre>
            </div>

            <!-- Teste de envio -->
            <div class="mt-4 rounded-xl border border-blue-200 bg-blue-50 p-4">
              <p class="text-sm font-semibold text-blue-700 mb-3">📤 Enviar Mensagem</p>
              <div class="flex flex-col sm:flex-row gap-3">
                <select v-model="testeOrgId"
                  class="flex-1 border border-blue-200 rounded-xl px-3 py-2 text-sm bg-white focus:outline-none focus:ring-2 focus:ring-blue-400">
                  <option value="">— Selecione uma organização —</option>
                  <option v-for="o in orgsDisponiveis" :key="o.id" :value="o.id">
                    {{ o.nome }}
                  </option>
                </select>
                <select v-model="testeTipo"
                  class="border border-blue-200 rounded-xl px-3 py-2 text-sm bg-white focus:outline-none focus:ring-2 focus:ring-blue-400">
                  <option value="mensagem_manual">mensagem_manual</option>
                  <option value="cadastro">cadastro</option>
                  <option value="bloqueio">bloqueio</option>
                  <option value="vencimento_iminente">vencimento_iminente</option>
                  <option value="dia_vencimento">dia_vencimento</option>
                  <option value="apos_vencimento">apos_vencimento</option>
                </select>
                <button
                  type="button"
                  :disabled="!testeOrgId || !urlAtiva || testeEnviando || (testeTipo === 'mensagem_manual' && !testeMensagemManual.trim())"
                  class="px-4 py-2 rounded-xl text-sm font-medium transition bg-blue-600 text-white hover:bg-blue-700 disabled:opacity-40 disabled:cursor-not-allowed whitespace-nowrap"
                  @click="enviarTeste"
                >
                  {{ testeEnviando ? 'Enviando...' : '▶ Enviar teste' }}
                </button>
              </div>
              <!-- Textarea para mensagem_manual -->
              <div v-if="testeTipo === 'mensagem_manual'" class="mt-3">
                <textarea
                  v-model="testeMensagemManual"
                  rows="3"
                  placeholder="Digite a mensagem a enviar para a organização selecionada..."
                  class="w-full border border-blue-200 rounded-xl px-3 py-2 text-sm bg-white focus:outline-none focus:ring-2 focus:ring-blue-400 resize-none"
                />
              </div>
              <p v-if="!urlAtiva" class="text-xs text-blue-500 mt-2">Digite a URL {{ form.n8n_modo === 'producao' ? 'de produção' : 'de teste' }} acima para habilitar o teste.</p>
              <div v-if="testeResultado" class="mt-3 p-3 rounded-lg text-xs font-medium"
                :class="testeResultado.ok ? 'bg-green-100 text-green-700' : 'bg-red-100 text-red-700'">
                {{ testeResultado.mensagem }}
              </div>
            </div>
          </div>

          <!-- ── Timing de notificações ── -->
          <div class="cartao">
            <h2 class="font-semibold text-base mb-0.5">⏰ Regras de Notificação</h2>
            <p class="text-xs text-slate-400 mb-5">Quando o sistema dispara automaticamente as mensagens.</p>

            <div class="flex flex-col gap-5">

              <!-- Antes do vencimento -->
              <div class="rounded-xl border border-slate-200 p-4">
                <div class="flex items-center gap-2 mb-3">
                  <span class="text-base">⚠️</span>
                  <p class="font-semibold text-sm text-slate-700">Antes do vencimento</p>
                </div>
                <div class="flex items-center gap-3">
                  <label class="text-sm text-slate-600 whitespace-nowrap">Enviar</label>
                  <input v-model.number="form.notif_dias_antes" type="number" min="1" max="90"
                    class="w-20 border border-slate-200 rounded-lg px-3 py-1.5 text-sm text-center focus:outline-none focus:ring-2 focus:ring-primaria" />
                  <label class="text-sm text-slate-600">dias antes do vencimento</label>
                </div>
              </div>

              <!-- No dia do vencimento -->
              <div class="rounded-xl border border-slate-200 p-4">
                <div class="flex items-center justify-between">
                  <div class="flex items-center gap-2">
                    <span class="text-base">📅</span>
                    <p class="font-semibold text-sm text-slate-700">No dia do vencimento</p>
                  </div>
                  <label class="flex items-center gap-2 cursor-pointer select-none">
                    <div class="relative">
                      <input type="checkbox" class="sr-only" v-model="notifNoVencimento" />
                      <div class="w-10 h-6 rounded-full transition"
                        :class="notifNoVencimento ? 'bg-primaria' : 'bg-slate-200'">
                        <div class="absolute top-1 w-4 h-4 rounded-full bg-white shadow transition-transform"
                          :class="notifNoVencimento ? 'translate-x-5' : 'translate-x-1'" />
                      </div>
                    </div>
                    <span class="text-sm text-slate-600">{{ notifNoVencimento ? 'Sim' : 'Não' }}</span>
                  </label>
                </div>
              </div>

              <!-- Após o vencimento -->
              <div class="rounded-xl border border-slate-200 p-4">
                <div class="flex items-center gap-2 mb-3">
                  <span class="text-base">🔴</span>
                  <p class="font-semibold text-sm text-slate-700">Após o vencimento</p>
                </div>
                <div class="flex flex-col gap-3">
                  <div class="flex items-center gap-3">
                    <label class="text-sm text-slate-600 whitespace-nowrap">Primeira mensagem após</label>
                    <input v-model.number="form.notif_apos_dias" type="number" min="0" max="90"
                      class="w-20 border border-slate-200 rounded-lg px-3 py-1.5 text-sm text-center focus:outline-none focus:ring-2 focus:ring-primaria" />
                    <label class="text-sm text-slate-600">dias</label>
                  </div>
                </div>
              </div>

              <!-- Repetição -->
              <div class="rounded-xl border border-slate-200 p-4">
                <div class="flex items-center gap-2 mb-3">
                  <span class="text-base">🔁</span>
                  <p class="font-semibold text-sm text-slate-700">Repetição após vencimento</p>
                </div>
                <div class="flex flex-col gap-3">
                  <div class="flex items-center gap-3">
                    <label class="text-sm text-slate-600 whitespace-nowrap">Repetir</label>
                    <input v-model.number="form.notif_repetir_vezes" type="number" min="0" max="20"
                      class="w-20 border border-slate-200 rounded-lg px-3 py-1.5 text-sm text-center focus:outline-none focus:ring-2 focus:ring-primaria" />
                    <label class="text-sm text-slate-600 whitespace-nowrap">vez(es) a cada</label>
                    <input v-model.number="form.notif_repetir_intervalo" type="number" min="1" max="60"
                      class="w-20 border border-slate-200 rounded-lg px-3 py-1.5 text-sm text-center focus:outline-none focus:ring-2 focus:ring-primaria" />
                    <label class="text-sm text-slate-600">dias</label>
                  </div>
                </div>
              </div>

              <!-- Resumo visual -->
              <div class="rounded-xl bg-slate-50 border border-slate-200 p-4 text-sm text-slate-600">
                <p class="font-semibold text-slate-700 mb-2 text-xs uppercase tracking-wide">Resumo do fluxo</p>
                <ol class="flex flex-col gap-1.5 text-xs list-decimal list-inside">
                  <li>
                    <strong>D-{{ form.notif_dias_antes }}</strong>: aviso de vencimento iminente
                  </li>
                  <li v-if="notifNoVencimento">
                    <strong>D0</strong>: lembrete no dia do vencimento
                  </li>
                  <li>
                    <strong>D+{{ form.notif_apos_dias }}</strong>: primeira mensagem após vencimento
                  </li>
                  <li v-if="form.notif_repetir_vezes > 0">
                    Repete mais <strong>{{ form.notif_repetir_vezes }}x</strong> a cada
                    <strong>{{ form.notif_repetir_intervalo }} dias</strong>
                    (até D+{{ form.notif_apos_dias + (form.notif_repetir_vezes * form.notif_repetir_intervalo) }})
                  </li>
                </ol>
              </div>

            </div>
          </div>

          <!-- ── Templates de mensagem ── -->
          <div class="cartao">
            <h2 class="font-semibold text-base mb-0.5">✍ Templates de Mensagem</h2>
            <p class="text-xs text-slate-400 mb-4">
              Variáveis:
              <code class="bg-slate-100 px-1 rounded">{nome}</code>
              <code class="bg-slate-100 px-1 rounded ml-1">{plano}</code>
              <code class="bg-slate-100 px-1 rounded ml-1">{vencimento}</code>
              <code class="bg-slate-100 px-1 rounded ml-1">{dias}</code>
            </p>
            <div class="flex flex-col gap-5">
              <div v-for="tpl in templates" :key="tpl.chave">
                <label class="text-sm font-medium text-slate-700 mb-1 block">{{ tpl.label }}</label>
                <textarea v-model="form[tpl.chave]" rows="2" :placeholder="tpl.placeholder"
                  class="w-full border border-slate-200 rounded-xl px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-primaria resize-none" />
              </div>
            </div>
          </div>

          <div class="flex justify-end">
            <button class="botao-primario" :disabled="cfg.salvando.value" @click="salvar">
              {{ cfg.salvando.value ? 'Salvando...' : '💾 Salvar configurações' }}
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

const form = reactive<Record<string, any>>({
  n8n_webhook_url_teste:    '',
  n8n_webhook_url_producao: '',
  n8n_modo:                 'teste',
  notif_dias_antes:         7,
  notif_no_vencimento:      'true',
  notif_apos_dias:          3,
  notif_repetir_vezes:      3,
  notif_repetir_intervalo:  7,
  msg_cadastro:             '',
  msg_bloqueio:             '',
  msg_vencimento_iminente:  '',
  msg_dia_vencimento:       '',
  msg_apos_vencimento:      '',
})

const urlAtiva = computed(() =>
  form.n8n_modo === 'producao' ? form.n8n_webhook_url_producao : form.n8n_webhook_url_teste
)

const notifNoVencimento = computed({
  get: () => form.notif_no_vencimento === 'true' || form.notif_no_vencimento === true,
  set: (v: boolean) => { form.notif_no_vencimento = v ? 'true' : 'false' },
})

// Teste de webhook
const orgsDisponiveis = ref<{ id: string; nome: string; telefone: string | null; email_contato: string | null; planos: any; dono: any }[]>([])
const testeOrgId = ref('')
const testeTipo = ref('mensagem_manual')
const testeMensagemManual = ref('')
const testeEnviando = ref(false)
const testeResultado = ref<{ ok: boolean; mensagem: string } | null>(null)
const n8n = useN8n()

const tipoParaTemplate: Record<string, string> = {
  cadastro:            'msg_cadastro',
  bloqueio:            'msg_bloqueio',
  vencimento_iminente: 'msg_vencimento_iminente',
  dia_vencimento:      'msg_dia_vencimento',
  apos_vencimento:     'msg_apos_vencimento',
}

function interpolarTemplate(tpl: string, vars: Record<string, string>): string {
  return tpl.replace(/\{(\w+)\}/g, (_, key) => vars[key] ?? `{${key}}`)
}

async function enviarTeste() {
  const org = orgsDisponiveis.value.find(o => o.id === testeOrgId.value)
  if (!org || !urlAtiva.value) return
  if (testeTipo.value === 'mensagem_manual' && !testeMensagemManual.value.trim()) return
  testeEnviando.value = true
  testeResultado.value = null

  const planoTitulo = org.planos?.titulo ?? ''
  const vencimentoStr = (org as any).vencimento ?? ''
  const vars = {
    nome:       org.nome,
    plano:      planoTitulo,
    vencimento: vencimentoStr,
    dias:       String(form.notif_dias_antes),
  }
  let mensagem: string
  if (testeTipo.value === 'mensagem_manual') {
    mensagem = testeMensagemManual.value.trim()
  } else {
    const chaveTemplate = tipoParaTemplate[testeTipo.value]
    const templateBase = chaveTemplate ? (form[chaveTemplate] as string) : ''
    mensagem = templateBase
      ? interpolarTemplate(templateBase, vars)
      : `[TESTE] tipo: ${testeTipo.value}`
  }

  try {
    const response = await fetch(urlAtiva.value, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        tipo: testeTipo.value,
        org_id: org.id,
        org_nome: org.nome,
        telefone: org.telefone ?? '',
        email: org.email_contato ?? org.dono?.email ?? '',
        mensagem,
        plano: planoTitulo,
        vencimento: vencimentoStr || null,
        teste: true,
      }),
    })
    testeResultado.value = response.ok
      ? { ok: true, mensagem: `✓ n8n respondeu ${response.status}. Webhook funcionando.` }
      : { ok: false, mensagem: `✗ n8n respondeu ${response.status}: ${response.statusText}` }
  } catch (e: any) {
    testeResultado.value = { ok: false, mensagem: `✗ Erro de conexão: ${e.message}` }
  } finally {
    testeEnviando.value = false
  }
}

const payloadExemplo = computed(() => JSON.stringify({
  tipo: 'vencimento_iminente',   // mensagem_manual | vencimento_iminente | dia_vencimento | apos_vencimento
  org_id: 'uuid-da-org',
  org_nome: 'Empresa Exemplo',
  telefone: '5511999999999',
  email: 'contato@empresa.com',
  mensagem: 'Olá! Seu plano vence em 7 dias.',
  plano: 'Pro',
  vencimento: '2026-06-30',
}, null, 2))

const templates = [
  { chave: 'msg_cadastro',            label: '👋 Boas-vindas (cadastro)',  placeholder: 'Olá {nome}! Seja bem-vindo ao {plano}. Estamos aqui para ajudar!' },
  { chave: 'msg_bloqueio',            label: '🔒 Bloqueio de conta',       placeholder: 'Olá {nome}! Sua conta foi bloqueada. Entre em contato conosco.' },
  { chave: 'msg_vencimento_iminente', label: '⚠️ Vencimento iminente',    placeholder: 'Olá {nome}! Seu plano {plano} vence em {dias} dias...' },
  { chave: 'msg_dia_vencimento',      label: '📅 Dia do vencimento',       placeholder: 'Olá {nome}! Hoje é o último dia do plano {plano}...' },
  { chave: 'msg_apos_vencimento',     label: '🔴 Após vencimento',         placeholder: 'Olá {nome}! Seu plano {plano} venceu...' },
]

async function salvar() {
  const payload: Record<string, string> = {}
  for (const [k, v] of Object.entries(form)) {
    payload[k] = String(v)
  }
  await cfg.salvar(payload)
}

onMounted(async () => {
  const [dados, orgsData] = await Promise.all([
    cfg.carregar(),
    servicoOrganizacoesAdmin().listarTodas(),
  ])
  const numericos = ['notif_dias_antes', 'notif_apos_dias', 'notif_repetir_vezes', 'notif_repetir_intervalo']
  for (const [k, v] of Object.entries(dados)) {
    if (k in form) {
      form[k] = numericos.includes(k) ? Number(v) : v
    }
  }
  orgsDisponiveis.value = orgsData
})
</script>
