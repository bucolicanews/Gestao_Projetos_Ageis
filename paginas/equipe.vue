<template>
  <div>
    <!-- Header -->
    <div class="mb-6">
      <div class="flex items-center justify-between gap-3">
        <h1 class="text-3xl font-bold">👥 Equipe</h1>
        <button v-if="projetoId && temPermissao('convidar_usuario')" class="botao-secundario text-sm" @click="abrirConvite">✉ Convidar</button>
      </div>
      <p class="text-sm text-slate-500 mt-1">{{ usuarios.length }} usuário{{ usuarios.length !== 1 ? 's' : '' }} cadastrado{{ usuarios.length !== 1 ? 's' : '' }}</p>
      <div class="mt-3">
        <select v-model="projetoId" class="px-3 py-2 border rounded-lg text-sm mx-2 max-w-full">
          <option value="">Todos os projetos</option>
          <option v-for="p in loja.projetos" :key="p.id" :value="p.id">{{ p.nome }}</option>
        </select>
      </div>
    </div>

    <div v-if="carregando" class="text-center py-20 text-slate-400">Carregando...</div>

    <div v-else class="space-y-3">
      <div v-if="!usuarios.length" class="cartao text-center py-12 text-slate-400">
        Nenhum usuário cadastrado.
      </div>

      <div
        v-for="u in usuarios"
        :key="u.id"
        class="cartao"
      >
        <div class="flex flex-wrap items-center gap-4">
          <!-- Avatar -->
          <div class="shrink-0">
            <img v-if="u.avatar_url" :src="u.avatar_url" class="w-12 h-12 rounded-full object-cover" />
            <div
              v-else
              class="w-12 h-12 rounded-full bg-indigo-100 text-indigo-700 font-bold text-lg flex items-center justify-center select-none"
            >
              {{ inicial(u.nome) }}
            </div>
          </div>

          <!-- Info -->
          <div class="flex-1 min-w-0">
            <div class="flex items-center gap-2">
              <span class="font-semibold text-slate-800 truncate">{{ u.nome || '—' }}</span>
              <span v-if="u.bloqueado" class="text-[10px] px-1.5 py-0.5 bg-red-100 text-red-600 rounded font-bold uppercase shrink-0">bloqueado</span>
            </div>
            <div class="text-xs text-slate-500 truncate">{{ u.email }}</div>
          </div>

          <!-- Papel + Ações: linha própria no mobile -->
          <div class="flex items-center justify-between w-full sm:w-auto sm:gap-2">

          <!-- Papel no projeto selecionado -->
          <template v-if="projetoId">
            <span
              v-if="membroDe(u.id)"
              :class="['text-[10px] px-2.5 py-1 rounded-full font-bold uppercase shrink-0', corPapel(membroDe(u.id)!.papel)]"
            >
              {{ nomePapel(membroDe(u.id)!.papel) }}
            </span>
            <span v-else class="text-[10px] px-2.5 py-1 rounded-full bg-slate-100 text-slate-400 font-bold uppercase shrink-0">
              fora do projeto
            </span>
          </template>
          <span v-else class="flex-1" />

          <!-- Ações -->
          <div class="flex items-center gap-1 shrink-0">
            <!-- Adicionar ao projeto (fora do projeto) -->
            <button
              v-if="projetoId && !membroDe(u.id)"
              class="text-xs text-indigo-500 hover:text-indigo-700 px-2 py-1 rounded hover:bg-indigo-50 transition-colors"
              title="Adicionar ao projeto"
              @click="abrirAdicionarAoProjeto(u)"
            >
              + projeto
            </button>

            <!-- Editar -->
            <button
              class="w-8 h-8 flex items-center justify-center rounded hover:bg-slate-100 text-slate-400 hover:text-indigo-600 transition-colors"
              title="Editar usuário"
              @click="abrirEditar(u)"
            >
              ✏
            </button>

            <!-- Gerar link de acesso -->
            <button
              class="w-8 h-8 flex items-center justify-center rounded hover:bg-slate-100 text-slate-400 hover:text-green-600 transition-colors"
              title="Gerar link de acesso"
              @click="gerarLinkAcesso(u)"
            >
              🔗
            </button>

            <!-- Remover do projeto -->
            <button
              v-if="projetoId && membroDe(u.id) && u.id !== donoId"
              class="w-8 h-8 flex items-center justify-center rounded hover:bg-slate-100 text-slate-300 hover:text-red-500 transition-colors"
              title="Remover do projeto"
              @click="confirmarRemoverDoProjeto(u)"
            >
              ×
            </button>

            <!-- Deletar usuário -->
            <button
              class="w-8 h-8 flex items-center justify-center rounded hover:bg-slate-100 text-slate-300 hover:text-red-600 transition-colors"
              title="Deletar usuário"
              @click="confirmarDeletar(u)"
            >
              🗑
            </button>
          </div>
          </div>
        </div>

        <!-- Stats row -->
        <div class="mt-3 pt-3 border-t border-slate-100 flex flex-wrap gap-3">
          <!-- Projetos -->
          <div class="flex items-center gap-1.5">
            <span class="text-xs font-semibold text-slate-600">📁 Projetos:</span>
            <span class="text-xs font-bold text-indigo-600">{{ projetosDeUsuario(u.id) }}</span>
          </div>

          <!-- Tarefas ativas -->
          <div class="flex items-center gap-1.5">
            <span class="text-xs font-semibold text-slate-600">⚡ Ativas:</span>
            <span class="text-xs font-bold text-amber-600">{{ tarefasDe(u.id).ativas }}</span>
          </div>

          <!-- Tarefas concluídas -->
          <div class="flex items-center gap-1.5">
            <span class="text-xs font-semibold text-slate-600">✅ Concluídas:</span>
            <span class="text-xs font-bold text-green-600">{{ tarefasDe(u.id).concluidas }}</span>
          </div>

          <!-- Pontos (se projeto selecionado) -->
          <div v-if="projetoId" class="flex items-center gap-1.5">
            <span class="text-xs font-semibold text-slate-600">🎯 Pontos no projeto:</span>
            <span class="text-xs font-bold text-indigo-600">{{ workloadDe(u.id).pontos }}</span>
          </div>
        </div>
      </div>
    </div>

    <!-- Modal: editar usuário -->
    <div
      v-if="modalEditarAberto"
      class="fixed inset-0 bg-black/40 z-50 flex items-center justify-center p-4"
    >
      <div class="bg-white rounded-xl p-6 w-full max-w-[420px] shadow-xl">
        <h3 class="font-semibold text-slate-800 mb-4">Editar usuário</h3>
        <div class="space-y-3 mb-4">
          <div>
            <label class="text-xs font-semibold text-slate-600 block mb-1">Nome</label>
            <input
              v-model="formEditar.nome"
              type="text"
              class="w-full px-3 py-2 border rounded-lg text-sm focus:outline-none focus:border-indigo-400"
            />
          </div>
          <div>
            <label class="text-xs font-semibold text-slate-600 block mb-1">E-mail</label>
            <input
              v-model="formEditar.email"
              type="email"
              class="w-full px-3 py-2 border rounded-lg text-sm focus:outline-none focus:border-indigo-400"
            />
          </div>
          <div>
            <label class="text-xs font-semibold text-slate-600 block mb-1">Papel (global)</label>
            <select
              v-model="formEditar.perfil"
              class="w-full px-3 py-2 border rounded-lg text-sm focus:outline-none focus:border-indigo-400"
            >
              <option value="">Selecione um papel...</option>
              <option v-for="r in PAPEIS_SISTEMA" :key="r.codigo" :value="r.codigo">{{ r.nome }}</option>
            </select>
          </div>
          <div v-if="projetoId && membroDe(usuarioEditando?.id)">
            <label class="text-xs font-semibold text-slate-600 block mb-1">Papel no projeto</label>
            <select
              v-model="formEditar.papel"
              class="w-full px-3 py-2 border rounded-lg text-sm focus:outline-none focus:border-indigo-400"
            >
              <option value="">Selecione um papel...</option>
              <option v-for="r in papeis" :key="r.id" :value="r.id">{{ r.nome }}</option>
            </select>
          </div>
          <div class="flex items-center justify-between pt-1">
            <div>
              <span class="text-xs font-semibold text-slate-600">Bloquear acesso</span>
              <p class="text-[10px] text-slate-400">Usuário bloqueado não consegue operar no sistema</p>
            </div>
            <button
              type="button"
              :class="[
                'relative inline-flex h-6 w-11 items-center rounded-full transition-colors',
                formEditar.bloqueado ? 'bg-red-500' : 'bg-slate-200'
              ]"
              @click="formEditar.bloqueado = !formEditar.bloqueado"
            >
              <span
                :class="[
                  'inline-block h-4 w-4 transform rounded-full bg-white shadow transition-transform',
                  formEditar.bloqueado ? 'translate-x-6' : 'translate-x-1'
                ]"
              />
            </button>
          </div>
        </div>
        <div class="flex gap-2 justify-end">
          <button class="px-4 py-2 text-sm text-slate-600" @click="modalEditarAberto = false">Cancelar</button>
          <button
            :disabled="salvando"
            class="px-4 py-2 text-sm bg-indigo-600 text-white rounded-lg hover:bg-indigo-700 disabled:opacity-40"
            @click="salvarEdicao"
          >
            {{ salvando ? 'Salvando...' : 'Salvar' }}
          </button>
        </div>
      </div>
    </div>

    <!-- Modal: adicionar ao projeto -->
    <div
      v-if="modalAddAberto"
      class="fixed inset-0 bg-black/40 z-50 flex items-center justify-center p-4"
    >
      <div class="bg-white rounded-xl p-6 w-full max-w-xs shadow-xl">
        <h3 class="font-semibold text-slate-800 mb-1">Adicionar ao projeto</h3>
        <p class="text-sm text-slate-500 mb-4 truncate">{{ usuarioParaAdicionar?.nome }}</p>
        <select
          v-model="papelNovo"
          class="w-full px-3 py-2 border rounded-lg text-sm mb-4 focus:outline-none focus:border-indigo-400"
        >
          <option value="">Selecione um papel...</option>
          <option v-for="r in papeis" :key="r.id" :value="r.id">{{ r.nome }}</option>
        </select>
        <div class="flex gap-2 justify-end">
          <button class="px-4 py-2 text-sm text-slate-600" @click="modalAddAberto = false">Cancelar</button>
          <button
            :disabled="!papelNovo || salvando"
            class="px-4 py-2 text-sm bg-indigo-600 text-white rounded-lg hover:bg-indigo-700 disabled:opacity-40"
            @click="adicionarAoProjeto"
          >
            {{ salvando ? 'Adicionando...' : 'Adicionar' }}
          </button>
        </div>
      </div>
    </div>

    <!-- Modal: convite por e-mail -->
    <div
      v-if="modalConviteAberto"
      class="fixed inset-0 bg-black/40 z-50 flex items-center justify-center p-4"
    >
      <div class="bg-white rounded-xl p-6 w-full max-w-[420px] shadow-xl">
        <h3 class="font-semibold text-slate-800 mb-4">Convidar por e-mail</h3>
        <input
          v-model="nomeConvite"
          type="text"
          placeholder="Nome do convidado (opcional)"
          class="w-full px-3 py-2 border rounded-lg text-sm mb-3 focus:outline-none focus:border-indigo-400"
        />
        <input
          v-model="emailConvite"
          type="email"
          placeholder="email@empresa.com"
          class="w-full px-3 py-2 border rounded-lg text-sm mb-3 focus:outline-none focus:border-indigo-400"
        />
        <select
          v-model="papelConvite"
          class="w-full px-3 py-2 border rounded-lg text-sm mb-4 focus:outline-none focus:border-indigo-400"
        >
          <option value="">Selecione um papel...</option>
          <option v-for="r in papeis" :key="r.id" :value="r.id">{{ r.nome }}</option>
        </select>
        <div v-if="linkConvite" class="p-3 bg-green-50 border border-green-200 rounded-lg mb-4">
          <p class="text-xs font-semibold text-green-700 mb-2">Link gerado:</p>
          <div class="flex gap-2">
            <input :value="linkConvite" readonly class="flex-1 border rounded px-2 py-1 text-xs bg-white" />
            <button class="bg-green-600 text-white px-3 py-1 rounded text-xs hover:bg-green-700" @click="copiarLink">Copiar</button>
          </div>
        </div>
        <div class="flex gap-2 justify-end">
          <button class="px-4 py-2 text-sm text-slate-600" @click="fecharConvite">Fechar</button>
          <button
            :disabled="!emailConvite || !papelConvite || salvando"
            class="px-4 py-2 text-sm bg-indigo-600 text-white rounded-lg hover:bg-indigo-700 disabled:opacity-40"
            @click="gerarConvite"
          >
            {{ salvando ? 'Gerando...' : 'Gerar link' }}
          </button>
        </div>
      </div>
    </div>

    <!-- Modal: link de acesso -->
    <div
      v-if="modalLinkAberto"
      class="fixed inset-0 bg-black/40 z-50 flex items-center justify-center p-4"
    >
      <div class="bg-white rounded-xl p-6 w-full max-w-[420px] shadow-xl">
        <h3 class="font-semibold text-slate-800 mb-1">Link de acesso</h3>
        <p class="text-xs text-slate-500 mb-4">Compartilhe com <strong>{{ emailLink }}</strong></p>
        <div class="flex gap-2 mb-4">
          <input
            :value="linkGerado"
            readonly
            class="flex-1 px-3 py-2 border rounded-lg text-xs bg-slate-50 focus:outline-none"
          />
          <button
            class="px-3 py-2 bg-indigo-600 text-white text-sm rounded-lg hover:bg-indigo-700"
            @click="copiarLinkAcesso"
          >
            Copiar
          </button>
        </div>
        <div class="flex justify-end">
          <button class="px-4 py-2 text-sm text-slate-600" @click="modalLinkAberto = false">Fechar</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, watch, onMounted } from 'vue'
