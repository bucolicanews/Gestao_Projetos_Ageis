<template>
  <div class="min-h-screen flex">
    <aside v-if="usuario" class="w-60 bg-white border-r border-slate-200 p-4 hidden md:flex flex-col">
      <!-- User card -->
      <div class="mb-4 flex items-center gap-2.5">
        <div class="w-9 h-9 rounded-full bg-primaria text-white flex items-center justify-center text-sm font-bold shrink-0 uppercase">
          {{ nomeUsuario.charAt(0) || '?' }}
        </div>
        <div class="min-w-0">
          <div class="text-sm font-semibold text-slate-800 truncate" :title="nomeUsuario">{{ nomeUsuario }}</div>
          <div class="text-[11px] text-slate-500 truncate">{{ labelRoleSidebar }}</div>
        </div>
      </div>

      <!-- Org info -->
      <div class="mb-5 pl-0.5">
        <div class="flex items-center gap-1.5 mb-0.5">
          <span class="text-[11px] font-semibold text-slate-700 truncate" :title="org?.nome">{{ org?.nome || 'Carregando...' }}</span>
          <span v-if="org && !isDevelopAdmin" class="text-[9px] px-1.5 py-0.5 rounded bg-slate-100 text-slate-500 uppercase font-semibold shrink-0">
            {{ org.plano }}
          </span>
        </div>
        <!-- Vencimento do plano -->
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

      <nav class="flex flex-col gap-1">
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

      <!-- Seção Sistema — visível para admins -->
      <ClientOnly>
      <div v-if="isAdmin" class="mt-4 pt-3 border-t border-slate-100">
        <div class="text-[10px] text-slate-400 font-bold uppercase tracking-wider mb-1 px-1">⚙ Sistema</div>
        <nav class="flex flex-col gap-1">
          <NuxtLink to="/papeis" class="flex items-center gap-2 px-3 py-2 rounded-lg hover:bg-slate-100 hover:text-primaria text-sm font-medium transition-colors">
            🎭 Papéis
          </NuxtLink>
          <NuxtLink to="/meu-plano" class="flex items-center gap-2 px-3 py-2 rounded-lg hover:bg-slate-100 hover:text-primaria text-sm font-medium transition-colors">
            📦 Meu Plano
          </NuxtLink>
        </nav>
      </div>
      </ClientOnly>

      <!-- Seção develop_admin — ClientOnly evita hydration mismatch -->
      <ClientOnly>
      <div v-if="isDevelopAdmin" class="mt-4 pt-3 border-t border-slate-100">
        <div class="text-[10px] text-purple-500 font-bold uppercase tracking-wider mb-1 px-1">⚙ Plataforma</div>
        <nav class="flex flex-col gap-1">
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

      <div class="mt-auto pt-4 border-t border-slate-100 flex items-center justify-between">
        <SinoNotificacoes v-if="usuario" />
        <button @click="sair" class="botao-secundario text-sm px-3 py-1.5">Sair</button>
      </div>
    </aside>

    <main class="flex-1 p-6 overflow-auto">
      <slot />
    </main>
  </div>
</template>

<script setup lang="ts">
const usuario = useSupabaseUser()
const cliente = useSupabaseClient()
const router = useRouter()

const org = ref<{ id: string; nome: string; plano: string; status: string; vencimento: string | null; criado_em: string } | null>(null)

function vencimentoEfetivo(o: typeof org.value): string | null {
  if (!o) return null
  if (o.vencimento) return o.vencimento
  // fallback: trial sem vencimento → criado_em + 14 dias
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
const isAdmin = ref(false)
const isDevelopAdmin = ref(false)
const labelRoleSidebar = ref('')
const nomeUsuario = ref('')

onMounted(async () => {
  if (!usuario.value) return
  nomeUsuario.value = usuario.value.user_metadata?.nome || usuario.value.email || ''
  const svc = servicoOrganizacao()
  const [o, perfil] = await Promise.all([svc.minha(), svc.meuPerfil()])
  org.value = o
  isAdmin.value = perfil?.perfil === 'admin'
  isDevelopAdmin.value = perfil?.perfil === 'develop_admin'
  // Custom role name takes priority; fallback to system role label
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
