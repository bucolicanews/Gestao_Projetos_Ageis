<template>
  <div class="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
    <div class="bg-white rounded-2xl shadow-xl w-full max-w-lg max-h-[90vh] overflow-y-auto">
      <div class="flex items-center justify-between p-6 border-b border-slate-100">
        <h2 class="text-lg font-bold">{{ org ? 'Editar Organização' : 'Nova Organização' }}</h2>
        <button @click="$emit('fechar')" class="text-slate-400 hover:text-slate-600 text-xl leading-none">&times;</button>
      </div>

      <form @submit.prevent="salvar" class="p-6 flex flex-col gap-4">
        <div>
          <label class="text-sm font-medium text-slate-700 mb-1 block">Nome *</label>
          <input v-model="form.nome" required placeholder="Nome da organização"
            class="w-full border border-slate-200 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-primaria" />
        </div>

        <div class="grid grid-cols-2 gap-4">
          <div>
            <label class="text-sm font-medium text-slate-700 mb-1 block">Plano</label>
            <select v-model="form.plano_id"
              class="w-full border border-slate-200 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-primaria">
              <option :value="null">— Sem plano —</option>
              <option v-for="p in planos" :key="p.id" :value="p.id">
                {{ p.titulo }} — R$ {{ Number(p.preco).toFixed(2) }}
              </option>
            </select>
          </div>
          <div>
            <label class="text-sm font-medium text-slate-700 mb-1 block">Status</label>
            <select v-model="form.status"
              class="w-full border border-slate-200 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-primaria">
              <option value="ativo">Ativo</option>
              <option value="trial">Trial</option>
              <option value="bloqueado">Bloqueado</option>
              <option value="cancelado">Cancelado</option>
              <option value="vencido">Vencido</option>
            </select>
          </div>
        </div>

        <div>
          <label class="text-sm font-medium text-slate-700 mb-1 block">Vencimento</label>
          <input v-model="form.vencimento" type="date"
            class="w-full border border-slate-200 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-primaria" />
        </div>

        <div class="grid grid-cols-2 gap-4">
          <div>
            <label class="text-sm font-medium text-slate-700 mb-1 block">Telefone (WhatsApp)</label>
            <input v-model="form.telefone" placeholder="5511999999999"
              class="w-full border border-slate-200 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-primaria" />
            <p class="text-xs text-slate-400 mt-0.5">Formato: 55 + DDD + número</p>
          </div>
          <div>
            <label class="text-sm font-medium text-slate-700 mb-1 block">Email de contato</label>
            <input v-model="form.email_contato" type="email" placeholder="contato@empresa.com"
              class="w-full border border-slate-200 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-primaria" />
          </div>
        </div>

        <p v-if="erro" class="text-sm text-perigo">{{ erro }}</p>

        <div class="flex justify-end gap-3 pt-2">
          <button type="button" @click="$emit('fechar')" class="botao-secundario">Cancelar</button>
          <button type="submit" :disabled="salvando" class="botao-primario">
            {{ salvando ? 'Salvando...' : 'Salvar' }}
          </button>
        </div>
      </form>
    </div>
  </div>
</template>

<script setup lang="ts">
import type { OrgAdmin } from '~/servicos/servicoOrganizacoesAdmin'

const props = defineProps<{
  org?: OrgAdmin | null
  planos: { id: string; titulo: string; preco: number }[]
}>()
const emit = defineEmits<{ fechar: []; salvo: [org: OrgAdmin] }>()

const svc = servicoOrganizacoesAdmin()
const salvando = ref(false)
const erro = ref('')

const form = reactive({
  nome: props.org?.nome ?? '',
  plano_id: props.org?.plano_id ?? null as string | null,
  status: props.org?.status ?? 'ativo',
  vencimento: props.org?.vencimento ?? '',
  telefone: props.org?.telefone ?? '',
  email_contato: props.org?.email_contato ?? '',
})

async function salvar() {
  erro.value = ''
  salvando.value = true
  try {
    const payload = {
      nome: form.nome,
      plano_id: form.plano_id || null,
      status: form.status,
      vencimento: form.vencimento || null,
      telefone: form.telefone || null,
      email_contato: form.email_contato || null,
    }
    const resultado = await svc.atualizar(props.org!.id, payload)
    emit('salvo', resultado)
    emit('fechar')
  } catch (e: any) {
    erro.value = e.message
  } finally {
    salvando.value = false
  }
}
</script>
