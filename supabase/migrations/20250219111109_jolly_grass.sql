-- Set explicit search paths for all functions
ALTER FUNCTION get_admin_settings() SET search_path = public;
ALTER FUNCTION manage_admin_status(text, boolean) SET search_path = public;
ALTER FUNCTION get_user_admin_status() SET search_path = public;
ALTER FUNCTION is_admin(uuid) SET search_path = public;
ALTER FUNCTION update_gemini_settings(text, text) SET search_path = public;
ALTER FUNCTION update_deepseek_settings(text, text) SET search_path = public;
ALTER FUNCTION update_ai_provider(text) SET search_path = public;
ALTER FUNCTION get_data_sources() SET search_path = public;
ALTER FUNCTION get_available_data_sources() SET search_path = public;

-- Re-grant necessary permissions
GRANT EXECUTE ON FUNCTION get_admin_settings() TO authenticated;
GRANT EXECUTE ON FUNCTION get_user_admin_status() TO authenticated;
GRANT EXECUTE ON FUNCTION is_admin(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION update_gemini_settings(text, text) TO authenticated;
GRANT EXECUTE ON FUNCTION update_deepseek_settings(text, text) TO authenticated;
GRANT EXECUTE ON FUNCTION update_ai_provider(text) TO authenticated;
GRANT EXECUTE ON FUNCTION get_data_sources() TO authenticated;
GRANT EXECUTE ON FUNCTION get_available_data_sources() TO authenticated;