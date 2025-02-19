/*
  # Add admin helper functions

  1. New Functions
    - get_user_admin_status: Allows users to check their admin status
    - is_admin: Internal helper to check if a user is an admin
*/

-- Function to get user's admin status
CREATE OR REPLACE FUNCTION get_user_admin_status()
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  _is_admin boolean;
BEGIN
  SELECT is_admin INTO _is_admin
  FROM auth.users
  WHERE id = auth.uid();
  
  RETURN COALESCE(_is_admin, false);
END;
$$;

-- Function to check if a user is an admin (for internal use)
CREATE OR REPLACE FUNCTION is_admin(user_id uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
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