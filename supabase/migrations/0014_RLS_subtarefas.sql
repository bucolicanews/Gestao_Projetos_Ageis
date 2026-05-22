-- Habilita o sistema de segurança na tabela
ALTER TABLE public.sub_tarefas ENABLE ROW LEVEL SECURITY;

-- POLÍTICA 1: Acesso Total
-- Permite que Administradores e Desenvolvedores Master vejam TUDO
CREATE POLICY "Acesso total por perfil elevado" 
ON public.sub_tarefas
FOR SELECT 
USING (
  EXISTS (
    SELECT 1 FROM public.usuarios 
    WHERE usuarios.id = auth.uid() 
    AND (usuarios.perfil_id = 1 OR usuarios.perfil_id = 2)
  )
);

-- POLÍTICA 2: Acesso Restrito
-- Outros perfis (Designer, QA, etc) só veem se forem os responsáveis ou os criadores
CREATE POLICY "Acesso restrito ao responsavel ou criador" 
ON public.sub_tarefas
FOR SELECT 
USING (
  responsavel_id = auth.uid() OR criado_por = auth.uid()
);