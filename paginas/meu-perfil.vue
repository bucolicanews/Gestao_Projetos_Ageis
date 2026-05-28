<template>
  <div class="max-w-2xl mx-auto space-y-6">
    <div>
      <h1 class="text-2xl font-bold">👤 Meu Perfil</h1>
      <p class="text-sm text-slate-500 mt-0.5">Gerencie seus dados e aparência</p>
    </div>

    <div v-if="carregando" class="cartao py-16 text-center text-slate-400 text-sm">Carregando...</div>

    <template v-else>

      <!-- ── Dados pessoais ── -->
      <div class="cartao space-y-5">
        <h2 class="font-semibold text-base border-b border-slate-100 pb-3">Dados pessoais</h2>

        <!-- Avatar -->
        <div class="flex items-center gap-5">
          <div class="relative shrink-0">
            <div class="w-20 h-20 rounded-full overflow-hidden bg-primaria flex items-center justify-center">
              <img
                v-if="avatarPreview"
                :src="avatarPreview"
                class="w-full h-full object-cover"
                alt="Avatar"
              />
              <span v-else class="text-white text-2xl font-bold uppercase">
                {{ (form.nome || usuario?.email || '?').charAt(0) }}
              </span>
            </div>
            <!-- Overlay de troca -->
            <label
              class="absolute inset-0 rounded-full flex items-center justify-center bg-black/40 text-white text-xs font-semibold opacity-0 hover:opacity-100 cursor-pointer transition-opacity"
              title="Trocar foto"
            >
              📷
              <input type="file" class="hidden" accept="image/*" @change="selecionarAvatar" />
            </label>
          </div>
          <div class="min-w-0">
            <p class="text-sm font-medium text-slate-700">Foto de perfil</p>
            <p class="text-xs text-slate-400 mt-0.5">JPG, PNG ou WebP · máx 2 MB</p>
            <button
              v-if="arquivoAvatar"
              class="mt-2 text-xs text-primaria hover:underline"
              :disabled="salvandoAvatar"
              @click="salvarAvatar"
            >
              {{ salvandoAvatar ? 'Salvando...' : '✓ Salvar foto' }}
            </button>
          </div>
        </div>

        <!-- Nome -->
        <div>
          <label class="text-sm font-medium text-slate-700 block mb-1">Nome</label>
          <input
            v-model="form.nome"
            type="text"
            class="w-full border border-slate-200 rounded-xl px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-primaria"
          />
        </div>

        <!-- Email (readonly) -->
        <div>
          <label class="text-sm font-medium text-slate-700 block mb-1">E-mail</label>
          <input
            :value="usuario?.email"
            type="email"
            readonly
            class="w-full border border-slate-100 rounded-xl px-3 py-2 text-sm bg-slate-50 text-slate-400 cursor-not-allowed"
          />
          <p class="text-xs text-slate-400 mt-1">O e-mail não pode ser alterado aqui.</p>
        </div>

        <!-- Feedback -->
        <div v-if="feedbackPerfil" class="p-3 rounded-xl text-sm flex items-center gap-2"
          :class="feedbackPerfil.tipo === 'sucesso' ? 'bg-green-50 border border-green-200 text-green-700' : 'bg-red-50 border border-red-200 text-red-600'">
          <span>{{ feedbackPerfil.tipo === 'sucesso' ? '✓' : '✕' }}</span>
          {{ feedbackPerfil.msg }}
        </div>

        <div class="flex justify-end">
          <button
            class="botao-primario text-sm px-6"
            :disabled="salvandoPerfil"
            @click="salvarPerfil"
          >
            {{ salvandoPerfil ? 'Salvando...' : 'Salvar dados' }}
          </button>
        </div>
      </div>

      <!-- ── Organização (só admin) ── -->
      <div v-if="isAdmin" class="cartao space-y-5">
        <h2 class="font-semibold text-base border-b border-slate-100 pb-3">Organização</h2>

        <!-- Logo -->
        <div class="flex items-center gap-5">
          <div class="relative shrink-0">
            <div class="w-20 h-20 rounded-xl overflow-hidden bg-slate-100 border border-slate-200 flex items-center justify-center">
              <img
                v-if="logoPreview"
                :src="logoPreview"
                class="w-full h-full object-contain p-1"
                alt="Logo"
              />
              <span v-else class="text-slate-400 text-3xl">🏢</span>
            </div>
            <label
              class="absolute inset-0 rounded-xl flex items-center justify-center bg-black/40 text-white text-xs font-semibold opacity-0 hover:opacity-100 cursor-pointer transition-opacity"
              title="Trocar logo"
            >
              📷
              <input type="file" class="hidden" accept="image/*" @change="selecionarLogo" />
            </label>
          </div>
          <div class="min-w-0">
            <p class="text-sm font-medium text-slate-700">Logo da organização</p>
            <p class="text-xs text-slate-400 mt-0.5">JPG, PNG, WebP ou SVG · máx 2 MB</p>
            <button
              v-if="arquivoLogo"
              class="mt-2 text-xs text-primaria hover:underline"
              :disabled="salvandoLogo"
              @click="salvarLogo"
            >
              {{ salvandoLogo ? 'Salvando...' : '✓ Salvar logo' }}
            </button>
          </div>
        </div>

        <!-- Nome da org -->
        <div>
          <label class="text-sm font-medium text-slate-700 block mb-1">Nome da organização</label>
          <input
            v-model="formOrg.nome"
            type="text"
            class="w-full border border-slate-200 rounded-xl px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-primaria"
          />
        </div>

        <!-- Feedback org -->
        <div v-if="feedbackOrg" class="p-3 rounded-xl text-sm flex items-center gap-2"
          :class="feedbackOrg.tipo === 'sucesso' ? 'bg-green-50 border border-green-200 text-green-700' : 'bg-red-50 border border-red-200 text-red-600'">
          <span>{{ feedbackOrg.tipo === 'sucesso' ? '✓' : '✕' }}</span>
          {{ feedbackOrg.msg }}
        </div>

        <div class="flex justify-end">
          <button
            class="botao-primario text-sm px-6"
            :disabled="salvandoOrg"
            @click="salvarOrg"
          >
            {{ salvandoOrg ? 'Salvando...' : 'Salvar organização' }}
          </button>
        </div>
      </div>

    </template>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ layout: 'default' })

