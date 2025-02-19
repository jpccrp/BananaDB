-- Drop encryption functions and triggers
DROP FUNCTION IF EXISTS encrypt_sensitive_data(text);
DROP FUNCTION IF EXISTS decrypt_sensitive_data(text);
DROP TRIGGER IF EXISTS api_key_updates ON admin_settings;
DROP FUNCTION IF EXISTS handle_api_key_updates();

-- Update get_admin_settings to return plain text
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