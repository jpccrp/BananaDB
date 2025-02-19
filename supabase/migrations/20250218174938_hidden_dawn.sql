/*
  # Fix RLS policies for admin access

  1. Changes
    - Update RLS policies to properly handle admin access
    - Add explicit policies for admin users
    - Ensure proper access control for both regular and admin users

  2. Security
    - Maintain strict access control
    - Ensure admins can access all data
    - Regular users can only access their own data
*/

-- Update projects policies
DROP POLICY IF EXISTS "Users can view own or all projects if admin" ON projects;
CREATE POLICY "Users can view own projects"
  ON projects
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Admins can view all projects"
  ON projects
  FOR SELECT
  TO authenticated
  USING (is_admin(auth.uid()));

-- Update car_listings policies
DROP POLICY IF EXISTS "Users can view own or all listings if admin" ON car_listings;
CREATE POLICY "Users can view own listings"
  ON car_listings
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Admins can view all listings"
  ON car_listings
  FOR SELECT
  TO authenticated
  USING (is_admin(auth.uid()));