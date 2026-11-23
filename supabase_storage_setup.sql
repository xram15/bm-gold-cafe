-- ==============================================================================
-- CONFIGURATION SUPABASE STORAGE POUR BM GOLD (Compatible RLS Supabase Cloud)
-- Exécutez ce script dans l'onglet "SQL Editor" de votre dashboard Supabase
-- ==============================================================================

-- 1. Création ou mise à jour du bucket public 'product-images'
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'product-images',
  'product-images',
  true,
  5242880, -- 5 Mo max par fichier
  ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif']
)
ON CONFLICT (id) DO UPDATE SET
  public = true,
  file_size_limit = 5242880,
  allowed_mime_types = ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif'];

-- 2. Règle : Lecture publique pour tout le monde (clients du menu)
DROP POLICY IF EXISTS "Public Access Product Images" ON storage.objects;
CREATE POLICY "Public Access Product Images"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'product-images');

-- 3. Règle : Upload pour les utilisateurs connectés ou public pour le menu
DROP POLICY IF EXISTS "Allow Upload Product Images" ON storage.objects;
CREATE POLICY "Allow Upload Product Images"
ON storage.objects FOR INSERT
TO public
WITH CHECK (bucket_id = 'product-images');

DROP POLICY IF EXISTS "Allow Update Product Images" ON storage.objects;
CREATE POLICY "Allow Update Product Images"
ON storage.objects FOR UPDATE
TO public
USING (bucket_id = 'product-images')
WITH CHECK (bucket_id = 'product-images');

DROP POLICY IF EXISTS "Allow Delete Product Images" ON storage.objects;
CREATE POLICY "Allow Delete Product Images"
ON storage.objects FOR DELETE
TO public
USING (bucket_id = 'product-images');
