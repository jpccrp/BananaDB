/*
  # Fix API key encryption and handling

  1. Changes
    - Fix encryption handling in update_admin_settings
    - Add separate functions for updating Gemini and Deepseek settings
    - Ensure proper encryption of API keys
*/

-- Create separate functions for updating each provider's settings
CREATE OR REPLACE FUNCTION update_gemini_settings(
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

  -- Update settings
  UPDATE admin_settings
  SET 
    gemini_api_key = CASE 
      WHEN p_gemini_api_key IS NOT NULL AND p_gemini_api_key != '' THEN
        encrypt_sensitive_data(p_gemini_api_key)
      ELSE
        gemini_api_key -- Keep existing value if new one is empty
      END,
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
      CASE 
        WHEN p_gemini_api_key IS NOT NULL AND p_gemini_api_key != '' THEN
          encrypt_sensitive_data(p_gemini_api_key)
        ELSE
          NULL
        END,
      p_gemini_prompt,
      'gemini'
    );
  END IF;
END;
$$;

CREATE OR REPLACE FUNCTION update_deepseek_settings(
  p_deepseek_api_key text,
  p_deepseek_prompt text
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

  -- Update settings
  UPDATE admin_settings
  SET 
    deepseek_api_key = CASE 
      WHEN p_deepseek_api_key IS NOT NULL AND p_deepseek_api_key != '' THEN
        encrypt_sensitive_data(p_deepseek_api_key)
      ELSE
        deepseek_api_key -- Keep existing value if new one is empty
      END,
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
      CASE 
        WHEN p_deepseek_api_key IS NOT NULL AND p_deepseek_api_key != '' THEN
          encrypt_sensitive_data(p_deepseek_api_key)
        ELSE
          NULL
        END,
      p_deepseek_prompt,
      'deepseek'
    );
  END IF;
END;
$$;

-- Update the AI provider selection function
CREATE OR REPLACE FUNCTION update_ai_provider(
  p_ai_provider text
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
      ai_provider
    ) VALUES (
      1,
      p_ai_provider
    );
  END IF;
END;
$$;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION update_gemini_settings(text, text) TO authenticated;
GRANT EXECUTE ON FUNCTION update_deepseek_settings(text, text) TO authenticated;
GRANT EXECUTE ON FUNCTION update_ai_provider(text) TO authenticated;