-- Migration: Complete Security Audit & Row Level Security (RLS) Enforcement
-- Date: 2026-10-06
-- Purpose: 
--   1. Enforce strict Row Level Security (RLS) on all CareerLedger tables.
--   2. Verify that every endpoint/query requires an authenticated and authorized user (auth.uid() = user_id).
--   3. Block unauthenticated access and cross-user data tampering (IDOR/BOLA prevention).
--   4. Restrict storage object uploads and downloads strictly to the authenticated object owner.

-- ============================================================================
-- 1. PROFILES TABLE SECURITY
-- ============================================================================
ALTER TABLE IF EXISTS public.profiles ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
    -- Drop stale permissive policies if any exist
    DROP POLICY IF EXISTS "Public profiles are viewable by everyone" ON public.profiles;
    DROP POLICY IF EXISTS "Users can view their own profile" ON public.profiles;
    DROP POLICY IF EXISTS "Users can insert their own profile" ON public.profiles;
    DROP POLICY IF EXISTS "Users can update their own profile" ON public.profiles;
    DROP POLICY IF EXISTS "Users can delete their own profile" ON public.profiles;

    -- Authenticated user can SELECT only their own profile
    CREATE POLICY "Users can view their own profile"
    ON public.profiles FOR SELECT
    TO authenticated
    USING (auth.uid() = user_id);

    -- Authenticated user can INSERT only matching their own auth.uid()
    CREATE POLICY "Users can insert their own profile"
    ON public.profiles FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = user_id);

    -- Authenticated user can UPDATE only their own profile
    CREATE POLICY "Users can update their own profile"
    ON public.profiles FOR UPDATE
    TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

    -- Authenticated user can DELETE only their own profile
    CREATE POLICY "Users can delete their own profile"
    ON public.profiles FOR DELETE
    TO authenticated
    USING (auth.uid() = user_id);
END $$;

-- ============================================================================
-- 2. PROJECTS TABLE SECURITY
-- ============================================================================
ALTER TABLE IF EXISTS public.projects ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
    DROP POLICY IF EXISTS "Users can view their own projects" ON public.projects;
    DROP POLICY IF EXISTS "Users can insert their own projects" ON public.projects;
    DROP POLICY IF EXISTS "Users can update their own projects" ON public.projects;
    DROP POLICY IF EXISTS "Users can delete their own projects" ON public.projects;

    CREATE POLICY "Users can view their own projects"
    ON public.projects FOR SELECT
    TO authenticated
    USING (auth.uid() = user_id);

    CREATE POLICY "Users can insert their own projects"
    ON public.projects FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = user_id);

    CREATE POLICY "Users can update their own projects"
    ON public.projects FOR UPDATE
    TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

    CREATE POLICY "Users can delete their own projects"
    ON public.projects FOR DELETE
    TO authenticated
    USING (auth.uid() = user_id);
END $$;

-- ============================================================================
-- 3. CERTIFICATES TABLE SECURITY
-- ============================================================================
ALTER TABLE IF EXISTS public.certificates ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
    DROP POLICY IF EXISTS "Users can view their own certificates" ON public.certificates;
    DROP POLICY IF EXISTS "Users can insert their own certificates" ON public.certificates;
    DROP POLICY IF EXISTS "Users can update their own certificates" ON public.certificates;
    DROP POLICY IF EXISTS "Users can delete their own certificates" ON public.certificates;

    CREATE POLICY "Users can view their own certificates"
    ON public.certificates FOR SELECT
    TO authenticated
    USING (auth.uid() = user_id);

    CREATE POLICY "Users can insert their own certificates"
    ON public.certificates FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = user_id);

    CREATE POLICY "Users can update their own certificates"
    ON public.certificates FOR UPDATE
    TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

    CREATE POLICY "Users can delete their own certificates"
    ON public.certificates FOR DELETE
    TO authenticated
    USING (auth.uid() = user_id);
END $$;

