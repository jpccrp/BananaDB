-- First, create a backup of existing data
CREATE TEMP TABLE admin_settings_backup AS 
SELECT * FROM admin_settings;

-- Drop existing table
DROP TABLE admin_settings;

-- Create new table with OpenRouter support
CREATE TABLE admin_settings (
  id integer PRIMARY KEY CHECK (id = 1),
  gemini_api_key text,
  gemini_prompt text NOT NULL,
  deepseek_api_key text,
  deepseek_prompt text NOT NULL,
  openrouter_api_key text,
  openrouter_prompt text NOT NULL DEFAULT '',
  site_url text,
  site_name text,
  ai_provider text NOT NULL DEFAULT 'gemini' CHECK (ai_provider IN ('gemini', 'deepseek', 'openrouter')),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- Restore data from backup
INSERT INTO admin_settings (
  id,
  gemini_api_key,
  gemini_prompt,
  deepseek_api_key,
  deepseek_prompt,
  ai_provider,
  updated_at
)
SELECT 
  id,
  gemini_api_key,
  gemini_prompt,
  deepseek_api_key,
  deepseek_prompt,
  ai_provider,
  updated_at
FROM admin_settings_backup;

-- Drop backup table
DROP TABLE admin_settings_backup;

-- Enable RLS
ALTER TABLE admin_settings ENABLE ROW LEVEL SECURITY;

-- Recreate RLS policies
CREATE POLICY "Anyone can read admin_settings"
  ON admin_settings
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Admins can update admin_settings"
  ON admin_settings
  FOR UPDATE
  TO authenticated
  USING (is_admin(auth.uid()))
  WITH CHECK (is_admin(auth.uid()));

CREATE POLICY "Admins can insert admin_settings"
  ON admin_settings
  FOR INSERT
  TO authenticated
  WITH CHECK (is_admin(auth.uid()));

-- Drop existing functions
DROP FUNCTION IF EXISTS get_admin_settings();
DROP FUNCTION IF EXISTS check_gemini_key();
DROP FUNCTION IF EXISTS update_gemini_settings(text, text);
DROP FUNCTION IF EXISTS update_deepseek_settings(text, text);
DROP FUNCTION IF EXISTS update_ai_provider(text);

-- Create get_admin_settings function
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

-- Create check_gemini_key function
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
    a.ai_provider
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

-- Create function to update Gemini settings
CREATE OR REPLACE FUNCTION update_gemini_settings(
  p_gemini_api_key text,
  p_gemini_prompt text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Only allow admins to update settings
  IF NOT is_admin(auth.uid()) THEN
    RAISE EXCEPTION 'Only administrators can update settings';
  END IF;

  -- Update settings
  UPDATE admin_settings
  SET 
    gemini_api_key = p_gemini_api_key,
    gemini_prompt = p_gemini_prompt,
    updated_at = now()
  WHERE id = 1;
  
  -- Insert if not exists
  IF NOT FOUND THEN
    INSERT INTO admin_settings (
      id, 
      gemini_api_key,
      gemini_prompt,
      ai_provider
    ) VALUES (
      1,
      p_gemini_api_key,
      p_gemini_prompt,
      'gemini'
    );
  END IF;
END;
$$;

-- Create function to update Deepseek settings
CREATE OR REPLACE FUNCTION update_deepseek_settings(
  p_deepseek_api_key text,
  p_deepseek_prompt text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Only allow admins to update settings
  IF NOT is_admin(auth.uid()) THEN
    RAISE EXCEPTION 'Only administrators can update settings';
  END IF;

  -- Update settings
  UPDATE admin_settings
  SET 
    deepseek_api_key = p_deepseek_api_key,
    deepseek_prompt = p_deepseek_prompt,
    updated_at = now()
  WHERE id = 1;
  
  -- Insert if not exists
  IF NOT FOUND THEN
    INSERT INTO admin_settings (
      id, 
      deepseek_api_key,
      deepseek_prompt,
      ai_provider
    ) VALUES (
      1,
      p_deepseek_api_key,
      p_deepseek_prompt,
      'deepseek'
    );
  END IF;
END;
$$;

-- Create function to update OpenRouter settings
CREATE OR REPLACE FUNCTION update_openrouter_settings(
  p_openrouter_api_key text,
  p_openrouter_prompt text,
  p_site_url text,
  p_site_name text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Only allow admins to update settings
  IF NOT is_admin(auth.uid()) THEN
    RAISE EXCEPTION 'Only administrators can update settings';
  END IF;

  -- Update settings
  UPDATE admin_settings
  SET 
    openrouter_api_key = p_openrouter_api_key,
    openrouter_prompt = p_openrouter_prompt,
    site_url = p_site_url,
    site_name = p_site_name,
    updated_at = now()
  WHERE id = 1;
  
  -- Insert if not exists
  IF NOT FOUND THEN
    INSERT INTO admin_settings (
      id, 
      openrouter_api_key,
      openrouter_prompt,
      site_url,
      site_name,
      ai_provider
    ) VALUES (
      1,
      p_openrouter_api_key,
      p_openrouter_prompt,
      p_site_url,
      p_site_name,
      'openrouter'
    );
  END IF;
END;
$$;

-- Create function to update AI provider
CREATE OR REPLACE FUNCTION update_ai_provider(
  p_ai_provider text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Only allow admins to update settings
  IF NOT is_admin(auth.uid()) THEN
    RAISE EXCEPTION 'Only administrators can update settings';
  END IF;

  -- Validate AI provider
  IF p_ai_provider NOT IN ('gemini', 'deepseek', 'openrouter') THEN
    RAISE EXCEPTION 'Invalid AI provider. Must be either "gemini", "deepseek", or "openrouter"';
  END IF;

  -- Update settings
  UPDATE admin_settings
  SET 
    ai_provider = p_ai_provider,
    updated_at = now()
  WHERE id = 1;
  
  -- Insert if not exists
  IF NOT FOUND THEN
    INSERT INTO admin_settings (
      id, 
      ai_provider
    ) VALUES (
      1,
      p_ai_provider
    );
  END IF;
END;
$$;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION get_admin_settings() TO authenticated;
GRANT EXECUTE ON FUNCTION check_gemini_key() TO authenticated;
GRANT EXECUTE ON FUNCTION update_gemini_settings(text, text) TO authenticated;
GRANT EXECUTE ON FUNCTION update_deepseek_settings(text, text) TO authenticated;
GRANT EXECUTE ON FUNCTION update_openrouter_settings(text, text, text, text) TO authenticated;
GRANT EXECUTE ON FUNCTION update_ai_provider(text) TO authenticated;