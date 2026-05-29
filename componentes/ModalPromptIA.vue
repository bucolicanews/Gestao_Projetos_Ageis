<template>
  <div
    class="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4"
    @click.self="$emit('fechar')"
  >
    <div class="bg-white rounded-xl shadow-xl w-full max-w-2xl max-h-[90vh] flex flex-col">

      <!-- Cabeçalho -->
      <div class="flex justify-between items-center p-5 border-b">
        <div>
          <h2 class="text-lg font-bold">🤖 Gerar projeto com IA</h2>
          <p class="text-sm text-slate-500 mt-0.5">Use Claude, ChatGPT ou Gemini para criar um projeto completo</p>
        </div>
        <button class="text-slate-400 hover:text-slate-700 text-xl leading-none" @click="$emit('fechar')">✕</button>
      </div>

      <!-- Corpo scrollável -->
      <div class="overflow-y-auto p-5 space-y-5 flex-1">

        <!-- Como usar -->
        <div class="bg-blue-50 rounded-lg p-4 text-sm text-blue-800 space-y-1">
          <p class="font-semibold mb-2">Como usar:</p>
          <p>1. Clique em <strong>Copiar prompt</strong> abaixo</p>
          <p>2. Abra o Claude, ChatGPT ou Gemini</p>
          <p>3. Cole o prompt e substitua a descrição do projeto</p>
          <p>4. Copie o JSON gerado e salve como arquivo <code class="bg-blue-100 px-1 rounded">.json</code></p>
          <p>5. Volte aqui e clique em <strong>↑ Importar JSON</strong></p>
        </div>

        <!-- Descrição do projeto -->
        <div>
          <label class="text-sm font-semibold text-slate-700 block mb-1">
            Descreva seu projeto:
          </label>
          <textarea
            v-model="descricaoCustom"
            rows="4"
            placeholder="Ex: Sistema de e-commerce com catálogo de produtos, carrinho, checkout com PIX e cartão, painel admin para pedidos. Stack: Vue 3 + Node.js + PostgreSQL."
            class="w-full text-sm border rounded-lg p-3 resize-none focus:outline-none focus:ring-2 focus:ring-primaria placeholder:text-slate-300"
          />
          <p class="text-xs text-slate-400 mt-1">
            Sua descrição substitui automaticamente o campo no prompt abaixo.
          </p>
        </div>

        <!-- Exemplos de descrição -->
        <div>
          <p class="text-sm font-semibold text-slate-700 mb-2">Ou use um exemplo:</p>
          <div class="space-y-2">
            <div
              v-for="ex in exemplos"
              :key="ex.titulo"
              class="border rounded-lg p-3 text-sm cursor-pointer hover:border-primaria hover:bg-slate-50 transition"
              @click="usarExemplo(ex.descricao)"
            >
              <p class="font-medium text-slate-700">{{ ex.titulo }}</p>
              <p class="text-slate-500 mt-0.5 text-xs">{{ ex.descricao }}</p>
            </div>
          </div>
          <p class="text-xs text-slate-400 mt-1">Clique para usar como descrição</p>
        </div>

        <!-- Prompt -->
        <div>
          <div class="flex justify-between items-center mb-2">
            <p class="text-sm font-semibold text-slate-700">Prompt completo:</p>
            <button
              class="botao-primario text-xs py-1 px-3"
              @click="copiarPrompt"
            >
              {{ copiado ? '✅ Copiado!' : '📋 Copiar prompt' }}
            </button>
          </div>
          <textarea
            ref="textareaRef"
            :value="promptAtual"
            readonly
            rows="14"
            class="w-full text-xs font-mono bg-slate-50 border rounded-lg p-3 resize-none focus:outline-none focus:ring-1 focus:ring-primaria"
          />
        </div>

      </div>

      <!-- Rodapé -->
      <div class="p-4 border-t flex justify-end gap-2">
        <button class="botao-secundario text-sm" @click="$emit('fechar')">Fechar</button>
        <button class="botao-primario text-sm" @click="copiarPrompt">
          {{ copiado ? '✅ Copiado!' : '📋 Copiar prompt' }}
        </button>
      </div>

    </div>
  </div>
</template>

<script lang="ts">
import { defineComponent, ref, computed } from 'vue'

