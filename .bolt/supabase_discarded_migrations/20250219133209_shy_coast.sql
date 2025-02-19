-- Drop existing functions to recreate them
DROP FUNCTION IF EXISTS check_gemini_key();
DROP FUNCTION IF EXISTS get_admin_settings();

-- Create get_admin_settings function with validation fields
CREATE OR REPLACE FUNCTION get_admin_settings()
RETURNS TABLE (
  gemini_api_key text,
  gemini_prompt text,
  deepseek_api_key text,
  deepseek_prompt text,
  ai_provider text,
  key_is_valid boolean,
  key_error_message text
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    COALESCE(a.gemini_api_key, ''),
    COALESCE(a.gemini_prompt, ''),
    COALESCE(a.deepseek_api_key, ''),
    COALESCE(a.deepseek_prompt, ''),
    COALESCE(a.ai_provider, 'gemini'),
    a.gemini_api_key IS NOT NULL AND a.gemini_api_key != '' AND 
    a.gemini_prompt IS NOT NULL AND a.gemini_prompt != '',
    CASE 
      WHEN a.gemini_api_key IS NULL OR a.gemini_api_key = '' THEN 'Missing API key'
      WHEN a.gemini_prompt IS NULL OR a.gemini_prompt = '' THEN 'Missing prompt'
      ELSE NULL
    END
  FROM admin_settings a
  WHERE id = 1;

  IF NOT FOUND THEN
    RETURN QUERY SELECT
      ''::text,
      ''::text,
      ''::text,
      ''::text,
      'gemini'::text,
      false,
      'No settings configured'::text;
  END IF;
END;
$$;

-- Create check_gemini_key function with validation fields
CREATE OR REPLACE FUNCTION check_gemini_key()
RETURNS TABLE (
  has_key boolean,
  has_prompt boolean,
  is_valid boolean,
  error_message text
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    a.gemini_api_key IS NOT NULL AND a.gemini_api_key != '',
    a.gemini_prompt IS NOT NULL AND a.gemini_prompt != '',
    a.gemini_api_key IS NOT NULL AND a.gemini_api_key != '' AND 
    a.gemini_prompt IS NOT NULL AND a.gemini_prompt != '',
    CASE 
      WHEN a.gemini_api_key IS NULL OR a.gemini_api_key = '' THEN 'Missing API key'
      WHEN a.gemini_prompt IS NULL OR a.gemini_prompt = '' THEN 'Missing prompt'
      ELSE NULL
    END
  FROM admin_settings a
  WHERE id = 1;

  IF NOT FOUND THEN
    RETURN QUERY SELECT
      false,
      false,
      false,
      'No settings configured'::text;
  END IF;
END;
$$;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION get_admin_settings() TO authenticated;
GRANT EXECUTE ON FUNCTION check_gemini_key() TO authenticated;