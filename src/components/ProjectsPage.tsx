import React, { useState } from 'react';
import { Plus, Pencil, Trash2, Loader2, AlertCircle } from 'lucide-react';
import { useProjects } from '../hooks/useSupabase';
import { supabase } from '../lib/supabase';
import { getProjectName } from '../utils/projectFormatting';
import type { Database } from '../lib/database.types';

type Project = Database['public']['Tables']['projects']['Row'];

const DOOR_CONFIGS = [
  'all door configs',
  '2/3 doors',
  '4/5 doors',
  '6/7 doors'
] as const;

const FUEL_TYPES = [
  'Petrol',
  'Diesel',
  'Electric',
  'Hybrid',
  'Plug-in Hybrid'
] as const;

const inputClassName = "mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 text-gray-900 placeholder-gray-500 focus:border-primary focus:outline-none focus:ring-1 focus:ring-primary sm:text-sm";

async function getRandomPokemonName(): Promise<string> {
  const randomId = Math.floor(Math.random() * 1008) + 1;
  try {
    const response = await fetch(`https://pokeapi.co/api/v2/pokemon/${randomId}`);
    const data = await response.json();
    return data.name;
  } catch (error) {
    console.error('Error fetching Pokemon name:', error);
    return 'pokemon' + randomId;
  }
}

function formatDate(date: string): string {
  return new Date(date).toLocaleDateString('en-GB', {
    day: '2-digit',
    month: '2-digit',
    year: 'numeric'
  });
}

