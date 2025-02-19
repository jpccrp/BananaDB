/*
  # Add Gemini key check function
  
  1. New Functions
    - check_gemini_key: Simple function to check Gemini API key status
  
  2. Security
    - Function is security definer
    - Only accessible to authenticated users
*/

-- Create a dedicated function to check Gemini key status
CREATE OR REPLACE FUNCTION check_gemini_key()
RETURNS TABLE (
  has_key boolean,
  has_prompt boolean,
  is_valid boolean,
  last_checked timestamptz,
  error_message text
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    a.gemini_api_key IS NOT NULL AND a.gemini_api_key != '',
    a.gemini_prompt IS NOT NULL AND a.gemini_prompt != '',
    COALESCE(a.key_is_valid, false),
    a.key_last_validated,
    a.key_error_message
  FROM admin_settings a
  WHERE id = 1;

  -- If no settings found, return defaults
  IF NOT FOUND THEN
    RETURN QUERY SELECT
      false,
      false,
      false,
      NULL::timestamptz,
      'No settings configured'::text;
  END IF;
END;
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION check_gemini_key() TO authenticated;