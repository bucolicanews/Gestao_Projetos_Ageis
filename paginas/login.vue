<template>
  <NuxtLayout name="autenticacao">
    <h1 class="text-2xl font-bold mb-1">Entrar</h1>
    <p class="text-slate-500 mb-6">
      Acesse sua conta para gerenciar projetos.
    </p>

    <form @submit.prevent="enviar" class="space-y-4">
      <div>
        <label class="block text-sm font-medium mb-1">E-mail</label>
        <input v-model="email" type="email" required class="w-full px-3 py-2 border rounded-lg" />
      </div>

      <div>
        <label class="block text-sm font-medium mb-1">Senha</label>
        <input v-model="senha" type="password" required class="w-full px-3 py-2 border rounded-lg" />
      </div>

      <p v-if="erro" class="text-perigo text-sm">
        {{ erro }}
      </p>

      <button class="botao-primario w-full justify-center" :disabled="carregando">
        {{ carregando ? 'Entrando...' : 'Entrar' }}
      </button>
    </form>

    <p class="text-sm text-center mt-4">
      Não tem conta?
      <NuxtLink to="/cadastro" class="text-primaria font-medium">
        Cadastre-se
      </NuxtLink>
    </p>
  </NuxtLayout>
</template>

<script lang="ts">
import { defineComponent, nextTick } from 'vue'

definePageMeta({
  layout: false
})

export default defineComponent({
  name: 'PaginaLogin',

  data() {
    return {
      email: '',
      senha: '',
      erro: '',
      carregando: false
    }
  },

  methods: {
    async enviar() {
      const { entrar } = useAutenticacao()
      const router = useRouter()

      this.carregando = true
      this.erro = ''

      try {
        await entrar(this.email, this.senha)

        // pequena pausa para cookie/sessão propagar
        await nextTick()

        await router.push('/')
      } catch (e: any) {
        this.erro = e?.message || 'Erro ao entrar'
      } finally {
        this.carregando = false
      }
    }
  }
})
</script>