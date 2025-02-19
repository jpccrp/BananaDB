import React, { useState } from 'react';
import { Check, ChevronsUpDown, Search } from 'lucide-react';
import { Combobox } from '@headlessui/react';
import { useProjects } from '../hooks/useSupabase';
import { getProjectName } from '../utils/projectFormatting';
import type { Database } from '../lib/database.types';

type Project = Database['public']['Tables']['projects']['Row'];

interface ProjectComboboxProps {
  selectedProject: Project | null;
  onSelect: (project: Project) => void;
}

function classNames(...classes: string[]) {
  return classes.filter(Boolean).join(' ');
}

export function ProjectCombobox({ selectedProject, onSelect }: ProjectComboboxProps) {
  const [query, setQuery] = useState('');
  const { projects, loading } = useProjects();

  const filteredProjects = query === ''
    ? projects
    : projects.filter((project) => {
        const projectName = getProjectName(project).toLowerCase();
        return projectName.includes(query.toLowerCase());
      });

  return (
    <Combobox as="div" value={selectedProject} onChange={onSelect}>
      <div className="relative">
        <div className="relative w-full cursor-default overflow-hidden rounded-md border border-gray-300 bg-white text-left focus:outline-none focus-visible:ring-2 focus-visible:ring-primary focus-visible:ring-opacity-75 focus-visible:ring-offset-2 sm:text-sm">
          <div className="flex items-center">
            <Search className="absolute left-3 h-4 w-4 text-gray-400" aria-hidden="true" />
            <Combobox.Input
              className="w-full border-none py-2 pl-10 pr-10 text-sm leading-5 text-gray-900 focus:ring-0"
              onChange={(event) => setQuery(event.target.value)}
              displayValue={(project: Project) => project ? getProjectName(project) : ''}
              placeholder="Search or select a project..."
            />
          </div>
          <Combobox.Button className="absolute inset-y-0 right-0 flex items-center px-2 focus:outline-none">
            <ChevronsUpDown
              className="h-4 w-4 text-gray-400 hover:text-gray-500"
              aria-hidden="true"
            />
          </Combobox.Button>
        </div>

        <Combobox.Options className="absolute z-10 mt-1 max-h-60 w-full overflow-auto rounded-md bg-white py-1 text-base shadow-lg ring-1 ring-black ring-opacity-5 focus:outline-none sm:text-sm">
          {loading ? (
            <div className="relative cursor-default select-none px-4 py-2 text-gray-700">
              Loading projects...
            </div>
          ) : filteredProjects.length === 0 && query !== '' ? (
            <div className="relative cursor-default select-none px-4 py-2 text-gray-700">
              No projects found.
            </div>
          ) : (
            <>
              {query === '' && (
                <div className="px-4 py-2 text-xs text-gray-500">
                  Available projects ({filteredProjects.length})
                </div>
              )}
              {filteredProjects.map((project) => (
                <Combobox.Option
                  key={project.id}
                  value={project}
                  className={({ active }) =>
                    classNames(
                      'relative cursor-pointer select-none py-2 pl-10 pr-4',
                      active ? 'bg-primary/10 text-gray-900' : 'text-gray-900'
                    )
                  }
                >
                  {({ active, selected }) => (
                    <>
                      <span className={classNames('block truncate', selected ? 'font-semibold' : '')}>
                        {getProjectName(project)}
                      </span>
                      {selected && (
                        <span
                          className={classNames(
                            'absolute inset-y-0 left-0 flex items-center pl-3',
                            active ? 'text-gray-900' : 'text-primary'
                          )}
                        >
                          <Check className="h-4 w-4" aria-hidden="true" />
                        </span>
                      )}
                    </>
                  )}
                </Combobox.Option>
              ))}
            </>
          )}
        </Combobox.Options>
      </div>
    </Combobox>
  );
}