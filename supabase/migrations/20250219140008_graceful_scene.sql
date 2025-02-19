-- Drop existing functions to recreate them
DROP FUNCTION IF EXISTS check_gemini_key();
DROP FUNCTION IF EXISTS get_admin_settings();

-- Create get_admin_settings function with proper defaults
CREATE OR REPLACE FUNCTION get_admin_settings()
RETURNS TABLE (
  gemini_api_key text,
  gemini_prompt text,
  deepseek_api_key text,
  deepseek_prompt text,
  ai_provider text
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  default_prompt text := $prompt$You are a car listing data parser. Your task is to extract structured information from raw car listing text.

CRITICAL: You MUST return your response in this EXACT format:
{
  "listings": [
    {
      "make": string,              // Car manufacturer (e.g., "BMW")
      "model": string,             // Car model (e.g., "320d")
      "year": number,              // Manufacturing year as 4-digit number
      "mileage": number,           // Mileage in kilometers
      "price": number,             // Price in euros
      "fuel_type": string,         // One of: "Petrol", "Diesel", "Electric", "Hybrid", "Plug-in Hybrid"
      "first_registration_date": string, // ISO date format (YYYY-MM-DD)
      "power_kw": number,          // Power in kW
      "power_hp": number,          // Power in HP
      "gear_type": string,         // "Manual" or "Automatic"
      "seller": string,            // Seller name/dealership
      "location": string           // Location of the car
    }
  ],
  "status": "CONTINUE"            // Must be either "CONTINUE" or "DONE"
}

CRITICAL RULES:
1. Process EXACTLY 10 listings at a time (or fewer for the final batch)
2. Set status to:
   - "CONTINUE" if there are more listings to process
   - "DONE" if this is the final batch
3. Format rules:
   - Join multi-line seller names with spaces
   - Remove special characters from seller names
   - Properly escape all strings
   - No newlines in field values
4. NEVER return a plain array - always use the exact format above
5. ALWAYS include both the "listings" array and "status" field$prompt$;
BEGIN
  -- First try to get existing settings
  RETURN QUERY
  SELECT 
    COALESCE(a.gemini_api_key, ''),
    COALESCE(a.gemini_prompt, default_prompt),
    COALESCE(a.deepseek_api_key, ''),
    COALESCE(a.deepseek_prompt, default_prompt),
    COALESCE(a.ai_provider, 'gemini')
  FROM admin_settings a
  WHERE id = 1;

  -- If no row exists, return defaults
  IF NOT FOUND THEN
    RETURN QUERY SELECT
      ''::text,
      default_prompt,
      ''::text,
      default_prompt,
      'gemini'::text;
  END IF;
END;
$$;

-- Create check_gemini_key function
CREATE OR REPLACE FUNCTION check_gemini_key()
RETURNS TABLE (
  has_key boolean,
  has_prompt boolean
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    a.gemini_api_key IS NOT NULL AND a.gemini_api_key != '',
    a.gemini_prompt IS NOT NULL AND a.gemini_prompt != ''
  FROM admin_settings a
  WHERE id = 1;

  IF NOT FOUND THEN
    RETURN QUERY SELECT
      false,
      false;
  END IF;
END;
$$;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION get_admin_settings() TO authenticated;
GRANT EXECUTE ON FUNCTION check_gemini_key() TO authenticated;

-- Ensure we have a row with proper defaults
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
  $prompt$You are a car listing data parser. Your task is to extract structured information from raw car listing text.

CRITICAL: You MUST return your response in this EXACT format:
{
  "listings": [
    {
      "make": string,              // Car manufacturer (e.g., "BMW")
      "model": string,             // Car model (e.g., "320d")
      "year": number,              // Manufacturing year as 4-digit number
      "mileage": number,           // Mileage in kilometers
      "price": number,             // Price in euros
      "fuel_type": string,         // One of: "Petrol", "Diesel", "Electric", "Hybrid", "Plug-in Hybrid"
      "first_registration_date": string, // ISO date format (YYYY-MM-DD)
      "power_kw": number,          // Power in kW
      "power_hp": number,          // Power in HP
      "gear_type": string,         // "Manual" or "Automatic"
      "seller": string,            // Seller name/dealership
      "location": string           // Location of the car
    }
  ],
  "status": "CONTINUE"            // Must be either "CONTINUE" or "DONE"
}

CRITICAL RULES:
1. Process EXACTLY 10 listings at a time (or fewer for the final batch)
2. Set status to:
   - "CONTINUE" if there are more listings to process
   - "DONE" if this is the final batch
3. Format rules:
   - Join multi-line seller names with spaces
   - Remove special characters from seller names
   - Properly escape all strings
   - No newlines in field values
4. NEVER return a plain array - always use the exact format above
5. ALWAYS include both the "listings" array and "status" field$prompt$,
  '',
  $prompt$You are a car listing data parser. Your task is to extract structured information from raw car listing text.

CRITICAL: You MUST return your response in this EXACT format:
{
  "listings": [
    {
      "make": string,              // Car manufacturer (e.g., "BMW")
      "model": string,             // Car model (e.g., "320d")
      "year": number,              // Manufacturing year as 4-digit number
      "mileage": number,           // Mileage in kilometers
      "price": number,             // Price in euros
      "fuel_type": string,         // One of: "Petrol", "Diesel", "Electric", "Hybrid", "Plug-in Hybrid"
      "first_registration_date": string, // ISO date format (YYYY-MM-DD)
      "power_kw": number,          // Power in kW
      "power_hp": number,          // Power in HP
      "gear_type": string,         // "Manual" or "Automatic"
      "seller": string,            // Seller name/dealership
      "location": string           // Location of the car
    }
  ],
  "status": "CONTINUE"            // Must be either "CONTINUE" or "DONE"
}

CRITICAL RULES:
1. Process EXACTLY 10 listings at a time (or fewer for the final batch)
2. Set status to:
   - "CONTINUE" if there are more listings to process
   - "DONE" if this is the final batch
3. Format rules:
   - Join multi-line seller names with spaces
   - Remove special characters from seller names
   - Properly escape all strings
   - No newlines in field values
4. NEVER return a plain array - always use the exact format above
5. ALWAYS include both the "listings" array and "status" field$prompt$,
  'gemini'
) ON CONFLICT (id) DO UPDATE SET
  gemini_prompt = EXCLUDED.gemini_prompt,
  deepseek_prompt = EXCLUDED.deepseek_prompt;