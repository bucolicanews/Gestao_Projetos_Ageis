
<template>
    <div
        class="bg-white p-3 rounded-lg shadow-sm border border-slate-200 hover:border-primaria transition-colors group relative">
        <!-- EDITAR -->
        <button @click="editar"
            class="absolute top-2 right-2 opacity-0 group-hover:opacity-100 p-1.5 bg-slate-100 rounded-md hover:bg-primaria hover:text-white transition-all z-10">
            ✏️
        </button>

        <!-- SUBTAREFAS -->
        <button @click="irParaSubTarefas"
            class="absolute top-2 right-10 opacity-0 group-hover:opacity-100 p-1.5 bg-slate-100 rounded-md hover:bg-primaria hover:text-white transition-all z-10">
            📋
        </button>

        <h4 class="text-sm font-semibold text-slate-700 pr-20">
            {{ tarefa.titulo }}
        </h4>
    </div>
</template>

<script lang="ts">
import { defineComponent } from 'vue'

export default defineComponent({
    name: 'CartaoTarefa',

    props: {
        tarefa: {
            type: Object,
            required: true
        }
    },

    emits: ['editar'],

    methods: {
        editar() {
            this.$emit('editar', this.tarefa)
        },

        irParaSubTarefas() {
            if (!this.tarefa?.id) return

            this.$router.push({
                name: 'subTarefas',
                params: { tarefaId: this.tarefa.id }
            })
        }
    }
})
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