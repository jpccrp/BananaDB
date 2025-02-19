/*
  # Fix API key encryption

  1. Changes
    - Re-encrypt existing API keys with proper encryption
    - Add trigger to ensure keys are always encrypted
    - Update functions to handle encryption properly
*/

-- Re-encrypt existing API keys with proper encryption
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

-- Create trigger function to handle key updates
CREATE OR REPLACE FUNCTION handle_api_key_updates()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Reset validation status when keys change
  IF (
    NEW.gemini_api_key IS DISTINCT FROM OLD.gemini_api_key OR
    NEW.deepseek_api_key IS DISTINCT FROM OLD.deepseek_api_key
  ) THEN
    NEW.key_last_validated = NULL;
    NEW.key_is_valid = false;
    NEW.key_error_message = NULL;
  END IF;

  -- Ensure keys are encrypted
  IF NEW.gemini_api_key IS NOT NULL AND NEW.gemini_api_key != '' THEN
    NEW.gemini_api_key = encrypt_sensitive_data(NEW.gemini_api_key);
  END IF;

  IF NEW.deepseek_api_key IS NOT NULL AND NEW.deepseek_api_key != '' THEN
    NEW.deepseek_api_key = encrypt_sensitive_data(NEW.deepseek_api_key);
  END IF;

  RETURN NEW;
END;
$$;

-- Create trigger for API key updates
DROP TRIGGER IF EXISTS api_key_updates ON admin_settings;
CREATE TRIGGER api_key_updates
  BEFORE UPDATE ON admin_settings
  FOR EACH ROW
  EXECUTE FUNCTION handle_api_key_updates();

-- Update functions to handle encryption properly
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
        p_gemini_api_key -- Trigger will handle encryption
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
      p_gemini_api_key, -- Trigger will handle encryption
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
        p_deepseek_api_key -- Trigger will handle encryption
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
      p_deepseek_api_key, -- Trigger will handle encryption
      p_deepseek_prompt,
      'deepseek'
    );
  END IF;
END;
$$;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION update_gemini_settings(text, text) TO authenticated;
GRANT EXECUTE ON FUNCTION update_deepseek_settings(text, text) TO authenticated;