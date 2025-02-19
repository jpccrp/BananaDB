/*
  # Add Deepseek AI provider support
  
  1. Changes
    - Add Deepseek-related columns to admin_settings
    - Update get_admin_settings function with new fields
    - Update update_admin_settings function with Deepseek support
    
  2. Security
    - Maintain existing RLS policies
    - Ensure secure handling of API keys
*/

-- Add new columns for Deepseek
ALTER TABLE admin_settings
ADD COLUMN IF NOT EXISTS deepseek_api_key text,
ADD COLUMN IF NOT EXISTS deepseek_prompt text,
ADD COLUMN IF NOT EXISTS ai_provider text DEFAULT 'gemini' CHECK (ai_provider IN ('gemini', 'deepseek'));

-- Drop existing function to allow return type modification
DROP FUNCTION IF EXISTS get_admin_settings();
DROP FUNCTION IF EXISTS update_admin_settings(text, text);

-- Create new version of get_admin_settings with additional fields
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
BEGIN
  RETURN QUERY
  SELECT 
    COALESCE(
      decrypt_sensitive_data(a.gemini_api_key),
      CURRENT_SETTING('app.settings.google_api_key', TRUE)
    ) as gemini_api_key,
    a.gemini_prompt,
    decrypt_sensitive_data(a.deepseek_api_key) as deepseek_api_key,
    a.deepseek_prompt,
    a.ai_provider,
    a.key_last_validated,
    a.key_is_valid,
    a.key_error_message
  FROM admin_settings a
  WHERE id = 1;
END;
$$;

-- Create new version of update_admin_settings with Deepseek support
CREATE OR REPLACE FUNCTION update_admin_settings(
  p_gemini_api_key text,
  p_gemini_prompt text,
  p_deepseek_api_key text,
  p_deepseek_prompt text,
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

  -- Update settings
  UPDATE admin_settings
  SET 
    gemini_api_key = encrypt_sensitive_data(p_gemini_api_key),
    gemini_prompt = p_gemini_prompt,
    deepseek_api_key = encrypt_sensitive_data(p_deepseek_api_key),
    deepseek_prompt = p_deepseek_prompt,
    ai_provider = p_ai_provider,
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
      deepseek_api_key,
      deepseek_prompt,
      ai_provider,
      key_last_validated,
      key_is_valid,
      key_error_message
    ) VALUES (
      1,
      encrypt_sensitive_data(p_gemini_api_key),
      p_gemini_prompt,
      encrypt_sensitive_data(p_deepseek_api_key),
      p_deepseek_prompt,
      p_ai_provider,
      NULL,
      false,
      NULL
    );
  END IF;
END;
$$;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION get_admin_settings() TO authenticated;
GRANT EXECUTE ON FUNCTION update_admin_settings(text, text, text, text, text) TO authenticated;