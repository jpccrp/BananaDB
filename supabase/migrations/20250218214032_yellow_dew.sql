/*
  # Fix AI provider persistence

  1. Changes
    - Add default value constraint for ai_provider column
    - Update get_admin_settings to always return a valid provider
    - Ensure update_ai_provider properly persists changes
*/

-- Add default value constraint to ai_provider if it doesn't exist
DO $$ 
BEGIN
  ALTER TABLE admin_settings 
    ALTER COLUMN ai_provider SET DEFAULT 'gemini';
EXCEPTION
  WHEN duplicate_column THEN NULL;
END $$;

-- Update get_admin_settings to ensure it always returns a valid provider
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
AS $$
DECLARE
  settings admin_settings;
BEGIN
  SELECT * INTO settings FROM admin_settings WHERE id = 1;
  
  IF NOT FOUND THEN
    RETURN QUERY SELECT
      CURRENT_SETTING('app.settings.google_api_key', TRUE),
      '',
      '',
      '',
      'gemini'::text,
      NULL::timestamptz,
      FALSE,
      NULL::text;
    RETURN;
  END IF;

  RETURN QUERY SELECT
    CASE 
      WHEN settings.gemini_api_key IS NOT NULL AND settings.gemini_api_key != '' THEN
        COALESCE(decrypt_sensitive_data(settings.gemini_api_key), settings.gemini_api_key)
      ELSE
        CURRENT_SETTING('app.settings.google_api_key', TRUE)
    END,
    COALESCE(settings.gemini_prompt, ''),
    CASE 
      WHEN settings.deepseek_api_key IS NOT NULL AND settings.deepseek_api_key != '' THEN
        COALESCE(decrypt_sensitive_data(settings.deepseek_api_key), settings.deepseek_api_key)
      ELSE
        ''
    END,
    COALESCE(settings.deepseek_prompt, ''),
    COALESCE(settings.ai_provider, 'gemini'),
    settings.key_last_validated,
    COALESCE(settings.key_is_valid, false),
    settings.key_error_message;
END;
$$;

-- Update the AI provider update function to ensure changes are persisted
CREATE OR REPLACE FUNCTION update_ai_provider(
  p_ai_provider text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Only allow admins to update settings
  IF NOT is_admin(auth.uid()) THEN
    RAISE EXCEPTION 'Only administrators can update settings';
  END IF;

  -- Validate AI provider
  IF p_ai_provider NOT IN ('gemini', 'deepseek') THEN
    RAISE EXCEPTION 'Invalid AI provider. Must be either "gemini" or "deepseek"';
  END IF;

  -- Ensure we have a settings row
  INSERT INTO admin_settings (id, ai_provider)
  VALUES (1, p_ai_provider)
  ON CONFLICT (id) DO UPDATE
  SET 
    ai_provider = p_ai_provider,
    updated_at = now();
END;
$$;

-- Ensure we have a default row with proper values
INSERT INTO admin_settings (id, ai_provider, gemini_prompt, deepseek_prompt)
VALUES (1, 'gemini', '', '')
ON CONFLICT (id) DO UPDATE
SET ai_provider = COALESCE(admin_settings.ai_provider, 'gemini');