const PROMPT_BASE = `Você é um especialista em gestão ágil de projetos de software.

Gere um projeto completo no formato JSON abaixo para o seguinte sistema:

[DESCREVA SEU PROJETO AQUI]

---

REGRAS OBRIGATÓRIAS:

1. Crie de 3 a 5 sprints de 2 semanas cada, com datas reais a partir de hoje
2. Distribua as tarefas entre as sprints de forma lógica (fundação primeiro, features depois)
3. Cada sprint deve ter entre 4 e 8 tarefas principais
4. Tarefas técnicas devem ter sub-tarefas detalhadas (2 a 4 por tarefa)
5. Todas as tarefas iniciam com coluna "backlog" ou "a_fazer"
6. Use ref_ids sequenciais: sprint_1, sprint_2... / tarefa_1, tarefa_2... / sub_1, sub_2...
7. Varie as prioridades de forma realista (urgente para bloqueadores, baixa para melhorias)
8. Adicione 2 a 4 anotações com decisões técnicas ou contexto importante
9. Deixe os campos de email em branco ("") — serão preenchidos após importação
10. Responda APENAS com o JSON válido, sem texto antes ou depois

---

VALORES VÁLIDOS:
status do projeto:  ativo | pausado | concluido | arquivado
status da sprint:   planejada | ativa | concluida
coluna da tarefa:   backlog | a_fazer | em_progresso | em_revisao | concluido
prioridade:         baixa | media | alta | urgente

---

ESTRUTURA JSON:

{
  "_meta": { "versao": "1.0", "exportado_em": "<ISO 8601>", "sistema": "GESTAO_PROJTOS_VUE" },
  "projeto": { "nome": "", "descricao": "", "status": "ativo", "membros": [] },
  "anotacoes": [{ "ref_id": "nota_1", "titulo": "", "conteudo": "", "criado_em": "<ISO 8601>" }],
  "sprints": [{
    "ref_id": "sprint_1", "nome": "", "objetivo": "",
    "status": "planejada", "data_inicio": "YYYY-MM-DD", "data_fim": "YYYY-MM-DD", "membros": []
  }],
  "tarefas": [{
    "ref_id": "tarefa_1", "titulo": "", "descricao": "",
    "prioridade": "alta", "coluna": "backlog", "posicao": 1, "pontos": 5,
    "prazo": null, "sprint_ref": "sprint_1", "tarefa_pai_ref": null, "responsavel_email": "",
    "comentarios": [],
    "sub_tarefas": [{
      "ref_id": "sub_1", "titulo": "", "descricao": "",
      "prioridade": "media", "coluna": "a_fazer", "posicao": 1, "pontos": 2,
      "prazo": null, "sprint_ref": "sprint_1", "responsavel_email": ""
    }]
  }]
}`

export default defineComponent({
  name: 'ModalPromptIA',

  emits: ['fechar'],

  setup() {
    const copiado    = ref(false)
    const textareaRef = ref<HTMLTextAreaElement | null>(null)
    const descricaoCustom = ref('')

    const exemplos = [
      {
        titulo: 'App de delivery',
        descricao: 'Aplicativo de delivery de comida com cadastro de restaurantes, cardápio com fotos, pedido com rastreamento em tempo real, pagamento PIX/cartão e avaliação de entregadores. Stack: React Native + Supabase.',
      },
      {
        titulo: 'Plataforma SaaS de RH',
        descricao: 'Plataforma de gestão de RH com módulo de ponto eletrônico, folha de pagamento, avaliação de desempenho e portal do colaborador. Stack: Next.js + NestJS + PostgreSQL.',
      },
      {
        titulo: 'Sistema de estoque',
        descricao: 'Sistema de controle de estoque para rede de farmácias com entrada/saída de produtos, alertas de validade, integração com fornecedores e relatórios de margem. Stack: Vue + Laravel.',
      },
    ]

    const promptAtual = computed(() => {
      if (!descricaoCustom.value) return PROMPT_BASE
      return PROMPT_BASE.replace('[DESCREVA SEU PROJETO AQUI]', descricaoCustom.value)
    })

    function usarExemplo(descricao: string) {
      descricaoCustom.value = descricao
    }

    async function copiarPrompt() {
      try {
        await navigator.clipboard.writeText(promptAtual.value)
        copiado.value = true
        setTimeout(() => { copiado.value = false }, 2500)
      } catch {
        textareaRef.value?.select()
        document.execCommand('copy')
        copiado.value = true
        setTimeout(() => { copiado.value = false }, 2500)
      }
    }

    return { copiado, textareaRef, exemplos, promptAtual, usarExemplo, copiarPrompt }
  },
})
</script>
