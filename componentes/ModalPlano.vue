<template>
  <div class="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
    <div class="bg-white rounded-2xl shadow-xl w-full max-w-xl flex flex-col max-h-[92vh]">

      <!-- Header -->
      <div class="flex items-center justify-between px-6 py-4 border-b border-slate-100 shrink-0">
        <h2 class="text-lg font-bold">{{ plano ? 'Editar Plano' : 'Novo Plano' }}</h2>
        <button @click="$emit('fechar')" class="w-8 h-8 flex items-center justify-center rounded-full text-slate-400 hover:bg-slate-100 text-xl leading-none">&times;</button>
      </div>

      <!-- Body -->
      <form @submit.prevent="salvar" class="overflow-y-auto flex flex-col gap-5 p-6">

        <!-- Título -->
        <div>
          <label class="text-sm font-medium text-slate-700 mb-1 block">Título *</label>
          <input v-model="form.titulo" required placeholder="Ex: Pro"
            class="w-full border border-slate-200 rounded-xl px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-primaria" />
        </div>

        <!-- Descrição -->
        <div>
          <label class="text-sm font-medium text-slate-700 mb-1 block">Descrição</label>
          <textarea v-model="form.descricao" rows="2" placeholder="Para times em crescimento..."
            class="w-full border border-slate-200 rounded-xl px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-primaria resize-none" />
        </div>

        <!-- Preço + Trial + Usuários -->
        <div class="grid grid-cols-3 gap-3">
          <div>
            <label class="text-sm font-medium text-slate-700 mb-1 block">Preço (R$) *</label>
            <input v-model.number="form.preco" type="number" min="0" step="0.01" required placeholder="99.90"
              class="w-full border border-slate-200 rounded-xl px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-primaria" />
          </div>
          <div>
            <label class="text-sm font-medium text-slate-700 mb-1 block">
              Dias trial
              <span class="text-[10px] text-slate-400 font-normal ml-1">0 = sem trial</span>
            </label>
            <input v-model.number="form.dias_trial" type="number" min="0" max="365" placeholder="14"
              class="w-full border border-slate-200 rounded-xl px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-primaria" />
          </div>
          <div>
            <label class="text-sm font-medium text-slate-700 mb-1 block">
              Max. usuários
              <span class="text-[10px] text-slate-400 font-normal ml-1">0 = ilimitado</span>
            </label>
            <input v-model.number="form.max_usuarios" type="number" min="0" placeholder="20"
              class="w-full border border-slate-200 rounded-xl px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-primaria" />
          </div>
        </div>

        <!-- Imagem URL -->
        <div>
          <label class="text-sm font-medium text-slate-700 mb-1 block">URL da Imagem</label>
          <input v-model="form.imagem_url" type="url" placeholder="https://..."
            class="w-full border border-slate-200 rounded-xl px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-primaria" />
          <img v-if="form.imagem_url" :src="form.imagem_url"
            class="mt-2 h-20 w-full object-cover rounded-xl border border-slate-200"
            @error="form.imagem_url = ''" />
        </div>

        <!-- Recursos — catálogo de seleção -->
        <div>
          <label class="text-sm font-medium text-slate-700 mb-2 block">Recursos incluídos</label>

          <!-- Catálogo de opções pré-definidas -->
          <div class="rounded-xl border border-slate-200 p-3 mb-3">
            <p class="text-[11px] font-semibold uppercase tracking-wide text-slate-400 mb-2">Selecione do catálogo</p>
            <div class="flex flex-wrap gap-2">
              <button
                v-for="opcao in catalogoRecursos"
                :key="opcao"
                type="button"
                class="text-xs px-3 py-1.5 rounded-full border transition"
                :class="form.recursos.includes(opcao)
                  ? 'bg-primaria text-white border-primaria'
                  : 'bg-white text-slate-600 border-slate-200 hover:border-primaria hover:text-primaria'"
                @click="toggleRecurso(opcao)"
              >
                <span v-if="form.recursos.includes(opcao)" class="mr-1">✓</span>{{ opcao }}
              </button>
            </div>
          </div>

          <!-- Recursos customizados -->
          <p class="text-[11px] font-semibold uppercase tracking-wide text-slate-400 mb-2">Recursos customizados</p>
          <div v-for="(r, idx) in recursosCustomizados" :key="idx" class="flex gap-2 mb-2">
            <input
              :value="r"
              @input="atualizarCustom(idx, ($event.target as HTMLInputElement).value)"
              placeholder="Ex: Integração com Jira"
              class="flex-1 border border-slate-200 rounded-xl px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-primaria"
            />
            <button type="button" @click="removerCustom(idx)"
              class="text-perigo hover:opacity-70 px-2 text-lg leading-none">&times;</button>
          </div>
          <button type="button" @click="adicionarCustom"
            class="text-sm text-primaria hover:underline">+ Recurso personalizado</button>
        </div>

        <!-- Preview dos recursos selecionados -->
        <div v-if="form.recursos.length" class="rounded-xl bg-slate-50 border border-slate-100 p-3">
          <p class="text-[11px] font-semibold uppercase tracking-wide text-slate-400 mb-2">Preview ({{ form.recursos.length }} recursos)</p>
          <ul class="grid grid-cols-2 gap-1">
            <li v-for="r in form.recursos" :key="r" class="flex items-center gap-1.5 text-xs text-slate-600">
              <span class="text-green-500">✓</span> {{ r }}
            </li>
          </ul>
        </div>

        <!-- Gratuito -->
        <label class="flex items-center gap-3 cursor-pointer select-none">
          <div class="relative">
            <input type="checkbox" class="sr-only" v-model="form.gratuito" />
            <div class="w-10 h-6 rounded-full transition"
              :class="form.gratuito ? 'bg-green-500' : 'bg-slate-200'">
              <div class="absolute top-1 w-4 h-4 rounded-full bg-white shadow transition-transform"
                :class="form.gratuito ? 'translate-x-5' : 'translate-x-1'" />
            </div>
          </div>
          <div>
            <span class="text-sm font-medium text-slate-700">Plano gratuito</span>
            <p class="text-xs text-slate-400">Sem necessidade de método de pagamento para assinar</p>
          </div>
        </label>

        <!-- Ativo -->
        <label class="flex items-center gap-3 cursor-pointer select-none">
          <div class="relative">
            <input type="checkbox" class="sr-only" v-model="form.ativo" />
            <div class="w-10 h-6 rounded-full transition"
              :class="form.ativo ? 'bg-primaria' : 'bg-slate-200'">
              <div class="absolute top-1 w-4 h-4 rounded-full bg-white shadow transition-transform"
                :class="form.ativo ? 'translate-x-5' : 'translate-x-1'" />
            </div>
          </div>
          <span class="text-sm font-medium text-slate-700">Plano ativo (visível para usuários)</span>
        </label>

        <!-- Erro -->
        <p v-if="erro" class="text-sm text-perigo">{{ erro }}</p>
      </form>

      <!-- Footer fixo -->
      <div class="flex justify-end gap-3 px-6 py-4 border-t border-slate-100 shrink-0">
        <button type="button" @click="$emit('fechar')" class="botao-secundario">Cancelar</button>
        <button type="button" :disabled="salvando" class="botao-primario" @click="salvar">
          {{ salvando ? 'Salvando...' : (plano ? 'Salvar alterações' : 'Criar plano') }}
        </button>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import type { Plano, PlanoInput } from '~/servicos/servicoPlanos'

