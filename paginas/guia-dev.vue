<template>
  <div class="max-w-3xl mx-auto space-y-6 pb-12">

    <div>
      <h1 class="text-3xl font-bold">🧑‍💻 Guia do Desenvolvedor</h1>
      <p class="text-slate-500 mt-1">Referência completa do fluxo de desenvolvimento profissional.</p>
    </div>

    <!-- Tabs -->
    <div class="flex border-b gap-0 overflow-x-auto">
      <button
        v-for="s in secoes"
        :key="s.id"
        :class="[
          'px-4 py-2.5 text-sm font-medium border-b-2 -mb-px transition whitespace-nowrap',
          ativa === s.id ? 'border-primaria text-primaria' : 'border-transparent text-slate-500 hover:text-slate-700'
        ]"
        @click="ativa = s.id"
      >
        {{ s.label }}
      </button>
    </div>

    <!-- BRANCHES -->
    <div v-if="ativa === 'branches'" class="space-y-4">
      <div class="cartao space-y-3">
        <h2 class="font-bold text-slate-800">Estrutura de Branches</h2>
        <p class="text-sm text-slate-500">Nunca trabalhe diretamente na <code class="bg-slate-100 px-1 rounded">main</code>. Toda mudança começa com uma branch.</p>

        <div class="space-y-2">
          <div v-for="b in branches" :key="b.tipo" class="flex items-start gap-3 p-3 rounded-lg border border-slate-100 bg-slate-50">
            <code :class="['text-xs font-bold px-2 py-1 rounded shrink-0', b.cor]">{{ b.tipo }}</code>
            <div>
              <p class="text-sm font-semibold text-slate-700">{{ b.uso }}</p>
              <p class="text-xs text-slate-400 mt-0.5">Exemplo: <code>{{ b.exemplo }}</code></p>
            </div>
          </div>
        </div>

        <div class="bg-slate-900 text-green-400 text-xs px-4 py-3 rounded-lg font-mono space-y-1">
          <p>git checkout develop</p>
          <p>git pull origin develop</p>
          <p>git checkout -b feature/nome-da-tarefa</p>
        </div>
      </div>
    </div>

    <!-- COMMITS -->
    <div v-else-if="ativa === 'commits'" class="space-y-4">
      <div class="cartao space-y-4">
        <h2 class="font-bold text-slate-800">Conventional Commits</h2>
        <p class="text-sm text-slate-500">Commits pequenos, frequentes e com prefixo semântico. Nunca um único "projeto pronto".</p>

        <div class="grid grid-cols-1 sm:grid-cols-2 gap-2">
          <div v-for="c in commitRefs" :key="c.tipo" class="flex gap-3 items-start border border-slate-100 rounded-lg p-3 bg-slate-50">
            <code class="text-primaria font-bold text-sm shrink-0">{{ c.tipo }}:</code>
            <div>
              <p class="text-sm font-semibold text-slate-700">{{ c.nome }}</p>
              <p class="text-xs text-slate-400">{{ c.desc }}</p>
            </div>
          </div>
        </div>

        <div class="space-y-2">
          <p class="text-xs font-bold text-slate-500 uppercase tracking-wide">Exemplos reais</p>
          <div v-for="ex in commitExemplos" :key="ex" class="bg-slate-900 text-green-400 text-xs px-3 py-2 rounded font-mono">{{ ex }}</div>
        </div>
      </div>
    </div>

    <!-- PR -->
    <div v-else-if="ativa === 'pr'" class="space-y-4">
      <div class="cartao space-y-4">
        <h2 class="font-bold text-slate-800">Pull Request</h2>
        <p class="text-sm text-slate-500">O PR é a porta de entrada para o código na branch principal. Sem PR, sem merge.</p>

        <div class="space-y-2">
          <p class="text-xs font-bold text-slate-500 uppercase tracking-wide">O PR deve ter</p>
          <div v-for="item in prChecklist" :key="item" class="flex items-center gap-2 text-sm text-slate-700">
            <span class="text-green-500">✓</span> {{ item }}
          </div>
        </div>

        <div class="bg-slate-900 text-slate-100 text-xs px-4 py-3 rounded-lg font-mono space-y-1 leading-relaxed">
          <p class="text-slate-400">## O que foi feito</p>
          <p>Implementa cadastro de clientes com validação de CPF</p>
          <p>&nbsp;</p>
          <p class="text-slate-400">## Checklist</p>
          <p>- [ ] Testes passando</p>
          <p>- [ ] Build sem erros</p>
          <p>- [ ] Review solicitado</p>
          <p>&nbsp;</p>
          <p class="text-slate-400">Closes #245</p>
        </div>

        <div class="border-l-4 border-amber-400 bg-amber-50 px-4 py-3 rounded-r-lg">
          <p class="text-xs font-bold text-amber-800">Regra de ouro</p>
          <p class="text-xs text-amber-700 mt-1">PR sempre aponta para <code class="bg-amber-100 px-1 rounded">develop</code> — nunca direto para <code class="bg-amber-100 px-1 rounded">main</code></p>
        </div>
      </div>
    </div>

    <!-- CI -->
    <div v-else-if="ativa === 'ci'" class="space-y-4">
      <div class="cartao space-y-4">
        <h2 class="font-bold text-slate-800">CI — Integração Contínua</h2>
        <p class="text-sm text-slate-500">Ao abrir o PR, uma pipeline automática é executada. Se falhar, o merge é bloqueado.</p>

        <div class="space-y-2">
          <div
            v-for="(etapa, i) in ciEtapas"
            :key="etapa.nome"
            class="flex items-center gap-3"
          >
            <div class="flex flex-col items-center">
              <div :class="['w-8 h-8 rounded-full flex items-center justify-center text-white text-xs font-bold', etapa.cor]">{{ i + 1 }}</div>
              <div v-if="i < ciEtapas.length - 1" class="w-0.5 h-4 bg-slate-200" />
            </div>
            <div>
              <p class="text-sm font-semibold text-slate-700">{{ etapa.nome }}</p>
              <p class="text-xs text-slate-400">{{ etapa.desc }}</p>
            </div>
          </div>
        </div>

        <div class="bg-red-50 border border-red-200 rounded-xl p-3">
          <p class="text-xs font-bold text-red-700">❌ Se o CI falhar</p>
          <p class="text-xs text-red-600 mt-1">O merge é bloqueado automaticamente. Corrija o problema, faça commit e push — o PR é atualizado automaticamente.</p>
        </div>
      </div>
    </div>

    <!-- RELEASE -->
    <div v-else-if="ativa === 'release'" class="space-y-4">
      <div class="cartao space-y-4">
        <h2 class="font-bold text-slate-800">Fluxo de Release</h2>
        <p class="text-sm text-slate-500">Release = conjunto de features prontas sendo empacotadas para produção.</p>

        <div class="bg-slate-900 text-green-400 text-xs px-4 py-4 rounded-lg font-mono space-y-1 leading-relaxed">
          <p class="text-slate-400"># 1. Criar branch de release</p>
          <p>git checkout develop && git checkout -b release/v1.5.0</p>
          <p>&nbsp;</p>
          <p class="text-slate-400"># 2. Após homologação aprovada — merge para main</p>
          <p>git checkout main && git merge release/v1.5.0</p>
          <p>&nbsp;</p>
          <p class="text-slate-400"># 3. Criar tag</p>
          <p>git tag v1.5.0 && git push origin v1.5.0</p>
          <p>&nbsp;</p>
          <p class="text-slate-400"># 4. Sync develop</p>
          <p>git checkout develop && git merge main</p>
        </div>

        <div class="space-y-1 text-xs text-slate-600">
          <p class="font-bold text-slate-700 uppercase tracking-wide text-[10px]">Semântica de versão (SemVer)</p>
          <p><code class="bg-slate-100 px-1 rounded">MAJOR</code> — quebra compatibilidade</p>
          <p><code class="bg-slate-100 px-1 rounded">MINOR</code> — nova funcionalidade compatível</p>
          <p><code class="bg-slate-100 px-1 rounded">PATCH</code> — correção de bug</p>
        </div>

        <div class="border-l-4 border-blue-400 bg-blue-50 px-4 py-3 rounded-r-lg">
          <p class="text-xs font-bold text-blue-700">Hotfix (emergência em produção)</p>
          <p class="text-xs text-blue-600 mt-1">
            <code class="bg-blue-100 px-1 rounded">main → hotfix/nome → correção → PR → main + develop</code>
          </p>
        </div>
      </div>
    </div>

  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'

