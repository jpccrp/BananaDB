-- Drop existing functions
DROP FUNCTION IF EXISTS get_admin_settings();
DROP FUNCTION IF EXISTS check_gemini_key();

-- Create individual getter functions
CREATE OR REPLACE FUNCTION get_gemini_apikey()
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN (
    SELECT COALESCE(gemini_api_key, '')
    FROM admin_settings
    WHERE id = 1
  );
END;
$$;

CREATE OR REPLACE FUNCTION get_gemini_prompt()
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN (
    SELECT COALESCE(gemini_prompt, '')
    FROM admin_settings
    WHERE id = 1
  );
END;
$$;

CREATE OR REPLACE FUNCTION get_deepseek_apikey()
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN (
    SELECT COALESCE(deepseek_api_key, '')
    FROM admin_settings
    WHERE id = 1
  );
END;
$$;

CREATE OR REPLACE FUNCTION get_deepseek_prompt()
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN (
    SELECT COALESCE(deepseek_prompt, '')
    FROM admin_settings
    WHERE id = 1
  );
END;
$$;

CREATE OR REPLACE FUNCTION get_openrouter_apikey()
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN (
    SELECT COALESCE(openrouter_api_key, '')
    FROM admin_settings
    WHERE id = 1
  );
END;
$$;

CREATE OR REPLACE FUNCTION get_openrouter_prompt()
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN (
    SELECT COALESCE(openrouter_prompt, '')
    FROM admin_settings
    WHERE id = 1
  );
END;
$$;

CREATE OR REPLACE FUNCTION get_openrouter_site_url()
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN (
    SELECT COALESCE(site_url, '')
    FROM admin_settings
    WHERE id = 1
  );
END;
$$;

CREATE OR REPLACE FUNCTION get_openrouter_site_name()
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN (
    SELECT COALESCE(site_name, '')
    FROM admin_settings
    WHERE id = 1
  );
END;
$$;

CREATE OR REPLACE FUNCTION get_ai_provider()
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN (
    SELECT COALESCE(ai_provider, 'gemini')
    FROM admin_settings
    WHERE id = 1
  );
END;
$$;

