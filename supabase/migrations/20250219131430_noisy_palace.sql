-- Add is_admin column to auth.users if it doesn't exist
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 
    FROM information_schema.columns 
    WHERE table_schema = 'auth' 
    AND table_name = 'users' 
    AND column_name = 'is_admin'
  ) THEN
    ALTER TABLE auth.users ADD COLUMN is_admin boolean DEFAULT false;
  END IF;
END $$;

-- Create or replace admin functions
CREATE OR REPLACE FUNCTION is_admin(user_id uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  _is_admin boolean;
BEGIN
  SELECT is_admin INTO _is_admin
  FROM auth.users
  WHERE id = user_id;
  
  RETURN COALESCE(_is_admin, false);
END;
$$;

CREATE OR REPLACE FUNCTION get_user_admin_status()
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN is_admin(auth.uid());
END;
$$;

-- Grant execute permissions
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