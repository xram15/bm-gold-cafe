-- =============================================================================
-- 👑 CONFIGURATION SUPABASE POUR BM GOLD - CAFÉ LOUNGE
-- =============================================================================
-- Instructions : 
-- Dans votre écran Supabase (actuellement ouvert) :
-- 1. Cliquez sur "SQL Editor" dans le menu à gauche (icône >_)
-- 2. Cliquez sur "+ New query" (ou "New query")
-- 3. Collez tout ce code et cliquez sur "Run" (bouton vert en bas à droite)
-- =============================================================================

-- 1. CRÉATION DE LA TABLE DES PRODUITS
CREATE TABLE IF NOT EXISTS public.products (
    id BIGSERIAL PRIMARY KEY,
    category_name TEXT NOT NULL,
    name TEXT NOT NULL,
    price TEXT NOT NULL,
    description TEXT,
    image_path TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    CONSTRAINT unique_product_category UNIQUE (category_name, name)
);

-- 2. SÉCURITÉ ROW LEVEL SECURITY (RLS)
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Lecture publique du menu" ON public.products;
CREATE POLICY "Lecture publique du menu"
ON public.products
FOR SELECT
TO public
USING (true);

DROP POLICY IF EXISTS "Modification réservée au propriétaire" ON public.products;
CREATE POLICY "Modification réservée au propriétaire"
ON public.products
FOR ALL
TO authenticated
USING (true)
WITH CHECK (true);

-- Permettre également la modification par le rôle public/anonyme si non authentifié lors des premiers tests
DROP POLICY IF EXISTS "Modification libre anon pour tests" ON public.products;
CREATE POLICY "Modification libre anon pour tests"
ON public.products
FOR ALL
TO anon
USING (true)
WITH CHECK (true);

-- 3. CRÉATION DU BUCKET STORAGE POUR LES PHOTOS (menu-photos)
INSERT INTO storage.buckets (id, name, public)
VALUES ('menu-photos', 'menu-photos', true)
ON CONFLICT (id) DO NOTHING;

DROP POLICY IF EXISTS "Photos publiques" ON storage.objects;
CREATE POLICY "Photos publiques"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'menu-photos');

DROP POLICY IF EXISTS "Upload photos par le propriétaire" ON storage.objects;
CREATE POLICY "Upload photos par le propriétaire"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'menu-photos');

DROP POLICY IF EXISTS "Upload photos anon" ON storage.objects;
CREATE POLICY "Upload photos anon"
ON storage.objects FOR INSERT
TO anon
WITH CHECK (bucket_id = 'menu-photos');

-- 4. TABLE DES ADMINISTRATEURS (ÉQUIPE DE GÉRANCE)
CREATE TABLE IF NOT EXISTS public.admins (
    id BIGSERIAL PRIMARY KEY,
    email TEXT UNIQUE NOT NULL,
    role TEXT DEFAULT 'admin' NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.admins ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Admins visibles et gérés par les authentifiés" ON public.admins;
CREATE POLICY "Admins visibles et gérés par les authentifiés"
ON public.admins
FOR ALL
TO authenticated
USING (true)
WITH CHECK (true);

DROP POLICY IF EXISTS "Admins anon select" ON public.admins;
CREATE POLICY "Admins anon select"
ON public.admins
FOR ALL
TO anon
USING (true)
WITH CHECK (true);
