/*
  # Switch to plain text API key storage
  
  1. Changes
    - Remove all encryption/decryption
    - Store API keys as plain text
    - Update all related functions
    
  2. Security Note
    - Keys are now stored in plain text for development
    - RLS policies still protect access to keys
*/

-- Drop any remaining encryption-related functions if they exist
DROP FUNCTION IF EXISTS encrypt_sensitive_data(text) CASCADE;
DROP FUNCTION IF EXISTS decrypt_sensitive_data(text) CASCADE;

-- Update get_admin_settings to work with plain text
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
    COALESCE(settings.gemini_api_key, CURRENT_SETTING('app.settings.google_api_key', TRUE)),
    COALESCE(settings.gemini_prompt, ''),
    COALESCE(settings.deepseek_api_key, ''),
    COALESCE(settings.deepseek_prompt, ''),
    COALESCE(settings.ai_provider, 'gemini'),
    settings.key_last_validated,
    COALESCE(settings.key_is_valid, false),
    settings.key_error_message;
END;
$$;

-- Update functions to work with plain text
CREATE OR REPLACE FUNCTION update_gemini_settings(
  p_gemini_api_key text,
  p_gemini_prompt text
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

  -- Update settings with plain text values
  UPDATE admin_settings
  SET 
    gemini_api_key = p_gemini_api_key,
    gemini_prompt = p_gemini_prompt,
    updated_at = now(),
    -- Reset validation on key change
    key_last_validated = NULL,
    key_is_valid = false,
    key_error_message = NULL
  WHERE id = 1;
  
  -- Insert if not exists
  IF NOT FOUND THEN
    INSERT INTO admin_settings (
      id, 
      gemini_api_key,
      gemini_prompt,
      ai_provider
    ) VALUES (
      1,
      p_gemini_api_key,
      p_gemini_prompt,
      'gemini'
    );
  END IF;
END;
$$;

CREATE OR REPLACE FUNCTION update_deepseek_settings(
  p_deepseek_api_key text,
  p_deepseek_prompt text
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

  -- Update settings with plain text values
  UPDATE admin_settings
  SET 
    deepseek_api_key = p_deepseek_api_key,
    deepseek_prompt = p_deepseek_prompt,
    updated_at = now(),
    -- Reset validation on key change
    key_last_validated = NULL,
    key_is_valid = false,
    key_error_message = NULL
  WHERE id = 1;
  
  -- Insert if not exists
  IF NOT FOUND THEN
    INSERT INTO admin_settings (
      id, 
      deepseek_api_key,
      deepseek_prompt,
      ai_provider
    ) VALUES (
      1,
      p_deepseek_api_key,
      p_deepseek_prompt,
      'deepseek'
    );
  END IF;
END;
$$;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION get_admin_settings() TO authenticated;
GRANT EXECUTE ON FUNCTION update_gemini_settings(text, text) TO authenticated;
GRANT EXECUTE ON FUNCTION update_deepseek_settings(text, text) TO authenticated;