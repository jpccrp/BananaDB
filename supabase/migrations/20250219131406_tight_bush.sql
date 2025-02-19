-- Verify auth schema permissions
DO $$ 
BEGIN
  -- Ensure auth schema exists
  IF NOT EXISTS (
    SELECT 1 
    FROM information_schema.schemata 
    WHERE schema_name = 'auth'
  ) THEN
    RAISE EXCEPTION 'auth schema does not exist';
  END IF;

  -- Ensure users table exists in auth schema
  IF NOT EXISTS (
    SELECT 1 
    FROM information_schema.tables 
    WHERE table_schema = 'auth' 
    AND table_name = 'users'
  ) THEN
    RAISE EXCEPTION 'auth.users table does not exist';
  END IF;

  -- Ensure is_admin column exists
  IF NOT EXISTS (
    SELECT 1 
    FROM information_schema.columns 
    WHERE table_schema = 'auth' 
    AND table_name = 'users' 
    AND column_name = 'is_admin'
  ) THEN
    RAISE EXCEPTION 'is_admin column does not exist in auth.users';
  END IF;
END $$;

-- Verify function permissions
DO $$ 
BEGIN
  -- Revoke all permissions and regrant them
  REVOKE ALL ON FUNCTION get_user_admin_status() FROM PUBLIC;
  REVOKE ALL ON FUNCTION get_user_admin_status() FROM authenticated;
  REVOKE ALL ON FUNCTION is_admin(uuid) FROM PUBLIC;
  REVOKE ALL ON FUNCTION is_admin(uuid) FROM authenticated;

  -- Grant proper permissions
  GRANT EXECUTE ON FUNCTION get_user_admin_status() TO authenticated;
  GRANT EXECUTE ON FUNCTION is_admin(uuid) TO authenticated;
END $$;

-- Set admin status for user if they exist
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