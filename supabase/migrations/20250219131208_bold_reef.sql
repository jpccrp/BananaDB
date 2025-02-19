-- First, drop existing functions to allow recreation with new return types
DROP FUNCTION IF EXISTS get_admin_settings();
DROP FUNCTION IF EXISTS check_gemini_key();

-- Create backup of existing data
CREATE TEMP TABLE admin_settings_backup AS 
SELECT * FROM admin_settings;

-- Drop existing table
DROP TABLE admin_settings;

-- Create new table with simplified schema
CREATE TABLE admin_settings (
  id integer PRIMARY KEY CHECK (id = 1),
  gemini_api_key text,
  gemini_prompt text NOT NULL,
  updated_at timestamptz NOT NULL DEFAULT now(),
  deepseek_api_key text,
  deepseek_prompt text NOT NULL,
  ai_provider text NOT NULL DEFAULT 'gemini' CHECK (ai_provider IN ('gemini', 'deepseek'))
);

-- Restore data from backup, excluding removed columns
INSERT INTO admin_settings (
  id,
  gemini_api_key,
  gemini_prompt,
  updated_at,
  deepseek_api_key,
  deepseek_prompt,
  ai_provider
)
SELECT 
  id,
  gemini_api_key,
  gemini_prompt,
  updated_at,
  deepseek_api_key,
  deepseek_prompt,
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

-- Create get_admin_settings function with new return type
CREATE FUNCTION get_admin_settings()
RETURNS TABLE (
  gemini_api_key text,
  gemini_prompt text,
  deepseek_api_key text,
  deepseek_prompt text,
  ai_provider text
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- First try to get existing settings
  RETURN QUERY
  SELECT 
    COALESCE(a.gemini_api_key, ''),
    COALESCE(a.gemini_prompt, 'You are a car listing data parser...'),
    COALESCE(a.deepseek_api_key, ''),
    COALESCE(a.deepseek_prompt, 'You are a car listing data parser...'),
    COALESCE(a.ai_provider, 'gemini')
  FROM admin_settings a
  WHERE id = 1;

  -- If no row exists, return defaults
  IF NOT FOUND THEN
    RETURN QUERY SELECT
      '',
      'You are a car listing data parser...',
      '',
      'You are a car listing data parser...',
      'gemini'::text;
  END IF;
END;
$$;

-- Create check_gemini_key function
CREATE FUNCTION check_gemini_key()
RETURNS TABLE (
  has_key boolean,
  has_prompt boolean
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    a.gemini_api_key IS NOT NULL AND a.gemini_api_key != '',
    a.gemini_prompt IS NOT NULL AND a.gemini_prompt != ''
  FROM admin_settings a
  WHERE id = 1;

  -- If no settings found, return defaults
  IF NOT FOUND THEN
    RETURN QUERY SELECT
      false,
      false;
  END IF;
END;
$$;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION get_admin_settings() TO authenticated;
GRANT EXECUTE ON FUNCTION check_gemini_key() TO authenticated;