definePageMeta({ layout: 'default' })

const ativa = ref('branches')

const secoes = [
  { id: 'branches', label: '🌿 Branches' },
  { id: 'commits',  label: '💬 Commits' },
  { id: 'pr',       label: '📝 Pull Request' },
  { id: 'ci',       label: '⚙️ CI Pipeline' },
  { id: 'release',  label: '🚀 Release' },
]

const branches = [
  { tipo: 'feature/*', cor: 'bg-blue-100 text-blue-800',   uso: 'Nova funcionalidade',      exemplo: 'feature/cadastro-cliente' },
  { tipo: 'bugfix/*',  cor: 'bg-red-100 text-red-800',     uso: 'Correção não-urgente',      exemplo: 'bugfix/correcao-token' },
  { tipo: 'hotfix/*',  cor: 'bg-orange-100 text-orange-800', uso: 'Emergência em produção',  exemplo: 'hotfix/falha-login' },
  { tipo: 'release/*', cor: 'bg-purple-100 text-purple-800', uso: 'Preparo de versão',       exemplo: 'release/v1.5.0' },
  { tipo: 'develop',   cor: 'bg-indigo-100 text-indigo-800', uso: 'Integração contínua',     exemplo: 'develop' },
  { tipo: 'main',      cor: 'bg-green-100 text-green-800',   uso: 'Produção — sempre estável', exemplo: 'main' },
]

