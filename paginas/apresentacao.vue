<template>
  <div class="overflow-x-hidden">

    <!-- ══════════════════════════════════════════════════════════
         HERO — fundo animado com blob e gradiente dinâmico
    ═══════════════════════════════════════════════════════════ -->
    <section class="relative min-h-screen flex items-center justify-center bg-[#0a0a1a] overflow-hidden px-4 py-20">

      <!-- Blobs animados -->
      <div class="absolute -top-40 -left-40 w-[600px] h-[600px] bg-indigo-600/20 rounded-full blur-[120px] animate-blob" />
      <div class="absolute -bottom-20 -right-20 w-[500px] h-[500px] bg-purple-600/20 rounded-full blur-[100px] animate-blob animation-delay-2000" />
      <div class="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[400px] h-[400px] bg-blue-500/10 rounded-full blur-[80px] animate-blob animation-delay-4000" />

      <!-- Grid overlay -->
      <div class="absolute inset-0 bg-[url('data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iNDAiIGhlaWdodD0iNDAiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI+PGRlZnM+PHBhdHRlcm4gaWQ9ImdyaWQiIHdpZHRoPSI0MCIgaGVpZ2h0PSI0MCIgcGF0dGVyblVuaXRzPSJ1c2VyU3BhY2VPblVzZSI+PHBhdGggZD0iTSAwIDEwIEwgNDAgMTAgTSAxMCAwIEwgMTAgNDAgTSAwIDIwIEwgNDAgMjAgTSAyMCAwIEwgMjAgNDAgTSAwIDMwIEwgNDAgMzAgTSAzMCAwIEwgMzAgNDAiIGZpbGw9Im5vbmUiIHN0cm9rZT0icmdiYSgyNTUsMjU1LDI1NSwwLjAzKSIgc3Ryb2tlLXdpZHRoPSIxIi8+PC9wYXR0ZXJuPjwvZGVmcz48cmVjdCB3aWR0aD0iMTAwJSIgaGVpZ2h0PSIxMDAlIiBmaWxsPSJ1cmwoI2dyaWQpIi8+PC9zdmc+')] opacity-40" />

      <!-- Conteúdo hero -->
      <div class="relative z-10 max-w-5xl mx-auto text-center">

        <!-- Badge -->
        <div class="inline-flex items-center gap-2 px-4 py-2 bg-indigo-500/10 border border-indigo-500/30 text-indigo-300 rounded-full text-xs font-semibold uppercase tracking-widest mb-8 animate-fade-in-down">
          <span class="w-1.5 h-1.5 rounded-full bg-indigo-400 animate-pulse" />
          Gestão de Projetos Ágil — SaaS Brasileiro
        </div>

        <!-- Headline -->
        <h1 class="text-4xl sm:text-6xl lg:text-7xl font-extrabold text-white leading-[1.1] mb-6 animate-fade-in-up">
          Seu time merece uma<br />
          <span class="bg-gradient-to-r from-indigo-400 via-purple-400 to-blue-400 bg-clip-text text-transparent">
            ferramenta de verdade.
          </span>
        </h1>

        <!-- Subtítulo -->
        <p class="text-lg sm:text-xl text-slate-300 max-w-2xl mx-auto mb-10 leading-relaxed animate-fade-in-up animation-delay-200">
          Kanban, Sprints, Backlog, métricas em tempo real e notificações automáticas.
          Tudo em português, com suporte e dados no Brasil.
        </p>

        <!-- CTAs -->
        <div class="flex flex-col sm:flex-row gap-4 justify-center mb-10 animate-fade-in-up animation-delay-400">
          <NuxtLink to="/cadastro"
            class="inline-flex items-center justify-center gap-2 bg-indigo-500 hover:bg-indigo-400 text-white font-bold px-8 py-4 rounded-2xl transition-all duration-300 text-base shadow-lg shadow-indigo-500/30 hover:shadow-indigo-500/50 hover:-translate-y-0.5">
            Começar grátis — 14 dias →
          </NuxtLink>
          <NuxtLink to="/planos"
            class="inline-flex items-center justify-center gap-2 bg-white/10 hover:bg-white/20 text-white font-semibold px-8 py-4 rounded-2xl transition-all duration-300 text-base border border-white/20 hover:border-white/40 backdrop-blur-sm">
            Ver planos e preços
          </NuxtLink>
        </div>

        <!-- Social proof inline -->
        <p class="text-slate-500 text-sm animate-fade-in-up animation-delay-600">
          Sem cartão de crédito · Cancele quando quiser · Dados no Brasil
        </p>

        <!-- Métricas hero -->
        <div class="mt-14 grid grid-cols-3 gap-6 max-w-lg mx-auto animate-fade-in-up animation-delay-600">
          <div>
            <div class="text-2xl sm:text-3xl font-extrabold text-white">{{ c1 }}x</div>
            <div class="text-xs text-slate-400 mt-0.5">mais produtividade</div>
          </div>
          <div class="border-x border-white/10">
            <div class="text-2xl sm:text-3xl font-extrabold text-white">&lt;{{ c2 }}min</div>
            <div class="text-xs text-slate-400 mt-0.5">para começar</div>
          </div>
          <div>
            <div class="text-2xl sm:text-3xl font-extrabold text-white">{{ c3 }}/7</div>
            <div class="text-xs text-slate-400 mt-0.5">disponível</div>
          </div>
        </div>
      </div>

      <!-- Seta scroll -->
      <div class="absolute bottom-8 left-1/2 -translate-x-1/2 animate-bounce opacity-40">
        <svg class="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"/>
        </svg>
      </div>
    </section>

    <!-- ══════════════════════════════════════════════════════════
         PROBLEMA — gancho emocional
    ═══════════════════════════════════════════════════════════ -->
    <section class="py-20 px-4 sm:px-6 bg-white">
      <div class="max-w-4xl mx-auto text-center reveal">
        <p class="text-xs font-bold uppercase tracking-widest text-indigo-500 mb-4">O problema que você conhece bem</p>
        <h2 class="text-3xl sm:text-4xl font-extrabold text-slate-900 leading-tight mb-6">
          Planilha, post-it e reunião que poderia ser um e-mail.<br />
          <span class="text-slate-400 font-normal">Isso custou quanto do seu time este mês?</span>
        </h2>
        <p class="text-slate-500 max-w-2xl mx-auto text-lg">
          Times sem um sistema claro perdem em média <strong class="text-slate-800">30% do tempo</strong> em retrabalho e comunicação ineficiente.
          A Gestão Ágil resolve isso com uma única plataforma.
        </p>
      </div>
    </section>

    <!-- ══════════════════════════════════════════════════════════
         FEATURES — cards com hover
    ═══════════════════════════════════════════════════════════ -->
    <section class="py-20 px-4 sm:px-6 bg-slate-50">
      <div class="max-w-6xl mx-auto">
        <div class="text-center mb-14 reveal">
          <p class="text-xs font-bold uppercase tracking-widest text-indigo-500 mb-3">Funcionalidades</p>
          <h2 class="text-3xl sm:text-4xl font-extrabold text-slate-900 mb-3">Tudo que seu time precisa</h2>
          <p class="text-slate-500 max-w-xl mx-auto">Uma plataforma completa. Sem precisar juntar 5 ferramentas diferentes.</p>
        </div>

        <div class="grid sm:grid-cols-2 lg:grid-cols-3 gap-6">
          <div
            v-for="(f, i) in features"
            :key="f.titulo"
            class="reveal bg-white rounded-2xl border border-slate-100 p-6 hover:border-indigo-200 hover:shadow-lg transition-all duration-300 group cursor-default"
            :style="`animation-delay: ${i * 80}ms`"
          >
            <div class="w-12 h-12 rounded-xl flex items-center justify-center text-2xl mb-4 group-hover:scale-110 transition-transform duration-300"
              :class="f.bg">
              {{ f.icone }}
            </div>
            <h3 class="font-bold text-slate-800 mb-2 text-lg">{{ f.titulo }}</h3>
            <p class="text-sm text-slate-500 leading-relaxed">{{ f.descricao }}</p>
          </div>
        </div>
      </div>
    </section>

    <!-- ══════════════════════════════════════════════════════════
         COMO FUNCIONA — timeline visual
    ═══════════════════════════════════════════════════════════ -->
    <section class="py-20 px-4 sm:px-6 bg-white">
      <div class="max-w-4xl mx-auto">
        <div class="text-center mb-14 reveal">
          <p class="text-xs font-bold uppercase tracking-widest text-indigo-500 mb-3">Simples assim</p>
          <h2 class="text-3xl sm:text-4xl font-extrabold text-slate-900 mb-3">Do cadastro ao primeiro projeto</h2>
          <p class="text-slate-500">Em menos de 10 minutos seu time está funcionando.</p>
        </div>

        <div class="flex flex-col gap-0">
          <div
            v-for="(passo, i) in passos"
            :key="passo.titulo"
            class="reveal flex gap-6 items-start"
          >
            <!-- Linha lateral -->
            <div class="flex flex-col items-center shrink-0">
              <div class="w-10 h-10 rounded-full bg-indigo-500 text-white flex items-center justify-center font-bold text-sm shadow-lg shadow-indigo-200">
                {{ i + 1 }}
              </div>
              <div v-if="i < passos.length - 1" class="w-0.5 h-12 bg-indigo-100 mt-1" />
            </div>
            <!-- Conteúdo -->
            <div class="pb-10">
              <div class="inline-flex items-center gap-2 text-xs font-bold text-indigo-500 uppercase tracking-wide mb-1">
                {{ passo.tempo }}
              </div>
              <h3 class="font-bold text-slate-800 text-lg mb-1">{{ passo.titulo }}</h3>
              <p class="text-slate-500 text-sm leading-relaxed max-w-md">{{ passo.descricao }}</p>
            </div>
          </div>
        </div>
      </div>
    </section>

    <!-- ══════════════════════════════════════════════════════════
         DEPOIMENTOS
    ═══════════════════════════════════════════════════════════ -->
    <section class="py-20 px-4 sm:px-6 bg-slate-900">
      <div class="max-w-5xl mx-auto">
        <div class="text-center mb-14 reveal">
          <p class="text-xs font-bold uppercase tracking-widest text-indigo-400 mb-3">O que os times dizem</p>
          <h2 class="text-3xl font-extrabold text-white mb-3">Resultados reais, times reais</h2>
        </div>

        <div class="grid sm:grid-cols-3 gap-6">
          <div
            v-for="(t, i) in depoimentos"
            :key="t.nome"
            class="reveal bg-white/5 border border-white/10 rounded-2xl p-6 backdrop-blur-sm hover:bg-white/10 transition"
            :style="`animation-delay: ${i * 100}ms`"
          >
            <div class="flex gap-1 mb-4">
              <span v-for="s in 5" :key="s" class="text-amber-400 text-sm">★</span>
            </div>
            <p class="text-slate-300 text-sm leading-relaxed mb-5 italic">"{{ t.texto }}"</p>
            <div class="flex items-center gap-3">
              <div class="w-9 h-9 rounded-full bg-indigo-500 text-white text-sm font-bold flex items-center justify-center">
                {{ t.nome.charAt(0) }}
              </div>
              <div>
                <div class="text-white text-sm font-semibold">{{ t.nome }}</div>
                <div class="text-slate-400 text-xs">{{ t.cargo }}</div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>

    <!-- ══════════════════════════════════════════════════════════
         DIFERENCIAIS vs concorrentes
    ═══════════════════════════════════════════════════════════ -->
    <section class="py-20 px-4 sm:px-6 bg-white">
      <div class="max-w-4xl mx-auto reveal">
        <div class="text-center mb-12">
          <p class="text-xs font-bold uppercase tracking-widest text-indigo-500 mb-3">Por que Gestão Ágil?</p>
          <h2 class="text-3xl font-extrabold text-slate-900">Feito para o mercado brasileiro</h2>
        </div>

        <div class="grid sm:grid-cols-2 gap-4">
          <div v-for="d in diferenciais" :key="d.titulo"
            class="flex gap-4 items-start p-5 rounded-xl bg-slate-50 hover:bg-indigo-50 transition group">
            <div class="w-10 h-10 rounded-xl bg-indigo-100 text-indigo-600 flex items-center justify-center text-xl shrink-0 group-hover:scale-110 transition-transform">
              {{ d.icone }}
            </div>
            <div>
              <h3 class="font-bold text-slate-800 mb-0.5">{{ d.titulo }}</h3>
              <p class="text-sm text-slate-500">{{ d.descricao }}</p>
            </div>
          </div>
        </div>
      </div>
    </section>

    <!-- ══════════════════════════════════════════════════════════
         CTA FINAL — urgência
    ═══════════════════════════════════════════════════════════ -->
    <section class="py-24 px-4 sm:px-6 relative overflow-hidden bg-[#0a0a1a]">
      <div class="absolute -top-20 left-1/4 w-96 h-96 bg-indigo-600/20 rounded-full blur-[80px] animate-blob" />
      <div class="absolute -bottom-20 right-1/4 w-80 h-80 bg-purple-600/20 rounded-full blur-[80px] animate-blob animation-delay-2000" />
      <div class="relative z-10 max-w-2xl mx-auto text-center reveal">
        <h2 class="text-3xl sm:text-4xl font-extrabold text-white mb-4">
          Seu concorrente já está<br />organizado. E você?
        </h2>
        <p class="text-slate-300 mb-10 text-lg">
          14 dias gratuitos. Sem cartão. Cancele quando quiser.
          <br/>Comece agora e sinta a diferença ainda esta semana.
        </p>
        <div class="flex flex-col sm:flex-row gap-4 justify-center">
          <NuxtLink to="/cadastro"
            class="inline-flex items-center justify-center gap-2 bg-indigo-500 hover:bg-indigo-400 text-white font-bold px-10 py-4 rounded-2xl transition-all duration-300 text-lg shadow-xl shadow-indigo-500/30 hover:shadow-indigo-500/50 hover:-translate-y-0.5">
            Criar minha conta grátis →
          </NuxtLink>
          <NuxtLink to="/planos"
            class="inline-flex items-center justify-center gap-2 bg-white/10 hover:bg-white/20 text-white font-semibold px-8 py-4 rounded-2xl transition border border-white/20">
            Ver planos
          </NuxtLink>
        </div>
        <p class="text-slate-500 text-sm mt-6">
          Sem burocracia · Suporte em português · Dados no Brasil
        </p>
      </div>
    </section>

  </div>
