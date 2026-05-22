-- ============================================================
-- 0011_criar_tabela_perfis.sql — Cria tabela de perfis para substituir enum
-- ============================================================

-- 1) Criar tabela de perfis
CREATE TABLE IF NOT EXISTS public.perfis (
    id SERIAL PRIMARY KEY,
    codigo VARCHAR(20) UNIQUE NOT NULL,
    nome VARCHAR(100) NOT NULL,
    descricao TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2) Inserir os perfis baseados no ROLES_DATA do frontend
INSERT INTO public.perfis (codigo, nome, descricao) VALUES
    ('DESENVOLVEDOR', 'Desenvolvedor Master', 'Desenvolvedor com acesso total ao código e decisões técnicas'),
    ('ADMIN', 'Administrador', 'Acesso administrativo total ao sistema'),
    ('ENGN', 'Engenheiro de Software', 'Engenheiro de software sênior'),
    ('GERT', 'Gerente de Projeto', 'Gerente de projeto responsável por entregas'),
    ('LIDR', 'Líder de Equipe', 'Líder de equipe de desenvolvimento'),
    ('QUAL', 'Qualidade / QA', 'Profissional de qualidade e testes'),
    ('DESIG', 'Designer UX/UI', 'Designer de experiência e interface'),
    ('TEST', 'Testador', 'Analista de testes'),
    ('DEV', 'Desenvolvedor Operacional', 'Desenvolvedor operacional de suporte')
ON CONFLICT (codigo) DO NOTHING;

-- 3) Adicionar coluna de referência nas tabelas
-- Tabela usuarios
ALTER TABLE public.usuarios 
ADD COLUMN IF NOT EXISTS perfil_id INTEGER REFERENCES public.perfis(id);

-- Tabela membros_projeto  
ALTER TABLE public.membros_projeto
ADD COLUMN IF NOT EXISTS perfil_id INTEGER REFERENCES public.perfis(id);

-- Tabela convites_projeto
ALTER TABLE public.convites_projeto
ADD COLUMN IF NOT EXISTS perfil_id INTEGER REFERENCES public.perfis(id);

-- 4) Migrar dados do enum texto para o novo campo perfil_id
-- Para usuarios
UPDATE public.usuarios u
SET perfil_id = p.id
FROM public.perfis p
WHERE p.codigo = u.perfil::text;

-- Para membros_projeto
UPDATE public.membros_projeto m
SET perfil_id = p.id
FROM public.perfis p
WHERE p.codigo = m.papel::text;

-- Para convites_projeto
UPDATE public.convites_projeto c
SET perfil_id = p.id
FROM public.perfis p
WHERE p.codigo = c.papel::text;

-- 5) Remover colunas antigas (opcional - fazer depois de validar)
-- ALTER TABLE public.usuarios DROP COLUMN IF EXISTS perfil;
-- ALTER TABLE public.membros_projeto DROP COLUMN IF EXISTS papel;
-- ALTER TABLE public.convites_projeto DROP COLUMN IF EXISTS papel;

-- 6) Adicionar comentários
COMMENT ON TABLE public.perfis IS 'Tabela de perfis/cargos do sistema. Substitui o enum papel_app.';
COMMENT ON COLUMN public.usuarios.perfil_id IS 'FK para tabela de perfis do sistema.';
COMMENT ON COLUMN public.membros_projeto.perfil_id IS 'FK para tabela de perfis do sistema.';
COMMENT ON COLUMN public.convites_projeto.perfil_id IS 'FK para tabela de perfis do sistema.';

-- 7) Criar índices para performance
CREATE INDEX IF NOT EXISTS idx_usuarios_perfil_id ON public.usuarios(perfil_id);
CREATE INDEX IF NOT EXISTS idx_membros_projeto_perfil_id ON public.membros_projeto(perfil_id);
CREATE INDEX IF NOT EXISTS idx_convites_projeto_perfil_id ON public.convites_projeto(perfil_id);