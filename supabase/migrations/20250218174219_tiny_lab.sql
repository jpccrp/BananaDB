/*
  # Fix admin function permissions

  1. Changes
    - Grant execute permission on get_user_admin_status function to authenticated users
    - Grant execute permission on is_admin function to authenticated users
*/

-- Grant execute permissions to authenticated users
GRANT EXECUTE ON FUNCTION get_user_admin_status() TO authenticated;
GRANT EXECUTE ON FUNCTION is_admin(uuid) TO authenticated;