import type { Papel } from '~/servicos/servicoPapeis'

const papeis = ref<Papel[]>([])

// System-level roles: control platform access only
const PAPEIS_SISTEMA = [
  { codigo: 'membro',        nome: 'Membro' },
  { codigo: 'admin',         nome: 'Administrador' },
  { codigo: 'develop_admin', nome: 'Dev Admin' },
]

const COR_TAILWIND = [
  'bg-purple-100 text-purple-700',
  'bg-cyan-100 text-cyan-700',
  'bg-amber-100 text-amber-700',
  'bg-green-100 text-green-700',
  'bg-emerald-100 text-emerald-700',
  'bg-pink-100 text-pink-700',
  'bg-indigo-100 text-indigo-700',
  'bg-orange-100 text-orange-700',
]

const route = useRoute()
const loja = useLojaProjetos()
const cliente = useSupabaseClient()
const svcEquipe = servicoEquipe()
const usuarioAtual = useSupabaseUser()

const minhasPermissoes = computed((): string[] => {
  if (!usuarioAtual.value) return []
  const eu = usuarios.value.find(u => u.id === usuarioAtual.value!.id)
  if (eu?.perfil === 'admin' || eu?.perfil === 'develop_admin') return ['*']
  const membro = membroDe(usuarioAtual.value.id)
  if (!membro?.papel) return []
  const papel = papeis.value.find(p => p.id === membro.papel)
  return papel?.permissoes ?? []
})

