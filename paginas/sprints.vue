```vue id="kl9d2p"
<template>
  <div>
    <div class="flex justify-between items-center mb-6 flex-wrap gap-3">
      <h1 class="text-3xl font-bold">
        🔄 Sprints
      </h1>

      <div class="flex gap-3 items-center">
        <select v-model="projetoId" class="px-3 py-2 border rounded-lg">
          <option value="">
            Selecione um projeto...
          </option>

          <option v-for="p in lojaProjetos.projetos" :key="p.id" :value="p.id">
            {{ p.nome }}
          </option>
        </select>

        <button v-if="projetoId" class="botao-primario" @click="abrirModalNovaSprint">
          + Nova sprint
        </button>
      </div>
    </div>

    <div v-if="!projetoId" class="text-slate-500">
      Escolha um projeto.
    </div>

    <div v-else class="grid gap-6 lg:grid-cols-[280px_1fr]">
      <aside class="space-y-2">
        <div v-if="!loja.sprints.length" class="text-sm text-slate-500 cartao">
          Nenhuma sprint criada.
        </div>

        <button v-for="s in loja.sprints" :key="s.id" @click="selecionarSprint(s.id)"
          :class="classeSprintSelecionada(s.id)">
          <div class="flex justify-between items-start">
            <h3 class="font-semibold">
              {{ s.nome }}
            </h3>

            <span :class="[
              'text-[10px] px-2 py-0.5 rounded uppercase font-semibold',
              corStatus(s.status)
            ]">
              {{ s.status }}
            </span>
          </div>

          <p class="text-xs text-slate-500 mt-1">
            {{ s.data_inicio }} → {{ s.data_fim }}
          </p>
        </button>
      </aside>

      <section v-if="loja.sprintAtual" class="space-y-4">
        <div class="cartao">
          <div class="flex justify-between items-start gap-4 flex-wrap">
            <div>
              <h2 class="text-2xl font-bold">
                {{ loja.sprintAtual.nome }}
              </h2>

              <p class="text-slate-500 text-sm mt-1">
                {{ loja.sprintAtual.objetivo || 'Sem objetivo definido.' }}
              </p>

              <p class="text-xs text-slate-400 mt-2">
                {{ loja.sprintAtual.data_inicio }}
                →
                {{ loja.sprintAtual.data_fim }}
              </p>
            </div>

            <select :value="loja.sprintAtual.status" @change="alterarStatusSprint"
              class="px-3 py-2 border rounded-lg text-sm">
              <option value="planejada">
                Planejada
              </option>

              <option value="ativa">
                Ativa
              </option>

              <option value="concluida">
                Concluída
              </option>
            </select>
          </div>

          <div class="mt-4">
            <div class="flex justify-between text-xs text-slate-500 mb-1">
              <span>Progresso</span>

              <span>
                {{ loja.progresso.ok }}/{{ loja.progresso.total }}
                ({{ loja.progresso.percent }}%)
              </span>
            </div>

            <div class="h-2 bg-slate-100 rounded-full overflow-hidden">
              <div class="h-full bg-sucesso transition-all" :style="{
                width: `${loja.progresso.percent}%`
              }" />
            </div>
          </div>
        </div>

        <div class="grid lg:grid-cols-2 gap-4">
          <GraficoBurndown :snapshots="loja.snapshots" @atualizar="atualizarSnapshot" />

          <div class="cartao">
            <h3 class="font-semibold mb-3">
              Tarefas da sprint
              ({{ loja.tarefasSprint.length }})
            </h3>

            <ul class="divide-y max-h-72 overflow-auto">
              <li v-for="t in loja.tarefasSprint" :key="t.id" class="py-2 flex justify-between items-center text-sm">
                <div>
                  <div class="font-medium">
                    {{ t.titulo }}
                  </div>

                  <div class="text-xs text-slate-400">
                    {{ t.coluna }} · {{ t.prioridade }}
                  </div>
                </div>

                <button class="text-xs text-perigo" @click="removerTarefaSprint(t.id)">
                  remover
                </button>
              </li>

              <li v-if="!loja.tarefasSprint.length" class="py-3 text-sm text-slate-400">
                Nenhuma tarefa associada.
              </li>
            </ul>
          </div>
        </div>

        <div class="cartao">
          <h3 class="font-semibold mb-3">
            📋 Backlog do projeto (associar à sprint)
          </h3>

          <ul class="divide-y">
            <li v-for="t in loja.backlog" :key="t.id" class="py-2 flex justify-between items-center text-sm">
              <div>
                <div class="font-medium">
                  {{ t.titulo }}
                </div>

                <div class="text-xs text-slate-400">
                  {{ t.prioridade }}
                </div>
              </div>

              <button class="botao-secundario text-xs px-3 py-1" @click="adicionarTarefaSprint(t.id)">
                + adicionar
              </button>
            </li>

            <li v-if="!loja.backlog.length" class="py-3 text-sm text-slate-400">
              Backlog vazio.
            </li>
          </ul>
        </div>
      </section>

      <section v-else class="text-slate-500 self-start">
        Selecione uma sprint à esquerda.
      </section>
    </div>

    <ModalSprint v-if="abrirNova" @fechar="fecharModalNovaSprint" @criada="sprintCriada" />
  </div>
</template>

<script lang="ts">
import { defineComponent } from 'vue'

export default defineComponent({
  name: 'PaginaSprints',

  data() {
    const route = useRoute()

    return {
      lojaProjetos: useLojaProjetos(),
      loja: useLojaSprints(),
      projetoId: String(route.query.projeto ?? ''),
      abrirNova: false
    }
  },

  async mounted() {
    if (!this.lojaProjetos.projetos.length) {
      await this.lojaProjetos.carregar()
    }
  },

  watch: {
    projetoId: {
      immediate: true,
      async handler(id: string) {
        if (id) {
          await this.loja.carregarPorProjeto(id)
        }
      }
    }
  },

  methods: {
    abrirModalNovaSprint() {
      this.abrirNova = true
    },

    fecharModalNovaSprint() {
      this.abrirNova = false
    },

    async sprintCriada() {
      this.fecharModalNovaSprint()

      if (this.projetoId) {
        await this.loja.carregarPorProjeto(this.projetoId)
      }
    },

    selecionarSprint(id: string) {
      this.loja.selecionar(id)
    },

    classeSprintSelecionada(id: string) {
      return [
        'w-full text-left cartao hover:shadow-md transition',
        this.loja.sprintAtual?.id === id
          ? 'ring-2 ring-primaria'
          : ''
      ]
    },

    async alterarStatusSprint(evento: Event) {
      const valor = (evento.target as HTMLSelectElement).value

      await this.loja.atualizar(
        this.loja.sprintAtual.id,
        { status: valor }
      )
    },

    async atualizarSnapshot() {
      await this.loja.atualizarSnapshot()
    },

    async removerTarefaSprint(id: string) {
      await this.loja.associar(id, null)
    },

    async adicionarTarefaSprint(id: string) {
      await this.loja.associar(
        id,
        this.loja.sprintAtual.id
      )
    },

    corStatus(status: string) {
      return {
        planejada: 'bg-slate-100 text-slate-600',
        ativa: 'bg-blue-100 text-blue-700',
        concluida: 'bg-green-100 text-green-700'
      }[status] || 'bg-slate-100'
    }
  }
})
</script>
```
