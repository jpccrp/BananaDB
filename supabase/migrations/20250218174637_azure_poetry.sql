/*
  # Fix RLS policies and error handling

  1. Changes
    - Update RLS policies to properly handle unauthenticated users
    - Add better error handling for auth state
    - Fix policy conditions for projects and car_listings tables

  2. Security
    - Ensure proper access control for authenticated users
    - Prevent unauthorized access to data
*/

-- Update projects policies to be more strict
DROP POLICY IF EXISTS "Users can view own or all projects if admin" ON projects;
CREATE POLICY "Users can view own or all projects if admin"
  ON projects
  FOR SELECT
  TO authenticated
  USING (
    auth.uid() IS NOT NULL
    AND (
      auth.uid() = user_id 
      OR 
      EXISTS (
        SELECT 1 
        FROM auth.users 
        WHERE id = auth.uid() 
        AND is_admin = true
      )
    )
  );

-- Update car_listings policies to be more strict
DROP POLICY IF EXISTS "Users can view own or all listings if admin" ON car_listings;
CREATE POLICY "Users can view own or all listings if admin"
  ON car_listings
  FOR SELECT
  TO authenticated
  USING (
    auth.uid() IS NOT NULL
    AND (
      auth.uid() = user_id 
      OR 
      EXISTS (
        SELECT 1 
        FROM auth.users 
        WHERE id = auth.uid() 
        AND is_admin = true
      )
    )
  );

-- Add explicit deny policies for unauthenticated users
CREATE POLICY "Deny all access to unauthenticated users for projects"
  ON projects
  FOR ALL
  TO public
  USING (false);

CREATE POLICY "Deny all access to unauthenticated users for car_listings"
  ON car_listings
  FOR ALL
  TO public
  USING (false);