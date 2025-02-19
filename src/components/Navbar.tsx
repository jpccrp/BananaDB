import React from 'react';
import { Car, FolderKanban, PlusCircle, LogOut, Shield, Settings } from 'lucide-react';
import { useAuth } from '../hooks/useAuth';

interface NavbarProps {
  onNavigate: (page: string) => void;
  currentPage: string;
  isAdmin: boolean;
}

export function Navbar({ onNavigate, currentPage, isAdmin }: NavbarProps) {
  const { user, signOut } = useAuth();

  return (
    <nav className="bg-white shadow-sm">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex justify-between h-16">
          <div className="flex">
            <div className="flex-shrink-0 flex items-center cursor-pointer" onClick={() => onNavigate('home')}>
              <Car className="h-8 w-8 text-primary" />
              <span className="ml-2 text-xl font-bold text-gray-900">BananaDB</span>
            </div>
            {user && (
              <div className="hidden sm:ml-6 sm:flex sm:space-x-8">
                <button
                  onClick={() => onNavigate('projects')}
                  className={`${
                    currentPage === 'projects'
                      ? 'border-primary text-gray-900'
                      : 'border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700'
                  } inline-flex items-center px-1 pt-1 border-b-2 text-sm font-medium`}
                >
                  <FolderKanban className="mr-2 h-4 w-4" />
                  Projects
                </button>
                <button
                  onClick={() => onNavigate('new-entry')}
                  className={`${
                    currentPage === 'new-entry'
                      ? 'border-primary text-gray-900'
                      : 'border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700'
                  } inline-flex items-center px-1 pt-1 border-b-2 text-sm font-medium`}
                >
                  <PlusCircle className="mr-2 h-4 w-4" />
                  New Entry
                </button>
                {isAdmin && (
                  <button
                    onClick={() => onNavigate('settings')}
                    className={`${
                      currentPage === 'settings'
                        ? 'border-primary text-gray-900'
                        : 'border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700'
                    } inline-flex items-center px-1 pt-1 border-b-2 text-sm font-medium`}
                  >
                    <Settings className="mr-2 h-4 w-4" />
                    Settings
                  </button>
                )}
              </div>
            )}
          </div>
          {user && (
            <div className="flex items-center">
              <div className="flex items-center space-x-4">
                {isAdmin && (
                  <div className="flex items-center text-primary">
                    <Shield className="h-4 w-4 mr-1" />
                    <span className="text-sm">Admin</span>
                  </div>
                )}
                <span className="text-sm text-gray-700">{user.email}</span>
                <button
                  onClick={signOut}
                  className="inline-flex items-center px-3 py-1 border border-transparent text-sm font-medium rounded-md text-gray-900 bg-primary hover:bg-primary-dark focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary"
                >
                  <LogOut className="h-4 w-4 mr-2" />
                  Sign out
                </button>
              </div>
            </div>
          )}
        </div>
      </div>
    </nav>
  );
}