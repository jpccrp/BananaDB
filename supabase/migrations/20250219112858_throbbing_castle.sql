/*
  # Fix admin settings schema and functions
  
  1. Updates
    - Ensure admin_settings table has correct structure
    - Update check_gemini_key function
    - Add missing RLS policies
*/

-- First ensure the table has the correct structure
DO $$ 
BEGIN
  -- Add missing columns if they don't exist
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'admin_settings' AND column_name = 'key_last_validated') 
  THEN
    ALTER TABLE admin_settings ADD COLUMN key_last_validated timestamptz;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'admin_settings' AND column_name = 'key_is_valid') 
  THEN
    ALTER TABLE admin_settings ADD COLUMN key_is_valid boolean DEFAULT false;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'admin_settings' AND column_name = 'key_error_message') 
  THEN
    ALTER TABLE admin_settings ADD COLUMN key_error_message text;
  END IF;
END $$;

-- Drop existing function to recreate it
DROP FUNCTION IF EXISTS check_gemini_key();

-- Create improved version of check_gemini_key
CREATE OR REPLACE FUNCTION public.check_gemini_key()
RETURNS TABLE (
  has_key boolean,
  has_prompt boolean,
  is_valid boolean,
  last_checked timestamptz,
  error_message text
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  settings record;
BEGIN
  -- Get settings with better error handling
  SELECT 
    a.gemini_api_key,
    a.gemini_prompt,
    a.key_last_validated,
    a.key_is_valid,
    a.key_error_message
  INTO settings
  FROM admin_settings a
  WHERE id = 1;

  IF NOT FOUND THEN
    -- Insert default row if none exists
    INSERT INTO admin_settings (id, gemini_api_key, gemini_prompt, ai_provider)
    VALUES (1, '', '', 'gemini')
    RETURNING 
      gemini_api_key,
      gemini_prompt,
      key_last_validated,
      key_is_valid,
      key_error_message
    INTO settings;
  END IF;

  -- Return status
  RETURN QUERY SELECT
    settings.gemini_api_key IS NOT NULL AND settings.gemini_api_key != '',
    settings.gemini_prompt IS NOT NULL AND settings.gemini_prompt != '',
    COALESCE(settings.key_is_valid, false),
    settings.key_last_validated,
    settings.key_error_message;
END;
$$;

-- Ensure RLS policies exist
DO $$ 
BEGIN
  -- Drop existing policies to avoid conflicts
  DROP POLICY IF EXISTS "Allow check_gemini_key to read admin_settings" ON admin_settings;
  DROP POLICY IF EXISTS "Admins can view settings" ON admin_settings;
  DROP POLICY IF EXISTS "Admins can update settings" ON admin_settings;
END $$;

-- Create comprehensive RLS policies
CREATE POLICY "Allow check_gemini_key to read admin_settings"
  ON admin_settings
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Admins can view settings"
  ON admin_settings
  FOR SELECT
  TO authenticated
  USING (is_admin(auth.uid()));

CREATE POLICY "Admins can update settings"
  ON admin_settings
  FOR UPDATE
  TO authenticated
  USING (is_admin(auth.uid()))
  WITH CHECK (is_admin(auth.uid()));

-- Re-grant permissions
GRANT EXECUTE ON FUNCTION check_gemini_key() TO authenticated;

-- Ensure default settings exist
INSERT INTO admin_settings (
  id,
  gemini_api_key,
  gemini_prompt,
  deepseek_api_key,
  deepseek_prompt,
  ai_provider,
  key_is_valid
) VALUES (
  1,
  '',
  'You are a car listing data parser...',
  '',
  'You are a car listing data parser...',
  'gemini',
  false
)
ON CONFLICT (id) DO UPDATE SET
  gemini_prompt = COALESCE(admin_settings.gemini_prompt, EXCLUDED.gemini_prompt),
  deepseek_prompt = COALESCE(admin_settings.deepseek_prompt, EXCLUDED.deepseek_prompt),
  ai_provider = COALESCE(admin_settings.ai_provider, EXCLUDED.ai_provider);