</template>

<script setup lang="ts">
definePageMeta({ layout: 'publica' })

// Contadores animados no hero
const c1 = ref(0)
const c2 = ref(0)
const c3 = ref(0)

function animarContadores() {
  const dur = 1200
  const steps = 40
  const interval = dur / steps
  let i = 0
  const timer = setInterval(() => {
    i++
    c1.value = Math.round((10 * i) / steps)
    c2.value = Math.round((5 * i) / steps)
    c3.value = 24
    if (i >= steps) clearInterval(timer)
  }, interval)
}

// Scroll reveal com IntersectionObserver
onMounted(() => {
  animarContadores()

  const observer = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
      if (entry.isIntersecting) {
        entry.target.classList.add('revealed')
        observer.unobserve(entry.target)
      }
    })
  }, { threshold: 0.15 })

  document.querySelectorAll('.reveal').forEach(el => observer.observe(el))
})

const features = [
  { icone: '📌', bg: 'bg-blue-50',   titulo: 'Quadro Kanban',       descricao: 'Arraste e solte tarefas em tempo real. Colunas personalizáveis, WIP limit e colaboração simultânea.' },
  { icone: '🔄', bg: 'bg-indigo-50', titulo: 'Sprints & Backlog',   descricao: 'Planeje iterações curtas, monitore story points e velocity do time com indicadores visuais.' },
  { icone: '📊', bg: 'bg-purple-50', titulo: 'Dashboard & Métricas', descricao: 'Burndown, CFD, lead time e cycle time. Tome decisões com dados, não com achismos.' },
  { icone: '👥', bg: 'bg-green-50',  titulo: 'Gestão de Equipe',    descricao: 'Papéis personalizados, convites por link, permissões granulares e controle de acesso por projeto.' },
  { icone: '🔔', bg: 'bg-amber-50',  titulo: 'Alertas WhatsApp',    descricao: 'Notificações automáticas de vencimento, prazos e atividades diretamente no WhatsApp da equipe.' },
  { icone: '🔒', bg: 'bg-rose-50',   titulo: 'Seguro e Confiável',  descricao: 'Dados isolados por organização, autenticação robusta, backups automáticos e infraestrutura BR.' },
]

