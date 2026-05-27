<template>
  <NuxtLayout name="autenticacao">
    <!-- Banner de convite -->
    <div v-if="conviteInfo" class="mb-6 rounded-xl border border-indigo-200 bg-indigo-50 p-4">
      <p class="text-xs font-bold text-indigo-400 uppercase tracking-wide mb-1">Convite recebido</p>
      <p class="text-sm font-semibold text-indigo-900">
        {{ conviteInfo.nome_org || 'Uma equipe' }}
      </p>
      <p class="text-xs text-indigo-600 mt-0.5">
        Função: <strong>{{ nomePapel(conviteInfo.perfil) }}</strong>
      </p>
    </div>

    <h1 class="text-2xl font-bold mb-1">
      {{ conviteInfo ? 'Complete seu cadastro' : 'Criar conta' }}
    </h1>
    <p class="text-slate-500 mb-6">
      {{ conviteInfo ? 'Defina sua senha para acessar a plataforma.' : 'Comece a organizar sua equipe agora.' }}
    </p>

    <form @submit.prevent="enviar" class="space-y-4">
      <input v-model="nome" placeholder="Seu nome completo" required
        class="w-full px-3 py-2 border rounded-lg" />

      <input v-model="email" type="email" placeholder="E-mail" required
        class="w-full px-3 py-2 border rounded-lg"
        :readonly="!!conviteInfo" />

      <input v-model="senha" type="password" placeholder="Senha (mín. 6)" minlength="6" required
        class="w-full px-3 py-2 border rounded-lg" />

      <p v-if="erro" class="text-perigo text-sm">{{ erro }}</p>

      <button class="botao-primario w-full justify-center" :disabled="carregando">
        {{ carregando ? 'Criando...' : conviteInfo ? 'Entrar na equipe →' : 'Criar conta' }}
      </button>
    </form>

    <p class="text-sm text-center mt-4">
      Já tem conta?
      <NuxtLink to="/login" class="text-primaria font-medium">Entrar</NuxtLink>
    </p>
  </NuxtLayout>
</template>

<script setup lang="ts">
definePageMeta({ layout: false })

const nomePapelResolvido = ref('')

function nomePapel(p: string) {
  return nomePapelResolvido.value || p
}

const route   = useRoute()
const cliente = useSupabaseClient()
const router  = useRouter()

const nome      = ref('')
const email     = ref('')
const senha     = ref('')
const erro      = ref('')
const carregando = ref(false)
const tokenConvite = ref('')

interface ConviteInfo {
  organizacao_id: string
  projeto_id: string
  perfil: string
  nome_org: string | null
}

const conviteInfo = ref<ConviteInfo | null>(null)

onMounted(async () => {
  if (route.query.email) email.value = String(route.query.email)
  if (route.query.nome)  nome.value  = String(route.query.nome)
  if (route.query.invite) {
    tokenConvite.value = String(route.query.invite)
    // Carrega dados do convite para mostrar banner (anon pode ler)
    const { data } = await cliente
      .from('convites_projeto')
      .select('organizacao_id, projeto_id, papel, nome_convidado, nome_org')
      .eq('token', tokenConvite.value)
      .is('usado_em', null)
      .maybeSingle()
    if (data) {
      conviteInfo.value = {
        organizacao_id: data.organizacao_id,
        projeto_id:     data.projeto_id,
        perfil:         data.papel ?? '',
        nome_org:       data.nome_org,
      }
      if (data.nome_convidado && !nome.value) nome.value = data.nome_convidado
      // Resolve role name: UUID → nome from papeis_projeto
      if (data.papel) {
        const { data: papelData } = await cliente
          .from('papeis_projeto')
          .select('nome')
          .eq('id', data.papel)
          .maybeSingle()
        nomePapelResolvido.value = papelData?.nome || data.papel
      }
    }
  }
})

async function enviar() {
  carregando.value = true
  erro.value = ''
  try {
    const redirect = typeof window !== 'undefined'
      ? `${window.location.origin}/confirmar`
      : undefined

    const metadata: Record<string, string> = { nome: nome.value }
    if (conviteInfo.value) {
      metadata.organizacao_id = conviteInfo.value.organizacao_id
      metadata.projeto_id     = conviteInfo.value.projeto_id
      metadata.perfil         = conviteInfo.value.perfil
    }

    const { error } = await cliente.auth.signUp({
      email: email.value,
      password: senha.value,
      options: { data: metadata, emailRedirectTo: redirect },
    })
    if (error) throw error

    await router.push('/')
  } catch (e: any) {
    erro.value = e?.message || 'Erro'
  } finally {
    carregando.value = false
  }
}
</script>