const props = defineProps<{ plano?: Plano | null }>()
const emit  = defineEmits<{ fechar: []; salvo: [plano: Plano] }>()

const loja     = useLojaPlanos()
const salvando = ref(false)
const erro     = ref('')

const catalogoRecursos = [
  'Até 3 projetos', 'Até 10 projetos', 'Projetos ilimitados',
  'Kanban e Backlog', 'Sprints', 'Métricas e relatórios', 'Relatórios avançados',
  'Suporte por email', 'Suporte prioritário', 'Suporte 24/7',
  'SLA dedicado', 'Onboarding personalizado',
  'API access', 'Notificações WhatsApp', 'Exportação de dados',
]

// recursos do catálogo que NÃO são customizados
function ehDoCatalogo(r: string) {
  return catalogoRecursos.includes(r)
}

const form = reactive<PlanoInput>({
  titulo:       props.plano?.titulo       ?? '',
  descricao:    props.plano?.descricao    ?? '',
  imagem_url:   props.plano?.imagem_url   ?? '',
  preco:        props.plano?.preco        ?? 0,
  recursos:     props.plano?.recursos     ? [...props.plano.recursos] : [],
  dias_trial:   props.plano?.dias_trial   ?? 14,
  max_usuarios: props.plano?.max_usuarios ?? 0,
  gratuito:     props.plano?.gratuito     ?? false,
  ativo:        props.plano?.ativo        ?? true,
})

// Lista editável de recursos customizados (não estão no catálogo)
const recursosCustomizados = ref<string[]>(
  (props.plano?.recursos ?? []).filter(r => !ehDoCatalogo(r))
)

function toggleRecurso(opcao: string) {
  if (form.recursos.includes(opcao)) {
    form.recursos = form.recursos.filter(r => r !== opcao)
  } else {
    form.recursos = [...form.recursos, opcao]
  }
}

function adicionarCustom() {
  recursosCustomizados.value.push('')
}

function atualizarCustom(idx: number, valor: string) {
  recursosCustomizados.value[idx] = valor
  sincronizarCustom()
}

function removerCustom(idx: number) {
  recursosCustomizados.value.splice(idx, 1)
  sincronizarCustom()
}

function sincronizarCustom() {
  const doCatalogo = form.recursos.filter(r => ehDoCatalogo(r))
  const custom = recursosCustomizados.value.filter(r => r.trim() !== '')
  form.recursos = [...doCatalogo, ...custom]
}

async function salvar() {
  erro.value = ''
  salvando.value = true
  sincronizarCustom()
  try {
    const payload: PlanoInput = {
      titulo:       form.titulo,
      descricao:    form.descricao  || null,
      imagem_url:   form.imagem_url || null,
      preco:        form.preco,
      recursos:     [...form.recursos],
      dias_trial:   form.dias_trial,
      max_usuarios: form.max_usuarios,
      gratuito:     form.gratuito,
      ativo:        form.ativo,
    }
    let resultado: Plano
    if (props.plano) {
      resultado = await loja.atualizar(props.plano.id, payload)
    } else {
      resultado = await loja.criar(payload)
    }
    emit('salvo', resultado)
    emit('fechar')
  } catch (e: any) {
    erro.value = e.message ?? 'Erro ao salvar plano.'
  } finally {
    salvando.value = false
  }
}
</script>
