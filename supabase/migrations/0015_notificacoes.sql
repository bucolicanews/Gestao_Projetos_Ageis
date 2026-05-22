CREATE TABLE IF NOT EXISTS public.notificacoes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id UUID NOT NULL REFERENCES public.usuarios(id) ON DELETE CASCADE,
    tipo TEXT NOT NULL CHECK (tipo IN ('tarefa_atribuida', 'comentario', 'prazo', 'subtarefa', 'convite', 'geral')),
    titulo TEXT NOT NULL,
    mensagem TEXT,
    lida BOOLEAN DEFAULT false,
    tarefa_id UUID REFERENCES public.tarefas(id) ON DELETE CASCADE,
    projeto_id UUID REFERENCES public.projetos(id) ON DELETE CASCADE,
    criado_em TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_notificacoes_usuario ON public.notificacoes(usuario_id);
CREATE INDEX IF NOT EXISTS idx_notificacoes_lida ON public.notificacoes(usuario_id, lida);

ALTER TABLE public.notificacoes ENABLE ROW LEVEL SECURITY;

-- Usuário só vê suas próprias notificações
CREATE POLICY "usuario_ve_proprias_notificacoes"
    ON public.notificacoes FOR SELECT
    USING (auth.uid() = usuario_id);

-- Usuário pode marcar como lida
CREATE POLICY "usuario_atualiza_proprias_notificacoes"
    ON public.notificacoes FOR UPDATE
    USING (auth.uid() = usuario_id);

-- Qualquer autenticado pode criar (triggers internos e o próprio sistema)
CREATE POLICY "autenticado_cria_notificacao"
    ON public.notificacoes FOR INSERT
    WITH CHECK (auth.role() = 'authenticated');
