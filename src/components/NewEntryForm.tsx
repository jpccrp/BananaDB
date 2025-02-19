import React, { useState, useEffect } from 'react';
import { AlertCircle, Loader2, Check, X, Bug } from 'lucide-react';
import { ProjectCombobox } from './ProjectCombobox';
import { useCarListings } from '../hooks/useSupabase';
import { supabase } from '../lib/supabase';
import { parseCarListing } from '../lib/ai';
import { generateUniqueIdentifier } from '../lib/gemini';
import type { ParsedCarListing } from '../lib/types';
import { getCountryFlag } from '../utils/countryFlags';
import type { Database } from '../lib/database.types';

type DataSource = Database['public']['Functions']['get_available_data_sources']['Returns'][0];
type Project = Database['public']['Tables']['projects']['Row'];

const inputClassName = "mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 text-gray-900 placeholder-gray-500 focus:border-primary focus:outline-none focus:ring-1 focus:ring-primary sm:text-sm";

interface AIStatus {
  loading: boolean;
  error: string | null;
  settings: {
    provider: string;
    hasKey: boolean;
    hasPrompt: boolean;
  } | null;
}

export function NewEntryForm() {
  const [source, setSource] = useState<string>('');
  const [dataSources, setDataSources] = useState<DataSource[]>([]);
  const [dataSourcesLoading, setDataSourcesLoading] = useState(true);
  const [selectedProject, setSelectedProject] = useState<Project | null>(null);
  const [rawData, setRawData] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [parsedListings, setParsedListings] = useState<ParsedCarListing[]>([]);
  const [parseError, setParseError] = useState<string | null>(null);
  const [progress, setProgress] = useState({ current: 0, total: 0, errors: 0 });
  const [showDebug, setShowDebug] = useState(false);
  const [aiResponse, setAiResponse] = useState<{
    raw: string;
    parsed?: any;
    error?: string;
  } | null>(null);
  const { createListing } = useCarListings();
  const [aiStatus, setAiStatus] = useState<AIStatus>({
    loading: true,
    error: null,
    settings: null
  });

  useEffect(() => {
    loadDataSources();
    checkAISettings();
  }, []);

  const checkAISettings = async () => {
    try {
      setAiStatus(prev => ({ ...prev, loading: true, error: null }));
      
      // Get provider first
      const { data: provider, error: providerError } = await supabase.rpc('get_ai_provider');
      if (providerError) throw providerError;

      const currentProvider = provider || 'gemini';
      let hasKey = false;
      let hasPrompt = false;

      // Get settings based on provider
      switch (currentProvider) {
        case 'gemini': {
          const [
            { data: apiKey, error: apiKeyError },
            { data: prompt, error: promptError }
          ] = await Promise.all([
            supabase.rpc('get_gemini_apikey'),
            supabase.rpc('get_gemini_prompt')
          ]);
          if (apiKeyError) throw apiKeyError;
          if (promptError) throw promptError;
          hasKey = !!apiKey;
          hasPrompt = !!prompt;
          break;
        }
        case 'deepseek': {
          const [
            { data: apiKey, error: apiKeyError },
            { data: prompt, error: promptError }
          ] = await Promise.all([
            supabase.rpc('get_deepseek_apikey'),
            supabase.rpc('get_deepseek_prompt')
          ]);
          if (apiKeyError) throw apiKeyError;
          if (promptError) throw promptError;
          hasKey = !!apiKey;
          hasPrompt = !!prompt;
          break;
        }
        case 'openrouter': {
          const [
            { data: apiKey, error: apiKeyError },
            { data: prompt, error: promptError }
          ] = await Promise.all([
            supabase.rpc('get_openrouter_apikey'),
            supabase.rpc('get_openrouter_prompt')
          ]);
          if (apiKeyError) throw apiKeyError;
          if (promptError) throw promptError;
          hasKey = !!apiKey;
          hasPrompt = !!prompt;
          break;
        }
      }

      setAiStatus({
        loading: false,
        error: null,
        settings: {
          provider: currentProvider,
          hasKey,
          hasPrompt
        }
      });
    } catch (err) {
      console.error('Error checking AI settings:', err);
      setAiStatus({
        loading: false,
        error: err instanceof Error ? err.message : 'Failed to check AI settings',
        settings: null
      });
    }
  };

  const loadDataSources = async () => {
    try {
      const { data, error } = await supabase.rpc('get_available_data_sources');
      if (error) throw error;
      setDataSources(data || []);
    } catch (err) {
      console.error('Error loading data sources:', err);
    } finally {
      setDataSourcesLoading(false);
    }
  };

  const handleParse = async () => {
    if (!selectedProject || !source || !rawData.trim()) {
      setParseError('Please select a project and data source, and enter listing data');
      return;
    }

    setIsSubmitting(true);
    setParseError(null);
    setParsedListings([]);
    setAiResponse(null);
    setProgress({ current: 0, total: 0, errors: 0 });

    try {
      // Store raw data for debugging
      setAiResponse({
        raw: rawData,
        parsed: null
      });

      const listings = await parseCarListing(rawData);
      
      if (listings.length === 0) {
        throw new Error('No valid listings could be extracted from the data. Please check the format and try again.');
      }
      
      setParsedListings(listings);
      setAiResponse(prev => ({
        ...prev!,
        parsed: listings
      }));
    } catch (err) {
      console.error('Error parsing data:', err);
      const errorMessage = err instanceof Error 
        ? err.message 
        : 'Failed to parse the car listings. Please check the format and try again.';
      
      setParseError(errorMessage);
      setAiResponse(prev => ({
        ...prev!,
        error: errorMessage
      }));
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (parsedListings.length === 0) return;
    
    setIsSubmitting(true);
    setProgress({ current: 0, total: parsedListings.length, errors: 0 });
    
    try {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) {
        throw new Error('No user found');
      }

      const errors: Array<{ listing: ParsedCarListing; error: string }> = [];
      let successCount = 0;

      for (let i = 0; i < parsedListings.length; i++) {
        const listing = {
          ...parsedListings[i],
          source,
          unique_identifier: generateUniqueIdentifier(parsedListings[i], source),
          user_id: user.id,
          project_id: selectedProject?.id
        };

        try {
          await createListing(listing);
          successCount++;
          setProgress(prev => ({ 
            ...prev, 
            current: successCount,
            errors: errors.length 
          }));
        } catch (err: any) {
          // Check if error is due to unique constraint
          if (err.message?.includes('unique constraint')) {
            console.log('Skipping duplicate listing:', listing.unique_identifier);
            errors.push({ 
              listing: parsedListings[i],
              error: 'Duplicate listing - already exists in database'
            });
            continue;
          }
          
          console.error('Error creating listing:', err);
          errors.push({ 
            listing: parsedListings[i],
            error: err.message || 'Unknown error occurred'
          });
        }
      }

      if (errors.length > 0) {
        setAiResponse(prev => ({
          ...prev!,
          errors: errors
        }));
        
        if (successCount === 0) {
          throw new Error(`Failed to create any listings. ${errors.length} error(s) occurred.`);
        } else {
          alert(`Created ${successCount} listings with ${errors.length} error(s). Check debug info for details.`);
        }
      } else {
        setRawData('');
        setParsedListings([]);
        setAiResponse(null);
        alert(`Successfully created ${successCount} listings!`);
      }
    } catch (err) {
      console.error('Error submitting listings:', err);
      alert(err instanceof Error ? err.message : 'Failed to submit listings. Please try again.');
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className="max-w-4xl mx-auto">
      <div className="bg-white shadow-sm rounded-lg p-6">
        <div className="flex justify-between items-center mb-6">
          <h1 className="text-2xl font-bold text-gray-900">New Entry</h1>
          <button
            type="button"
            onClick={() => setShowDebug(!showDebug)}
            className="inline-flex items-center px-3 py-1 rounded-md text-sm font-medium text-gray-700 bg-gray-100 hover:bg-gray-200"
          >
            <Bug className="h-4 w-4 mr-2" />
            Toggle Debug Info
          </button>
        </div>

        {/* AI Status Panel */}
        {aiStatus.loading ? (
          <div className="mb-6 p-4 bg-gray-50 rounded-lg flex items-center">
            <Loader2 className="h-5 w-5 text-gray-400 animate-spin mr-3" />
            <p className="text-sm text-gray-600">Checking AI configuration...</p>
          </div>
        ) : aiStatus.error ? (
          <div className="mb-6 bg-red-50 border-l-4 border-red-400 p-4">
            <div className="flex">
              <AlertCircle className="h-5 w-5 text-red-400 flex-shrink-0" />
              <div className="ml-3">
                <p className="text-sm text-red-700">Error checking AI settings: {aiStatus.error}</p>
              </div>
            </div>
          </div>
        ) : aiStatus.settings && (
          <div className="mb-6 bg-gray-50 rounded-lg p-4">
            <h3 className="text-sm font-medium text-gray-700 mb-2">AI Configuration Status</h3>
            <div className="space-y-2">
              <div className="flex items-center">
                <span className="text-sm text-gray-600 w-32">Active Provider:</span>
                <span className="text-sm font-medium capitalize">{aiStatus.settings.provider}</span>
              </div>
              <div className="flex items-center">
                <span className="text-sm text-gray-600 w-32">API Key:</span>
                {aiStatus.settings.hasKey ? (
                  <Check className="h-4 w-4 text-green-500" />
                ) : (
                  <X className="h-4 w-4 text-red-500" />
                )}
              </div>
              <div className="flex items-center">
                <span className="text-sm text-gray-600 w-32">Prompt:</span>
                {aiStatus.settings.hasPrompt ? (
                  <Check className="h-4 w-4 text-green-500" />
                ) : (
                  <X className="h-4 w-4 text-red-500" />
                )}
              </div>
            </div>
          </div>
        )}

        <form onSubmit={handleSubmit} className="space-y-6">
          <div>
            <label htmlFor="project" className="block text-sm font-medium text-gray-700">
              Project
            </label>
            <div className="mt-1">
              <ProjectCombobox
                selectedProject={selectedProject}
                onSelect={setSelectedProject}
              />
            </div>
          </div>

          <div>
            <label htmlFor="source" className="block text-sm font-medium text-gray-700">
              Data Source
            </label>
            <select
              id="source"
              value={source}
              onChange={(e) => setSource(e.target.value)}
              className={inputClassName}
              required
            >
              <option value="">Select a data source</option>
              {dataSourcesLoading ? (
                <option value="" disabled>Loading data sources...</option>
              ) : dataSources.map((source) => (
                <option key={source.id} value={source.name}>
                  {getCountryFlag(source.country)} {source.name}
                </option>
              ))}
            </select>
          </div>

          <div>
            <label htmlFor="rawData" className="block text-sm font-medium text-gray-700">
              Raw Listing Data
            </label>
            <div className="mt-1">
              <textarea
                id="rawData"
                rows={10}
                value={rawData}
                onChange={(e) => setRawData(e.target.value)}
                className={inputClassName}
                placeholder="Paste one or more car listings here. The AI will automatically detect and separate multiple listings."
                required
              />
            </div>
          </div>

          {!parsedListings.length && !parseError && (
            <div className="bg-yellow-50 border-l-4 border-primary p-4">
              <div className="flex">
                <div className="flex-shrink-0">
                  <AlertCircle className="h-5 w-5 text-primary" />
                </div>
                <div className="ml-3">
                  <p className="text-sm text-yellow-700">
                    First select your project and data source, then paste one or more car listings. The AI will automatically detect and separate multiple listings.
                  </p>
                </div>
              </div>
            </div>
          )}

          {parseError && (
            <div className="bg-red-50 border-l-4 border-red-400 p-4">
              <div className="flex">
                <div className="flex-shrink-0">
                  <X className="h-5 w-5 text-red-400" />
                </div>
                <div className="ml-3">
                  <p className="text-sm text-red-700">{parseError}</p>
                </div>
              </div>
            </div>
          )}

          {isSubmitting && progress.total > 0 && (
            <div className="bg-blue-50 border-l-4 border-blue-400 p-4">
              <div className="flex items-center">
                <Loader2 className="h-5 w-5 text-blue-400 animate-spin mr-3" />
                <div className="ml-3">
                  <p className="text-sm text-blue-700">
                    Processing {progress.current} of {progress.total}
                    {progress.errors > 0 && ` (${progress.errors} errors)`}...
                  </p>
                </div>
              </div>
            </div>
          )}

          {showDebug && aiResponse && (
            <div className="bg-gray-50 border-l-4 border-gray-400 p-4">
              <h3 className="text-lg font-medium text-gray-800 mb-2">
                Debug Information
              </h3>
              <div className="space-y-4">
                <div>
                  <h4 className="text-sm font-medium text-gray-700 mb-1">Raw Input:</h4>
                  <pre className="text-sm text-gray-600 whitespace-pre-wrap bg-gray-100 p-4 rounded">
                    {aiResponse.raw}
                  </pre>
                </div>
                {aiResponse.parsed && (
                  <div>
                    <h4 className="text-sm font-medium text-gray-700 mb-1">Parsed Output:</h4>
                    <pre className="text-sm text-gray-600 whitespace-pre-wrap bg-gray-100 p-4 rounded">
                      {JSON.stringify(aiResponse.parsed, null, 2)}
                    </pre>
                  </div>
                )}
                {aiResponse.error && (
                  <div>
                    <h4 className="text-sm font-medium text-red-700 mb-1">Error:</h4>
                    <pre className="text-sm text-red-600 whitespace-pre-wrap bg-red-50 p-4 rounded">
                      {aiResponse.error}
                    </pre>
                  </div>
                )}
                {aiResponse.errors && aiResponse.errors.length > 0 && (
                  <div>
                    <h4 className="text-sm font-medium text-red-700 mb-1">Database Errors:</h4>
                    <div className="space-y-2">
                      {aiResponse.errors.map((error, index) => (
                        <div key={index} className="bg-red-50 p-4 rounded">
                          <p className="text-sm text-red-700 font-medium">Error: {error.error}</p>
                          <pre className="text-sm text-red-600 mt-2">
                            {JSON.stringify(error.listing, null, 2)}
                          </pre>
                        </div>
                      ))}
                    </div>
                  </div>
                )}
              </div>
            </div>
          )}

          {parsedListings.length > 0 && (
            <div className="bg-green-50 border-l-4 border-green-400 p-4">
              <h3 className="text-lg font-medium text-green-800 mb-2">
                Successfully Parsed {parsedListings.length} Listings
              </h3>
              <div className="max-h-60 overflow-y-auto">
                {parsedListings.map((listing, index) => (
                  <div key={index} className="mb-4 p-3 bg-white rounded shadow-sm">
                    <div className="grid grid-cols-2 gap-4 text-sm text-green-700">
                      <div>
                        <p><strong>Make:</strong> {listing.make}</p>
                        <p><strong>Model:</strong> {listing.model}</p>
                        <p><strong>Year:</strong> {listing.year}</p>
                        <p><strong>Mileage:</strong> {listing.mileage.toLocaleString()} km</p>
                        <p><strong>Price:</strong> €{listing.price.toLocaleString()}</p>
                      </div>
                      <div>
                        {listing.fuel_type && <p><strong>Fuel Type:</strong> {listing.fuel_type}</p>}
                        {listing.power_hp && <p><strong>Power:</strong> {listing.power_hp} HP</p>}
                        {listing.gear_type && <p><strong>Transmission:</strong> {listing.gear_type}</p>}
                        {listing.number_of_doors && <p><strong>Doors:</strong> {listing.number_of_doors}</p>}
                        {listing.location && <p><strong>Location:</strong> {listing.location}</p>}
                      </div>
                    </div>
                  </div>
                ))}
              </div>
              <div className="mt-4">
                <p className="text-sm text-green-700">
                  Please review the parsed listings above. If they look correct, click "Submit" to create all listings.
                </p>
              </div>
            </div>
          )}

          <div className="flex justify-end space-x-4">
            {!parsedListings.length ? (
              <button
                type="button"
                onClick={handleParse}
                disabled={isSubmitting || !rawData.trim() || !source || !selectedProject}
                className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-gray-900 bg-primary hover:bg-primary-dark focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary disabled:opacity-50 disabled:cursor-not-allowed"
              >
                {isSubmitting ? (
                  <>
                    <Loader2 className="h-4 w-4 mr-2 animate-spin" />
                    Parsing...
                  </>
                ) : (
                  <>
                    <AlertCircle className="h-4 w-4 mr-2" />
                    Parse Data
                  </>
                )}
              </button>
            ) : (
              <button
                type="submit"
                disabled={isSubmitting}
                className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-gray-900 bg-primary hover:bg-primary-dark focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary disabled:opacity-50 disabled:cursor-not-allowed"
              >
                {isSubmitting ? (
                  <>
                    <Loader2 className="h-4 w-4 mr-2 animate-spin" />
                    Submitting...
                  </>
                ) : (
                  <>
                    <Check className="h-4 w-4 mr-2" />
                    Submit {parsedListings.length} Listings
                  </>
                )}
              </button>
            )}
          </div>
        </form>
      </div>
    </div>
  );
}