/*
  # Add default settings

  1. Changes
    - Ensures admin_settings table has a default row
    - Sets default values for required fields
    - Adds explicit NOT NULL constraints
  
  2. Data
    - Adds default Gemini prompt
    - Sets default AI provider to 'gemini'
*/

-- First ensure the table exists
CREATE TABLE IF NOT EXISTS admin_settings (
  id integer PRIMARY KEY CHECK (id = 1),
  gemini_api_key text,
  gemini_prompt text,
  deepseek_api_key text,
  deepseek_prompt text,
  ai_provider text DEFAULT 'gemini',
  key_last_validated timestamptz,
  key_is_valid boolean DEFAULT false,
  key_error_message text,
  updated_at timestamptz DEFAULT now()
);

-- Add NOT NULL constraints where appropriate
ALTER TABLE admin_settings 
  ALTER COLUMN gemini_prompt SET NOT NULL,
  ALTER COLUMN deepseek_prompt SET NOT NULL,
  ALTER COLUMN ai_provider SET NOT NULL;

-- Insert default values if no row exists
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

-- Ensure RLS is enabled
ALTER TABLE admin_settings ENABLE ROW LEVEL SECURITY;

-- Update the get_admin_settings function to handle NULL values better
CREATE OR REPLACE FUNCTION get_admin_settings()
RETURNS TABLE (
  gemini_api_key text,
  gemini_prompt text,
  deepseek_api_key text,
  deepseek_prompt text,
  ai_provider text,
  key_last_validated timestamptz,
  key_is_valid boolean,
  key_error_message text
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
    COALESCE(a.ai_provider, 'gemini'),
    a.key_last_validated,
    COALESCE(a.key_is_valid, false),
    a.key_error_message
  FROM admin_settings a
  WHERE id = 1;

  -- If no row exists, return defaults
  IF NOT FOUND THEN
    RETURN QUERY SELECT
      '',
      'You are a car listing data parser...',
      '',
      'You are a car listing data parser...',
      'gemini',
      NULL::timestamptz,
      false,
      NULL::text;
  END IF;
END;
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION get_admin_settings() TO authenticated;