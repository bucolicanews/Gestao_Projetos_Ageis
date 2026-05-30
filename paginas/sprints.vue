<template>
  <div>
    <div class="flex flex-col gap-3 mb-6">
      <div class="flex items-center justify-between gap-3">
        <h1 class="text-3xl font-bold">🔄 Sprints</h1>
        <button v-if="projetoId" class="botao-primario" @click="abrirModalNovaSprint">
          + Nova sprint
        </button>
      </div>
      <select v-model="projetoId" class="px-3 py-2 border rounded-lg text-sm mx-2 max-w-full">
        <option value="">Selecione um projeto...</option>
        <option v-for="p in lojaProjetos.projetos" :key="p.id" :value="p.id">
          {{ p.nome }}
        </option>
      </select>
    </div>

    <div v-if="!projetoId" class="text-slate-500">Escolha um projeto.</div>

    <div v-else class="grid gap-6 lg:grid-cols-[300px_1fr] min-w-0">
      <!-- Sidebar: lista de sprints -->
      <aside :class="['space-y-2 min-w-0', visaoMobile === 'detalhe' ? 'hidden lg:block' : 'block']">
        <div v-if="!loja.sprints.length" class="text-sm text-slate-500 cartao">
          Nenhuma sprint criada.
        </div>

        <div
          v-for="s in loja.sprints"
          :key="s.id"
          :class="[
            'cartao hover:shadow-md transition cursor-pointer',
            loja.sprintAtual?.id === s.id ? 'ring-2 ring-primaria' : ''
          ]"
          @click="selecionarSprint(s.id)"
        >
          <div class="flex justify-between items-start gap-2">
            <div class="flex-1 min-w-0">
              <h3 class="font-semibold truncate">{{ s.nome }}</h3>
              <p class="text-xs text-slate-400 mt-0.5">
                {{ formatarData(s.data_inicio) }} → {{ formatarData(s.data_fim) }}
              </p>
            </div>

            <span :class="['text-[10px] px-2 py-0.5 rounded uppercase font-semibold shrink-0', corStatus(s.status)]">
              {{ s.status }}
            </span>
          </div>

          <!-- Botões editar/excluir -->
          <div class="flex gap-2 mt-2 pt-2 border-t border-slate-100">
            <button
              class="text-xs text-slate-400 hover:text-primaria px-2 py-0.5 rounded hover:bg-slate-50"
              @click.stop="abrirEdicao(s)"
            >
              ✏️ Editar
            </button>
            <button
              class="text-xs text-slate-400 hover:text-perigo px-2 py-0.5 rounded hover:bg-red-50"
              @click.stop="confirmarExclusao(s)"
            >
              🗑 Excluir
            </button>
          </div>
        </div>
      </aside>

      <!-- Detalhe da sprint -->
      <section v-if="loja.sprintAtual" :class="['space-y-4 min-w-0 overflow-x-hidden', visaoMobile === 'lista' ? 'hidden lg:block' : 'block']">
        <!-- Botão voltar (mobile only) -->
        <button class="lg:hidden flex items-center gap-1 text-sm text-primaria font-medium py-1" @click="visaoMobile = 'lista'">
          ← Voltar às sprints
        </button>
        <!-- Header sprint -->
        <div class="cartao">
          <div class="flex justify-between items-start gap-4 flex-wrap">
            <div>
              <h2 class="text-2xl font-bold">{{ loja.sprintAtual.nome }}</h2>
              <p class="text-slate-500 text-sm mt-1">{{ loja.sprintAtual.objetivo || 'Sem objetivo definido.' }}</p>
              <p class="text-xs text-slate-400 mt-2">
                {{ formatarData(loja.sprintAtual.data_inicio) }} → {{ formatarData(loja.sprintAtual.data_fim) }}
              </p>
            </div>

            <select
              :value="loja.sprintAtual.status"
              class="px-3 py-2 border rounded-lg text-sm"
              @change="alterarStatusSprint"
            >
              <option value="planejada">Planejada</option>
              <option value="ativa">Ativa</option>
              <option value="concluida">Concluída</option>
            </select>
          </div>

          <!-- Progresso -->
          <div class="mt-4">
            <div class="flex justify-between text-xs text-slate-500 mb-1">
              <span>Progresso</span>
              <span>{{ loja.progresso.ok }}/{{ loja.progresso.total }} ({{ loja.progresso.percent }}%)</span>
            </div>
            <div class="h-2 bg-slate-100 rounded-full overflow-hidden">
              <div class="h-full bg-sucesso transition-all" :style="{ width: `${loja.progresso.percent}%` }" />
            </div>
          </div>
        </div>

        <!-- Abas -->
        <div class="flex border-b gap-0 overflow-x-auto">
          <button
            v-for="tab in abas"
            :key="tab.id"
            :class="[
              'px-5 py-2.5 text-sm font-medium border-b-2 -mb-px transition',
              aba === tab.id ? 'border-primaria text-primaria' : 'border-transparent text-slate-500 hover:text-slate-700'
            ]"
            @click="aba = tab.id"
          >
            {{ tab.label }}
          </button>
        </div>

        <!-- ABA: Planejamento -->
        <div v-if="aba === 'planejamento'" class="space-y-4">
          <!-- KPIs Sprint Engine -->
          <div class="grid grid-cols-2 sm:grid-cols-4 gap-3">
            <div class="cartao text-center py-3">
              <div class="text-2xl font-bold text-primaria">{{ loja.pontosAlocados }}</div>
              <div class="text-[10px] text-slate-400 uppercase font-semibold tracking-wider mt-0.5">SP planejados</div>
            </div>
            <div class="cartao text-center py-3">
              <div class="text-2xl font-bold text-sucesso">{{ loja.pontosConcluidos }}</div>
              <div class="text-[10px] text-slate-400 uppercase font-semibold tracking-wider mt-0.5">SP concluídos</div>
            </div>
            <div class="cartao text-center py-3">
              <div class="text-2xl font-bold text-amber-500">
                {{ loja.sprintAtual?.capacidade_horas || loja.capacidadeCalculada || '—' }}h
              </div>
              <div class="text-[10px] text-slate-400 uppercase font-semibold tracking-wider mt-0.5">Capacidade</div>
            </div>
            <div class="cartao text-center py-3">
              <div
                class="text-2xl font-bold"
                :class="dorPercent >= 80 ? 'text-sucesso' : dorPercent >= 50 ? 'text-alerta' : 'text-perigo'"
              >
                {{ dorPercent }}%
              </div>
              <div class="text-[10px] text-slate-400 uppercase font-semibold tracking-wider mt-0.5">DoR pronto</div>
            </div>
          </div>

          <!-- Velocity média histórica -->
          <div v-if="loja.velocityMedia > 0" class="cartao flex items-center gap-4 py-3">
            <span class="text-slate-500 text-sm">Velocity média (histórico):</span>
            <span class="font-bold text-lg text-primaria">{{ loja.velocityMedia }} SP/sprint</span>
            <span v-if="loja.pontosAlocados > loja.velocityMedia" class="text-xs text-perigo font-medium">
              ⚠️ Overcommit: {{ loja.pontosAlocados - loja.velocityMedia }} pts acima da média
            </span>
            <span v-else-if="loja.pontosAlocados > 0" class="text-xs text-sucesso font-medium">
              ✓ Dentro da capacidade histórica
            </span>
          </div>

          <!-- Tarefas da sprint + criação inline -->
          <div class="cartao">
            <div class="flex justify-between items-center mb-3">
              <h3 class="font-semibold">✅ Tarefas desta sprint ({{ loja.tarefasSprint.length }})</h3>
              <button
                class="botao-primario text-xs px-3 py-1"
                @click="abrirModalNovaTarefa"
              >
                + Nova tarefa
              </button>
            </div>

            <ul class="divide-y max-h-96 overflow-auto">
              <li
                v-for="t in loja.tarefasSprint"
                :key="t.id"
                class="py-2.5 flex justify-between items-center text-sm"
              >
                <div class="min-w-0 flex-1">
                  <div class="font-medium truncate">{{ t.titulo }}</div>
                  <div class="text-xs text-slate-400 flex gap-2 mt-0.5">
                    <span :class="['px-1.5 py-0.5 rounded text-[10px] uppercase font-semibold', corColuna(t.coluna)]">
                      {{ t.coluna.replace('_', ' ') }}
                    </span>
                    <span>{{ t.prioridade }}</span>
                    <span v-if="t.pontos">· {{ t.pontos }} pts</span>
                    <span v-if="t.responsavel">· {{ t.responsavel?.nome }}</span>
                  </div>
                </div>
                <div class="flex gap-1 shrink-0 ml-3">
                  <button
                    class="text-xs text-slate-400 hover:text-slate-600 px-2 py-0.5 rounded hover:bg-slate-50"
                    title="Devolver ao backlog (não exclui)"
                    @click="removerTarefaSprint(t.id)"
                  >
                    ↓ Backlog
                  </button>
                  <button
                    class="text-xs text-perigo hover:text-red-700 px-2 py-0.5 rounded hover:bg-red-50"
                    title="Excluir permanentemente"
                    @click="excluirTarefaPermanente(t.id)"
                  >
                    🗑
                  </button>
                </div>
              </li>

              <li v-if="!loja.tarefasSprint.length" class="py-6 text-sm text-slate-400 text-center">
                Nenhuma tarefa nesta sprint ainda.<br>
                <button class="text-primaria hover:underline mt-1 text-xs" @click="abrirModalNovaTarefa">
                  Clique aqui para criar a primeira
                </button>
              </li>
            </ul>
          </div>

          <!-- Backlog para puxar tarefas já existentes -->
          <div v-if="loja.backlog.length > 0" class="cartao">
            <div class="flex justify-between items-center mb-3">
              <h3 class="font-semibold">📋 Puxar do backlog</h3>
              <span class="text-xs text-slate-400">{{ loja.backlog.length }} tarefa(s) · {{ loja.pontosBacklog }} pts</span>
            </div>
            <ul class="divide-y max-h-80 overflow-auto">
              <li
                v-for="t in loja.backlog"
                :key="t.id"
                class="py-2.5 flex justify-between items-center text-sm gap-3"
              >
                <div class="min-w-0 flex-1">
                  <div class="font-medium truncate">{{ t.titulo }}</div>
                  <div class="flex flex-wrap items-center gap-1.5 mt-1">
                    <!-- coluna/status atual -->
                    <span :class="['text-[9px] px-1.5 py-0.5 rounded uppercase font-semibold', corColuna(t.coluna)]">
                      {{ t.coluna?.replace(/_/g, ' ') || 'backlog' }}
                    </span>
                    <!-- prioridade -->
                    <span :class="['text-[9px] px-1.5 py-0.5 rounded uppercase font-semibold', corPrioridade(t.prioridade)]">
                      {{ t.prioridade }}
                    </span>
                    <!-- story points -->
                    <span v-if="t.pontos" class="text-[9px] px-1.5 py-0.5 rounded bg-primaria/10 text-primaria font-bold">
                      {{ t.pontos }} SP
                    </span>
                    <!-- sprint relacionada -->
                    <span v-if="t.sprint?.nome" class="text-[9px] px-1.5 py-0.5 rounded bg-indigo-100 text-indigo-600 font-medium truncate max-w-[100px]" :title="t.sprint.nome">
                      🏃 {{ t.sprint.nome }}
                    </span>
                    <!-- DoR -->
                    <span v-if="t.dor_ok" class="text-[9px] px-1 py-0.5 rounded bg-green-100 text-green-700 font-bold">DoR ✓</span>
                    <span v-else class="text-[9px] px-1 py-0.5 rounded bg-slate-100 text-slate-400">DoR ✗</span>
                  </div>
                </div>
                <button
                  class="botao-secundario text-xs px-3 py-1 shrink-0"
                  :disabled="!t.dor_ok && loja.sprintAtual?.status === 'ativa'"
                  :title="!t.dor_ok && loja.sprintAtual?.status === 'ativa' ? 'Tarefa não passou pelo DoR' : ''"
                  @click="adicionarTarefaSprint(t.id)"
                >
                  + puxar
                </button>
              </li>
            </ul>
          </div>
        </div>

        <!-- ABA: BACKLOG -->
        <div v-else-if="aba === 'backlog'" class="space-y-4">

          <!-- Sprint Backlog: TODAS as tarefas já associadas a esta sprint -->
          <div class="cartao border-l-4 border-primaria">
            <div class="flex justify-between items-center mb-2">
              <h3 class="font-semibold text-sm">
                🏃 Sprint Backlog
                <span class="text-slate-400 font-normal ml-1">({{ sprintBacklogNaoIniciado.length }})</span>
              </h3>
              <span class="text-xs text-slate-400">Tarefas desta sprint</span>
            </div>

            <div v-if="!sprintBacklogNaoIniciado.length" class="py-6 text-center text-sm text-slate-400">
              Nenhuma tarefa associada a esta sprint ainda.
            </div>

            <ul v-else class="divide-y">
              <li
                v-for="t in sprintBacklogNaoIniciado"
                :key="t.id"
                class="py-2 flex items-center gap-3 text-sm"
              >
                <div class="w-1.5 h-1.5 rounded-full bg-primaria shrink-0" />
                <div class="flex-1 min-w-0">
                  <span class="font-medium truncate">{{ t.titulo }}</span>
                  <div class="flex flex-wrap gap-1.5 mt-1">
                    <span :class="['text-[9px] px-1.5 py-0.5 rounded uppercase font-semibold', corColuna(t.coluna)]">
                      {{ t.coluna?.replace(/_/g, ' ') || 'backlog' }}
                    </span>
                    <span v-if="t.pontos" class="text-[9px] px-1.5 py-0.5 rounded bg-primaria/10 text-primaria font-bold">{{ t.pontos }} SP</span>
                    <span :class="['text-[9px] px-1.5 py-0.5 rounded uppercase font-semibold', corPrioridade(t.prioridade)]">{{ t.prioridade }}</span>
                    <span v-if="t.dor_ok" class="text-[9px] px-1 py-0.5 rounded bg-green-100 text-green-700 font-bold">DoR ✓</span>
                    <span v-else class="text-[9px] px-1 py-0.5 rounded bg-amber-50 text-amber-600">DoR ✗</span>
                    <span v-if="t.responsavel?.nome" class="text-[9px] text-slate-400">👤 {{ t.responsavel.nome }}</span>
                  </div>
                </div>
                <button
                  class="text-xs text-slate-400 hover:text-primaria px-2 py-1 rounded hover:bg-slate-100 shrink-0"
                  @click="abrirEdicaoTarefa(t)"
                >✏️</button>
                <button
                  class="text-xs text-slate-400 hover:text-perigo px-2 py-1 rounded hover:bg-red-50 shrink-0"
                  title="Remover da sprint"
                  @click="removerTarefaSprint(t.id)"
                >↓</button>
              </li>
            </ul>
          </div>

          <!-- Divisor -->
          <div class="flex items-center gap-3 text-xs text-slate-400">
            <div class="flex-1 border-t" />
            <span>📋 Product Backlog — disponível para puxar</span>
            <div class="flex-1 border-t" />
          </div>

          <!-- Barra de busca + filtros -->
          <div class="cartao space-y-3">
            <input
              v-model="backlogBusca"
              type="text"
              placeholder="🔍 Buscar por título ou descrição..."
              class="w-full px-3 py-2 border rounded-lg text-sm focus:outline-none focus:border-primaria"
            />
            <div class="flex flex-wrap gap-2">
              <!-- Filtro tipo -->
              <select v-model="backlogFiltroTipo" class="px-2 py-1 border rounded text-xs">
                <option value="">Todos os tipos</option>
                <option value="feature">✨ Feature</option>
                <option value="bug">🐛 Bug</option>
                <option value="melhoria">⚡ Melhoria</option>
                <option value="techdeb">🔧 Tech Debt</option>
                <option value="spike">🔬 Spike</option>
              </select>
              <!-- Filtro prioridade -->
              <select v-model="backlogFiltroPrioridade" class="px-2 py-1 border rounded text-xs">
                <option value="">Todas as prioridades</option>
                <option value="urgente">Urgente</option>
                <option value="alta">Alta</option>
                <option value="media">Média</option>
                <option value="baixa">Baixa</option>
              </select>
              <!-- Filtro DoR -->
              <select v-model="backlogFiltroDor" class="px-2 py-1 border rounded text-xs">
                <option value="">Todos (DoR)</option>
                <option value="pronto">✅ DoR pronto</option>
                <option value="pendente">⏳ DoR pendente</option>
              </select>
              <!-- Limpar -->
              <button
                v-if="backlogBusca || backlogFiltroTipo || backlogFiltroPrioridade || backlogFiltroDor"
                class="text-xs text-slate-400 hover:text-perigo px-2"
                @click="backlogBusca = ''; backlogFiltroTipo = ''; backlogFiltroPrioridade = ''; backlogFiltroDor = ''"
              >
                ✕ Limpar filtros
              </button>
            </div>
          </div>

          <!-- Contadores + refresh -->
          <div class="flex flex-wrap items-center gap-4 text-sm px-1">
            <span class="text-slate-500">
              <strong class="text-slate-700">{{ backlogFiltrado.length }}</strong>
              <span v-if="backlogFiltrado.length !== loja.backlog.length"> de {{ loja.backlog.length }}</span>
              tarefa(s)
            </span>
            <span class="text-slate-500">
              <strong class="text-primaria">{{ backlogSpTotal }}</strong> SP
            </span>
            <span class="text-slate-500">
              <strong :class="backlogDorOkCount === backlogFiltrado.length && backlogFiltrado.length > 0 ? 'text-sucesso' : 'text-alerta'">
                {{ backlogDorOkCount }}/{{ backlogFiltrado.length }}
              </strong> DoR ✓
            </span>
            <button
              class="ml-auto text-xs text-slate-400 hover:text-primaria flex items-center gap-1"
              :disabled="loja.carregando"
              @click="recarregarBacklog"
            >
              🔄 {{ loja.carregando ? 'Carregando...' : 'Atualizar' }}
            </button>
          </div>

          <!-- Lista backlog -->
          <div class="cartao p-0 overflow-hidden">
            <div v-if="!loja.backlog.length" class="py-12 text-center text-sm text-slate-400">
              <p>Nenhuma tarefa no backlog do projeto.</p>
              <p class="text-xs mt-1">Tarefas já nesta sprint não aparecem aqui. Subtarefas também não.</p>
              <button class="text-primaria hover:underline text-xs mt-2" @click="recarregarBacklog">🔄 Recarregar</button>
            </div>
            <div v-else-if="!backlogFiltrado.length" class="py-12 text-center text-sm text-slate-400">
              Nenhuma tarefa passou pelos filtros.
              <button class="text-primaria hover:underline text-xs ml-1" @click="backlogBusca = ''; backlogFiltroTipo = ''; backlogFiltroPrioridade = ''; backlogFiltroDor = ''">Limpar filtros</button>
            </div>

            <ul v-else class="divide-y">
              <li
                v-for="t in backlogFiltrado"
                :key="t.id"
                class="px-4 py-3 flex items-start gap-3 hover:bg-slate-50 transition-colors"
              >
                <!-- Indicador DoR -->
                <div
                  :class="[
                    'w-1.5 h-full min-h-[40px] rounded-full shrink-0 mt-0.5',
                    t.dor_ok ? 'bg-sucesso' : 'bg-slate-200'
                  ]"
                />

                <!-- Conteúdo -->
                <div class="flex-1 min-w-0">
                  <div class="flex items-start gap-2 flex-wrap">
                    <span class="font-medium text-sm text-slate-800 truncate">{{ t.titulo }}</span>
                    <span v-if="t.sprint?.nome" class="text-[9px] px-1.5 py-0.5 rounded bg-indigo-100 text-indigo-600 font-semibold shrink-0" :title="t.sprint.nome">
                      🏃 {{ t.sprint.nome }}
                    </span>
                  </div>

                  <div class="flex flex-wrap items-center gap-1.5 mt-1.5">
                    <!-- Tipo -->
                    <span class="text-[9px] px-1.5 py-0.5 rounded bg-slate-100 text-slate-500 font-medium">
                      {{ { feature: '✨', bug: '🐛', melhoria: '⚡', techdeb: '🔧', spike: '🔬' }[t.tipo_tarefa] || '' }}
                      {{ t.tipo_tarefa || 'feature' }}
                    </span>
                    <!-- Prioridade -->
                    <span :class="['text-[9px] px-1.5 py-0.5 rounded uppercase font-semibold', corPrioridade(t.prioridade)]">
                      {{ t.prioridade }}
                    </span>
                    <!-- Coluna -->
                    <span :class="['text-[9px] px-1.5 py-0.5 rounded uppercase font-semibold', corColuna(t.coluna)]">
                      {{ t.coluna?.replace(/_/g, ' ') || 'backlog' }}
                    </span>
                    <!-- SP -->
                    <span v-if="t.pontos" class="text-[9px] px-1.5 py-0.5 rounded bg-primaria/10 text-primaria font-bold">
                      {{ t.pontos }} SP
                    </span>
                    <!-- Responsável -->
                    <span v-if="t.responsavel?.nome" class="text-[9px] text-slate-400">
                      👤 {{ t.responsavel.nome }}
                    </span>
                    <!-- DoR badge -->
                    <span v-if="t.dor_ok" class="text-[9px] px-1 py-0.5 rounded bg-green-100 text-green-700 font-bold">DoR ✓</span>
                    <span v-else class="text-[9px] px-1 py-0.5 rounded bg-amber-50 text-amber-600 font-medium">DoR ✗</span>
                  </div>

                  <p v-if="t.criterio_aceite" class="text-xs text-slate-400 mt-1 truncate" :title="t.criterio_aceite">
                    📝 {{ t.criterio_aceite }}
                  </p>
                </div>

                <!-- Ações -->
                <div class="flex gap-1 shrink-0">
                  <button
                    class="text-xs text-slate-400 hover:text-primaria px-2 py-1 rounded hover:bg-slate-100"
                    title="Editar"
                    @click="abrirEdicaoTarefa(t)"
                  >
                    ✏️
                  </button>
                  <button
                    class="botao-secundario text-xs px-3 py-1"
                    :disabled="!t.dor_ok && loja.sprintAtual?.status === 'ativa'"
                    :title="!t.dor_ok && loja.sprintAtual?.status === 'ativa' ? 'Tarefa não passou pelo DoR' : 'Adicionar à sprint'"
                    @click="adicionarTarefaSprint(t.id)"
                  >
                    + sprint
                  </button>
                </div>
              </li>
            </ul>
          </div>
        </div>

        <!-- ABA: Execução -->
        <div v-else-if="aba === 'execucao'" class="space-y-4">
          <GraficoBurndown :snapshots="loja.snapshots" @atualizar="atualizarSnapshot" />

          <div class="cartao">
            <h3 class="font-semibold mb-3">Tarefas ({{ loja.tarefasSprint.length }})</h3>
            <ul class="divide-y max-h-96 overflow-auto">
              <li
                v-for="t in loja.tarefasSprint"
                :key="t.id"
                class="py-2.5 flex justify-between items-center text-sm"
              >
                <div>
                  <div class="font-medium">{{ t.titulo }}</div>
                  <div class="text-xs text-slate-400">
                    {{ t.prioridade }}
                    <span v-if="t.responsavel"> · {{ t.responsavel?.nome }}</span>
                  </div>
                </div>
                <span :class="['text-[10px] px-2 py-0.5 rounded uppercase font-semibold', corColuna(t.coluna)]">
                  {{ t.coluna.replace('_', ' ') }}
                </span>
              </li>
              <li v-if="!loja.tarefasSprint.length" class="py-3 text-sm text-slate-400">Nenhuma tarefa.</li>
            </ul>
          </div>
        </div>

        <!-- ABA: Métricas -->
        <div v-else-if="aba === 'metricas'" class="space-y-4">
          <GraficoVelocity
            :historico="loja.velocityHistorico"
            :media="loja.velocityMedia"
          />

          <GraficoThroughput
            :dados="loja.throughput.dados"
            :total="loja.throughput.total"
            :media="loja.throughput.media"
          />

          <div class="cartao">
            <h3 class="font-semibold mb-4">Distribuição por coluna</h3>
            <div v-if="loja.tarefasSprint.length" class="space-y-3">
              <div v-for="item in loja.distribuicao" :key="item.coluna" class="flex items-center gap-3 text-sm">
                <span class="w-28 text-slate-600 shrink-0">{{ item.label }}</span>
                <div class="flex-1 h-5 bg-slate-100 rounded overflow-hidden">
                  <div
                    class="h-full rounded transition-all"
                    :style="{
                      width: loja.tarefasSprint.length ? `${(item.total / loja.tarefasSprint.length) * 100}%` : '0%',
                      background: item.cor
                    }"
                  />
                </div>
                <span class="w-8 text-right font-semibold text-slate-700">{{ item.total }}</span>
              </div>
            </div>
            <div v-else class="text-sm text-slate-400 py-4 text-center">Sem tarefas na sprint.</div>
          </div>
        </div>
      </section>

      <section v-else class="text-slate-500 self-start cartao min-w-0">
        Selecione uma sprint à esquerda para ver os detalhes.
      </section>
    </div>

    <!-- Modal nova/editar sprint -->
    <ModalSprint
      v-if="abrirModal"
      :sprint="sprintEditando"
      @fechar="fecharModal"
      @criada="sprintCriada"
      @atualizada="fecharModal"
    />

    <!-- Modal tarefa completo -->
    <ModalTarefa
      :exibir="exibirModalTarefa"
      :tarefa="tarefaParaModal"
      :membros="membrosDoProj"
      @fechar="exibirModalTarefa = false"
      @salvo="tarefaCriada"
    />

    <!-- Confirmação excluir -->
    <div v-if="sprintParaExcluir" class="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
      <div class="cartao w-full max-w-sm">
        <h3 class="font-bold text-lg mb-2">Excluir sprint</h3>
        <p class="text-slate-500 text-sm mb-4">
          Tem certeza que quer excluir <strong>{{ sprintParaExcluir.nome }}</strong>?
          As tarefas associadas voltam ao backlog.
        </p>
        <div class="flex gap-2 justify-end">
          <button class="botao-secundario" @click="sprintParaExcluir = null">Cancelar</button>
          <button class="botao-primario bg-red-600 hover:bg-red-700" @click="excluirSprint">Excluir</button>
        </div>
      </div>
    </div>
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
      aba: 'planejamento' as 'planejamento' | 'backlog' | 'execucao' | 'metricas',
      abrirModal: false,
      sprintEditando: null as any,
      sprintParaExcluir: null as any,
      exibirModalTarefa: false,
      tarefaParaModal: null as any,
      membrosDoProj: [] as any[],
      backlogBusca: '',
      backlogFiltroTipo: '' as string,
      backlogFiltroPrioridade: '' as string,
      backlogFiltroDor: '' as string,
      visaoMobile: 'lista' as 'lista' | 'detalhe',
      abas: [
        { id: 'planejamento', label: '📋 Planejamento' },
        { id: 'backlog',      label: '🗂 Backlog' },
        { id: 'execucao',     label: '▶️ Execução' },
        { id: 'metricas',     label: '📊 Métricas' },
      ],
    }
  },

  computed: {
    dorPercent(): number {
      const total = this.loja.tarefasSprint.length
      if (!total) return 0
      const ok = this.loja.tarefasSprint.filter((t: any) => t.dor_ok).length
      return Math.round((ok / total) * 100)
    },

    backlogFiltrado(): any[] {
      return this.loja.backlog.filter((t: any) => {
        if (this.backlogBusca) {
          const q = this.backlogBusca.toLowerCase()
          if (!t.titulo?.toLowerCase().includes(q) && !t.descricao?.toLowerCase().includes(q)) return false
        }
        if (this.backlogFiltroTipo && t.tipo_tarefa !== this.backlogFiltroTipo) return false
        if (this.backlogFiltroPrioridade && t.prioridade !== this.backlogFiltroPrioridade) return false
        if (this.backlogFiltroDor === 'pronto' && !t.dor_ok) return false
        if (this.backlogFiltroDor === 'pendente' && t.dor_ok) return false
        return true
      })
    },

    backlogSpTotal(): number {
      return this.backlogFiltrado.reduce((acc: number, t: any) => acc + (t.pontos || 0), 0)
    },

    backlogDorOkCount(): number {
      return this.backlogFiltrado.filter((t: any) => t.dor_ok).length
    },

    // Todas as tarefas já associadas a esta sprint (independente da coluna)
    sprintBacklogNaoIniciado(): any[] {
      return this.loja.tarefasSprint
    },
  },

  async mounted() {
    if (!this.lojaProjetos.projetos.length) {
      await this.lojaProjetos.carregar()
    }
    if (this.loja.sprintAtual) {
      await this.loja.selecionar(this.loja.sprintAtual.id)
    }
  },

  watch: {
    projetoId: {
      immediate: true,
      async handler(id: string) {
        if (id) {
          await this.loja.carregarPorProjeto(id)
          this.loja.carregarVelocity(id)
        }
      }
    },

    async aba(novaAba: string) {
      if (novaAba === 'backlog' && this.loja.sprintAtual) {
        await this.loja.selecionar(this.loja.sprintAtual.id)
      }
    },
  },

  methods: {
    abrirModalNovaSprint() {
      this.sprintEditando = null
      this.abrirModal = true
    },

    abrirEdicao(sprint: any) {
      this.sprintEditando = sprint
      this.abrirModal = true
    },

    fecharModal() {
      this.abrirModal = false
      this.sprintEditando = null
    },

    async sprintCriada() {
      this.fecharModal()
      if (this.projetoId) {
        await this.loja.carregarPorProjeto(this.projetoId)
      }
    },

    confirmarExclusao(sprint: any) {
      this.sprintParaExcluir = sprint
    },

    async excluirSprint() {
      if (!this.sprintParaExcluir) return
      await this.loja.excluir(this.sprintParaExcluir.id)
      this.sprintParaExcluir = null
    },

    async selecionarSprint(id: string) {
      await this.loja.selecionar(id)
      this.aba = 'planejamento'
      this.visaoMobile = 'detalhe'
      if (this.projetoId) {
        this.loja.carregarVelocity(this.projetoId)
      }
    },

    async alterarStatusSprint(evento: Event) {
      const valor = (evento.target as HTMLSelectElement).value
      await this.loja.atualizar(this.loja.sprintAtual.id, { status: valor })
    },

    async atualizarSnapshot() {
      await this.loja.atualizarSnapshot()
    },

    async recarregarBacklog() {
      if (this.loja.sprintAtual) {
        await this.loja.selecionar(this.loja.sprintAtual.id)
      }
    },

    async abrirEdicaoTarefa(tarefa: any) {
      if (!this.membrosDoProj.length && this.loja.sprintAtual?.projeto_id) {
        this.membrosDoProj = await servicoEquipe().listarMembrosPorID(this.loja.sprintAtual.projeto_id)
      }
      this.tarefaParaModal = tarefa
      this.exibirModalTarefa = true
    },

    async abrirModalNovaTarefa() {
      if (!this.membrosDoProj.length && this.loja.sprintAtual?.projeto_id) {
        this.membrosDoProj = await servicoEquipe().listarMembrosPorID(this.loja.sprintAtual.projeto_id)
      }
      this.tarefaParaModal = {
        projeto_id: this.loja.sprintAtual?.projeto_id || this.projetoId,
        sprint_id: this.loja.sprintAtual?.id,
        coluna: 'a_fazer',
        prioridade: 'media'
      }
      this.exibirModalTarefa = true
    },

    tarefaCriada(nova: any) {
      if (nova?.id) {
        this.loja.tarefasSprint.unshift(nova)
      }
      this.exibirModalTarefa = false
    },

    async removerTarefaSprint(id: string) {
      await this.loja.associar(id, null)
    },

    async excluirTarefaPermanente(id: string) {
      if (!confirm('Excluir esta tarefa permanentemente? Esta ação não pode ser desfeita.')) return
      await servicoTarefas().excluirTarefa(id)
      this.loja.removerTarefaLocal(id)
      // Sincroniza kanban se estiver carregado
      useLojaKanban().removerTarefa(id)
    },

    async adicionarTarefaSprint(id: string) {
      await this.loja.associar(id, this.loja.sprintAtual.id)
    },

    formatarData(data: string | null): string {
      if (!data) return '—'
      return data.slice(0, 10).split('-').reverse().join('/')
    },

    corStatus(status: string) {
      return {
        planejada: 'bg-slate-100 text-slate-600',
        ativa: 'bg-blue-100 text-blue-700',
        concluida: 'bg-green-100 text-green-700',
      }[status] || 'bg-slate-100'
    },

    corColuna(coluna: string) {
      return {
        backlog: 'bg-slate-100 text-slate-600',
        a_fazer: 'bg-blue-100 text-blue-700',
        em_progresso: 'bg-amber-100 text-amber-700',
        em_revisao: 'bg-violet-100 text-violet-700',
        concluido: 'bg-green-100 text-green-700',
      }[coluna] || 'bg-slate-100'
    },

    corPrioridade(p: string) {
      return {
        baixa:   'bg-slate-100 text-slate-500',
        media:   'bg-blue-100 text-blue-600',
        alta:    'bg-amber-100 text-amber-700',
        urgente: 'bg-red-100 text-red-600',
      }[p] || 'bg-slate-100 text-slate-500'
    },
  }
})
</script>
