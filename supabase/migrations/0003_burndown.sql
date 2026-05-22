-- Migration para criar a tabela sub_tarefas
CREATE TABLE public.sub_tarefas (
    -- Identificadores Únicos
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    projeto_id UUID NOT NULL,
    sprint_id UUID,
    
    -- Relacionamento com a tarefa principal (tarefa_pai)
    tarefa_pai_id UUID NOT NULL,
    
    -- Campos de Texto
    titulo TEXT NOT NULL,
    descricao TEXT,
    
    -- Enums e Tipos Customizados (conforme sua estrutura de tarefas)
    prioridade public.prioridade_tarefa,
    coluna public.coluna_kanban,
    
    -- Campos Numéricos
    posicao INTEGER DEFAULT 0,
    pontos INTEGER DEFAULT 0,
    
    -- Relacionamentos com a tabela usuarios
    responsavel_id UUID,
    criado_por UUID,
    
    -- Datas e Timestamps
    prazo DATE,
    criado_em TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    atualizado_em TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    entrou_coluna_em TIMESTAMPTZ,
    concluido_em TIMESTAMPTZ,

    -- CONFIGURAÇÃO DAS CHAVES ESTRANGEIRAS (RELACIONAMENTOS)
    
    -- 1. Garante que a tarefa_pai_id aponte para um ID válido na tabela tarefas
    CONSTRAINT fk_sub_tarefas_pai 
        FOREIGN KEY (tarefa_pai_id) 
        REFERENCES public.tarefas(id) 
        ON DELETE CASCADE,

    -- 2. Garante que o responsavel_id aponte para um usuário válido
    CONSTRAINT fk_sub_tarefas_responsavel 
        FOREIGN KEY (responsavel_id) 
        REFERENCES public.usuarios(id) 
        ON DELETE SET NULL,

    -- 3. Garante que o criado_por aponte para um usuário válido
    CONSTRAINT fk_sub_tarefas_criador 
        FOREIGN KEY (criado_por) 
        REFERENCES public.usuarios(id) 
        ON DELETE SET NULL
);

-- Indexação para melhorar a performance de busca por tarefa pai
CREATE INDEX idx_sub_tarefas_pai_id ON public.sub_tarefas(tarefa_pai_id);