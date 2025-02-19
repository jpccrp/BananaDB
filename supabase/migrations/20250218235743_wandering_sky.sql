/*
  # Add Data Sources Management
  
  1. New Tables
    - `data_sources`
      - `id` (serial, primary key)
      - `name` (text, unique)
      - `country` (text)
      - `created_at` (timestamp)
  
  2. Security
    - Enable RLS
    - Add policies for admin access only
    
  3. Initial Data
    - Insert existing data sources
*/

-- Create data_sources table
CREATE TABLE IF NOT EXISTS data_sources (
  id SERIAL PRIMARY KEY,
  name TEXT UNIQUE NOT NULL,
  country TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Enable RLS
ALTER TABLE data_sources ENABLE ROW LEVEL SECURITY;

-- Create policies for admin access
CREATE POLICY "Admins can view data sources"
  ON data_sources
  FOR SELECT
  TO authenticated
  USING (is_admin(auth.uid()));

CREATE POLICY "Admins can insert data sources"
  ON data_sources
  FOR INSERT
  TO authenticated
  WITH CHECK (is_admin(auth.uid()));

CREATE POLICY "Admins can update data sources"
  ON data_sources
  FOR UPDATE
  TO authenticated
  USING (is_admin(auth.uid()))
  WITH CHECK (is_admin(auth.uid()));

CREATE POLICY "Admins can delete data sources"
  ON data_sources
  FOR DELETE
  TO authenticated
  USING (is_admin(auth.uid()));

-- Insert initial data
INSERT INTO data_sources (name, country) VALUES
  ('mobile.de', 'Germany'),
  ('autoscout24', 'Germany'),
  ('olx.pt', 'Portugal'),
  ('standvirtual.pt', 'Portugal')
ON CONFLICT (name) DO NOTHING;

-- Create function to manage data sources
CREATE OR REPLACE FUNCTION get_data_sources()
RETURNS TABLE (
  id INTEGER,
  name TEXT,
  country TEXT,
  created_at TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  IF NOT is_admin(auth.uid()) THEN
    RAISE EXCEPTION 'Only administrators can view data sources';
  END IF;

  RETURN QUERY
  SELECT ds.id, ds.name, ds.country, ds.created_at
  FROM data_sources ds
  ORDER BY ds.name;
END;
$$;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION get_data_sources() TO authenticated;