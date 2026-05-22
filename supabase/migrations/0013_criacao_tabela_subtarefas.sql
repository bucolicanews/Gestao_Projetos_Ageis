CREATE TABLE IF NOT EXISTS public.sub_tarefas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    projeto_id UUID NOT NULL,
    sprint_id UUID,
    tarefa_pai_id UUID NOT NULL,
    titulo TEXT NOT NULL,
    descricao TEXT,
    prioridade public.prioridade_tarefa,
    coluna public.coluna_kanban,
    posicao INTEGER DEFAULT 0,
    pontos INTEGER DEFAULT 0,
    responsavel_id UUID,
    criado_por UUID,
    prazo DATE,
    criado_em TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    atualizado_em TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    entrou_coluna_em TIMESTAMPTZ,
    concluido_em TIMESTAMPTZ,

    -- Chaves Estrangeiras
    CONSTRAINT fk_sub_tarefas_pai FOREIGN KEY (tarefa_pai_id) REFERENCES public.tarefas(id) ON DELETE CASCADE,
    CONSTRAINT fk_sub_tarefas_responsavel FOREIGN KEY (responsavel_id) REFERENCES public.usuarios(id) ON DELETE SET NULL,
    CONSTRAINT fk_sub_tarefas_criador FOREIGN KEY (criado_por) REFERENCES public.usuarios(id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_sub_tarefas_pai_id ON public.sub_tarefas(tarefa_pai_id);