const passos = [
  { tempo: 'Minuto 1', titulo: 'Crie sua conta',    descricao: 'Cadastro rápido sem cartão de crédito. Em segundos você já está dentro da plataforma com 14 dias de trial completo.' },
  { tempo: 'Minuto 3', titulo: 'Monte sua equipe',  descricao: 'Convide membros por link, defina papéis (dev, QA, PO, scrum master) e configure os projetos com descrição e status.' },
  { tempo: 'Minuto 10', titulo: 'Entregue mais',    descricao: 'Crie suas primeiras tarefas, abra o Kanban e sua equipe já está alinhada. Dashboard ao vivo mostrando o progresso.' },
]

const depoimentos = [
  {
    nome: 'Rafael Mendes',
    cargo: 'CTO · Startup SaaS',
    texto: 'Mudamos de planilha para o Gestão Ágil e em duas semanas o time estava entregando 40% mais rápido. O Kanban em tempo real fez toda a diferença.',
  },
  {
    nome: 'Ana Cristina',
    cargo: 'Product Owner · Agência Digital',
    texto: 'Finalmente um produto em português, com suporte que responde. Nosso backlog nunca foi tão organizado. Os alertas WhatsApp salvaram vários prazos.',
  },
  {
    nome: 'Lucas Faria',
    cargo: 'Scrum Master · Consultoria',
    texto: 'As métricas de velocity e o burndown chart convenceram o cliente da capacidade do time. Apresentamos dados, não opinião. Renovamos o contrato.',
  },
]

