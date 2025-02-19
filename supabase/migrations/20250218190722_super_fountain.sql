-- Update admin_settings with environment variable API key
UPDATE admin_settings
SET gemini_api_key = CURRENT_SETTING('app.settings.google_api_key', TRUE)
WHERE id = 1;

-- Create function to get settings with fallback
CREATE OR REPLACE FUNCTION get_admin_settings()
RETURNS TABLE (
  gemini_api_key text,
  gemini_prompt text
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    COALESCE(a.gemini_api_key, CURRENT_SETTING('app.settings.google_api_key', TRUE)) as gemini_api_key,
    a.gemini_prompt
  FROM admin_settings a
  WHERE id = 1;
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION get_admin_settings() TO authenticated;