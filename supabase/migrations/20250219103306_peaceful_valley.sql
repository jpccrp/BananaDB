-- Drop existing function to update its return type
DROP FUNCTION IF EXISTS get_admin_settings();

-- Create a simpler version of get_admin_settings that doesn't try to decrypt
CREATE OR REPLACE FUNCTION get_admin_settings()
RETURNS TABLE (
  gemini_api_key text,
  gemini_prompt text,
  deepseek_api_key text,
  deepseek_prompt text,
  ai_provider text,
  key_last_validated timestamptz,
  key_is_valid boolean,
  key_error_message text
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    a.gemini_api_key,
    a.gemini_prompt,
    a.deepseek_api_key,
    a.deepseek_prompt,
    COALESCE(a.ai_provider, 'gemini'),
    a.key_last_validated,
    COALESCE(a.key_is_valid, false),
    a.key_error_message
  FROM admin_settings a
  WHERE id = 1;
  
  -- If no settings exist, return empty values
  IF NOT FOUND THEN
    RETURN QUERY SELECT
      ''::text,
      ''::text,
      ''::text,
      ''::text,
      'gemini'::text,
      NULL::timestamptz,
      false::boolean,
      NULL::text;
  END IF;
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION get_admin_settings() TO authenticated;