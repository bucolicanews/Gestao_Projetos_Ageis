<template>
  <div>
    <div v-if="verificando" class="flex items-center justify-center h-40 text-slate-400">
      Verificando permissões...
    </div>

    <template v-else-if="isDevelopAdmin">
      <!-- Header -->
      <div class="flex justify-between items-center mb-6">
        <div>
          <h1 class="text-2xl font-bold">💰 Dashboard Financeiro</h1>
          <p class="text-sm text-slate-500 mt-0.5">Visão geral de receita e organizações</p>
        </div>
        <button class="botao-secundario text-sm" :disabled="carregando" @click="carregar">
          {{ carregando ? 'Atualizando...' : '↻ Atualizar' }}
        </button>
      </div>

      <!-- Erro -->
      <div v-if="erro" class="text-perigo text-sm mb-4">{{ erro }}</div>

      <!-- Skeleton carregando -->
      <div v-if="carregando" class="grid grid-cols-2 md:grid-cols-4 gap-4 mb-6">
        <div v-for="i in 4" :key="i" class="cartao animate-pulse h-24 bg-slate-100" />
      </div>

      <template v-else-if="metricas">
        <!-- Cards métricas -->
        <div class="grid grid-cols-2 md:grid-cols-4 gap-4 mb-6">
          <div class="cartao">
            <p class="text-xs text-slate-500 mb-1">Total Organizações</p>
            <p class="text-3xl font-bold text-slate-800">{{ metricas.totalOrgs }}</p>
            <p class="text-xs text-green-600 mt-1">{{ metricas.orgsAtivas }} ativas</p>
          </div>

          <div class="cartao">
            <p class="text-xs text-slate-500 mb-1">MRR Potencial</p>
            <p class="text-3xl font-bold text-primaria">
              R$ {{ metricas.mrrPotencial.toFixed(2).replace('.', ',') }}
            </p>
            <p class="text-xs text-slate-400 mt-1">orgs c/ plano vinculado</p>
          </div>

          <div class="cartao">
            <p class="text-xs text-slate-500 mb-1">Planos Cadastrados</p>
            <p class="text-3xl font-bold text-slate-800">{{ metricas.totalPlanos }}</p>
            <p class="text-xs text-green-600 mt-1">{{ metricas.planosAtivos }} ativos</p>
          </div>

          <div class="cartao bg-amber-50 border-amber-100">
            <p class="text-xs text-amber-600 mb-1">Sem plano vinculado</p>
            <p class="text-3xl font-bold text-amber-700">
              {{ metricas.orgsPorPlano.find(p => p.plano_id === null)?.total ?? 0 }}
            </p>
            <p class="text-xs text-amber-500 mt-1">organizações</p>
          </div>
        </div>

        <!-- Linha: Orgs por plano + Orgs recentes -->
        <div class="grid md:grid-cols-2 gap-6">

          <!-- Distribuição por plano -->
          <div class="cartao">
            <h3 class="font-semibold text-sm mb-4">Organizações por Plano</h3>
            <div class="flex flex-col gap-3">
              <div
                v-for="item in metricas.orgsPorPlano.filter(p => p.plano_id !== null)"
                :key="item.plano_id"
                class="flex items-center gap-3"
              >
                <div class="flex-1">
                  <div class="flex justify-between text-sm mb-1">
                    <span class="font-medium">{{ item.titulo }}</span>
                    <span class="text-slate-500">{{ item.total }} org{{ item.total !== 1 ? 's' : '' }}</span>
                  </div>
                  <div class="h-2 bg-slate-100 rounded-full overflow-hidden">
                    <div
                      class="h-2 bg-primaria rounded-full transition-all"
                      :style="{ width: metricas.totalOrgs ? `${(item.total / metricas.totalOrgs) * 100}%` : '0%' }"
                    />
                  </div>
                </div>
                <span class="text-xs font-semibold text-slate-600 w-24 text-right">
                  R$ {{ Number(item.preco).toFixed(2).replace('.', ',') }}/mês
                </span>
              </div>

              <div v-if="!metricas.orgsPorPlano.filter(p => p.plano_id !== null).length" class="text-sm text-slate-400 text-center py-4">
                Nenhuma org vinculada a planos ainda.
                <br>
                <NuxtLink to="/develop/organizacoes" class="text-primaria hover:underline text-xs mt-1 inline-block">
                  Gerenciar organizações →
                </NuxtLink>
              </div>
            </div>
          </div>

          <!-- Orgs recentes -->
          <div class="cartao">
            <div class="flex justify-between items-center mb-4">
              <h3 class="font-semibold text-sm">Organizações Recentes</h3>
              <NuxtLink to="/develop/organizacoes" class="text-xs text-primaria hover:underline">Ver todas →</NuxtLink>
            </div>
            <div class="flex flex-col gap-2">
              <div
                v-for="org in metricas.orgsRecentes"
                :key="org.id"
                class="flex items-center justify-between py-2 border-b border-slate-50 last:border-0"
              >
                <div>
                  <p class="text-sm font-medium text-slate-800">{{ org.nome }}</p>
                  <p class="text-xs text-slate-400">{{ org.plano ?? 'Sem plano' }}</p>
                </div>
                <span
                  class="text-xs px-2 py-0.5 rounded-full font-medium"
                  :class="org.ativo ? 'bg-green-100 text-green-700' : 'bg-slate-100 text-slate-500'"
                >
                  {{ org.ativo ? 'Ativa' : 'Inativa' }}
                </span>
              </div>

              <div v-if="!metricas.orgsRecentes.length" class="text-sm text-slate-400 text-center py-6">
                Nenhuma organização cadastrada.
              </div>
            </div>
          </div>

        </div>

        <!-- Banner próximas funcionalidades -->
        <div class="mt-6 p-4 rounded-xl border border-dashed border-slate-200 bg-slate-50">
          <p class="text-sm text-slate-500 font-medium mb-2">Próximas métricas (após Fase 2 — Assinaturas)</p>
          <div class="flex flex-wrap gap-3">
            <span class="text-xs bg-white border border-slate-200 rounded-lg px-3 py-1.5 text-slate-400">📈 Churn rate</span>
            <span class="text-xs bg-white border border-slate-200 rounded-lg px-3 py-1.5 text-slate-400">💳 Pagamentos pendentes</span>
            <span class="text-xs bg-white border border-slate-200 rounded-lg px-3 py-1.5 text-slate-400">🔔 Vencimentos próximos</span>
            <span class="text-xs bg-white border border-slate-200 rounded-lg px-3 py-1.5 text-slate-400">📊 Receita por mês</span>
            <span class="text-xs bg-white border border-slate-200 rounded-lg px-3 py-1.5 text-slate-400">🏆 Top planos</span>
          </div>
        </div>
      </template>
    </template>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ layout: 'default' })

const { isDevelopAdmin, verificando } = useDevelopAdmin()
const { carregando, erro, metricas, carregar } = useFinanceiro()

onMounted(() => carregar())
</script>
