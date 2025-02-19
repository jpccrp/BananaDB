-- First, drop existing functions to allow recreation
DROP FUNCTION IF EXISTS update_gemini_settings(text, text);
DROP FUNCTION IF EXISTS update_deepseek_settings(text, text);
DROP FUNCTION IF EXISTS update_ai_provider(text);

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
      deepseek_prompt,
      ai_provider
    ) VALUES (
      1,
      p_gemini_api_key,
      p_gemini_prompt,
      '',
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
      gemini_prompt,
      ai_provider
    ) VALUES (
      1,
      p_deepseek_api_key,
      p_deepseek_prompt,
      '',
      'deepseek'
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
  IF p_ai_provider NOT IN ('gemini', 'deepseek') THEN
    RAISE EXCEPTION 'Invalid AI provider. Must be either "gemini" or "deepseek"';
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
      ai_provider,
      gemini_prompt,
      deepseek_prompt
    ) VALUES (
      1,
      p_ai_provider,
      '',
      ''
    );
  END IF;
END;
$$;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION update_gemini_settings(text, text) TO authenticated;
GRANT EXECUTE ON FUNCTION update_deepseek_settings(text, text) TO authenticated;
GRANT EXECUTE ON FUNCTION update_ai_provider(text) TO authenticated;

-- Ensure default settings exist
INSERT INTO admin_settings (
  id,
  gemini_api_key,
  gemini_prompt,
  deepseek_api_key,
  deepseek_prompt,
  ai_provider
) VALUES (
  1,
  '',
  'You are a car listing data parser...',
  '',
  'You are a car listing data parser...',
  'gemini'
) ON CONFLICT (id) DO NOTHING;