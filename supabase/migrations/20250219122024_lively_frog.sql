-- Add logging to is_admin function
CREATE OR REPLACE FUNCTION is_admin(user_id uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  _is_admin boolean;
  _user_email text;
BEGIN
  -- Get user email for logging
  SELECT email, is_admin INTO _user_email, _is_admin
  FROM auth.users
  WHERE id = user_id;
  
  RAISE NOTICE 'is_admin check for % (ID: %): %', 
    _user_email, 
    user_id, 
    COALESCE(_is_admin, false);
  
  RETURN COALESCE(_is_admin, false);
END;
$$;

-- Verify admin users
DO $$
DECLARE
  _user record;
BEGIN
  FOR _user IN (
    SELECT id, email, is_admin
    FROM auth.users
    WHERE email = 'g8sh8s@gmail.com'
  ) LOOP
    RAISE NOTICE 'User % (ID: %): is_admin = %', 
      _user.email, 
      _user.id, 
      COALESCE(_user.is_admin, false);
      
    -- Ensure admin flag is set
    IF NOT COALESCE(_user.is_admin, false) THEN
      UPDATE auth.users
      SET is_admin = true
      WHERE id = _user.id;
      
      RAISE NOTICE 'Updated admin status to true for %', _user.email;
    END IF;
  END LOOP;
END $$;

-- Re-grant permissions
GRANT EXECUTE ON FUNCTION is_admin(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION get_user_admin_status() TO authenticated;