const commitRefs = [
  { tipo: 'feat',     nome: 'Feature',    desc: 'Nova funcionalidade' },
  { tipo: 'fix',      nome: 'Fix',        desc: 'Correção de bug' },
  { tipo: 'refactor', nome: 'Refactor',   desc: 'Sem mudança de comportamento' },
  { tipo: 'test',     nome: 'Test',       desc: 'Testes' },
  { tipo: 'docs',     nome: 'Docs',       desc: 'Documentação' },
  { tipo: 'chore',    nome: 'Chore',      desc: 'Manutenção e config' },
  { tipo: 'perf',     nome: 'Perf',       desc: 'Performance' },
  { tipo: 'ci',       nome: 'CI',         desc: 'Pipeline CI' },
]

const commitExemplos = [
  'feat: criar modelo Cliente',
  'feat: implementar service de cadastro',
  'fix: corrigir validação de CPF',
  'test: adicionar testes do endpoint POST /cliente',
  'refactor: extrair validação para helper',
]

const prChecklist = [
  'Título descritivo (feat: o que faz)',
  'Descrição do que foi implementado',
  'Critérios de aceite validados',
  'Checklist de testes',
  'Issue linkada (Closes #245)',
  'Screenshots quando aplicável',
]

const ciEtapas = [
  { nome: 'Instalar dependências', desc: 'npm ci', cor: 'bg-slate-500' },
  { nome: 'Lint',                  desc: 'Verificar padrões de código', cor: 'bg-blue-500' },
  { nome: 'Build',                 desc: 'Compilar o projeto', cor: 'bg-indigo-500' },
  { nome: 'Testes unitários',      desc: 'npm run test', cor: 'bg-purple-500' },
  { nome: 'Testes de integração',  desc: 'Testar fluxos completos', cor: 'bg-violet-500' },
  { nome: 'Segurança',             desc: 'Scan de vulnerabilidades', cor: 'bg-orange-500' },
  { nome: 'Cobertura',             desc: 'Mínimo 80% de cobertura', cor: 'bg-green-500' },
]
</script>
