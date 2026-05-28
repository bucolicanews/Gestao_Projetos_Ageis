-- 0056_storage_avatars_logos.sql
-- 1) Coluna logo_url em organizacoes
-- 2) Buckets públicos: avatars e logos
-- 3) Policies de storage

-- ============================================================
-- 1) logo_url em organizacoes
-- ============================================================
ALTER TABLE public.organizacoes
  ADD COLUMN IF NOT EXISTS logo_url text;

-- ============================================================
-- 2) Buckets
-- ============================================================
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES
  ('avatars', 'avatars', true, 2097152,  ARRAY['image/jpeg','image/png','image/webp','image/gif']),
  ('logos',   'logos',   true, 2097152,  ARRAY['image/jpeg','image/png','image/webp','image/svg+xml'])
ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- 3) Policies storage.objects
-- ============================================================

-- Avatars: leitura pública
DROP POLICY IF EXISTS "avatars_public_read"  ON storage.objects;
CREATE POLICY "avatars_public_read"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'avatars');

-- Avatars: usuário só sobe/substitui/exclui na própria pasta (userId/)
DROP POLICY IF EXISTS "avatars_owner_write" ON storage.objects;
CREATE POLICY "avatars_owner_write"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'avatars'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

DROP POLICY IF EXISTS "avatars_owner_update" ON storage.objects;
CREATE POLICY "avatars_owner_update"
  ON storage.objects FOR UPDATE
  TO authenticated
  USING (
    bucket_id = 'avatars'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

DROP POLICY IF EXISTS "avatars_owner_delete" ON storage.objects;
CREATE POLICY "avatars_owner_delete"
  ON storage.objects FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'avatars'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

-- Logos: leitura pública
DROP POLICY IF EXISTS "logos_public_read"   ON storage.objects;
CREATE POLICY "logos_public_read"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'logos');

-- Logos: admin da org sobe/substitui na pasta (orgId/)
DROP POLICY IF EXISTS "logos_admin_write" ON storage.objects;
CREATE POLICY "logos_admin_write"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'logos'
    AND EXISTS (
      SELECT 1 FROM public.usuarios u
      WHERE u.id = auth.uid()
        AND u.perfil = 'admin'
        AND u.organizacao_id::text = (storage.foldername(name))[1]
    )
  );

DROP POLICY IF EXISTS "logos_admin_update" ON storage.objects;
CREATE POLICY "logos_admin_update"
  ON storage.objects FOR UPDATE
  TO authenticated
  USING (
    bucket_id = 'logos'
    AND EXISTS (
      SELECT 1 FROM public.usuarios u
      WHERE u.id = auth.uid()
        AND u.perfil = 'admin'
        AND u.organizacao_id::text = (storage.foldername(name))[1]
    )
  );

DROP POLICY IF EXISTS "logos_admin_delete" ON storage.objects;
CREATE POLICY "logos_admin_delete"
  ON storage.objects FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'logos'
    AND EXISTS (
      SELECT 1 FROM public.usuarios u
      WHERE u.id = auth.uid()
        AND u.perfil = 'admin'
        AND u.organizacao_id::text = (storage.foldername(name))[1]
    )
  );