-- Create individual setter functions
CREATE OR REPLACE FUNCTION set_gemini_apikey(p_value text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT is_admin(auth.uid()) THEN
    RAISE EXCEPTION 'Only administrators can update settings';
  END IF;

  UPDATE admin_settings
  SET gemini_api_key = p_value
  WHERE id = 1;
  
  IF NOT FOUND THEN
    INSERT INTO admin_settings (id, gemini_api_key)
    VALUES (1, p_value);
  END IF;
END;
$$;

CREATE OR REPLACE FUNCTION set_gemini_prompt(p_value text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT is_admin(auth.uid()) THEN
    RAISE EXCEPTION 'Only administrators can update settings';
  END IF;

  UPDATE admin_settings
  SET gemini_prompt = p_value
  WHERE id = 1;
  
  IF NOT FOUND THEN
    INSERT INTO admin_settings (id, gemini_prompt)
    VALUES (1, p_value);
  END IF;
END;
$$;

CREATE OR REPLACE FUNCTION set_deepseek_apikey(p_value text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT is_admin(auth.uid()) THEN
    RAISE EXCEPTION 'Only administrators can update settings';
  END IF;

  UPDATE admin_settings
  SET deepseek_api_key = p_value
  WHERE id = 1;
  
  IF NOT FOUND THEN
    INSERT INTO admin_settings (id, deepseek_api_key)
    VALUES (1, p_value);
  END IF;
END;
$$;

CREATE OR REPLACE FUNCTION set_deepseek_prompt(p_value text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT is_admin(auth.uid()) THEN
    RAISE EXCEPTION 'Only administrators can update settings';
  END IF;

  UPDATE admin_settings
  SET deepseek_prompt = p_value
  WHERE id = 1;
  
  IF NOT FOUND THEN
    INSERT INTO admin_settings (id, deepseek_prompt)
    VALUES (1, p_value);
  END IF;
END;
$$;

CREATE OR REPLACE FUNCTION set_openrouter_apikey(p_value text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT is_admin(auth.uid()) THEN
    RAISE EXCEPTION 'Only administrators can update settings';
  END IF;

  UPDATE admin_settings
  SET openrouter_api_key = p_value
  WHERE id = 1;
  
  IF NOT FOUND THEN
    INSERT INTO admin_settings (id, openrouter_api_key)
    VALUES (1, p_value);
  END IF;
END;
$$;

CREATE OR REPLACE FUNCTION set_openrouter_prompt(p_value text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT is_admin(auth.uid()) THEN
    RAISE EXCEPTION 'Only administrators can update settings';
  END IF;

  UPDATE admin_settings
  SET openrouter_prompt = p_value
  WHERE id = 1;
  
  IF NOT FOUND THEN
    INSERT INTO admin_settings (id, openrouter_prompt)
    VALUES (1, p_value);
  END IF;
END;
$$;

CREATE OR REPLACE FUNCTION set_openrouter_site_url(p_value text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT is_admin(auth.uid()) THEN
    RAISE EXCEPTION 'Only administrators can update settings';
  END IF;

  UPDATE admin_settings
  SET site_url = p_value
  WHERE id = 1;
  
  IF NOT FOUND THEN
    INSERT INTO admin_settings (id, site_url)
    VALUES (1, p_value);
  END IF;
END;
$$;

CREATE OR REPLACE FUNCTION set_openrouter_site_name(p_value text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT is_admin(auth.uid()) THEN
    RAISE EXCEPTION 'Only administrators can update settings';
  END IF;

  UPDATE admin_settings
  SET site_name = p_value
  WHERE id = 1;
  
  IF NOT FOUND THEN
    INSERT INTO admin_settings (id, site_name)
    VALUES (1, p_value);
  END IF;
END;
$$;

CREATE OR REPLACE FUNCTION set_ai_provider(p_value text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT is_admin(auth.uid()) THEN
    RAISE EXCEPTION 'Only administrators can update settings';
  END IF;

  IF p_value NOT IN ('gemini', 'deepseek', 'openrouter') THEN
    RAISE EXCEPTION 'Invalid AI provider. Must be either "gemini", "deepseek", or "openrouter"';
  END IF;

  UPDATE admin_settings
  SET ai_provider = p_value
  WHERE id = 1;
  
  IF NOT FOUND THEN
    INSERT INTO admin_settings (id, ai_provider)
    VALUES (1, p_value);
  END IF;
END;
$$;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION get_gemini_apikey() TO authenticated;
GRANT EXECUTE ON FUNCTION get_gemini_prompt() TO authenticated;
GRANT EXECUTE ON FUNCTION get_deepseek_apikey() TO authenticated;
GRANT EXECUTE ON FUNCTION get_deepseek_prompt() TO authenticated;
GRANT EXECUTE ON FUNCTION get_openrouter_apikey() TO authenticated;
GRANT EXECUTE ON FUNCTION get_openrouter_prompt() TO authenticated;
GRANT EXECUTE ON FUNCTION get_openrouter_site_url() TO authenticated;
GRANT EXECUTE ON FUNCTION get_openrouter_site_name() TO authenticated;
GRANT EXECUTE ON FUNCTION get_ai_provider() TO authenticated;

GRANT EXECUTE ON FUNCTION set_gemini_apikey(text) TO authenticated;
GRANT EXECUTE ON FUNCTION set_gemini_prompt(text) TO authenticated;
GRANT EXECUTE ON FUNCTION set_deepseek_apikey(text) TO authenticated;
GRANT EXECUTE ON FUNCTION set_deepseek_prompt(text) TO authenticated;
GRANT EXECUTE ON FUNCTION set_openrouter_apikey(text) TO authenticated;
GRANT EXECUTE ON FUNCTION set_openrouter_prompt(text) TO authenticated;
GRANT EXECUTE ON FUNCTION set_openrouter_site_url(text) TO authenticated;
GRANT EXECUTE ON FUNCTION set_openrouter_site_name(text) TO authenticated;
GRANT EXECUTE ON FUNCTION set_ai_provider(text) TO authenticated;