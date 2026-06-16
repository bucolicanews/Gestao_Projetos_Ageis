<template>
  <div class="cartao space-y-6">
    <div>
      <h3 class="font-bold text-lg">🚀 Wizard de Release</h3>
      <p class="text-sm text-slate-500 mt-0.5">Siga os passos para criar a release desta sprint.</p>
    </div>

    <!-- Versão -->
    <div>
      <label class="rotulo">Versão da release</label>
      <div class="flex items-center gap-2 mt-1">
        <input
          v-model="versao"
          type="text"
          placeholder="Ex: v1.5.0"
          class="campo max-w-[180px]"
        />
        <span class="text-xs text-slate-400">Semântico: MAJOR.MINOR.PATCH</span>
      </div>
      <p class="text-xs text-slate-400 mt-1">
        <strong>MAJOR</strong>: quebra compatibilidade &nbsp;|&nbsp;
        <strong>MINOR</strong>: nova funcionalidade &nbsp;|&nbsp;
        <strong>PATCH</strong>: correção de bug
      </p>
    </div>

    <!-- Passos -->
    <div class="space-y-3">
      <p class="rotulo">Passos obrigatórios (execute em ordem)</p>

      <div
        v-for="(passo, i) in passos"
        :key="i"
        :class="[
          'border rounded-xl p-4 transition-all',
          passo.ok ? 'bg-green-50 border-green-200' : 'bg-white border-slate-200'
        ]"
      >
        <div class="flex items-start gap-3">
          <button
            :class="[
              'mt-0.5 w-5 h-5 rounded-full border-2 flex items-center justify-center shrink-0 transition-all',
              passo.ok ? 'bg-green-500 border-green-500 text-white' : 'border-slate-300'
            ]"
            @click="passo.ok = !passo.ok"
          >
            <span v-if="passo.ok" class="text-xs leading-none">✓</span>
          </button>

          <div class="flex-1 min-w-0">
            <p :class="['font-semibold text-sm', passo.ok ? 'text-green-700 line-through opacity-60' : 'text-slate-800']">
              {{ i + 1 }}. {{ passo.titulo }}
            </p>
            <p class="text-xs text-slate-500 mt-0.5">{{ passo.desc }}</p>

            <div v-if="passo.cmd" class="flex items-center gap-2 mt-2">
              <code class="flex-1 bg-slate-900 text-green-400 text-xs px-3 py-2 rounded font-mono whitespace-pre-wrap">{{ passo.cmd }}</code>
              <button class="btn-copiar" @click="copiar(passo.cmd!, `passo-${i}`)">
                {{ copiado === `passo-${i}` ? '✅' : '📋' }}
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Progresso -->
    <div>
      <div class="flex justify-between text-xs text-slate-500 mb-1">
        <span>Progresso da release</span>
        <span>{{ concluidos }}/{{ passos.length }}</span>
      </div>
      <div class="h-2 bg-slate-100 rounded-full overflow-hidden">
        <div
          class="h-full bg-green-500 transition-all"
          :style="{ width: `${(concluidos / passos.length) * 100}%` }"
        />
      </div>
      <p v-if="concluidos === passos.length" class="text-xs text-green-700 font-semibold mt-2 text-center">
        🎉 Release {{ versao || 'vX.Y.Z' }} concluída!
      </p>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, computed } from 'vue'

const versao = ref('')

const vNome = computed(() => versao.value.trim() || 'vX.Y.Z')

const passos = reactive([
  {
    ok: false,
    titulo: 'Garantir que develop está estável',
    desc: 'Todos os PRs da sprint devem estar merged. CI verde. Sem bugs abertos críticos.',
    cmd: null as string | null,
  },
  {
    ok: false,
    titulo: 'Criar branch de release',
    desc: 'Nunca adicione novas features na branch de release — apenas bugfixes e documentação.',
    get cmd() { return `git checkout develop\ngit pull origin develop\ngit checkout -b release/${vNome.value}` },
  },
  {
    ok: false,
    titulo: 'Homologação com PO / cliente',
    desc: 'Deploy em staging. PO valida as funcionalidades da sprint. Documente a aprovação.',
    cmd: null,
  },
  {
    ok: false,
    titulo: 'Merge para main',
    desc: 'Após aprovação em homologação. PR de release/* → main com mínimo 2 approvals.',
    get cmd() { return `git checkout main\ngit merge release/${vNome.value}\ngit push origin main` },
  },
  {
    ok: false,
    titulo: 'Criar tag de versão',
    desc: 'A tag marca o ponto exato do código que foi para produção. Histórico imutável.',
    get cmd() { return `git tag ${vNome.value}\ngit push origin ${vNome.value}` },
  },
  {
    ok: false,
    titulo: 'Sync de volta para develop',
    desc: 'Garante que qualquer hotfix feito na release não se perca no develop.',
    get cmd() { return `git checkout develop\ngit merge main\ngit push origin develop` },
  },
  {
    ok: false,
    titulo: 'Deploy em produção',
    desc: 'Pipeline CI/CD dispara automaticamente ao push na main, ou deploy manual.',
    cmd: null,
  },
])

const concluidos = computed(() => passos.filter(p => p.ok).length)

const copiado = ref('')

async function copiar(texto: string, chave: string) {
  await navigator.clipboard.writeText(texto)
  copiado.value = chave
  setTimeout(() => { copiado.value = '' }, 2000)
}
</script>

<style scoped>
.rotulo {
  display: block;
  font-size: 11px;
  font-weight: 700;
  color: hsl(215 16% 47%);
  text-transform: uppercase;
  letter-spacing: 0.05em;
}

.campo {
  width: 100%;
  padding: 8px 12px;
  border-radius: 8px;
  border: 1px solid hsl(214 32% 91%);
  font-size: 14px;
  background: #fff;
  color: hsl(222 47% 11%);
  transition: border-color 0.15s;
}

.campo:focus {
  outline: none;
  border-color: hsl(221 83% 53%);
  box-shadow: 0 0 0 3px hsl(221 83% 53% / 0.12);
}

.btn-copiar {
  flex-shrink: 0;
  padding: 4px 8px;
  border-radius: 6px;
  border: 1.5px solid #374151;
  background: #1e293b;
  color: #9ca3af;
  cursor: pointer;
  font-size: 11px;
  transition: all 0.15s;
}

.btn-copiar:hover {
  color: #e2e8f0;
}
</style>
