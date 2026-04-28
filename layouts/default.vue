<template>
  <div class="min-h-screen flex">
    <aside v-if="usuario" class="w-60 bg-white border-r border-slate-200 p-4 hidden md:block">
      <h1 class="text-xl font-bold text-primaria mb-6">Gestão Ágil</h1>
      <nav class="flex flex-col gap-2">
        <NuxtLink to="/" class="hover:text-primaria">📊 Dashboard</NuxtLink>
        <NuxtLink to="/projetos" class="hover:text-primaria">📁 Projetos</NuxtLink>
        <NuxtLink to="/kanban" class="hover:text-primaria">📌 Quadro Kanban</NuxtLink>
        <NuxtLink to="/sprints" class="hover:text-primaria">🔄 Sprints</NuxtLink>
        <NuxtLink to="/equipe" class="hover:text-primaria">👥 Equipe</NuxtLink>
      </nav>
      <button @click="sair" class="botao-secundario mt-8 w-full justify-center">Sair</button>
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

async function sair() {
  await cliente.auth.signOut()
  router.push('/login')
}
</script>
