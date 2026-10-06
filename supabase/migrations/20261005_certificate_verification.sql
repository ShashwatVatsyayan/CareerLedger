-- Migration: Add Verification fields to certificates table
-- Date: 2026-10-05
-- Purpose: Support professional credential verification system

-- 1. Safely add columns to public.certificates if they don't already exist
ALTER TABLE public.certificates
ADD COLUMN IF NOT EXISTS evidence_url text,
ADD COLUMN IF NOT EXISTS verification_status text DEFAULT 'NOT_VERIFIED',
ADD COLUMN IF NOT EXISTS verification_method text,
ADD COLUMN IF NOT EXISTS verified_at timestamptz,
ADD COLUMN IF NOT EXISTS verification_source text,
ADD COLUMN IF NOT EXISTS verification_details text;

-- 2. Create index on user_id and verification_status for high-performance filtering
CREATE INDEX IF NOT EXISTS idx_certificates_user_verification
ON public.certificates (user_id, verification_status);

-- 3. Prepare storage bucket for certificate evidence (Free Tier compatible)
INSERT INTO storage.buckets (id, name, public)
VALUES ('certificate-evidence', 'certificate-evidence', true)
ON CONFLICT (id) DO NOTHING;

-- 4. Storage Row Level Security (RLS) policies
-- Ensure users can only upload and view their own certificate evidence
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE schemaname = 'storage' AND tablename = 'objects' AND policyname = 'Users can upload their own certificate evidence'
    ) THEN
        CREATE POLICY "Users can upload their own certificate evidence"
        ON storage.objects FOR INSERT
        TO authenticated
        WITH CHECK (
            bucket_id = 'certificate-evidence' 
            AND (storage.foldername(name))[1] = auth.uid()::text
        );
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE schemaname = 'storage' AND tablename = 'objects' AND policyname = 'Users can view their own certificate evidence'
    ) THEN
        CREATE POLICY "Users can view their own certificate evidence"
        ON storage.objects FOR SELECT
        TO authenticated
        USING (
            bucket_id = 'certificate-evidence' 
            AND (storage.foldername(name))[1] = auth.uid()::text
        );
    END IF;
END $$;
