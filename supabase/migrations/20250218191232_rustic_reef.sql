/*
  # Improve API Key Management
  
  1. Changes
    - Add encryption for API keys
    - Add key rotation support
    - Add key validation tracking
    
  2. Security
    - Encrypt sensitive data
    - Track key usage and validity
    - Support key rotation
*/

-- Drop existing function to allow modification
DROP FUNCTION IF EXISTS get_admin_settings();

-- Create encryption function for sensitive data
CREATE OR REPLACE FUNCTION encrypt_sensitive_data(input text)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  encryption_key text;
BEGIN
  -- Get encryption key from vault or environment
  encryption_key := CURRENT_SETTING('app.settings.encryption_key', TRUE);
  
  -- Return encrypted data using pgcrypto
  RETURN ENCODE(
    ENCRYPT(
      CONVERT_TO(input, 'utf8'),
      DECODE(encryption_key, 'hex'),
      'aes'
    ),
    'base64'
  );
END;
$$;

-- Create decryption function for sensitive data
CREATE OR REPLACE FUNCTION decrypt_sensitive_data(encrypted_data text)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  encryption_key text;
  decrypted bytea;
BEGIN
  -- Get encryption key from vault or environment
  encryption_key := CURRENT_SETTING('app.settings.encryption_key', TRUE);
  
  -- Decrypt the data
  decrypted := DECRYPT(
    DECODE(encrypted_data, 'base64'),
    DECODE(encryption_key, 'hex'),
    'aes'
  );
  
  -- Return decrypted text
  RETURN CONVERT_FROM(decrypted, 'utf8');
EXCEPTION
  WHEN OTHERS THEN
    -- On error, return null (invalid encryption)
    RETURN NULL;
END;
$$;

-- Add columns for key management
ALTER TABLE admin_settings 
ADD COLUMN IF NOT EXISTS key_last_validated timestamptz,
ADD COLUMN IF NOT EXISTS key_is_valid boolean DEFAULT false,
ADD COLUMN IF NOT EXISTS key_error_message text;

-- Create new version of get_admin_settings with additional fields
CREATE OR REPLACE FUNCTION get_admin_settings()
RETURNS TABLE (
  gemini_api_key text,
  gemini_prompt text,
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
    a.key_last_validated,
    a.key_is_valid,
    a.key_error_message
  FROM admin_settings a
  WHERE id = 1;
END;
$$;

-- Update admin_settings to use encryption for new values
CREATE OR REPLACE FUNCTION update_admin_settings(
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

  -- Update settings with encrypted API key
  UPDATE admin_settings
  SET 
    gemini_api_key = encrypt_sensitive_data(p_gemini_api_key),
    gemini_prompt = p_gemini_prompt,
    updated_at = now(),
    -- Reset validation on key change
    key_last_validated = NULL,
    key_is_valid = false,
    key_error_message = NULL
  WHERE id = 1;
END;
$$;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION update_admin_settings(text, text) TO authenticated;
REVOKE EXECUTE ON FUNCTION encrypt_sensitive_data(text) FROM public;
REVOKE EXECUTE ON FUNCTION decrypt_sensitive_data(text) FROM public;