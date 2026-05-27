<template>
  <div>
    <!-- Hero -->
    <section class="bg-gradient-to-br from-indigo-50 via-white to-blue-50 py-24 px-6">
      <div class="max-w-5xl mx-auto text-center">
        <div class="inline-flex items-center gap-2 px-3 py-1.5 bg-primaria/10 text-primaria rounded-full text-xs font-semibold uppercase tracking-wider mb-6">
          ✦ Gestão de projetos ágil para times modernos
        </div>
        <h1 class="text-4xl md:text-6xl font-extrabold text-slate-900 leading-tight mb-6">
          Organize sua equipe.<br />
          <span class="text-primaria">Entregue mais rápido.</span>
        </h1>
        <p class="text-lg text-slate-500 max-w-2xl mx-auto mb-10">
          Kanban, Sprints, Backlog e métricas em uma plataforma completa.
          Do planejamento à entrega, sem complicação.
        </p>
        <div class="flex flex-col sm:flex-row gap-3 justify-center">
          <NuxtLink to="/planos" class="botao-primario text-base px-6 py-3">
            Ver planos e preços →
          </NuxtLink>
          <NuxtLink to="/cadastro" class="botao-secundario text-base px-6 py-3">
            Criar conta grátis
          </NuxtLink>
        </div>
        <p class="text-xs text-slate-400 mt-4">Sem cartão de crédito. Cancele a qualquer momento.</p>
      </div>
    </section>

    <!-- Features -->
    <section class="py-20 px-6 bg-white">
      <div class="max-w-5xl mx-auto">
        <div class="text-center mb-14">
          <h2 class="text-3xl font-bold text-slate-900 mb-3">Tudo que seu time precisa</h2>
          <p class="text-slate-500">Uma plataforma completa para gestão ágil de ponta a ponta.</p>
        </div>
        <div class="grid md:grid-cols-3 gap-8">
          <div v-for="f in features" :key="f.titulo" class="rounded-2xl border border-slate-100 p-6 hover:border-primaria/30 hover:shadow-md transition">
            <div class="text-3xl mb-4">{{ f.icone }}</div>
            <h3 class="font-bold text-slate-800 mb-2">{{ f.titulo }}</h3>
            <p class="text-sm text-slate-500 leading-relaxed">{{ f.descricao }}</p>
          </div>
        </div>
      </div>
    </section>

    <!-- Como funciona -->
    <section class="py-20 px-6 bg-slate-50">
      <div class="max-w-4xl mx-auto">
        <div class="text-center mb-14">
          <h2 class="text-3xl font-bold text-slate-900 mb-3">Como funciona</h2>
          <p class="text-slate-500">Em 3 passos simples você e sua equipe estão operando.</p>
        </div>
        <div class="flex flex-col md:flex-row gap-6">
          <div v-for="(passo, i) in passos" :key="passo.titulo"
            class="flex-1 bg-white rounded-2xl border border-slate-100 p-6 relative">
            <div class="w-8 h-8 rounded-full bg-primaria text-white flex items-center justify-center text-sm font-bold mb-4">
              {{ i + 1 }}
            </div>
            <h3 class="font-bold text-slate-800 mb-2">{{ passo.titulo }}</h3>
            <p class="text-sm text-slate-500">{{ passo.descricao }}</p>
          </div>
        </div>
      </div>
    </section>

    <!-- Social proof -->
    <section class="py-16 px-6 bg-white">
      <div class="max-w-4xl mx-auto text-center">
        <div class="grid md:grid-cols-3 gap-8">
          <div v-for="m in metricas" :key="m.valor">
            <div class="text-4xl font-extrabold text-primaria mb-1">{{ m.valor }}</div>
            <div class="text-sm text-slate-500">{{ m.label }}</div>
          </div>
        </div>
      </div>
    </section>

    <!-- CTA final -->
    <section class="py-20 px-6 bg-gradient-to-br from-indigo-600 to-blue-700 text-white">
      <div class="max-w-2xl mx-auto text-center">
        <h2 class="text-3xl font-bold mb-4">Pronto para começar?</h2>
        <p class="text-indigo-100 mb-8">Escolha o plano ideal para o seu time e comece hoje mesmo.</p>
        <NuxtLink to="/planos" class="inline-flex items-center gap-2 bg-white text-primaria font-bold px-8 py-3 rounded-xl hover:bg-indigo-50 transition text-base">
          Ver planos →
        </NuxtLink>
      </div>
    </section>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ layout: 'publica' })

const features = [
  { icone: '📌', titulo: 'Quadro Kanban',      descricao: 'Visualize o fluxo de trabalho do time em tempo real com colunas personalizáveis.' },
  { icone: '🔄', titulo: 'Sprints e Backlog',  descricao: 'Planeje iterações curtas, priorize o backlog e acompanhe a velocidade do time.' },
  { icone: '📊', titulo: 'Dashboard e Métricas', descricao: 'Burndown chart, tempo de ciclo e visão geral do progresso em dashboards claros.' },
  { icone: '👥', titulo: 'Gestão de Equipe',   descricao: 'Papéis personalizados, convites por link e controle de permissões por projeto.' },
  { icone: '🔔', titulo: 'Notificações',       descricao: 'Alertas automáticos de prazos, vencimentos e atividades importantes via WhatsApp.' },
  { icone: '🔒', titulo: 'Seguro e Confiável', descricao: 'Dados isolados por organização, autenticação robusta e backups automáticos.' },
]

const passos = [
  { titulo: 'Crie sua conta',      descricao: 'Registre-se em menos de 1 minuto. Sem cartão de crédito necessário no período de trial.' },
  { titulo: 'Monte sua equipe',    descricao: 'Convide membros, defina papéis e crie seus primeiros projetos em minutos.' },
  { titulo: 'Comece a entregar',   descricao: 'Use Kanban, Sprints e Backlog para organizar e acompanhar o trabalho do time.' },
]

const metricas = [
  { valor: '10x',  label: 'mais produtividade reportada pelos times' },
  { valor: '< 5min', label: 'para configurar seu workspace' },
  { valor: '24/7', label: 'disponibilidade da plataforma' },
]
</script>
