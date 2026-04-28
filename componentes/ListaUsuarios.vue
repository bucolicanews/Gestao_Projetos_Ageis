<template>
    <div v-if="membros && membros.length > 0" class="divide-y">
        <div v-for="membro in membros" :key="membro.usuario_id"
            class="p-4 flex justify-between items-center hover:bg-slate-50">
            <div class="flex items-center gap-3">
                <div
                    class="w-10 h-10 rounded-full bg-slate-200 flex items-center justify-center font-bold text-slate-500">
                    {{ inicialNome(membro) }}
                </div>

                <div>
                    <p class="text-sm font-semibold">
                        {{ membro.usuarios?.nome }}
                    </p>

                    <p class="text-xs text-slate-500">
                        {{ membro.usuarios?.email }}
                    </p>
                </div>
            </div>

            <div class="flex items-center gap-4">
                <span :class="[
                    'px-2 py-1 text-[10px] font-bold uppercase rounded-md border',
                    classesPapel(membro.papel)
                ]">
                    {{ formatarPapel(membro.papel) }}
                </span>

                <button v-if="membro.usuario_id !== donoId" class="text-slate-400 hover:text-red-500"
                    @click="remover(membro.usuario_id)">
                    🗑️
                </button>
            </div>
        </div>
    </div>

    <div v-else class="p-8 text-center bg-slate-50 rounded-lg border-2 border-dashed border-slate-200">
        <p class="text-slate-500 text-sm italic">
            Nenhum membro vinculado a este projeto ainda.
        </p>
    </div>
</template>

<script lang="ts">
import { defineComponent } from 'vue'

const ROLES_DATA = [
    { id: 1, codigo: 'DESENVOLVEDOR', nome: 'Desenvolvedor Master' },
    { id: 2, codigo: 'ADMIN', nome: 'Administrador' },
    { id: 3, codigo: 'ENGN', nome: 'Engenheiro de Software' },
    { id: 4, codigo: 'GERT', nome: 'Gerente de Projeto' },
    { id: 5, codigo: 'LIDR', nome: 'Líder de Equipe' },
    { id: 6, codigo: 'QUAL', nome: 'Qualidade / QA' },
    { id: 7, codigo: 'DESIG', nome: 'Designer UX/UI' },
    { id: 8, codigo: 'TEST', nome: 'Testador' },
    { id: 9, codigo: 'DEV', nome: 'Desenvolvedor Operacional' }
]

export default defineComponent({
    name: 'ListaUsuarios',

    props: {
        membros: {
            type: Array,
            default: () => []
        },

        donoId: {
            type: String,
            default: ''
        }
    },

    emits: ['remover'],

    methods: {
        remover(usuarioId: string) {
            this.$emit('remover', usuarioId)
        },

        inicialNome(membro: any): string {
            return (
                membro?.usuarios?.nome
                    ?.charAt(0)
                    ?.toUpperCase() || '?'
            )
        },

        formatarPapel(codigo: string): string {
            const role = ROLES_DATA.find(
                (item) => item.codigo === codigo
            )

            return role ? role.nome : codigo
        },

        classesPapel(codigo: string): string {
            const mapa: Record<string, string> = {
                DESENVOLVEDOR:
                    'bg-purple-50 text-purple-700 border-purple-100',

                ADMIN:
                    'bg-blue-50 text-blue-700 border-blue-100',

                ENGN:
                    'bg-cyan-50 text-cyan-700 border-cyan-100',

                GERT:
                    'bg-amber-50 text-amber-700 border-amber-100',

                LIDR:
                    'bg-green-50 text-green-700 border-green-100',

                QUAL:
                    'bg-emerald-50 text-emerald-700 border-emerald-100',

                DESIG:
                    'bg-pink-50 text-pink-700 border-pink-100',

                TEST:
                    'bg-orange-50 text-orange-700 border-orange-100',

                DEV:
                    'bg-slate-50 text-slate-700 border-slate-100'
            }

            return (
                mapa[codigo] ||
                'bg-slate-50 text-slate-700 border-slate-100'
            )
        }
    }
})
</script>