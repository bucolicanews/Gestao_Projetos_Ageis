<template>
  <NuxtLayout name="autenticacao">
    <h1 class="text-2xl font-bold mb-1">
      Criar conta
    </h1>

    <p class="text-slate-500 mb-6">
      Comece a organizar sua equipe agora.
    </p>

    <form @submit.prevent="enviar" class="space-y-4">
      <input v-model="nome" placeholder="Nome" required class="w-full px-3 py-2 border rounded-lg" />

      <input v-model="email" type="email" placeholder="E-mail" required class="w-full px-3 py-2 border rounded-lg" />

      <input v-model="senha" type="password" placeholder="Senha (mín. 6)" minlength="6" required
        class="w-full px-3 py-2 border rounded-lg" />

      <p v-if="erro" class="text-perigo text-sm">
        {{ erro }}
      </p>

      <button class="botao-primario w-full justify-center" :disabled="carregando">
        {{ carregando ? 'Criando...' : 'Criar conta' }}
      </button>
    </form>

    <p class="text-sm text-center mt-4">
      Já tem conta?

      <NuxtLink to="/login" class="text-primaria font-medium">
        Entrar
      </NuxtLink>
    </p>
  </NuxtLayout>
</template>

<script lang="ts">
import { defineComponent } from 'vue'

definePageMeta({
  layout: false
})

export default defineComponent({
  name: 'PaginaCadastro',

  data() {
    return {
      nome: '',
      email: '',
      senha: '',
      erro: '',
      carregando: false
    }
  },

  methods: {
    async enviar() {
      const { cadastrar } = useAutenticacao()
      const router = useRouter()

      this.carregando = true
      this.erro = ''

      try {
        await cadastrar(
          this.email,
          this.senha,
          this.nome
        )

        await router.push('/')
      } catch (e: any) {
        this.erro = e?.message || 'Erro'
      } finally {
        this.carregando = false
      }
    }
  }
})
</script>