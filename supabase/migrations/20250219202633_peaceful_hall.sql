-- Drop existing functions
DROP FUNCTION IF EXISTS get_admin_settings();
DROP FUNCTION IF EXISTS check_gemini_key();
DROP FUNCTION IF EXISTS get_gemini_apikey();
DROP FUNCTION IF EXISTS get_gemini_prompt();
DROP FUNCTION IF EXISTS get_deepseek_apikey();
DROP FUNCTION IF EXISTS get_deepseek_prompt();
DROP FUNCTION IF EXISTS get_openrouter_apikey();
DROP FUNCTION IF EXISTS get_openrouter_prompt();
DROP FUNCTION IF EXISTS get_openrouter_site_url();
DROP FUNCTION IF EXISTS get_openrouter_site_name();
DROP FUNCTION IF EXISTS get_ai_provider();

-- Create a single function to get all settings
CREATE OR REPLACE FUNCTION get_admin_settings()
RETURNS TABLE (
  gemini_api_key text,
  gemini_prompt text,
  deepseek_api_key text,
  deepseek_prompt text,
  openrouter_api_key text,
  openrouter_prompt text,
  site_url text,
  site_name text,
  ai_provider text
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
    COALESCE(a.openrouter_api_key, ''),
    COALESCE(a.openrouter_prompt, ''),
    COALESCE(a.site_url, ''),
    COALESCE(a.site_name, ''),
    COALESCE(a.ai_provider, 'gemini')
  FROM admin_settings a
  WHERE id = 1;

  IF NOT FOUND THEN
    RETURN QUERY SELECT
      ''::text,
      ''::text,
      ''::text,
      ''::text,
      ''::text,
      ''::text,
      ''::text,
      ''::text,
      'gemini'::text;
  END IF;
END;
$$;

-- Create function to check Gemini key status
CREATE OR REPLACE FUNCTION check_gemini_key()
RETURNS TABLE (
  has_key boolean,
  has_prompt boolean,
  provider text
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    CASE 
      WHEN a.ai_provider = 'gemini' THEN
        a.gemini_api_key IS NOT NULL AND a.gemini_api_key != ''
      WHEN a.ai_provider = 'deepseek' THEN
        a.deepseek_api_key IS NOT NULL AND a.deepseek_api_key != ''
      ELSE
        a.openrouter_api_key IS NOT NULL AND a.openrouter_api_key != ''
    END,
    CASE 
      WHEN a.ai_provider = 'gemini' THEN
        a.gemini_prompt IS NOT NULL AND a.gemini_prompt != ''
      WHEN a.ai_provider = 'deepseek' THEN
        a.deepseek_prompt IS NOT NULL AND a.deepseek_prompt != ''
      ELSE
        a.openrouter_prompt IS NOT NULL AND a.openrouter_prompt != ''
    END,
    COALESCE(a.ai_provider, 'gemini')
  FROM admin_settings a
  WHERE id = 1;

  IF NOT FOUND THEN
    RETURN QUERY SELECT
      false,
      false,
      'gemini'::text;
  END IF;
END;
$$;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION get_admin_settings() TO authenticated;
GRANT EXECUTE ON FUNCTION check_gemini_key() TO authenticated;