export function ProjectsPage() {
  const { projects, loading, error, createProject, updateProject, deleteProject } = useProjects();
  const [showNewProject, setShowNewProject] = useState(false);
  const [editingProject, setEditingProject] = useState<Project | null>(null);
  const [formError, setFormError] = useState<string | null>(null);
  const [isDeletingProject, setIsDeletingProject] = useState<string | null>(null);
  const [deleteError, setDeleteError] = useState<string | null>(null);
  const [newProject, setNewProject] = useState({
    make: '',
    model: '',
    year_range_start: 2020,
    year_range_end: 2024,
    engine_capacity_start: 0,
    engine_capacity_end: 0,
    fuel_type: 'Petrol',
    co2_emissions: 0,
    doors_config: 'all door configs',
    freename: '',
    transport_costs: 0,
    isv: 0,
    portuguese_registration: 0,
    german_plates_insurance: 0
  });

  const handleCreateProject = async (e: React.FormEvent) => {
    e.preventDefault();
    setFormError(null);

    try {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) {
        setFormError('You must be logged in to create a project');
        return;
      }

      if (newProject.year_range_start > newProject.year_range_end) {
        setFormError('Start year cannot be greater than end year');
        return;
      }

      if (newProject.engine_capacity_start > newProject.engine_capacity_end) {
        setFormError('Start engine capacity cannot be greater than end capacity');
        return;
      }

      const pokemonName = await getRandomPokemonName();
      const projectData = {
        ...newProject,
        freename: pokemonName,
        user_id: user.id
      };
      
      await createProject(projectData);
      setNewProject({
        make: '',
        model: '',
        year_range_start: 2020,
        year_range_end: 2024,
        engine_capacity_start: 0,
        engine_capacity_end: 0,
        fuel_type: 'Petrol',
        co2_emissions: 0,
        doors_config: 'all door configs',
        freename: '',
        transport_costs: 0,
        isv: 0,
        portuguese_registration: 0,
        german_plates_insurance: 0
      });
      setShowNewProject(false);
    } catch (err) {
      console.error('Error creating project:', err);
      setFormError('Failed to create project. Please try again.');
    }
  };

  const handleEditProject = (project: Project) => {
    setEditingProject(project);
    setNewProject({
      make: project.make,
      model: project.model,
      year_range_start: project.year_range_start,
      year_range_end: project.year_range_end,
      engine_capacity_start: project.engine_capacity_start,
      engine_capacity_end: project.engine_capacity_end,
      fuel_type: project.fuel_type,
      co2_emissions: project.co2_emissions,
      doors_config: project.doors_config,
      freename: project.freename,
      transport_costs: project.transport_costs || 0,
      isv: project.isv || 0,
      portuguese_registration: project.portuguese_registration || 0,
      german_plates_insurance: project.german_plates_insurance || 0
    });
    setShowNewProject(true);
  };

  const handleUpdateProject = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!editingProject) return;
    setFormError(null);

    try {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) {
        setFormError('You must be logged in to update a project');
        return;
      }

      if (newProject.year_range_start > newProject.year_range_end) {
        setFormError('Start year cannot be greater than end year');
        return;
      }

      if (newProject.engine_capacity_start > newProject.engine_capacity_end) {
        setFormError('Start engine capacity cannot be greater than end capacity');
        return;
      }

      await updateProject(editingProject.id, {
        ...newProject,
        user_id: editingProject.user_id
      });
      
      setEditingProject(null);
      setNewProject({
        make: '',
        model: '',
        year_range_start: 2020,
        year_range_end: 2024,
        engine_capacity_start: 0,
        engine_capacity_end: 0,
        fuel_type: 'Petrol',
        co2_emissions: 0,
        doors_config: 'all door configs',
        freename: '',
        transport_costs: 0,
        isv: 0,
        portuguese_registration: 0,
        german_plates_insurance: 0
      });
      setShowNewProject(false);
    } catch (err) {
      console.error('Error updating project:', err);
      setFormError('Failed to update project. Please try again.');
    }
  };

  const handleDeleteProject = async (projectId: string) => {
    if (!confirm('Are you sure you want to delete this project? The project will be removed but all associated car listings will be preserved.')) {
      return;
    }

    setIsDeletingProject(projectId);
    setDeleteError(null);

    try {
      await deleteProject(projectId);
      // Project list will automatically update through the useProjects hook
    } catch (err) {
      console.error('Error deleting project:', err);
      setDeleteError('Failed to delete project. Please try again.');
    } finally {
      setIsDeletingProject(null);
    }
  };

  if (error) {
    return (
      <div className="max-w-7xl mx-auto py-6 px-4 sm:px-6 lg:px-8">
        <div className="bg-red-50 border-l-4 border-red-400 p-4">
          <div className="flex">
            <div className="flex-shrink-0">
              <AlertCircle className="h-5 w-5 text-red-400" />
            </div>
            <div className="ml-3">
              <p className="text-sm text-red-700">
                Error loading projects. Please try refreshing the page.
              </p>
            </div>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="max-w-7xl mx-auto py-6 px-4 sm:px-6 lg:px-8">
      <div className="sm:flex sm:items-center">
        <div className="sm:flex-auto">
          <h1 className="text-2xl font-semibold text-gray-900">Projects</h1>
          <p className="mt-2 text-sm text-gray-700">
            Create and manage your vehicle research projects
          </p>
        </div>
        <div className="mt-4 sm:mt-0 sm:ml-16 sm:flex-none">
          <button
            type="button"
            onClick={() => {
              setEditingProject(null);
              setShowNewProject(true);
              setFormError(null);
            }}
            className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-gray-900 bg-primary hover:bg-primary-dark focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary"
          >
            <Plus className="h-4 w-4 mr-2" />
            New Project
          </button>
        </div>
      </div>

      {deleteError && (
        <div className="mt-6 bg-red-50 border-l-4 border-red-400 p-4">
          <div className="flex">
            <div className="flex-shrink-0">
              <AlertCircle className="h-5 w-5 text-red-400" />
            </div>
            <div className="ml-3">
              <p className="text-sm text-red-700">{deleteError}</p>
            </div>
          </div>
        </div>
      )}

      {showNewProject && (
        <div className="mt-6">
          <form onSubmit={editingProject ? handleUpdateProject : handleCreateProject} className="space-y-4 bg-gray-50 p-6 rounded-lg shadow-sm">
            {formError && (
              <div className="bg-red-50 border-l-4 border-red-400 p-4">
                <div className="flex">
                  <div className="flex-shrink-0">
                    <AlertCircle className="h-5 w-5 text-red-400" />
                  </div>
                  <div className="ml-3">
                    <p className="text-sm text-red-700">{formError}</p>
                  </div>
                </div>
              </div>
            )}
            <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
              <div>
                <label htmlFor="make" className="block text-sm font-medium text-gray-700">
                  Make
                </label>
                <input
                  type="text"
                  id="make"
                  value={newProject.make}
                  onChange={(e) => setNewProject({ ...newProject, make: e.target.value })}
                  className={inputClassName}
                  required
                />
              </div>
              <div>
                <label htmlFor="model" className="block text-sm font-medium text-gray-700">
                  Model
                </label>
                <input
                  type="text"
                  id="model"
                  value={newProject.model}
                  onChange={(e) => setNewProject({ ...newProject, model: e.target.value })}
                  className={inputClassName}
                  required
                />
              </div>
              <div>
                <label htmlFor="yearRangeStart" className="block text-sm font-medium text-gray-700">
                  Year Range Start
                </label>
                <input
                  type="number"
                  id="yearRangeStart"
                  value={newProject.year_range_start}
                  onChange={(e) => setNewProject({ ...newProject, year_range_start: parseInt(e.target.value) })}
                  className={inputClassName}
                  required
                />
              </div>
              <div>
                <label htmlFor="yearRangeEnd" className="block text-sm font-medium text-gray-700">
                  Year Range End
                </label>
                <input
                  type="number"
                  id="yearRangeEnd"
                  value={newProject.year_range_end}
                  onChange={(e) => setNewProject({ ...newProject, year_range_end: parseInt(e.target.value) })}
                  className={inputClassName}
                  required
                />
              </div>
              <div>
                <label htmlFor="engineCapacityStart" className="block text-sm font-medium text-gray-700">
                  Engine Capacity Start (cc)
                </label>
                <input
                  type="number"
                  id="engineCapacityStart"
                  value={newProject.engine_capacity_start}
                  onChange={(e) => setNewProject({ ...newProject, engine_capacity_start: parseInt(e.target.value) })}
                  className={inputClassName}
                  required
                />
              </div>
              <div>
                <label htmlFor="engineCapacityEnd" className="block text-sm font-medium text-gray-700">
                  Engine Capacity End (cc)
                </label>
                <input
                  type="number"
                  id="engineCapacityEnd"
                  value={newProject.engine_capacity_end}
                  onChange={(e) => setNewProject({ ...newProject, engine_capacity_end: parseInt(e.target.value) })}
                  className={inputClassName}
                  required
                />
              </div>
              <div>
                <label htmlFor="fuelType" className="block text-sm font-medium text-gray-700">
                  Fuel Type
                </label>
                <select
                  id="fuelType"
                  value={newProject.fuel_type}
                  onChange={(e) => setNewProject({ ...newProject, fuel_type: e.target.value })}
                  className={inputClassName}
                  required
                >
                  {FUEL_TYPES.map((fuel) => (
                    <option key={fuel} value={fuel}>
                      {fuel}
                    </option>
                  ))}
                </select>
              </div>
              <div>
                <label htmlFor="co2Emissions" className="block text-sm font-medium text-gray-700">
                  CO2 Emissions (g/km)
                </label>
                <input
                  type="number"
                  id="co2Emissions"
                  value={newProject.co2_emissions}
                  onChange={(e) => setNewProject({ ...newProject, co2_emissions: parseInt(e.target.value) })}
                  className={inputClassName}
                  required
                />
              </div>
              <div>
                <label htmlFor="doorsConfig" className="block text-sm font-medium text-gray-700">
                  Doors/Seats Configuration
                </label>
                <select
                  id="doorsConfig"
                  value={newProject.doors_config}
                  onChange={(e) => setNewProject({ ...newProject, doors_config: e.target.value })}
                  className={inputClassName}
                  required
                >
                  {DOOR_CONFIGS.map((config) => (
                    <option key={config} value={config}>
                      {config}
                    </option>
                  ))}
                </select>
              </div>
              <div>
                <label htmlFor="transportCosts" className="block text-sm font-medium text-gray-700">
                  Transport Costs (€)
                </label>
                <input
                  type="number"
                  id="transportCosts"
                  value={newProject.transport_costs}
                  onChange={(e) => setNewProject({ ...newProject, transport_costs: parseInt(e.target.value) })}
                  className={inputClassName}
                  min="0"
                  step="0.01"
                  required
                />
              </div>
              <div>
                <label htmlFor="isv" className="block text-sm font-medium text-gray-700">
                  ISV - Portuguese Vehicle Tax (€)
                </label>
                <input
                  type="number"
                  id="isv"
                  value={newProject.isv}
                  onChange={(e) => setNewProject({ ...newProject, isv: parseInt(e.target.value) })}
                  className={inputClassName}
                  min="0"
                  step="0.01"
                  required
                />
              </div>
              <div>
                <label htmlFor="portugueseRegistration" className="block text-sm font-medium text-gray-700">
                  Portuguese Registration (€)
                </label>
                <input
                  type="number"
                  id="portugueseRegistration"
                  value={newProject.portuguese_registration}
                  onChange={(e) => setNewProject({ ...newProject, portuguese_registration: parseInt(e.target.value) })}
                  className={inputClassName}
                  min="0"
                  step="0.01"
                  required
                />
              </div>
              <div>
                <label htmlFor="germanPlatesInsurance" className="block text-sm font-medium text-gray-700">
                  Temporary German Plates and Insurance (€)
                </label>
                <input
                  type="number"
                  id="germanPlatesInsurance"
                  value={newProject.german_plates_insurance}
                  onChange={(e) => setNewProject({ ...newProject, german_plates_insurance: parseInt(e.target.value) })}
                  className={inputClassName}
                  min="0"
                  step="0.01"
                  required
                />
              </div>
            </div>
            <div className="flex justify-end space-x-3">
              <button
                type="button"
                onClick={() => {
                  setShowNewProject(false);
                  setEditingProject(null);
                  setFormError(null);
                }}
                className="px-4 py-2 text-sm font-medium text-gray-700 hover:text-gray-900"
              >
                Cancel
              </button>
              <button
                type="submit"
                className="px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-gray-900 bg-primary hover:bg-primary-dark focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary"
              >
                {editingProject ? 'Update' : 'Create'}
              </button>
            </div>
          </form>
        </div>
      )}

      <div className="mt-8">
        <div className="overflow-x-auto">
          <div className="inline-block min-w-full align-middle">
            <div className="overflow-hidden shadow ring-1 ring-black ring-opacity-5 rounded-lg">
              <table className="min-w-full divide-y divide-gray-300">
                <thead className="bg-gray-50">
                  <tr>
                    <th scope="col" className="py-3.5 pl-4 pr-3 text-left text-sm font-semibold text-gray-900 sm:pl-6">
                      Project Name
                    </th>
                    <th scope="col" className="px-3 py-3.5 text-left text-sm font-semibold text-gray-900">
                      Make
                    </th>
                    <th scope="col" className="px-3 py-3.5 text-left text-sm font-semibold text-gray-900">
                      Model
                    </th>
                    <th scope="col" className="px-3 py-3.5 text-left text-sm font-semibold text-gray-900">
                      Year Range
                    </th>
                    <th scope="col" className="px-3 py-3.5 text-left text-sm font-semibold text-gray-900">
                      Engine Capacity Range
                    </th>
                    <th scope="col" className="px-3 py-3.5 text-left text-sm font-semibold text-gray-900">
                      Fuel Type
                    </th>
                    <th scope="col" className="px-3 py-3.5 text-left text-sm font-semibold text-gray-900">
                      CO2 Emissions (g/km)
                    </th>
                    <th scope="col" className="px-3 py-3.5 text-left text-sm font-semibold text-gray-900">
                      Doors/Seats
                    </th>
                    <th scope="col" className="px-3 py-3.5 text-left text-sm font-semibold text-gray-900">
                      Created
                    </th>
                    <th scope="col" className="relative py-3.5 pl-3 pr-4 sm:pr-6">
                      <span className="sr-only">Actions</span>
                    </th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-200 bg-white">
                  {loading ? (
                    <tr>
                      <td colSpan={10} className="text-center py-4">
                        <Loader2 className="h-6 w-6 animate-spin mx-auto text-primary" />
                      </td>
                    </tr>
                  ) : projects.length === 0 ? (
                    <tr>
                      <td colSpan={10} className="text-center py-4 text-sm text-gray-500">
                        No projects yet. Create your first project to get started.
                      </td>
                    </tr>
                  ) : (
                    projects.map((project) => (
                      <tr key={project.id}>
                        <td className="whitespace-nowrap py-4 pl-4 pr-3 text-sm font-medium text-gray-900 sm:pl-6">
                          {getProjectName(project)}
                        </td>
                        <td className="whitespace-nowrap px-3 py-4 text-sm text-gray-500">
                          {project.make}
                        </td>
                        <td className="whitespace-nowrap px-3 py-4 text-sm text-gray-500">
                          {project.model}
                        </td>
                        <td className="whitespace-nowrap px-3 py-4 text-sm text-gray-500">
                          {project.year_range_start}-{project.year_range_end}
                        </td>
                        <td className="whitespace-nowrap px-3 py-4 text-sm text-gray-500">
                          {project.engine_capacity_start}-{project.engine_capacity_end}
                        </td>
                        <td className="whitespace-nowrap px-3 py-4 text-sm text-gray-500">
                          {project.fuel_type}
                        </td>
                        <td className="whitespace-nowrap px-3 py-4 text-sm text-gray-500">
                          {project.co2_emissions}
                        </td>
                        <td className="whitespace-nowrap px-3 py-4 text-sm text-gray-500">
                          {project.doors_config}
                        </td>
                        <td className="whitespace-nowrap px-3 py-4 text-sm text-gray-500">
                          {formatDate(project.created_at)}
                        </td>
                        <td className="relative whitespace-nowrap py-4 pl-3 pr-4 text-right text-sm font-medium sm:pr-6">
                          <div className="flex items-center justify-end space-x-2">
                            <button
                              onClick={() => handleEditProject(project)}
                              className="text-primary hover:text-primary-dark"
                            >
                              <Pencil className="h-4 w-4" />
                              <span className="sr-only">Edit project</span>
                            </button>
                            {isDeletingProject === project.id ? (
                              <Loader2 className="h-4 w-4 animate-spin text-red-600" />
                            ) : (
                              <button
                                onClick={() => handleDeleteProject(project.id)}
                                className="text-red-600 hover:text-red-900"
                              >
                                <Trash2 className="h-4 w-4" />
                                <span className="sr-only">Delete project</span>
                              </button>
                            )}
                          </div>
                        </td>
                      </tr>
                    ))
                  )}
                </tbody>
              </table>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}