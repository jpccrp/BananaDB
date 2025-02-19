-- Drop existing encryption functions
DROP FUNCTION IF EXISTS encrypt_sensitive_data(text);
DROP FUNCTION IF EXISTS decrypt_sensitive_data(text);

-- Create simpler encryption functions that use base64 encoding
CREATE OR REPLACE FUNCTION encrypt_sensitive_data(input text)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Simple base64 encoding for now
  RETURN encode(convert_to(input, 'UTF8'), 'base64');
EXCEPTION
  WHEN OTHERS THEN
    RETURN input;
END;
$$;

CREATE OR REPLACE FUNCTION decrypt_sensitive_data(encrypted_data text)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Simple base64 decoding
  RETURN convert_from(decode(encrypted_data, 'base64'), 'UTF8');
EXCEPTION
  WHEN OTHERS THEN
    RETURN encrypted_data;
END;
$$;

-- Re-encrypt existing API keys with the new method
UPDATE admin_settings
SET 
  gemini_api_key = CASE 
    WHEN gemini_api_key IS NOT NULL AND gemini_api_key != '' THEN
      encrypt_sensitive_data(gemini_api_key)
    ELSE
      gemini_api_key
    END,
  deepseek_api_key = CASE 
    WHEN deepseek_api_key IS NOT NULL AND deepseek_api_key != '' THEN
      encrypt_sensitive_data(deepseek_api_key)
    ELSE
      deepseek_api_key
    END
WHERE id = 1;

-- Revoke execute from public
REVOKE EXECUTE ON FUNCTION encrypt_sensitive_data(text) FROM public;
REVOKE EXECUTE ON FUNCTION decrypt_sensitive_data(text) FROM public;