const cliente  = useSupabaseClient()
const usuario  = useSupabaseUser()
const upload   = useUploadImagem()
const svcOrg   = servicoOrganizacao()

const carregando    = ref(true)
const isAdmin       = ref(false)
const orgId         = ref<string | null>(null)

const form     = reactive({ nome: '' })
const formOrg  = reactive({ nome: '' })

const avatarPreview  = ref<string | null>(null)
const logoPreview    = ref<string | null>(null)
const arquivoAvatar  = ref<File | null>(null)
const arquivoLogo    = ref<File | null>(null)

const salvandoPerfil = ref(false)
const salvandoAvatar = ref(false)
const salvandoOrg    = ref(false)
const salvandoLogo   = ref(false)

type Feedback = { tipo: 'sucesso' | 'erro'; msg: string }
const feedbackPerfil = ref<Feedback | null>(null)
const feedbackOrg    = ref<Feedback | null>(null)

function mostrarFeedback(ref: Ref<Feedback | null>, tipo: 'sucesso' | 'erro', msg: string) {
  ref.value = { tipo, msg }
  setTimeout(() => { ref.value = null }, 4000)
}

onMounted(async () => {
  if (!usuario.value) return
  try {
    const [dadosUsuario, perfil, org] = await Promise.all([
      cliente.from('usuarios').select('nome, avatar_url').eq('id', usuario.value.id).single(),
      svcOrg.meuPerfil(),
      svcOrg.minha(),
    ])

    form.nome = dadosUsuario.data?.nome || usuario.value.user_metadata?.nome || ''
    avatarPreview.value = dadosUsuario.data?.avatar_url || null
    isAdmin.value = perfil?.perfil === 'admin'
    orgId.value = org?.id || null

    if (org) {
      formOrg.nome = org.nome
      const { data: orgData } = await cliente.from('organizacoes').select('logo_url').eq('id', org.id).single()
      logoPreview.value = (orgData as any)?.logo_url || null
    }
  } finally {
    carregando.value = false
  }
})

function selecionarAvatar(e: Event) {
  const file = (e.target as HTMLInputElement).files?.[0]
  if (!file) return
  arquivoAvatar.value = file
  avatarPreview.value = URL.createObjectURL(file)
}

function selecionarLogo(e: Event) {
  const file = (e.target as HTMLInputElement).files?.[0]
  if (!file) return
  arquivoLogo.value = file
  logoPreview.value = URL.createObjectURL(file)
}

async function salvarAvatar() {
  if (!arquivoAvatar.value || !usuario.value) return
  salvandoAvatar.value = true
  try {
    const url = await upload.uploadAvatar(usuario.value.id, arquivoAvatar.value)
    await cliente.from('usuarios').update({ avatar_url: url }).eq('id', usuario.value.id)
    avatarPreview.value = url
    arquivoAvatar.value = null
    mostrarFeedback(feedbackPerfil, 'sucesso', 'Foto atualizada.')
  } catch (e: any) {
    mostrarFeedback(feedbackPerfil, 'erro', e.message || 'Erro ao salvar foto.')
  } finally {
    salvandoAvatar.value = false
  }
}

async function salvarPerfil() {
  if (!usuario.value) return
  salvandoPerfil.value = true
  try {
    await Promise.all([
      cliente.from('usuarios').update({ nome: form.nome }).eq('id', usuario.value.id),
      cliente.auth.updateUser({ data: { nome: form.nome } }),
    ])
    mostrarFeedback(feedbackPerfil, 'sucesso', 'Dados salvos com sucesso.')
  } catch (e: any) {
    mostrarFeedback(feedbackPerfil, 'erro', e.message || 'Erro ao salvar.')
  } finally {
    salvandoPerfil.value = false
  }
}

async function salvarLogo() {
  if (!arquivoLogo.value || !orgId.value) return
  salvandoLogo.value = true
  try {
    const url = await upload.uploadLogo(orgId.value, arquivoLogo.value)
    await cliente.from('organizacoes').update({ logo_url: url }).eq('id', orgId.value)
    logoPreview.value = url
    arquivoLogo.value = null
    mostrarFeedback(feedbackOrg, 'sucesso', 'Logo atualizada.')
  } catch (e: any) {
    mostrarFeedback(feedbackOrg, 'erro', e.message || 'Erro ao salvar logo.')
  } finally {
    salvandoLogo.value = false
  }
}

async function salvarOrg() {
  if (!orgId.value) return
  salvandoOrg.value = true
  try {
    await cliente.from('organizacoes').update({ nome: formOrg.nome }).eq('id', orgId.value)
    mostrarFeedback(feedbackOrg, 'sucesso', 'Organização atualizada.')
  } catch (e: any) {
    mostrarFeedback(feedbackOrg, 'erro', e.message || 'Erro ao salvar.')
  } finally {
    salvandoOrg.value = false
  }
}
</script>