-- ============================================================================
-- 4. ACHIEVEMENTS TABLE SECURITY
-- ============================================================================
ALTER TABLE IF EXISTS public.achievements ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
    DROP POLICY IF EXISTS "Users can view their own achievements" ON public.achievements;
    DROP POLICY IF EXISTS "Users can insert their own achievements" ON public.achievements;
    DROP POLICY IF EXISTS "Users can update their own achievements" ON public.achievements;
    DROP POLICY IF EXISTS "Users can delete their own achievements" ON public.achievements;

    CREATE POLICY "Users can view their own achievements"
    ON public.achievements FOR SELECT
    TO authenticated
    USING (auth.uid() = user_id);

    CREATE POLICY "Users can insert their own achievements"
    ON public.achievements FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = user_id);

    CREATE POLICY "Users can update their own achievements"
    ON public.achievements FOR UPDATE
    TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

    CREATE POLICY "Users can delete their own achievements"
    ON public.achievements FOR DELETE
    TO authenticated
    USING (auth.uid() = user_id);
END $$;

-- ============================================================================
-- 5. EDUCATION & EXPERIENCE TABLES SECURITY
-- ============================================================================
ALTER TABLE IF EXISTS public.education ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.experience ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
    -- Education policies
    DROP POLICY IF EXISTS "Users can view their own education" ON public.education;
    DROP POLICY IF EXISTS "Users can insert their own education" ON public.education;
    DROP POLICY IF EXISTS "Users can update their own education" ON public.education;
    DROP POLICY IF EXISTS "Users can delete their own education" ON public.education;

    CREATE POLICY "Users can view their own education"
    ON public.education FOR SELECT
    TO authenticated
    USING (auth.uid() = user_id);

    CREATE POLICY "Users can insert their own education"
    ON public.education FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = user_id);

    CREATE POLICY "Users can update their own education"
    ON public.education FOR UPDATE
    TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

    CREATE POLICY "Users can delete their own education"
    ON public.education FOR DELETE
    TO authenticated
    USING (auth.uid() = user_id);

    -- Experience policies
    DROP POLICY IF EXISTS "Users can view their own experience" ON public.experience;
    DROP POLICY IF EXISTS "Users can insert their own experience" ON public.experience;
    DROP POLICY IF EXISTS "Users can update their own experience" ON public.experience;
    DROP POLICY IF EXISTS "Users can delete their own experience" ON public.experience;

    CREATE POLICY "Users can view their own experience"
    ON public.experience FOR SELECT
    TO authenticated
    USING (auth.uid() = user_id);

    CREATE POLICY "Users can insert their own experience"
    ON public.experience FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = user_id);

    CREATE POLICY "Users can update their own experience"
    ON public.experience FOR UPDATE
    TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

    CREATE POLICY "Users can delete their own experience"
    ON public.experience FOR DELETE
    TO authenticated
    USING (auth.uid() = user_id);
END $$;

-- ============================================================================
-- 6. STORAGE BUCKET ROW LEVEL SECURITY
-- ============================================================================
-- Enforce that certificate evidence can ONLY be uploaded, downloaded, and deleted
-- by the authenticated owner whose auth.uid() matches the top-level folder name.
DO $$ BEGIN
    DROP POLICY IF EXISTS "Users can upload their own certificate evidence" ON storage.objects;
    DROP POLICY IF EXISTS "Users can view their own certificate evidence" ON storage.objects;
    DROP POLICY IF EXISTS "Users can delete their own certificate evidence" ON storage.objects;

    CREATE POLICY "Users can upload their own certificate evidence"
    ON storage.objects FOR INSERT
    TO authenticated
    WITH CHECK (
        bucket_id = 'certificate-evidence'
        AND (storage.foldername(name))[1] = auth.uid()::text
    );

    CREATE POLICY "Users can view their own certificate evidence"
    ON storage.objects FOR SELECT
    TO authenticated
    USING (
        bucket_id = 'certificate-evidence'
        AND (storage.foldername(name))[1] = auth.uid()::text
    );

    CREATE POLICY "Users can delete their own certificate evidence"
    ON storage.objects FOR DELETE
    TO authenticated
    USING (
        bucket_id = 'certificate-evidence'
        AND (storage.foldername(name))[1] = auth.uid()::text
    );
END $$;