const diferenciais = [
  { icone: '🇧🇷', titulo: 'Totalmente em português',     descricao: 'Interface, suporte e documentação em PT-BR. Sem barreiras de idioma para nenhum membro do time.' },
  { icone: '💰', titulo: 'Preço justo para o Brasil',    descricao: 'Planos acessíveis em reais, sem conversão de câmbio. Pague via PIX, boleto ou cartão.' },
  { icone: '⚡', titulo: 'Configuração em minutos',      descricao: 'Sem treinamento longo. Qualquer membro da equipe aprende a usar em menos de uma hora.' },
  { icone: '🔒', titulo: 'Dados no Brasil',              descricao: 'Infraestrutura na região SA-East. Seus dados não saem do país. Conformidade com a LGPD.' },
]
</script>

<style scoped>
/* ── Blob animation ── */
@keyframes blob {
  0%, 100% { transform: translate(0, 0) scale(1); }
  33%       { transform: translate(30px, -20px) scale(1.1); }
  66%       { transform: translate(-20px, 20px) scale(0.9); }
}
.animate-blob { animation: blob 8s ease-in-out infinite; }
.animation-delay-2000 { animation-delay: 2s; }
.animation-delay-4000 { animation-delay: 4s; }

/* ── Fade-in hero ── */
@keyframes fadeInDown {
  from { opacity: 0; transform: translateY(-16px); }
  to   { opacity: 1; transform: translateY(0); }
}
@keyframes fadeInUp {
  from { opacity: 0; transform: translateY(24px); }
  to   { opacity: 1; transform: translateY(0); }
}
.animate-fade-in-down {
  animation: fadeInDown 0.7s ease both;
}
.animate-fade-in-up {
  animation: fadeInUp 0.7s ease both;
}
.animation-delay-200 { animation-delay: 0.2s; }
.animation-delay-400 { animation-delay: 0.4s; }
.animation-delay-600 { animation-delay: 0.6s; }

/* ── Scroll reveal ── */
.reveal {
  opacity: 0;
  transform: translateY(32px);
  transition: opacity 0.7s ease, transform 0.7s ease;
}
.reveal.revealed {
  opacity: 1;
  transform: translateY(0);
}
</style>
