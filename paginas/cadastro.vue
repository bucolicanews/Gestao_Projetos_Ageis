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
      carregando: false,
      tokenConvite: '',
    }
  },

  async mounted() {
    const route = useRoute()
    if (route.query.email) {
      this.email = String(route.query.email)
    }
    if (route.query.invite) {
      this.tokenConvite = String(route.query.invite)
    }
  },

  methods: {
    async resolverConvite(): Promise<{ organizacao_id: string; projeto_id: string; perfil: string } | null> {
      if (!this.tokenConvite) return null
      const cliente = useSupabaseClient()
      // Busca tudo do convite em uma query — sem join em projetos (que exige auth)
      const { data } = await cliente
        .from('convites_projeto')
        .select('organizacao_id, projeto_id, papel')
        .eq('token', this.tokenConvite)
        .is('usado_em', null)
        .single()
      if (!data?.organizacao_id) return null
      return {
        organizacao_id: data.organizacao_id,
        projeto_id: data.projeto_id,
        perfil: data.papel ?? 'desenvolvedor',
      }
    },

    async enviar() {
      const cliente = useSupabaseClient()
      const router = useRouter()

      this.carregando = true
      this.erro = ''

      try {
        const convite = await this.resolverConvite()
        const redirect = typeof window !== 'undefined'
          ? `${window.location.origin}/confirmar`
          : undefined

        const metadata: Record<string, string> = { nome: this.nome }
        if (convite) {
          metadata.organizacao_id = convite.organizacao_id
          metadata.projeto_id     = convite.projeto_id
          metadata.perfil         = convite.perfil
        }

        const { error } = await cliente.auth.signUp({
          email: this.email,
          password: this.senha,
          options: { data: metadata, emailRedirectTo: redirect },
        })
        if (error) throw error

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