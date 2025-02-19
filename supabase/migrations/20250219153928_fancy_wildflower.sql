-- Drop existing functions to recreate them
DROP FUNCTION IF EXISTS check_gemini_key();

-- Create improved check_gemini_key function that also returns provider
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
      ELSE
        a.deepseek_api_key IS NOT NULL AND a.deepseek_api_key != ''
    END,
    CASE 
      WHEN a.ai_provider = 'gemini' THEN
        a.gemini_prompt IS NOT NULL AND a.gemini_prompt != ''
      ELSE
        a.deepseek_prompt IS NOT NULL AND a.deepseek_prompt != ''
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

-- Grant execute permission
GRANT EXECUTE ON FUNCTION check_gemini_key() TO authenticated;