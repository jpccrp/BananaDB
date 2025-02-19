/*
  # Fix admin settings schema
  
  1. Updates
    - Drop and recreate admin_settings table with correct schema
    - Preserve existing data
    - Add proper constraints and defaults
*/

-- First, create a backup of existing data
CREATE TEMP TABLE admin_settings_backup AS 
SELECT * FROM admin_settings;

-- Drop existing table
DROP TABLE admin_settings;

-- Create new table with correct schema
CREATE TABLE admin_settings (
  id integer PRIMARY KEY CHECK (id = 1),
  gemini_api_key text,
  gemini_prompt text NOT NULL,
  updated_at timestamptz NOT NULL DEFAULT now(),
  key_last_validated timestamptz,
  key_is_valid boolean NOT NULL DEFAULT false,
  key_error_message text,
  deepseek_api_key text,
  deepseek_prompt text NOT NULL,
  ai_provider text NOT NULL DEFAULT 'gemini' CHECK (ai_provider IN ('gemini', 'deepseek'))
);

-- Restore data from backup
INSERT INTO admin_settings (
  id,
  gemini_api_key,
  gemini_prompt,
  updated_at,
  key_last_validated,
  key_is_valid,
  key_error_message,
  deepseek_api_key,
  deepseek_prompt,
  ai_provider
)
SELECT 
  id,
  gemini_api_key,
  gemini_prompt,
  updated_at,
  key_last_validated,
  COALESCE(key_is_valid, false),
  key_error_message,
  deepseek_api_key,
  COALESCE(deepseek_prompt, gemini_prompt),
  COALESCE(ai_provider, 'gemini')
FROM admin_settings_backup;

-- Drop backup table
DROP TABLE admin_settings_backup;

-- Enable RLS
ALTER TABLE admin_settings ENABLE ROW LEVEL SECURITY;

-- Recreate RLS policies
DROP POLICY IF EXISTS "Anyone can read admin_settings" ON admin_settings;
DROP POLICY IF EXISTS "Admins can update admin_settings" ON admin_settings;
DROP POLICY IF EXISTS "Admins can insert admin_settings" ON admin_settings;

CREATE POLICY "Anyone can read admin_settings"
  ON admin_settings
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Admins can update admin_settings"
  ON admin_settings
  FOR UPDATE
  TO authenticated
  USING (is_admin(auth.uid()))
  WITH CHECK (is_admin(auth.uid()));

CREATE POLICY "Admins can insert admin_settings"
  ON admin_settings
  FOR INSERT
  TO authenticated
  WITH CHECK (is_admin(auth.uid()));

-- Update check_gemini_key function to match new schema
CREATE OR REPLACE FUNCTION check_gemini_key()
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
  -- Get settings
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
    -- Return defaults if no settings exist
    RETURN QUERY SELECT
      false,
      false,
      false,
      NULL::timestamptz,
      'No settings configured'::text;
    RETURN;
  END IF;

  -- Return status
  RETURN QUERY SELECT
    settings.gemini_api_key IS NOT NULL AND settings.gemini_api_key != '',
    settings.gemini_prompt IS NOT NULL AND settings.gemini_prompt != '',
    settings.key_is_valid,
    settings.key_last_validated,
    settings.key_error_message;
END;
$$;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION check_gemini_key() TO authenticated;