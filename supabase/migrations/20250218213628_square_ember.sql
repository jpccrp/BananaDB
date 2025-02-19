-- Create a function to update AI provider with proper validation
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
  
  -- Insert if not exists with default values
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

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION update_ai_provider(text) TO authenticated;

-- Ensure default row exists with proper AI provider
INSERT INTO admin_settings (id, ai_provider, gemini_prompt, deepseek_prompt)
VALUES (1, 'gemini', '', '')
ON CONFLICT (id) DO NOTHING;