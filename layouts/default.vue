<template>
  <div class="min-h-screen flex flex-col">

    <!-- ── Barra superior — sempre visível ── -->
    <header v-if="usuario" class="sticky top-0 z-30 flex items-center justify-between px-4 py-2 bg-white border-b border-slate-200 shrink-0">
      <!-- Identidade na barra superior -->
      <div class="flex items-center gap-3">
        <!-- Mobile: nome do app -->
        <span class="font-bold text-primaria text-base md:hidden">Gestão Ágil</span>

        <!-- Desktop: admin → logo + nome da org | usuário → avatar + nome -->
        <div class="hidden md:flex items-center gap-2">
          <template v-if="isAdmin || isDevelopAdmin">
            <!-- Logo da organização (admin) -->
            <div class="w-7 h-7 rounded-lg overflow-hidden bg-slate-100 border border-slate-200 flex items-center justify-center shrink-0">
              <img v-if="logoUrl" :src="logoUrl" class="w-full h-full object-contain p-0.5" alt="" />
              <span v-else class="text-slate-400 text-xs">🏢</span>
            </div>
            <span class="text-sm font-semibold text-slate-700 truncate max-w-[160px]">{{ org?.nome || nomeUsuario }}</span>
          </template>
          <template v-else>
            <!-- Avatar do usuário comum -->
            <div class="w-7 h-7 rounded-full overflow-hidden bg-primaria text-white flex items-center justify-center text-xs font-bold uppercase shrink-0">
              <img v-if="avatarUrl" :src="avatarUrl" class="w-full h-full object-cover" alt="" />
              <span v-else>{{ nomeUsuario.charAt(0) || '?' }}</span>
            </div>
            <span class="text-sm font-semibold text-slate-700 truncate max-w-[160px]">{{ nomeUsuario }}</span>
          </template>
        </div>
      </div>

      <!-- Ações -->
      <div class="flex items-center gap-1">
        <!-- Sino — sempre na barra superior -->
        <SinoNotificacoes v-if="usuario" />
        <!-- Hamburger — só mobile -->
        <button
          class="md:hidden w-10 h-10 flex items-center justify-center rounded-lg hover:bg-slate-100 text-slate-600 text-xl"
          @click="menuMobileAberto = true"
        >
          ☰
        </button>
      </div>
    </header>

    <!-- ── Conteúdo principal ── -->
    <div class="flex flex-1 overflow-hidden">

      <!-- Backdrop mobile -->
      <div
        v-if="menuMobileAberto"
        class="fixed inset-0 bg-black/40 z-40 md:hidden"
        @click="menuMobileAberto = false"
      />

      <!-- Sidebar -->
      <aside
        v-if="usuario"
        class="fixed inset-y-0 left-0 z-50 w-64 md:relative md:w-60 md:z-auto bg-white border-r border-slate-200 p-4 flex flex-col transition-transform duration-300 overflow-y-auto shrink-0"
        :class="menuMobileAberto ? 'translate-x-0' : '-translate-x-full md:translate-x-0'"
      >
        <!-- Header mobile (dentro do drawer) -->
        <div class="flex items-center justify-between mb-4 md:hidden">
          <span class="font-bold text-primaria">Gestão Ágil</span>
          <button
            class="w-8 h-8 flex items-center justify-center rounded hover:bg-slate-100 text-slate-500"
            @click="menuMobileAberto = false"
          >
            ✕
          </button>
        </div>

        <!-- User card -->
        <NuxtLink to="/meu-perfil" class="mb-4 flex items-center gap-2.5 rounded-xl p-1.5 -mx-1.5 hover:bg-slate-100 transition group" @click="menuMobileAberto = false">
          <div class="w-9 h-9 rounded-full overflow-hidden bg-primaria text-white flex items-center justify-center text-sm font-bold shrink-0 uppercase">
            <img v-if="avatarUrl" :src="avatarUrl" class="w-full h-full object-cover" alt="" />
            <span v-else>{{ nomeUsuario.charAt(0) || '?' }}</span>
          </div>
          <div class="min-w-0 flex-1">
            <div class="text-sm font-semibold text-slate-800 truncate group-hover:text-primaria transition" :title="nomeUsuario">{{ nomeUsuario }}</div>
            <div class="text-[11px] text-slate-500 truncate">{{ labelRoleSidebar }}</div>
          </div>
          <span class="text-slate-300 text-xs group-hover:text-primaria transition shrink-0">✏️</span>
        </NuxtLink>

        <!-- Org info -->
        <div class="mb-5 pl-0.5">
          <div class="flex items-center gap-1.5 mb-0.5">
            <img v-if="logoUrl" :src="logoUrl" class="w-4 h-4 rounded object-contain" alt="" />
            <span class="text-[11px] font-semibold text-slate-700 truncate" :title="org?.nome">{{ org?.nome || 'Carregando...' }}</span>
            <span v-if="org && !isDevelopAdmin" class="text-[9px] px-1.5 py-0.5 rounded bg-slate-100 text-slate-500 uppercase font-semibold shrink-0">
              {{ org.plano }}
            </span>
          </div>
          <div v-if="vencimentoEfetivo(org) && !isDevelopAdmin" class="mt-1">
            <span
              class="text-[10px] font-medium px-1.5 py-0.5 rounded"
              :class="org!.status === 'trial'
                ? 'bg-amber-50 text-amber-600'
                : vencendoEmBreve(vencimentoEfetivo(org)!)
                  ? 'bg-red-50 text-red-600'
                  : 'bg-slate-100 text-slate-500'"
            >
              {{ org!.status === 'trial' ? 'Trial' : 'Ativo' }} até {{ formatarVencimento(vencimentoEfetivo(org)) }}
            </span>
          </div>
        </div>

        <nav class="flex flex-col gap-1" @click="menuMobileAberto = false">
          <NuxtLink to="/" class="flex items-center gap-2 px-3 py-2 rounded-lg hover:bg-slate-100 hover:text-primaria text-sm font-medium transition-colors">
            📊 Dashboard
          </NuxtLink>
          <NuxtLink to="/projetos" class="flex items-center gap-2 px-3 py-2 rounded-lg hover:bg-slate-100 hover:text-primaria text-sm font-medium transition-colors">
            📁 Projetos
          </NuxtLink>
          <NuxtLink to="/kanban" class="flex items-center gap-2 px-3 py-2 rounded-lg hover:bg-slate-100 hover:text-primaria text-sm font-medium transition-colors">
            📌 Quadro Kanban
          </NuxtLink>
          <NuxtLink to="/backlog" class="flex items-center gap-2 px-3 py-2 rounded-lg hover:bg-slate-100 hover:text-primaria text-sm font-medium transition-colors">
            📋 Backlog
          </NuxtLink>
          <NuxtLink to="/sprints" class="flex items-center gap-2 px-3 py-2 rounded-lg hover:bg-slate-100 hover:text-primaria text-sm font-medium transition-colors">
            🔄 Sprints
          </NuxtLink>
          <NuxtLink to="/equipe" class="flex items-center gap-2 px-3 py-2 rounded-lg hover:bg-slate-100 hover:text-primaria text-sm font-medium transition-colors">
            👥 Equipe
          </NuxtLink>
        </nav>

        <!-- Seção Sistema — admins -->
        <ClientOnly>
        <div v-if="isAdmin" class="mt-4 pt-3 border-t border-slate-100">
          <div class="text-[10px] text-slate-400 font-bold uppercase tracking-wider mb-1 px-1">⚙ Sistema</div>
          <nav class="flex flex-col gap-1" @click="menuMobileAberto = false">
            <NuxtLink to="/papeis" class="flex items-center gap-2 px-3 py-2 rounded-lg hover:bg-slate-100 hover:text-primaria text-sm font-medium transition-colors">
              🎭 Papéis
            </NuxtLink>
            <NuxtLink to="/meu-plano" class="flex items-center gap-2 px-3 py-2 rounded-lg hover:bg-slate-100 hover:text-primaria text-sm font-medium transition-colors">
              📦 Meu Plano
            </NuxtLink>
          </nav>
        </div>
        </ClientOnly>

        <!-- Seção develop_admin -->
        <ClientOnly>
        <div v-if="isDevelopAdmin" class="mt-4 pt-3 border-t border-slate-100">
          <div class="text-[10px] text-purple-500 font-bold uppercase tracking-wider mb-1 px-1">⚙ Plataforma</div>
          <nav class="flex flex-col gap-1" @click="menuMobileAberto = false">
            <NuxtLink to="/develop/financeiro" class="flex items-center gap-2 px-3 py-2 rounded-lg hover:bg-purple-50 hover:text-purple-700 text-sm font-medium transition-colors text-slate-600">
              💰 Financeiro
            </NuxtLink>
            <NuxtLink to="/develop/pagamentos" class="flex items-center gap-2 px-3 py-2 rounded-lg hover:bg-purple-50 hover:text-purple-700 text-sm font-medium transition-colors text-slate-600">
              💳 Pagamentos
            </NuxtLink>
            <NuxtLink to="/develop/organizacoes" class="flex items-center gap-2 px-3 py-2 rounded-lg hover:bg-purple-50 hover:text-purple-700 text-sm font-medium transition-colors text-slate-600">
              🏢 Organizações
            </NuxtLink>
            <NuxtLink to="/develop/planos" class="flex items-center gap-2 px-3 py-2 rounded-lg hover:bg-purple-50 hover:text-purple-700 text-sm font-medium transition-colors text-slate-600">
              📦 Planos
            </NuxtLink>
            <NuxtLink to="/develop/notificacoes" class="flex items-center gap-2 px-3 py-2 rounded-lg hover:bg-purple-50 hover:text-purple-700 text-sm font-medium transition-colors text-slate-600">
              🔔 Notificações
            </NuxtLink>
            <NuxtLink to="/develop/configuracoes" class="flex items-center gap-2 px-3 py-2 rounded-lg hover:bg-purple-50 hover:text-purple-700 text-sm font-medium transition-colors text-slate-600">
              🔧 Configurações
            </NuxtLink>
          </nav>
        </div>
        </ClientOnly>

        <div class="mt-auto pt-4 border-t border-slate-100">
          <button @click="sair" class="botao-secundario text-sm px-3 py-1.5 w-full justify-center">Sair</button>
        </div>
      </aside>

      <!-- Main -->
      <main class="flex-1 p-3 md:p-6 overflow-y-auto overflow-x-hidden min-w-0 max-w-full break-words">
        <slot />
      </main>
    </div>
  </div>
