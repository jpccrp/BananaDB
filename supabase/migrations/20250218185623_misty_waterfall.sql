/*
  # Create admin settings table

  1. New Tables
    - `admin_settings`
      - `id` (integer, primary key)
      - `gemini_api_key` (text)
      - `gemini_prompt` (text)
      - `updated_at` (timestamp)

  2. Security
    - Enable RLS on `admin_settings` table
    - Add policies for admin access only
*/

-- Create admin_settings table
CREATE TABLE IF NOT EXISTS admin_settings (
  id integer PRIMARY KEY CHECK (id = 1), -- Only one row allowed
  gemini_api_key text,
  gemini_prompt text,
  updated_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE admin_settings ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Only admins can view settings"
  ON admin_settings
  FOR SELECT
  TO authenticated
  USING (is_admin(auth.uid()));

CREATE POLICY "Only admins can update settings"
  ON admin_settings
  FOR UPDATE
  TO authenticated
  USING (is_admin(auth.uid()))
  WITH CHECK (is_admin(auth.uid()));

CREATE POLICY "Only admins can insert settings"
  ON admin_settings
  FOR INSERT
  TO authenticated
  WITH CHECK (is_admin(auth.uid()));

-- Insert default row
INSERT INTO admin_settings (id, gemini_prompt)
VALUES (1, 'You are a car listing data parser...') -- Add your default prompt here
ON CONFLICT (id) DO NOTHING;