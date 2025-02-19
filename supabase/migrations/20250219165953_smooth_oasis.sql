-- Drop existing functions
DROP FUNCTION IF EXISTS get_admin_settings();
DROP FUNCTION IF EXISTS check_gemini_key();

-- Create individual getter functions
CREATE OR REPLACE FUNCTION get_gemini_settings()
RETURNS TABLE (
  api_key text,
  prompt text
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    COALESCE(gemini_api_key, ''),
    COALESCE(gemini_prompt, '')
  FROM admin_settings
  WHERE id = 1;

  IF NOT FOUND THEN
    RETURN QUERY SELECT
      ''::text,
      ''::text;
  END IF;
END;
$$;

CREATE OR REPLACE FUNCTION get_deepseek_settings()
RETURNS TABLE (
  api_key text,
  prompt text
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    COALESCE(deepseek_api_key, ''),
    COALESCE(deepseek_prompt, '')
  FROM admin_settings
  WHERE id = 1;

  IF NOT FOUND THEN
    RETURN QUERY SELECT
      ''::text,
      ''::text;
  END IF;
END;
$$;

CREATE OR REPLACE FUNCTION get_openrouter_settings()
RETURNS TABLE (
  api_key text,
  prompt text,
  site_url text,
  site_name text
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    COALESCE(openrouter_api_key, ''),
    COALESCE(openrouter_prompt, ''),
    COALESCE(site_url, ''),
    COALESCE(site_name, '')
  FROM admin_settings
  WHERE id = 1;

  IF NOT FOUND THEN
    RETURN QUERY SELECT
      ''::text,
      ''::text,
      ''::text,
      ''::text;
  END IF;
END;
$$;

CREATE OR REPLACE FUNCTION get_ai_provider()
RETURNS TABLE (
  provider text
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN QUERY
  SELECT COALESCE(ai_provider, 'gemini')
  FROM admin_settings
  WHERE id = 1;

  IF NOT FOUND THEN
    RETURN QUERY SELECT 'gemini'::text;
  END IF;
END;
$$;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION get_gemini_settings() TO authenticated;
GRANT EXECUTE ON FUNCTION get_deepseek_settings() TO authenticated;
GRANT EXECUTE ON FUNCTION get_openrouter_settings() TO authenticated;
GRANT EXECUTE ON FUNCTION get_ai_provider() TO authenticated;