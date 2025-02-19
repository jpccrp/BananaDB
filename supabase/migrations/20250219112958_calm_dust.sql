/*
  # Fix admin settings RLS policies
  
  1. Updates
    - Drop and recreate RLS policies with proper permissions
    - Add missing INSERT policy
    - Ensure proper function permissions
*/

-- Drop existing policies
DROP POLICY IF EXISTS "Allow check_gemini_key to read admin_settings" ON admin_settings;
DROP POLICY IF EXISTS "Admins can view settings" ON admin_settings;
DROP POLICY IF EXISTS "Admins can update settings" ON admin_settings;

-- Create comprehensive RLS policies
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

-- Re-grant function permissions
GRANT EXECUTE ON FUNCTION check_gemini_key() TO authenticated;
GRANT EXECUTE ON FUNCTION get_admin_settings() TO authenticated;

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
ON CONFLICT (id) DO NOTHING;