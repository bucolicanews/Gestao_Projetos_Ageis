-- 1) Evolução da tabela de tarefas: adicionando campos de detalhe e prazo
ALTER TABLE public.tarefas ADD COLUMN IF NOT EXISTS descricao text;
ALTER TABLE public.tarefas ADD COLUMN IF NOT EXISTS prazo_final timestamptz;
ALTER TABLE public.tarefas ADD COLUMN IF NOT EXISTS anexos jsonb DEFAULT '[]'::jsonb;

-- 2) Criação da tabela de subtarefas
CREATE TABLE IF NOT EXISTS public.subtarefas (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  tarefa_id uuid NOT NULL REFERENCES public.tarefas(id) ON DELETE CASCADE,
  projeto_id uuid NOT NULL REFERENCES public.projetos(id) ON DELETE CASCADE,
  titulo text NOT NULL,
  concluida boolean DEFAULT false,
  responsavel_id uuid REFERENCES public.usuarios(id),
  criado_por uuid DEFAULT auth.uid() REFERENCES public.usuarios(id),
  created_at timestamptz DEFAULT now()
);

-- 3) Habilitar RLS (Segurança de Nível de Linha)
ALTER TABLE public.subtarefas ENABLE ROW LEVEL SECURITY;

-- Política: Membros do projeto podem visualizar as subtarefas
CREATE POLICY "membros_veem_subtarefas" ON public.subtarefas
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.membros_projeto
      WHERE projeto_id = subtarefas.projeto_id 
      AND usuario_id = auth.uid()
    )
  );

-- Política: Membros do projeto podem gerenciar (inserir/editar/apagar) subtarefas
CREATE POLICY "membros_gerenciam_subtarefas" ON public.subtarefas
  FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.membros_projeto
      WHERE projeto_id = subtarefas.projeto_id 
      AND usuario_id = auth.uid()
    )
  );