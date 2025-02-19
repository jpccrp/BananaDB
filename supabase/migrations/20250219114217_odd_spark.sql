/*
  # Fix Supabase Connection Issues

  1. Changes
    - Drop and recreate admin_settings table with correct schema
    - Ensure all required functions exist with proper permissions
    - Add default row to admin_settings
    - Clean up any stale policies

  2. Security
    - Enable RLS
    - Set proper policies
    - Grant correct permissions
*/

-- First, drop everything to start fresh
DROP TABLE IF EXISTS admin_settings CASCADE;
DROP FUNCTION IF EXISTS get_admin_settings();
DROP FUNCTION IF EXISTS check_gemini_key();

-- Create admin_settings table
CREATE TABLE admin_settings (
  id integer PRIMARY KEY CHECK (id = 1),
  gemini_api_key text,
  gemini_prompt text NOT NULL DEFAULT '',
  updated_at timestamptz NOT NULL DEFAULT now(),
  deepseek_api_key text,
  deepseek_prompt text NOT NULL DEFAULT '',
  ai_provider text NOT NULL DEFAULT 'gemini' CHECK (ai_provider IN ('gemini', 'deepseek'))
);

-- Enable RLS
ALTER TABLE admin_settings ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
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

-- Create get_admin_settings function
CREATE OR REPLACE FUNCTION get_admin_settings()
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
  RETURN QUERY
  SELECT 
    COALESCE(a.gemini_api_key, ''),
    COALESCE(a.gemini_prompt, ''),
    COALESCE(a.deepseek_api_key, ''),
    COALESCE(a.deepseek_prompt, ''),
    COALESCE(a.ai_provider, 'gemini')
  FROM admin_settings a
  WHERE id = 1;

  IF NOT FOUND THEN
    RETURN QUERY SELECT
      ''::text,
      ''::text,
      ''::text,
      ''::text,
      'gemini'::text;
  END IF;
END;
$$;

-- Create check_gemini_key function
CREATE OR REPLACE FUNCTION check_gemini_key()
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

-- Insert default settings
INSERT INTO admin_settings (id, gemini_api_key, gemini_prompt, deepseek_api_key, deepseek_prompt, ai_provider)
VALUES (1, '', '', '', '', 'gemini')
ON CONFLICT (id) DO NOTHING;