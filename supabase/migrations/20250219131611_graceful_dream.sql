-- First, temporarily disable RLS on all tables
ALTER TABLE projects DISABLE ROW LEVEL SECURITY;
ALTER TABLE car_listings DISABLE ROW LEVEL SECURITY;
ALTER TABLE data_sources DISABLE ROW LEVEL SECURITY;
ALTER TABLE admin_settings DISABLE ROW LEVEL SECURITY;

-- Drop all existing policies
DROP POLICY IF EXISTS "Users can view own projects" ON projects;
DROP POLICY IF EXISTS "Admins can view all projects" ON projects;
DROP POLICY IF EXISTS "Users can view own listings" ON car_listings;
DROP POLICY IF EXISTS "Admins can view all listings" ON car_listings;
DROP POLICY IF EXISTS "Admins can view data sources" ON data_sources;
DROP POLICY IF EXISTS "Admins can insert data sources" ON data_sources;
DROP POLICY IF EXISTS "Admins can update data sources" ON data_sources;
DROP POLICY IF EXISTS "Admins can delete data sources" ON data_sources;
DROP POLICY IF EXISTS "Anyone can read admin_settings" ON admin_settings;
DROP POLICY IF EXISTS "Admins can update admin_settings" ON admin_settings;
DROP POLICY IF EXISTS "Admins can insert admin_settings" ON admin_settings;

-- Now we can safely drop and recreate the functions
DROP FUNCTION IF EXISTS get_user_admin_status();
DROP FUNCTION IF EXISTS is_admin(uuid);

-- Create base is_admin function with better error handling
CREATE FUNCTION is_admin(user_id uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  _is_admin boolean;
BEGIN
  IF user_id IS NULL THEN
    RETURN false;
  END IF;

  SELECT is_admin INTO _is_admin
  FROM auth.users
  WHERE id = user_id;
  
  RETURN COALESCE(_is_admin, false);
END;
$$;

-- Create user-facing admin status check
CREATE FUNCTION get_user_admin_status()
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  _user_id uuid;
BEGIN
  -- Get current user ID
  _user_id := auth.uid();
  
  IF _user_id IS NULL THEN
    RETURN false;
  END IF;

  -- Use is_admin function to check status
  RETURN is_admin(_user_id);
END;
$$;

-- Re-enable RLS
ALTER TABLE projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE car_listings ENABLE ROW LEVEL SECURITY;
ALTER TABLE data_sources ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_settings ENABLE ROW LEVEL SECURITY;

-- Recreate policies for projects
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

-- Recreate policies for car_listings
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

-- Recreate policies for data_sources
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

-- Recreate policies for admin_settings
CREATE POLICY "Anyone can read admin_settings"
  ON admin_settings
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Admins can update admin_settings"
  ON admin_settings
  FOR UPDATE
  TO authenticated
  USING (is_admin(auth.uid()))
  WITH CHECK (is_admin(auth.uid()));

CREATE POLICY "Admins can insert admin_settings"
  ON admin_settings
  FOR INSERT
  TO authenticated
  WITH CHECK (is_admin(auth.uid()));

-- Ensure proper permissions
REVOKE ALL ON FUNCTION is_admin(uuid) FROM public;
REVOKE ALL ON FUNCTION get_user_admin_status() FROM public;

GRANT EXECUTE ON FUNCTION is_admin(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION get_user_admin_status() TO authenticated;

-- Set admin status for specific user if they exist
UPDATE auth.users
SET is_admin = true
WHERE email = 'g8sh8s@gmail.com';

-- Log status
DO $$
DECLARE
  _user_count integer;
BEGIN
  SELECT COUNT(*) INTO _user_count
  FROM auth.users
  WHERE email = 'g8sh8s@gmail.com';

  IF _user_count = 0 THEN
    RAISE NOTICE 'User g8sh8s@gmail.com does not exist yet. Admin status will be set when they sign up.';
  ELSE
    RAISE NOTICE 'Admin status set for user g8sh8s@gmail.com';
  END IF;
END $$;