</template>

<script setup lang="ts">
const usuario = useSupabaseUser()
const cliente = useSupabaseClient()
const router  = useRouter()

const menuMobileAberto = ref(false)
const org = ref<{ id: string; nome: string; plano: string; status: string; vencimento: string | null; criado_em: string } | null>(null)

function vencimentoEfetivo(o: typeof org.value): string | null {
  if (!o) return null
  if (o.vencimento) return o.vencimento
  if (o.status === 'trial') {
    const d = new Date(o.criado_em)
    d.setDate(d.getDate() + 14)
    return d.toISOString().split('T')[0]
  }
  return null
}

function formatarVencimento(v: string | null): string {
  if (!v) return ''
  const [ano, mes, dia] = v.split('-')
  return `${dia}/${mes}/${ano}`
}

function vencendoEmBreve(v: string): boolean {
  const dias = Math.ceil((new Date(v).getTime() - Date.now()) / 86_400_000)
  return dias <= 7
}

const isAdmin        = ref(false)
const isDevelopAdmin = ref(false)
const labelRoleSidebar = ref('')
const nomeUsuario    = ref('')
const avatarUrl      = ref<string | null>(null)
const logoUrl        = ref<string | null>(null)

onMounted(async () => {
  if (!usuario.value) return
  nomeUsuario.value = usuario.value.user_metadata?.nome || usuario.value.email || ''
  const svc = servicoOrganizacao()
  const [o, perfil, dadosUser] = await Promise.all([
    svc.minha(),
    svc.meuPerfil(),
    cliente.from('usuarios').select('avatar_url').eq('id', usuario.value.id).single(),
  ])
  org.value = o
  isAdmin.value = perfil?.perfil === 'admin'
  isDevelopAdmin.value = perfil?.perfil === 'develop_admin'
  avatarUrl.value = (dadosUser.data as any)?.avatar_url || null

  if (o?.id) {
    const { data: orgData } = await cliente.from('organizacoes').select('logo_url').eq('id', o.id).single()
    logoUrl.value = (orgData as any)?.logo_url || null
  }

  if (perfil?.nomePapel) {
    labelRoleSidebar.value = perfil.nomePapel
  } else if (perfil?.perfil === 'admin') {
    labelRoleSidebar.value = 'Administrador'
  } else if (perfil?.perfil === 'develop_admin') {
    labelRoleSidebar.value = 'Dev Admin'
  } else {
    labelRoleSidebar.value = 'Membro'
  }
})

async function sair() {
  await cliente.auth.signOut()
  router.push('/login')
}
</script>
