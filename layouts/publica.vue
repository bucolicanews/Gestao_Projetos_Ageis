<template>
  <div class="min-h-screen flex flex-col bg-white">
    <!-- Nav -->
    <header class="border-b border-slate-100 sticky top-0 bg-white/95 backdrop-blur z-40">
      <div class="max-w-6xl mx-auto px-6 h-16 flex items-center justify-between">
        <NuxtLink to="/apresentacao" class="flex items-center gap-2">
          <span class="text-xl font-bold text-primaria">Gestão Ágil</span>
          <span class="text-[10px] px-1.5 py-0.5 rounded bg-primaria/10 text-primaria font-semibold uppercase tracking-wide">SaaS</span>
        </NuxtLink>
        <nav class="hidden md:flex items-center gap-6 text-sm font-medium text-slate-600">
          <NuxtLink to="/apresentacao" class="hover:text-primaria transition">Produto</NuxtLink>
          <NuxtLink to="/planos" class="hover:text-primaria transition">Planos</NuxtLink>
        </nav>
        <div class="flex items-center gap-3">
          <NuxtLink to="/login" class="text-sm font-medium text-slate-600 hover:text-primaria transition px-3 py-1.5">
            Entrar
          </NuxtLink>
          <NuxtLink to="/planos" class="botao-primario text-sm px-4 py-2">
            Começar grátis
          </NuxtLink>
        </div>
      </div>
    </header>

    <!-- Content -->
    <main class="flex-1">
      <slot />
    </main>

    <!-- Footer -->
    <footer class="border-t border-slate-100 py-8 text-center text-sm text-slate-400">
      <div class="max-w-6xl mx-auto px-6 flex flex-col md:flex-row items-center justify-between gap-3">
        <span class="font-semibold text-slate-500">Gestão Ágil</span>
        <span>© {{ new Date().getFullYear() }} — Todos os direitos reservados.</span>
        <div class="flex gap-4">
          <NuxtLink to="/login" class="hover:text-slate-600 transition">Entrar</NuxtLink>
          <NuxtLink to="/planos" class="hover:text-slate-600 transition">Planos</NuxtLink>
        </div>
      </div>
    </footer>
  </div>
</template>
