<template>
  <div class="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
    <div class="bg-white rounded-2xl shadow-xl w-full max-w-sm p-6">
      <h3 class="font-bold text-base mb-1">
        {{ org.status === 'bloqueado' ? 'Desbloquear organização' : 'Bloquear organização' }}
      </h3>
      <p class="text-sm text-slate-600 mb-4">
        <strong>{{ org.nome }}</strong>
        <template v-if="org.status !== 'bloqueado'"> — usuários perderão acesso imediatamente.</template>
        <template v-else> — acesso será restaurado.</template>
      </p>

      <div v-if="org.status !== 'bloqueado'" class="mb-4">
        <label class="text-sm font-medium text-slate-700 mb-1 block">Motivo do bloqueio</label>
        <input v-model="motivo" placeholder="Ex: inadimplência, violação de termos..."
          class="w-full border border-slate-200 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-primaria" />
      </div>

      <p v-if="erro" class="text-sm text-perigo mb-3">{{ erro }}</p>

      <div class="flex gap-3 justify-end">
        <button class="botao-secundario" @click="$emit('fechar')">Cancelar</button>
        <button
          :class="org.status === 'bloqueado' ? 'botao-primario' : 'botao-perigo'"
          :disabled="salvando"
          @click="confirmar"
        >
          {{ salvando ? 'Aguarde...' : (org.status === 'bloqueado' ? 'Desbloquear' : 'Bloquear') }}
        </button>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import type { OrgAdmin } from '~/servicos/servicoOrganizacoesAdmin'

const props = defineProps<{ org: OrgAdmin }>()
const emit = defineEmits<{ fechar: []; atualizado: [] }>()

const svc = servicoOrganizacoesAdmin()
const n8n = useN8n()
const motivo = ref('')
const salvando = ref(false)
const erro = ref('')

let msgBloqueio = ''
onMounted(async () => {
  const cfg = useConfiguracoesSistema()
  const dados = await cfg.carregar()
  msgBloqueio = dados.msg_bloqueio ?? ''
})

function interpolar(tpl: string, vars: Record<string, string>): string {
  return tpl.replace(/\{(\w+)\}/g, (_, k) => vars[k] ?? `{${k}}`)
}

async function confirmar() {
  salvando.value = true
  erro.value = ''
  try {
    if (props.org.status === 'bloqueado') {
      await svc.desbloquear(props.org.id)
    } else {
      await svc.bloquear(props.org.id, motivo.value)
      // Envia notificação de bloqueio via n8n (não-bloqueante)
      if (msgBloqueio) {
        const vars = {
          nome:       props.org.nome,
          plano:      props.org.planos?.titulo ?? props.org.plano ?? '',
          vencimento: props.org.vencimento ?? '',
          dias:       '',
        }
        n8n.enviarMensagem({
          org_id:   props.org.id,
          org_nome: props.org.nome,
          telefone: props.org.telefone ?? '',
          email:    props.org.email_contato ?? props.org.dono?.email ?? '',
          mensagem: interpolar(msgBloqueio, vars),
          tipo:     'bloqueio',
          plano:    vars.plano,
          vencimento: props.org.vencimento,
          motivo:   motivo.value,
        })
      }
    }
    emit('atualizado')
    emit('fechar')
  } catch (e: any) {
    erro.value = e.message
  } finally {
    salvando.value = false
  }
}
</script>
