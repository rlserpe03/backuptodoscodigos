-- ========================================================
-- SISTEMA ESCOLAR TIPO CLASSDOJO - SCHEMA SUPABASE (POSTGRESQL)
-- ========================================================

-- 1. TABELA DE TURMAS
CREATE TABLE IF NOT EXISTS public.turmas (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    serie VARCHAR(50) NOT NULL,
    criado_em TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 2. TABELA DE ALUNOS
CREATE TABLE IF NOT EXISTS public.alunos (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    turma_id UUID REFERENCES public.turmas(id) ON DELETE CASCADE,
    nome VARCHAR(150) NOT NULL,
    avatar_url VARCHAR(255) DEFAULT 'https://api.dicebear.com/7.x/bottts/svg?seed=default',
    pontos INT DEFAULT 0 NOT NULL,
    criado_em TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 3. TABELA DE OCORRÊNCIAS DIÁRIAS / HISTÓRICO
CREATE TABLE IF NOT EXISTS public.ocorrencias (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    aluno_id UUID REFERENCES public.alunos(id) ON DELETE CASCADE NOT NULL,
    tipo VARCHAR(20) CHECK (tipo IN ('positiva', 'negativa', 'neutra')) NOT NULL,
    titulo VARCHAR(100) NOT NULL,
    descricao TEXT,
    pontos_alteracao INT DEFAULT 0 NOT NULL,
    data_ocorrencia TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 4. TABELA DE AVISOS AOS PAIS (MURAL)
CREATE TABLE IF NOT EXISTS public.avisos_pais (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    turma_id UUID REFERENCES public.turmas(id) ON DELETE CASCADE,
    titulo VARCHAR(150) NOT NULL,
    conteudo TEXT NOT NULL,
    urgente BOOLEAN DEFAULT false,
    criado_em TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- POLÍTICAS DE SEGURANÇA (RLS - Permissão de Leitura/Escrita Anon)
ALTER TABLE public.turmas ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.alunos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ocorrencias ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.avisos_pais ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Acesso Publico Turmas" ON public.turmas FOR ALL USING (true);
CREATE POLICY "Acesso Publico Alunos" ON public.alunos FOR ALL USING (true);
CREATE POLICY "Acesso Publico Ocorrencias" ON public.ocorrencias FOR ALL USING (true);
CREATE POLICY "Acesso Publico Avisos" ON public.avisos_pais FOR ALL USING (true);

-- DADOS INICIAIS DE TESTE (DEMO)
INSERT INTO public.turmas (id, nome, serie) VALUES 
('c0a80101-0000-0000-0000-000000000001', '5º Ano A', 'Ensino Fundamental I');

INSERT INTO public.alunos (turma_id, nome, avatar_url, pontos) VALUES
('c0a80101-0000-0000-0000-000000000001', 'Lucas Silva', 'https://api.dicebear.com/7.x/bottts/svg?seed=Lucas', 12),
('c0a80101-0000-0000-0000-000000000001', 'Sophia Oliveira', 'https://api.dicebear.com/7.x/bottts/svg?seed=Sophia', 18),
('c0a80101-0000-0000-0000-000000000001', 'Gabriel Santos', 'https://api.dicebear.com/7.x/bottts/svg?seed=Gabriel', 8),
('c0a80101-0000-0000-0000-000000000001', 'Isabela Lima', 'https://api.dicebear.com/7.x/bottts/svg?seed=Isabela', 15);

INSERT INTO public.avisos_pais (turma_id, titulo, conteudo, urgente) VALUES
('c0a80101-0000-0000-0000-000000000001', 'Reunião de Pais e Mestres', 'Lembramos que nesta quinta-feira às 19h teremos nossa reunião bimestral.', true),
('c0a80101-0000-0000-0000-000000000001', 'Feira de Ciências', 'Os alunos devem trazer os materiais do projeto até sexta-feira.', false);