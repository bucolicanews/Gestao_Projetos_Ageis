<template>
  <div class="min-h-screen flex">
    <aside v-if="usuario" class="w-60 bg-white border-r border-slate-200 p-4 hidden md:flex flex-col">
      <!-- Org info -->
      <div class="mb-5">
        <div class="flex items-center gap-1.5 mb-0.5">
          <span class="text-xs font-bold text-primaria uppercase tracking-wider">Gestão Ágil</span>
          <span v-if="org" class="text-[9px] px-1.5 py-0.5 rounded bg-slate-100 text-slate-500 uppercase font-semibold">
            {{ org.plano }}
          </span>
        </div>
        <div v-if="org" class="text-xs text-slate-600 font-medium truncate" :title="org.nome">{{ org.nome }}</div>
        <div v-if="isAdmin" class="text-[10px] text-indigo-500 font-semibold mt-0.5">👑 Administrador</div>
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
        <NuxtLink to="/papeis" class="flex items-center gap-2 px-3 py-2 rounded-lg hover:bg-slate-100 hover:text-primaria text-sm font-medium transition-colors">
          🎭 Papéis
        </NuxtLink>
      </nav>

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

const org = ref<{ id: string; nome: string; plano: string } | null>(null)
const isAdmin = ref(false)

onMounted(async () => {
  if (!usuario.value) return
  const svc = servicoOrganizacao()
  const [o, perfil] = await Promise.all([svc.minha(), svc.meuPerfil()])
  org.value = o
  isAdmin.value = perfil?.perfil === 'admin'
})

async function sair() {
  await cliente.auth.signOut()
  router.push('/login')
}
</script>
