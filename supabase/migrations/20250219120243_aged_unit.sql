-- Drop and recreate get_user_admin_status with better debugging
CREATE OR REPLACE FUNCTION get_user_admin_status()
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  _is_admin boolean;
  _user_id uuid;
  _user_email text;
BEGIN
  -- Get current user ID
  _user_id := auth.uid();
  
  -- Get user email for logging
  SELECT email INTO _user_email
  FROM auth.users
  WHERE id = _user_id;

  -- Get admin status
  SELECT is_admin INTO _is_admin
  FROM auth.users
  WHERE id = _user_id;
  
  -- Log the check (will appear in Supabase logs)
  RAISE NOTICE 'Checking admin status for user % (ID: %): %', 
    _user_email, 
    _user_id, 
    COALESCE(_is_admin, false);
  
  RETURN COALESCE(_is_admin, false);
END;
$$;

-- Re-grant execute permission
GRANT EXECUTE ON FUNCTION get_user_admin_status() TO authenticated;

-- Verify admin flag is set correctly
DO $$
DECLARE
  _user_id uuid;
  _is_admin boolean;
BEGIN
  -- Get the user ID for the email that was made admin
  SELECT id, is_admin INTO _user_id, _is_admin
  FROM auth.users
  WHERE email = 'g8sh8s@gmail.com';
  
  RAISE NOTICE 'Current admin status for g8sh8s@gmail.com (ID: %): %',
    _user_id,
    COALESCE(_is_admin, false);
    
  -- If admin flag is not set, set it
  IF NOT COALESCE(_is_admin, false) THEN
    UPDATE auth.users
    SET is_admin = true
    WHERE id = _user_id;
    
    RAISE NOTICE 'Updated admin status to true';
  END IF;
END $$;