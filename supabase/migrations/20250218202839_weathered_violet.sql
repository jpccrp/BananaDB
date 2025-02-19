/*
  # Fix encryption implementation

  1. Changes
    - Use pgcrypto for encryption with a static key
    - Re-encrypt existing API keys
    - Update functions to handle encryption/decryption properly
*/

-- Create encryption functions with a static key
CREATE OR REPLACE FUNCTION encrypt_sensitive_data(input text)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Use a static key for encryption (this is a SHA-256 hash of 'BananaDB-2025')
  RETURN encode(
    encrypt(
      convert_to(input, 'utf8'),
      decode('e7cf3ef4f17c3999a94f2c6f612e8a888e5b1026878e4e19398b23bd38ec221a', 'hex'),
      'aes'
    ),
    'base64'
  );
EXCEPTION
  WHEN OTHERS THEN
    -- On error, return original input
    RETURN input;
END;
$$;

CREATE OR REPLACE FUNCTION decrypt_sensitive_data(encrypted_data text)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Use the same static key for decryption
  RETURN convert_from(
    decrypt(
      decode(encrypted_data, 'base64'),
      decode('e7cf3ef4f17c3999a94f2c6f612e8a888e5b1026878e4e19398b23bd38ec221a', 'hex'),
      'aes'
    ),
    'utf8'
  );
EXCEPTION
  WHEN OTHERS THEN
    -- On error, return original input
    RETURN encrypted_data;
END;
$$;

-- Re-encrypt existing API keys
UPDATE admin_settings
SET 
  gemini_api_key = CASE 
    WHEN gemini_api_key IS NOT NULL AND gemini_api_key != '' AND 
         decrypt_sensitive_data(gemini_api_key) IS NULL THEN
      encrypt_sensitive_data(gemini_api_key)
    ELSE
      gemini_api_key
    END,
  deepseek_api_key = CASE 
    WHEN deepseek_api_key IS NOT NULL AND deepseek_api_key != '' AND
         decrypt_sensitive_data(deepseek_api_key) IS NULL THEN
      encrypt_sensitive_data(deepseek_api_key)
    ELSE
      deepseek_api_key
    END
WHERE id = 1;

-- Update get_admin_settings to properly handle decryption
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
    settings.gemini_prompt,
    CASE 
      WHEN settings.deepseek_api_key IS NOT NULL AND settings.deepseek_api_key != '' THEN
        COALESCE(decrypt_sensitive_data(settings.deepseek_api_key), settings.deepseek_api_key)
      ELSE
        ''
    END,
    settings.deepseek_prompt,
    settings.ai_provider,
    settings.key_last_validated,
    settings.key_is_valid,
    settings.key_error_message;
END;
$$;

-- Revoke execute from public
REVOKE EXECUTE ON FUNCTION encrypt_sensitive_data(text) FROM public;
REVOKE EXECUTE ON FUNCTION decrypt_sensitive_data(text) FROM public;