function temPermissao(chave: string): boolean {
  const p = minhasPermissoes.value
  return p.includes('*') || p.includes(chave)
}

const projetoId = ref(String(route.query.projeto ?? ''))
const usuarios = ref<any[]>([])
const membros = ref<any[]>([])
const todosOsMembros = ref<any[]>([])  // membros_projeto de TODOS os projetos (para contar projetos por user)
const todasTarefas = ref<any[]>([])    // tarefas de TODOS os projetos (para stats globais)
const tarefasWorkload = ref<any[]>([]) // tarefas do projeto selecionado (pontos)
const carregando = ref(false)
const salvando = ref(false)
const donoId = ref('')

// Modal editar
const modalEditarAberto = ref(false)
const usuarioEditando = ref<any>(null)
const formEditar = ref({ nome: '', email: '', perfil: '', papel: '', bloqueado: false })

// Modal add ao projeto
const modalAddAberto = ref(false)
const usuarioParaAdicionar = ref<any>(null)
const papelNovo = ref('')

// Modal convite
const modalConviteAberto = ref(false)
const emailConvite = ref('')
const nomeConvite  = ref('')
const papelConvite = ref('')
const linkConvite  = ref('')

// ---- helpers ----

function membroDe(usuarioId: string) {
  return membros.value.find(m => m.usuario_id === usuarioId) ?? null
}

