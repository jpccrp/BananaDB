/*
  # Add Data Sources View Function
  
  1. New Functions
    - `get_available_data_sources`: Returns all data sources for authenticated users
  
  2. Security
    - Function is accessible to all authenticated users
*/

-- Create function to get available data sources for all users
CREATE OR REPLACE FUNCTION get_available_data_sources()
RETURNS TABLE (
  id INTEGER,
  name TEXT,
  country TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT ds.id, ds.name, ds.country
  FROM data_sources ds
  ORDER BY ds.name;
END;
$$;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION get_available_data_sources() TO authenticated;