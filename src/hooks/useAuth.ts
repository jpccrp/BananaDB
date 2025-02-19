import { useEffect, useState } from 'react';
import { useSupabaseClient, useSession } from '@supabase/auth-helpers-react';
import type { User } from '@supabase/supabase-js';

export function useAuth() {
  const supabase = useSupabaseClient();
  const session = useSession();
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);
  const [isAdmin, setIsAdmin] = useState(false);

  const checkAdminStatus = async (currentUser: User) => {
    try {
      const { data, error } = await supabase.rpc('get_user_admin_status');
      if (error) return false;
      return !!data;
    } catch (err) {
      return false;
    }
  };

  useEffect(() => {
    const currentUser = session?.user ?? null;
    setUser(currentUser);

    if (currentUser) {
      checkAdminStatus(currentUser).then(adminStatus => {
        setIsAdmin(adminStatus);
      });
    } else {
      setIsAdmin(false);
    }

    setLoading(false);
  }, [session]);

  const signOut = async () => {
    try {
      await supabase.auth.signOut();
    } catch (error) {
      console.error('Error signing out:', error);
    }
  };

  return {
    user,
    loading,
    signOut,
    isAdmin,
  };
}