function projetosDeUsuario(usuarioId: string) {
  return todosOsMembros.value.filter(m => m.usuario_id === usuarioId).length
}

function tarefasDe(usuarioId: string) {
  const ts = todasTarefas.value.filter(t => t.responsavel_id === usuarioId)
  return {
    ativas: ts.filter(t => t.coluna !== 'concluido').length,
    concluidas: ts.filter(t => t.coluna === 'concluido').length,
  }
}

function workloadDe(usuarioId: string) {
  const ts = tarefasWorkload.value.filter(t => t.responsavel_id === usuarioId)
  return { pontos: ts.reduce((a, t) => a + (t.pontos || 0), 0) }
}

function inicial(nome?: string) {
  return (nome || '?').charAt(0).toUpperCase()
}

function nomePapel(id: string) {
  return papeis.value.find(p => p.id === id)?.nome || id
}

function corPapel(id: string) {
  const idx = papeis.value.findIndex(p => p.id === id)
  return idx >= 0 ? COR_TAILWIND[idx % COR_TAILWIND.length] : 'bg-slate-100 text-slate-600'
}

// ---- carregamento ----

async function carregar() {
  carregando.value = true
  try {
    const [usuariosRes, todosMembroRes, todasTarefasRes] = await Promise.all([
      cliente.from('usuarios').select('id, nome, email, avatar_url, perfil, bloqueado').order('nome'),
      cliente.from('membros_projeto').select('usuario_id, projeto_id'),
      cliente.from('tarefas').select('responsavel_id, coluna, pontos, projeto_id').is('tarefa_pai_id', null),
    ])

    usuarios.value = usuariosRes.data || []
    todosOsMembros.value = todosMembroRes.data || []
    todasTarefas.value = todasTarefasRes.data || []

    if (projetoId.value) {
      const [membrosData, projetoRes] = await Promise.all([
        svcEquipe.listarMembrosPorID(projetoId.value),
        cliente.from('projetos').select('proprietario_id').eq('id', projetoId.value).single(),
      ])
      membros.value = membrosData || []
      donoId.value = projetoRes.data?.proprietario_id || ''
      tarefasWorkload.value = todasTarefasRes.data?.filter(t => t.projeto_id === projetoId.value) || []
    } else {
      membros.value = []
      donoId.value = ''
      tarefasWorkload.value = []
    }
  } finally {
    carregando.value = false
  }
}

