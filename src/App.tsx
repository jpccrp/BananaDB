import React, { useState } from 'react';
import { Navbar } from './components/Navbar';
import { NewEntryForm } from './components/NewEntryForm';
import { ProjectsPage } from './components/ProjectsPage';
import { AdminSettings } from './components/AdminSettings';
import { Auth } from './components/Auth';
import { useAuth } from './hooks/useAuth';
import { Loader2 } from 'lucide-react';

function App() {
  const [currentPage, setCurrentPage] = useState('home');
  const { user, loading, isAdmin } = useAuth();

  const renderContent = () => {
    switch (currentPage) {
      case 'new-entry':
        return <NewEntryForm />;
      case 'projects':
        return <ProjectsPage />;
      case 'settings':
        return isAdmin ? <AdminSettings /> : (
          <div className="max-w-4xl mx-auto py-6">
            <div className="bg-red-50 border-l-4 border-red-400 p-4">
              <div className="flex">
                <div className="flex-shrink-0">
                  <span className="text-red-400">⚠️</span>
                </div>
                <div className="ml-3">
                  <p className="text-sm text-red-700">
                    You need administrator privileges to access this page.
                  </p>
                </div>
              </div>
            </div>
          </div>
        );
      default:
        return (
          <div className="border-4 border-dashed border-gray-200 rounded-lg h-96 flex items-center justify-center">
            <p className="text-gray-500 text-lg">Welcome to BananaDB</p>
          </div>
        );
    }
  };

  if (loading) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <Loader2 className="h-8 w-8 animate-spin text-primary" />
      </div>
    );
  }

  if (!user) {
    return <Auth />;
  }

  return (
    <div className="min-h-screen bg-gray-50">
      <Navbar onNavigate={setCurrentPage} currentPage={currentPage} isAdmin={isAdmin} />
      <main className="max-w-7xl mx-auto py-6 sm:px-6 lg:px-8">
        <div className="px-4 py-6 sm:px-0">
          {renderContent()}
        </div>
      </main>
    </div>
  );
}

export default App;