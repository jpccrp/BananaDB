-- Drop existing functions first
DROP FUNCTION IF EXISTS get_admin_settings();
DROP FUNCTION IF EXISTS update_admin_settings(text, text);
DROP FUNCTION IF EXISTS encrypt_sensitive_data(text);
DROP FUNCTION IF EXISTS decrypt_sensitive_data(text);

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
  
  IF encryption_key IS NULL THEN
    RETURN input;
  END IF;
  
  -- Return encrypted data using pgcrypto
  RETURN ENCODE(
    ENCRYPT(
      CONVERT_TO(input, 'utf8'),
      DECODE(encryption_key, 'hex'),
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
  
  IF encryption_key IS NULL THEN
    RETURN encrypted_data;
  END IF;
  
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
    -- On error, return original input
    RETURN encrypted_data;
END;
$$;

-- Add columns for key management if they don't exist
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'admin_settings' AND column_name = 'key_last_validated') 
  THEN
    ALTER TABLE admin_settings ADD COLUMN key_last_validated timestamptz;
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'admin_settings' AND column_name = 'key_is_valid') 
  THEN
    ALTER TABLE admin_settings ADD COLUMN key_is_valid boolean DEFAULT false;
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'admin_settings' AND column_name = 'key_error_message') 
  THEN
    ALTER TABLE admin_settings ADD COLUMN key_error_message text;
  END IF;
END $$;

-- Create function to get settings with validation info
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

-- Create function to update settings
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
  
  -- Insert if not exists
  IF NOT FOUND THEN
    INSERT INTO admin_settings (
      id, 
      gemini_api_key, 
      gemini_prompt, 
      key_last_validated,
      key_is_valid,
      key_error_message
    ) VALUES (
      1,
      encrypt_sensitive_data(p_gemini_api_key),
      p_gemini_prompt,
      NULL,
      false,
      NULL
    );
  END IF;
END;
$$;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION get_admin_settings() TO authenticated;
GRANT EXECUTE ON FUNCTION update_admin_settings(text, text) TO authenticated;
REVOKE EXECUTE ON FUNCTION encrypt_sensitive_data(text) FROM public;
REVOKE EXECUTE ON FUNCTION decrypt_sensitive_data(text) FROM public;