// ---- editar ----

function abrirEditar(u: any) {
  usuarioEditando.value = u
  const membro = membroDe(u.id)
  formEditar.value = {
    nome: u.nome || '',
    email: u.email || '',
    perfil: u.perfil || 'desenvolvedor',
    papel: membro?.papel || '',
    bloqueado: u.bloqueado ?? false,
  }
  modalEditarAberto.value = true
}

async function salvarEdicao() {
  if (!usuarioEditando.value) return
  salvando.value = true
  try {
    const { error } = await cliente
      .from('usuarios')
      .update({
        nome: formEditar.value.nome,
        email: formEditar.value.email,
        perfil: formEditar.value.perfil,
        bloqueado: formEditar.value.bloqueado,
      })
      .eq('id', usuarioEditando.value.id)
    if (error) throw error

    // Atualiza papel no projeto se membro
    const membro = membroDe(usuarioEditando.value.id)
    if (membro && formEditar.value.papel && projetoId.value) {
      await cliente
        .from('membros_projeto')
        .update({ papel: formEditar.value.papel })
        .eq('id', membro.id)
      membro.papel = formEditar.value.papel
    }

    // Atualiza lista local
    const u = usuarios.value.find(x => x.id === usuarioEditando.value.id)
    if (u) {
      u.nome = formEditar.value.nome
      u.email = formEditar.value.email
      u.perfil = formEditar.value.perfil
      u.bloqueado = formEditar.value.bloqueado
    }
    modalEditarAberto.value = false
  } catch (e: any) {
    alert(e?.message || 'Erro ao salvar')
  } finally {
    salvando.value = false
  }
}

