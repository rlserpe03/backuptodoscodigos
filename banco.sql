-- 1. TABELA DE PERFIS (Conectada ao Auth do Supabase)
CREATE TABLE public.profiles (
    id UUID REFERENCES auth.users ON DELETE CASCADE PRIMARY KEY,
    name TEXT NOT NULL,
    role TEXT CHECK (role IN ('admin', 'teacher')) DEFAULT 'teacher',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- 2. TABELA DE PROFESSORES
CREATE TABLE public.teachers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    profile_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    full_name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    subject TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- 3. TABELA DE ALUNOS
CREATE TABLE public.students (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    full_name TEXT NOT NULL,
    registration_number TEXT UNIQUE,
    grade_level TEXT,
    total_points INT DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- 4. TABELA DE PRODUTOS
CREATE TABLE public.products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    description TEXT,
    quantity INT DEFAULT 0 CHECK (quantity >= 0),
    point_cost INT DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- 5. TABELA DE REGISTO DE PONTOS
CREATE TABLE public.points_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID REFERENCES public.students(id) ON DELETE CASCADE NOT NULL,
    teacher_id UUID REFERENCES public.teachers(id) ON DELETE SET NULL,
    points_change INT NOT NULL,
    reason TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- 6. TABELA DE OCORRÊNCIAS
CREATE TABLE public.incidents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID REFERENCES public.students(id) ON DELETE CASCADE NOT NULL,
    teacher_id UUID REFERENCES public.teachers(id) ON DELETE SET NULL,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    severity TEXT CHECK (severity IN ('low', 'medium', 'high')) DEFAULT 'low',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- 7. AUTOMATIZAÇÃO: Atualizar o saldo de pontos do aluno
CREATE OR REPLACE FUNCTION update_student_points()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE public.students
    SET total_points = total_points + NEW.points_change
    WHERE id = NEW.student_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_student_points
AFTER INSERT ON public.points_log
FOR EACH ROW
EXECUTE FUNCTION update_student_points();



-- ==============================================================================
-- DEU ERRO E DROPEI TUDO
-- SCRIPT PARA APAGAR TODAS AS TABELAS E OBJETOS DO ESQUEMA PUBLIC
-- ==============================================================================

-- 1. ELIMINAR O ESQUEMA PUBLIC E TUDO DENTRO DELE
-- O comando CASCADE força a exclusão de todas as tabelas, funções e gatilhos associados.
DROP SCHEMA public CASCADE;

-- 2. RECRIAR O ESQUEMA PUBLIC VAZIO
CREATE SCHEMA public;

-- 3. RESTAURAR AS PERMISSÕES PADRÃO DO SUPABASE
-- Concede permissões para as funções internas do Supabase (postgres, anon, authenticated, service_role)
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO anon;
GRANT ALL ON SCHEMA public TO authenticated;
GRANT ALL ON SCHEMA public TO service_role;
GRANT ALL ON SCHEMA public TO PUBLIC;

-- 4. RECARREGAR O CACHE DA API DO SUPABASE
NOTIFY pgrst, 'reload schema';








-- ==============================================================================
-- SCRIPT DA NOVA ESTRUTURA - DE CRIAÇÃO DA ESTRUTURA DO BANCO DE DADOS (SUPABASE / POSTGRESQL)
-- ==============================================================================

-- 1. TABELA DE PERFIS (Conectada ao módulo Auth do Supabase)
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID REFERENCES auth.users ON DELETE CASCADE PRIMARY KEY,
    name TEXT NOT NULL,
    role TEXT CHECK (role IN ('admin', 'teacher')) DEFAULT 'teacher',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- 2. TABELA DE PROFESSORES (Com a coluna assigned_classes incluída)
CREATE TABLE IF NOT EXISTS public.teachers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    profile_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    full_name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    username TEXT,
    password TEXT,
    subject TEXT,
    assigned_classes text[] DEFAULT '{}', -- Guarda a lista de turmas (ex: ['3º Ano A', '7º Ano A'])
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- 3. TABELA DE ALUNOS
CREATE TABLE IF NOT EXISTS public.students (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    full_name TEXT NOT NULL,
    registration_number TEXT UNIQUE,
    student_password TEXT,
    parent_username TEXT,
    parent_password TEXT,
    grade_level TEXT,
    total_points INT DEFAULT 0,
    avatar TEXT DEFAULT '🐣',
    incidents_json JSONB DEFAULT '[]'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- 4. TABELA DE PRODUTOS (LOJA DE RECOMPENSAS)
CREATE TABLE IF NOT EXISTS public.products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    description TEXT,
    quantity INT DEFAULT 0 CHECK (quantity >= 0),
    points INT DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- 5. TABELA DE PEDIDOS DE RECOMPENSAS
CREATE TABLE IF NOT EXISTS public.orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID REFERENCES public.students(id) ON DELETE CASCADE NOT NULL,
    student_name TEXT NOT NULL,
    student_grade TEXT,
    product_name TEXT NOT NULL,
    points_spent INT NOT NULL,
    delivered BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- 6. TABELA DE REGISTRO DE PONTOS (LOG DE PONTUAÇÃO)
CREATE TABLE IF NOT EXISTS public.points_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID REFERENCES public.students(id) ON DELETE CASCADE NOT NULL,
    teacher_id UUID REFERENCES public.teachers(id) ON DELETE SET NULL,
    points_change INT NOT NULL,
    reason TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- 7. TABELA DE OCORRÊNCIAS
CREATE TABLE IF NOT EXISTS public.incidents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID REFERENCES public.students(id) ON DELETE CASCADE NOT NULL,
    teacher_id UUID REFERENCES public.teachers(id) ON DELETE SET NULL,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    severity TEXT CHECK (severity IN ('low', 'medium', 'high')) DEFAULT 'low',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- ==============================================================================
-- AUTOMATIZAÇÃO: ATUALIZAÇÃO AUTOMÁTICA DOS PONTOS DO ALUNO
-- ==============================================================================

CREATE OR REPLACE FUNCTION update_student_points()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE public.students
    SET total_points = total_points + NEW.points_change
    WHERE id = NEW.student_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_student_points ON public.points_log;
CREATE TRIGGER trigger_update_student_points
AFTER INSERT ON public.points_log
FOR EACH ROW
EXECUTE FUNCTION update_student_points();

-- Recarrega o esquema para a API do Supabase reconhecer os novos campos imediatamente
NOTIFY pgrst, 'reload schema';



-- ==============================================================================
-- CORREÇÃO DE PERMISSÕES PARA AS TABELAS DO SUPABASE - DEU ERRO NO CADASTRO  DE PROFESSOR
-- ==============================================================================

-- 1. CONCEDER PERMISSÕES DE LEITURA E ESCRITA NAS TABELAS
-- Permite que tanto utilizadores anónimos (anon) como autenticados (authenticated)
-- consigam inserir (INSERT), ler (SELECT), atualizar (UPDATE) e apagar (DELETE).
GRANT ALL ON ALL TABLES IN SCHEMA public TO anon;
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO service_role;

-- 2. CONCEDER PERMISSÕES NAS SEQUÊNCIAS (Para IDs automáticos e geradores)
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO service_role;

-- 3. DESATIVAR RLS (ROW LEVEL SECURITY) NAS TABELAS PRINCIPAIS
-- Desativar a segurança a nível de linha evita que o Supabase bloqueie requisições da web
ALTER TABLE IF EXISTS public.teachers DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.profiles DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.students DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.products DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.orders DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.points_log DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.incidents DISABLE ROW LEVEL SECURITY;

-- 4. RECARREGAR O CACHE DA API
NOTIFY pgrst, 'reload schema';




-- Garante que a tabela students permite atualizações (UPDATE)
CREATE POLICY "Permitir atualizacao publica em students" 
ON public.students 
FOR UPDATE 
USING (true) 
WITH CHECK (true);