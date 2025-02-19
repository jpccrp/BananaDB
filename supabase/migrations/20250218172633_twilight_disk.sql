/*
  # Add admin role functionality

  1. Changes
    - Add admin role to auth.users
    - Update RLS policies to allow admin access
    - Add function to manage admin status

  2. Security
    - Only superuser can grant/revoke admin status
    - Admins can view all data but can't modify other users' admin status
*/

-- Add is_admin column to auth.users
ALTER TABLE auth.users ADD COLUMN IF NOT EXISTS is_admin boolean DEFAULT false;

-- Create function to manage admin status (only superuser can execute)
CREATE OR REPLACE FUNCTION manage_admin_status(user_email text, make_admin boolean)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE auth.users
  SET is_admin = make_admin
  WHERE email = user_email;
END;
$$;

-- Revoke execute from public and grant only to superuser
REVOKE EXECUTE ON FUNCTION manage_admin_status FROM public;
GRANT EXECUTE ON FUNCTION manage_admin_status TO postgres;

-- Update projects policies
DROP POLICY IF EXISTS "Users can view their own projects" ON projects;
CREATE POLICY "Users can view own or all projects if admin"
  ON projects
  FOR SELECT
  TO authenticated
  USING (
    auth.uid() = user_id 
    OR 
    EXISTS (
      SELECT 1 FROM auth.users 
      WHERE id = auth.uid() 
      AND is_admin = true
    )
  );

-- Update car_listings policies
DROP POLICY IF EXISTS "Users can view their own car listings" ON car_listings;
CREATE POLICY "Users can view own or all listings if admin"
  ON car_listings
  FOR SELECT
  TO authenticated
  USING (
    auth.uid() = user_id 
    OR 
    EXISTS (
      SELECT 1 FROM auth.users 
      WHERE id = auth.uid() 
      AND is_admin = true
    )
  );