// ---- deletar ----

async function confirmarDeletar(u: any) {
  if (!confirm(`Deletar ${u.nome}?\nIsso remove o perfil e todos os vínculos de projeto.`)) return
  try {
    const { error } = await cliente.from('usuarios').delete().eq('id', u.id)
    if (error) throw error
    usuarios.value = usuarios.value.filter(x => x.id !== u.id)
  } catch (e: any) {
    alert(e?.message || 'Erro ao deletar')
  }
}

// ---- link de acesso ----

const modalLinkAberto = ref(false)
const linkGerado = ref('')
const emailLink = ref('')

function gerarLinkAcesso(u: any) {
  if (!u.email) { alert('Usuário sem e-mail cadastrado.'); return }
  emailLink.value = u.email
  linkGerado.value = `${window.location.origin}/login?email=${encodeURIComponent(u.email)}`
  modalLinkAberto.value = true
}

function copiarLinkAcesso() {
  navigator.clipboard.writeText(linkGerado.value)
}

// ---- remover do projeto ----

async function confirmarRemoverDoProjeto(u: any) {
  const membro = membroDe(u.id)
  if (!membro) return
  if (!confirm(`Remover ${u.nome} do projeto?`)) return
  try {
    await svcEquipe.removerMembro(membro.id)
    membros.value = membros.value.filter(m => m.id !== membro.id)
  } catch (e: any) {
    alert(e?.message || 'Erro ao remover')
  }
}

// ---- adicionar ao projeto ----

function abrirAdicionarAoProjeto(u: any) {
  usuarioParaAdicionar.value = u
  papelNovo.value = ''
  modalAddAberto.value = true
}

async function adicionarAoProjeto() {
  if (!usuarioParaAdicionar.value || !papelNovo.value) return
  salvando.value = true
  try {
    await svcEquipe.adicionarMembro(projetoId.value, usuarioParaAdicionar.value.id, papelNovo.value)
    membros.value.push({ id: crypto.randomUUID(), usuario_id: usuarioParaAdicionar.value.id, papel: papelNovo.value })
    modalAddAberto.value = false
  } catch (e: any) {
    alert(e?.message || 'Erro ao adicionar')
  } finally {
    salvando.value = false
  }
}

// ---- convite ----

function abrirConvite() {
  emailConvite.value = ''
  nomeConvite.value  = ''
  papelConvite.value = ''
  linkConvite.value  = ''
  modalConviteAberto.value = true
}

function fecharConvite() {
  modalConviteAberto.value = false
}

async function gerarConvite() {
  if (!emailConvite.value || !papelConvite.value) return
  salvando.value = true
  try {
    // Busca nome da org do usuário atual
    const orgData = await servicoOrganizacao().minha()
    const { data, error } = await cliente
      .from('convites_projeto')
      .insert({
        projeto_id:      projetoId.value,
        email:           emailConvite.value,
        papel:           papelConvite.value,
        nome_convidado:  nomeConvite.value || null,
        nome_org:        orgData?.nome || null,
      })
      .select().single()
    if (error) throw error
    const params = new URLSearchParams({ invite: data.token, email: emailConvite.value })
    if (nomeConvite.value) params.set('nome', nomeConvite.value)
    linkConvite.value = `${window.location.origin}/cadastro?${params.toString()}`
  } catch (e: any) {
    alert(e?.message || 'Erro ao gerar convite')
  } finally {
    salvando.value = false
  }
}

function copiarLink() {
  navigator.clipboard.writeText(linkConvite.value)
}

watch(projetoId, carregar)

onMounted(async () => {
  if (!loja.projetos.length) await loja.carregar()
  papeis.value = await servicoPapeis().listar()
  await carregar()
})
</script>
