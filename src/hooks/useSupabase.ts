import { useEffect, useState } from 'react';
import { supabase } from '../lib/supabase';
import { useAuth } from './useAuth';
import type { Database } from '../lib/database.types';

type Project = Database['public']['Tables']['projects']['Row'];
type CarListing = Database['public']['Tables']['car_listings']['Row'];

export function useProjects() {
  const [projects, setProjects] = useState<Project[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);
  const { user, isAdmin } = useAuth();

  useEffect(() => {
    const fetchProjects = async () => {
      if (!user) {
        setProjects([]);
        setLoading(false);
        return;
      }

      try {
        let query = supabase
          .from('projects')
          .select('*')
          .order('created_at', { ascending: false });

        // If not admin, only fetch user's projects
        if (!isAdmin) {
          query = query.eq('user_id', user.id);
        }

        const { data, error } = await query;

        if (error) throw error;
        setProjects(data || []);
      } catch (err) {
        console.error('Error fetching projects:', err);
        setError(err instanceof Error ? err : new Error('An error occurred'));
        setProjects([]);
      } finally {
        setLoading(false);
      }
    };

    fetchProjects();
  }, [user, isAdmin]);

  const createProject = async (project: Omit<Project, 'id' | 'created_at'>) => {
    if (!user) throw new Error('You must be logged in to create a project');

    try {
      const { data, error } = await supabase
        .from('projects')
        .insert([project])
        .select()
        .single();

      if (error) throw error;
      setProjects(prev => [data, ...prev]);
      return data;
    } catch (err) {
      throw err instanceof Error ? err : new Error('An error occurred');
    }
  };

  const updateProject = async (id: string, updates: Partial<Project>) => {
    if (!user) throw new Error('You must be logged in to update a project');

    try {
      const { data, error } = await supabase
        .from('projects')
        .update(updates)
        .eq('id', id)
        .select()
        .single();

      if (error) throw error;
      setProjects(prev => prev.map(p => p.id === id ? data : p));
      return data;
    } catch (err) {
      throw err instanceof Error ? err : new Error('An error occurred');
    }
  };

  const deleteProject = async (id: string) => {
    if (!user) throw new Error('You must be logged in to delete a project');
    if (!isAdmin) throw new Error('Only administrators can delete projects');

    try {
      const { error } = await supabase
        .from('projects')
        .delete()
        .eq('id', id);

      if (error) throw error;
      setProjects(prev => prev.filter(p => p.id !== id));
    } catch (err) {
      throw err instanceof Error ? err : new Error('An error occurred');
    }
  };

  return {
    projects,
    loading,
    error,
    createProject,
    updateProject,
    deleteProject,
  };
}

export function useCarListings(projectId?: string) {
  const [listings, setListings] = useState<CarListing[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);
  const { user, isAdmin } = useAuth();

  useEffect(() => {
    const fetchListings = async () => {
      if (!user) {
        setListings([]);
        setLoading(false);
        return;
      }

      try {
        let query = supabase
          .from('car_listings')
          .select('*')
          .order('created_at', { ascending: false });

        if (projectId) {
          query = query.eq('project_id', projectId);
        }

        // If not admin, only fetch user's listings
        if (!isAdmin) {
          query = query.eq('user_id', user.id);
        }

        const { data, error } = await query;

        if (error) throw error;
        setListings(data || []);
      } catch (err) {
        console.error('Error fetching listings:', err);
        setError(err instanceof Error ? err : new Error('An error occurred'));
        setListings([]);
      } finally {
        setLoading(false);
      }
    };

    fetchListings();
  }, [projectId, user, isAdmin]);

  const createListing = async (listing: Omit<CarListing, 'id' | 'created_at'>) => {
    if (!user) throw new Error('You must be logged in to create a listing');

    try {
      const { data, error } = await supabase
        .from('car_listings')
        .insert([listing])
        .select()
        .single();

      if (error) throw error;
      setListings(prev => [data, ...prev]);
      return data;
    } catch (err) {
      throw err instanceof Error ? err : new Error('An error occurred');
    }
  };

  const updateListing = async (id: string, updates: Partial<CarListing>) => {
    if (!user) throw new Error('You must be logged in to update a listing');

    try {
      const { data, error } = await supabase
        .from('car_listings')
        .update(updates)
        .eq('id', id)
        .select()
        .single();

      if (error) throw error;
      setListings(prev => prev.map(l => l.id === id ? data : l));
      return data;
    } catch (err) {
      throw err instanceof Error ? err : new Error('An error occurred');
    }
  };

  const deleteListing = async (id: string) => {
    if (!user) throw new Error('You must be logged in to delete a listing');

    try {
      const { error } = await supabase
        .from('car_listings')
        .delete()
        .eq('id', id);

      if (error) throw error;
      setListings(prev => prev.filter(l => l.id !== id));
    } catch (err) {
      throw err instanceof Error ? err : new Error('An error occurred');
    }
  };

  return {
    listings,
    loading,
    error,
    createListing,
    updateListing,
    deleteListing,
  };
}