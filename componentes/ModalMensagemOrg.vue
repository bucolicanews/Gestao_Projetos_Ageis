<template>
  <div class="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
    <div class="bg-white rounded-2xl shadow-xl w-full max-w-md">
      <div class="flex items-center justify-between p-5 border-b border-slate-100">
        <div>
          <h2 class="text-base font-bold">Enviar Mensagem</h2>
          <p class="text-xs text-slate-500 mt-0.5">{{ org.nome }}</p>
        </div>
        <button @click="$emit('fechar')" class="text-slate-400 hover:text-slate-600 text-xl leading-none">&times;</button>
      </div>

      <form @submit.prevent="enviar" class="p-5 flex flex-col gap-4">
        <!-- Destino -->
        <div class="bg-slate-50 rounded-lg p-3 text-sm flex flex-col gap-1">
          <div class="flex gap-2">
            <span class="text-slate-400 w-20">Telefone:</span>
            <span class="font-medium">{{ org.telefone || '—' }}</span>
            <span v-if="!org.telefone" class="text-amber-500 text-xs">(não cadastrado)</span>
          </div>
          <div class="flex gap-2">
            <span class="text-slate-400 w-20">Email:</span>
            <span class="font-medium">{{ org.email_contato || org.dono?.email || '—' }}</span>
          </div>
        </div>

        <!-- Mensagem rápida (templates) -->
        <div>
          <label class="text-sm font-medium text-slate-700 mb-1 block">Template rápido</label>
          <div class="flex flex-wrap gap-2">
            <button
              v-for="t in templates"
              :key="t.label"
              type="button"
              class="text-xs px-2 py-1 rounded-lg bg-slate-100 hover:bg-primaria hover:text-white transition"
              @click="form.mensagem = t.texto"
            >{{ t.label }}</button>
          </div>
        </div>

        <!-- Mensagem -->
        <div>
          <label class="text-sm font-medium text-slate-700 mb-1 block">Mensagem *</label>
          <textarea
            v-model="form.mensagem"
            required
            rows="4"
            placeholder="Digite a mensagem..."
            class="w-full border border-slate-200 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-primaria resize-none"
          />
          <p class="text-xs text-slate-400 mt-1">
            Variáveis: <code>{nome}</code>, <code>{plano}</code>, <code>{vencimento}</code>
          </p>
        </div>

        <p v-if="n8n.erro.value" class="text-sm text-perigo bg-red-50 rounded-lg p-3">
          {{ n8n.erro.value }}
        </p>
        <p v-if="sucesso" class="text-sm text-green-700 bg-green-50 rounded-lg p-3">
          Mensagem enviada com sucesso!
        </p>

        <div class="flex justify-end gap-3">
          <button type="button" @click="$emit('fechar')" class="botao-secundario">Fechar</button>
          <button
            type="submit"
            :disabled="n8n.enviando.value || sucesso || !org.telefone"
            class="botao-primario"
            :title="!org.telefone ? 'Cadastre o telefone da organização primeiro' : ''"
          >
            {{ n8n.enviando.value ? 'Enviando...' : '📤 Enviar via n8n' }}
          </button>
        </div>
      </form>
    </div>
  </div>
</template>

<script setup lang="ts">
import type { OrgAdmin } from '~/servicos/servicoOrganizacoesAdmin'

const props = defineProps<{ org: OrgAdmin }>()
const emit = defineEmits<{ fechar: []; enviado: [] }>()

const n8n = useN8n()
const sucesso = ref(false)

const form = reactive({ mensagem: '' })

const templates = [
  { label: 'Vencimento próximo', texto: `Olá {nome}! Seu plano {plano} está próximo do vencimento ({vencimento}). Renove agora para manter o acesso.` },
  { label: 'Plano vencido', texto: `Olá {nome}! Seu plano {plano} venceu. Entre em contato para reativar.` },
  { label: 'Boas-vindas', texto: `Olá {nome}! Seja bem-vindo ao sistema. Seu plano {plano} está ativo.` },
  { label: 'Conta bloqueada', texto: `Olá {nome}! Sua conta foi temporariamente bloqueada. Entre em contato conosco.` },
]

function interpolar(texto: string): string {
  return texto
    .replace('{nome}', props.org.nome)
    .replace('{plano}', props.org.planos?.titulo ?? props.org.plano ?? '')
    .replace('{vencimento}', props.org.vencimento
      ? new Date(props.org.vencimento).toLocaleDateString('pt-BR')
      : 'não definido'
    )
}

async function enviar() {
  const ok = await n8n.enviarMensagem({
    org_id: props.org.id,
    org_nome: props.org.nome,
    telefone: props.org.telefone ?? '',
    email: props.org.email_contato ?? props.org.dono?.email ?? '',
    mensagem: interpolar(form.mensagem),
    tipo: 'manual',
    plano: props.org.planos?.titulo ?? props.org.plano ?? '',
    vencimento: props.org.vencimento,
  })
  if (ok) {
    sucesso.value = true
    emit('enviado')
    setTimeout(() => emit('fechar'), 1500)
  }
}
</script>
