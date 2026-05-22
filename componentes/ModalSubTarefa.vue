<template>
    <div v-if="modelValue" class="modal-overlay">
        <div class="modal-content">

            <header class="modal-header">
                <h2>
                    {{ subTarefaParaEditar ? 'Editar Subtarefa' : 'Nova Subtarefa' }}
                </h2>
                <button @click="fechar" class="btn-close">&times;</button>
            </header>

            <form @submit.prevent="salvar">

                <div class="form-group">
                    <label>Título</label>
                    <input v-model="form.titulo" type="text" placeholder="O que precisa ser feito?" required />
                </div>

                <div class="form-group">
                    <label>Descrição</label>
                    <textarea v-model="form.descricao" rows="3"></textarea>
                </div>

                <div class="form-row">
                    <div class="form-group">
                        <label>Prioridade</label>
                        <select v-model="form.prioridade">
                            <option value="baixa">Baixa</option>
                            <option value="media">Média</option>
                            <option value="alta">Alta</option>
                            <option value="urgente">Urgente</option>
                        </select>
                    </div>

                    <div class="form-group">
                        <label>Prazo</label>
                        <input v-model="form.prazo" type="date" />
                    </div>
                </div>

                <div class="form-row">
                    <div class="form-group">
                        <label>Responsável</label>
                        <select v-model="form.responsavel_id">
                            <option value="">— Sem responsável —</option>
                            <option
                                v-for="membro in membros"
                                :key="membro.usuario_id"
                                :value="membro.usuario_id"
                            >
                                {{ membro.usuarios?.nome || membro.usuarios?.email }}
                            </option>
                        </select>
                    </div>

                    <div class="form-group">
                        <label>Pontos</label>
                        <input v-model.number="form.pontos" type="number" min="0" max="100" placeholder="0" />
                    </div>
                </div>

                <footer class="modal-actions">
                    <button type="button" @click="fechar" class="btn-secondary">
                        Cancelar
                    </button>

                    <button type="submit" :disabled="carregando" class="btn-primary">
                        {{ carregando ? 'Salvando...' : 'Salvar Subtarefa' }}
                    </button>
                </footer>

            </form>
        </div>
    </div>
</template>

<script>
import { servicoSubTarefas } from '@/servicos/servicoSubTarefas'
import { servicoEquipe } from '@/servicos/servicoEquipe'

export default {
    props: {
        modelValue: Boolean,
        projetoId: String,
        tarefaPaiId: String,
        subTarefaParaEditar: Object
    },

    data() {
        return {
            carregando: false,
            servico: null,
            membros: [],

            formInicial: {
                titulo: '',
                descricao: '',
                prioridade: 'media',
                prazo: '',
                responsavel_id: '',
                coluna: 'a_fazer',
                posicao: 0,
                pontos: 0
            },

            form: {}
        }
    },

    created() {
        this.servico = servicoSubTarefas()
        this.resetForm()
    },

    mounted() {
        window.addEventListener('keydown', this.handleEsc)
    },

    beforeUnmount() {
        window.removeEventListener('keydown', this.handleEsc)
    },

    watch: {
        async modelValue(aberto) {
            if (aberto) {
                if (this.subTarefaParaEditar) {
                    this.form = { ...this.subTarefaParaEditar }
                } else {
                    this.resetForm()
                }
                await this.carregarMembros()
            }
        }
    },

    methods: {
        resetForm() {
            this.form = { ...this.formInicial }
        },

        fechar() {
            this.$emit('update:modelValue', false)
        },

        handleEsc(e) {
            if (e.key === 'Escape') {
                this.fechar()
            }
        },

        async carregarMembros() {
            try {
                const equipe = servicoEquipe()
                if (this.projetoId) {
                    this.membros = await equipe.listarMembrosPorID(this.projetoId) || []
                } else {
                    this.membros = await equipe.listarMembros() || []
                }
            } catch {
                this.membros = []
            }
        },

        async salvar() {
            try {
                this.carregando = true

                if (this.subTarefaParaEditar) {
                    await this.servico.atualizar(
                        this.subTarefaParaEditar.id,
                        this.form
                    )
                } else {
                    const payload = {
                        ...this.form,
                        projeto_id: this.projetoId,
                        tarefa_pai_id: this.tarefaPaiId
                    }

                    await this.servico.criar(payload)
                }

                this.$emit('sucesso')
                this.fechar()

            } catch (error) {
                alert('Erro ao salvar: ' + error.message)
            } finally {
                this.carregando = false
            }
        }
    }
}
</script>

<style scoped>
.modal-overlay {
    position: fixed;
    inset: 0;
    background: rgba(15, 23, 42, 0.6);
    backdrop-filter: blur(4px);

    display: flex;
    align-items: center;
    justify-content: center;

    z-index: 999;
    padding: 20px;
}

.modal-content {
    background: #fff;
    width: 100%;
    max-width: 520px;
    border-radius: 16px;
    padding: 24px;

    max-height: 90vh;
    overflow-y: auto;

    box-shadow: 0 10px 25px rgba(0, 0, 0, 0.15);
    animation: modalFade 0.25s ease;
}

@keyframes modalFade {
    from {
        opacity: 0;
        transform: translateY(20px);
    }

    to {
        opacity: 1;
        transform: translateY(0);
    }
}

.modal-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 20px;
}

.modal-header h2 {
    font-size: 20px;
    font-weight: 600;
}

.btn-close {
    background: none;
    border: none;
    font-size: 22px;
    cursor: pointer;
    color: #6b7280;
}

.btn-close:hover {
    color: #ef4444;
}

.form-group {
    margin-bottom: 16px;
    display: flex;
    flex-direction: column;
}

.form-group label {
    font-size: 13px;
    margin-bottom: 5px;
}

input,
textarea,
select {
    padding: 10px;
    border-radius: 8px;
    border: 1px solid #d1d5db;
}

input:focus,
textarea:focus,
select:focus {
    outline: none;
    border-color: #4f46e5;
}

.form-row {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 12px;
}

.modal-actions {
    display: flex;
    justify-content: flex-end;
    gap: 10px;
    margin-top: 20px;
}

.btn-primary {
    background: #4f46e5;
    color: white;
    border: none;
    padding: 10px 16px;
    border-radius: 8px;
    cursor: pointer;
}

.btn-primary:hover {
    background: #4338ca;
}

.btn-secondary {
    background: #e5e7eb;
    border: none;
    padding: 10px 16px;
    border-radius: 8px;
    cursor: pointer;
}
</style>