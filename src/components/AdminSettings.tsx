import React, { useState, useEffect, useCallback } from 'react';
import { Plus, Loader2, Trash2, AlertCircle, Eye, EyeOff, Bug } from 'lucide-react';
import { supabase } from '../lib/supabase';
import { DataSourcesManager } from './DataSourcesManager';

const inputClassName = "mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 text-gray-900 placeholder-gray-500 focus:border-primary focus:outline-none focus:ring-1 focus:ring-primary sm:text-sm";

interface Settings {
  gemini_api_key: string;
  gemini_prompt: string;
  deepseek_api_key: string;
  deepseek_prompt: string;
  openrouter_api_key: string;
  openrouter_prompt: string;
  site_url: string;
  site_name: string;
  ai_provider: 'gemini' | 'deepseek' | 'openrouter';
}

const defaultSettings: Settings = {
  gemini_api_key: '',
  gemini_prompt: '',
  deepseek_api_key: '',
  deepseek_prompt: '',
  openrouter_api_key: '',
  openrouter_prompt: '',
  site_url: window.location.origin,
  site_name: 'BananaDB',
  ai_provider: 'gemini'
};

export function AdminSettings() {
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [settings, setSettings] = useState<Settings>(defaultSettings);
  const [showGeminiKey, setShowGeminiKey] = useState(false);
  const [showDeepseekKey, setShowDeepseekKey] = useState(false);
  const [showOpenRouterKey, setShowOpenRouterKey] = useState(false);
  const [isSavingGemini, setIsSavingGemini] = useState(false);
  const [isSavingDeepseek, setIsSavingDeepseek] = useState(false);
  const [isSavingOpenRouter, setIsSavingOpenRouter] = useState(false);
  const [isUpdatingProvider, setIsUpdatingProvider] = useState(false);
  const [message, setMessage] = useState<{ type: 'success' | 'error'; text: string } | null>(null);
  const [debugInfo, setDebugInfo] = useState<any>(null);

  const loadSettings = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);

      // Get all settings in parallel
      const [
        { data: geminiApiKey } = { data: '' },
        { data: geminiPrompt } = { data: '' },
        { data: deepseekApiKey } = { data: '' },
        { data: deepseekPrompt } = { data: '' },
        { data: openrouterApiKey } = { data: '' },
        { data: openrouterPrompt } = { data: '' },
        { data: siteUrl } = { data: '' },
        { data: siteName } = { data: '' },
        { data: provider } = { data: 'gemini' }
      ] = await Promise.all([
        supabase.rpc('get_gemini_apikey'),
        supabase.rpc('get_gemini_prompt'),
        supabase.rpc('get_deepseek_apikey'),
        supabase.rpc('get_deepseek_prompt'),
        supabase.rpc('get_openrouter_apikey'),
        supabase.rpc('get_openrouter_prompt'),
        supabase.rpc('get_openrouter_site_url'),
        supabase.rpc('get_openrouter_site_name'),
        supabase.rpc('get_ai_provider')
      ]);

      setSettings({
        gemini_api_key: geminiApiKey || '',
        gemini_prompt: geminiPrompt || '',
        deepseek_api_key: deepseekApiKey || '',
        deepseek_prompt: deepseekPrompt || '',
        openrouter_api_key: openrouterApiKey || '',
        openrouter_prompt: openrouterPrompt || '',
        site_url: siteUrl || window.location.origin,
        site_name: siteName || 'BananaDB',
        ai_provider: (provider || 'gemini') as Settings['ai_provider']
      });
    } catch (err) {
      console.error('Error loading settings:', err);
      setError(err instanceof Error ? err.message : 'Failed to load settings');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    loadSettings();
  }, [loadSettings]);

  const handleSaveGemini = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsSavingGemini(true);
    setMessage(null);

    try {
      const [apiKeyError, promptError] = await Promise.all([
        supabase.rpc('set_gemini_apikey', { p_value: settings.gemini_api_key }),
        supabase.rpc('set_gemini_prompt', { p_value: settings.gemini_prompt })
      ]);

      if (apiKeyError?.error) throw apiKeyError.error;
      if (promptError?.error) throw promptError.error;

      setMessage({
        type: 'success',
        text: 'Gemini settings saved successfully!'
      });
      
      await loadSettings();
    } catch (err) {
      console.error('Error saving Gemini settings:', err);
      setMessage({
        type: 'error',
        text: 'Failed to save Gemini settings. Please try again.'
      });
    } finally {
      setIsSavingGemini(false);
    }
  };

  const handleSaveDeepseek = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsSavingDeepseek(true);
    setMessage(null);

    try {
      const [apiKeyError, promptError] = await Promise.all([
        supabase.rpc('set_deepseek_apikey', { p_value: settings.deepseek_api_key }),
        supabase.rpc('set_deepseek_prompt', { p_value: settings.deepseek_prompt })
      ]);

      if (apiKeyError?.error) throw apiKeyError.error;
      if (promptError?.error) throw promptError.error;

      setMessage({
        type: 'success',
        text: 'Deepseek settings saved successfully!'
      });
      
      await loadSettings();
    } catch (err) {
      console.error('Error saving Deepseek settings:', err);
      setMessage({
        type: 'error',
        text: 'Failed to save Deepseek settings. Please try again.'
      });
    } finally {
      setIsSavingDeepseek(false);
    }
  };

  const handleSaveOpenRouter = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsSavingOpenRouter(true);
    setMessage(null);

    try {
      const [apiKeyError, promptError, siteUrlError, siteNameError] = await Promise.all([
        supabase.rpc('set_openrouter_apikey', { p_value: settings.openrouter_api_key }),
        supabase.rpc('set_openrouter_prompt', { p_value: settings.openrouter_prompt }),
        supabase.rpc('set_openrouter_site_url', { p_value: settings.site_url }),
        supabase.rpc('set_openrouter_site_name', { p_value: settings.site_name })
      ]);

      if (apiKeyError?.error) throw apiKeyError.error;
      if (promptError?.error) throw promptError.error;
      if (siteUrlError?.error) throw siteUrlError.error;
      if (siteNameError?.error) throw siteNameError.error;

      setMessage({
        type: 'success',
        text: 'OpenRouter settings saved successfully!'
      });
      
      await loadSettings();
    } catch (err) {
      console.error('Error saving OpenRouter settings:', err);
      setMessage({
        type: 'error',
        text: 'Failed to save OpenRouter settings. Please try again.'
      });
    } finally {
      setIsSavingOpenRouter(false);
    }
  };

  const handleUpdateProvider = async (provider: Settings['ai_provider']) => {
    if (provider === settings.ai_provider || isUpdatingProvider) return;
    
    setIsUpdatingProvider(true);
    setMessage(null);

    try {
      const { error } = await supabase.rpc('set_ai_provider', { p_value: provider });

      if (error) throw error;

      setMessage({
        type: 'success',
        text: `Switched to ${provider} provider successfully!`
      });
      
      await loadSettings();
    } catch (err) {
      console.error('Error updating AI provider:', err);
      setMessage({
        type: 'error',
        text: 'Failed to update AI provider. Please try again.'
      });
    } finally {
      setIsUpdatingProvider(false);
    }
  };

  const handleInputChange = (field: keyof Settings, value: string) => {
    setSettings(prev => ({
      ...prev,
      [field]: value
    }));
  };

  if (loading) {
    return (
      <div className="max-w-4xl mx-auto">
        <div className="bg-white shadow-sm rounded-lg p-6">
          <div className="flex items-center justify-center h-64">
            <Loader2 className="h-8 w-8 animate-spin text-primary" />
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="max-w-4xl mx-auto">
      <div className="bg-white shadow-sm rounded-lg p-6">
        <div className="flex justify-between items-center mb-6">
          <h2 className="text-2xl font-bold text-gray-900">Admin Settings</h2>
          <button
            onClick={() => setDebugInfo(prev => prev ? null : {
              settings: {
                ...settings,
                gemini_api_key: settings.gemini_api_key ? '***' : '',
                deepseek_api_key: settings.deepseek_api_key ? '***' : '',
                openrouter_api_key: settings.openrouter_api_key ? '***' : ''
              },
              timestamp: new Date().toISOString()
            })}
            className="inline-flex items-center px-3 py-1 rounded-md text-sm font-medium text-gray-700 bg-gray-100 hover:bg-gray-200"
          >
            <Bug className="h-4 w-4 mr-2" />
            Toggle Debug Info
          </button>
        </div>

        {debugInfo && (
          <div className="mb-6 p-4 bg-gray-50 rounded-lg overflow-x-auto">
            <h3 className="text-sm font-medium text-gray-900 mb-2">Debug Information</h3>
            <pre className="text-xs text-gray-600 whitespace-pre-wrap">
              {JSON.stringify(debugInfo, null, 2)}
            </pre>
          </div>
        )}

        {error && (
          <div className="mb-6 bg-red-50 border-l-4 border-red-400 p-4">
            <div className="flex">
              <AlertCircle className="h-5 w-5 text-red-400" />
              <div className="ml-3">
                <p className="text-sm text-red-700">{error}</p>
              </div>
            </div>
          </div>
        )}

        <div>
          <label className="block text-sm font-medium text-gray-700 mb-4">
            AI Provider
          </label>
          <div className="flex items-center space-x-4">
            <label className="inline-flex items-center">
              <input
                type="radio"
                value="gemini"
                checked={settings.ai_provider === 'gemini'}
                onChange={(e) => handleUpdateProvider(e.target.value as Settings['ai_provider'])}
                className="form-radio h-4 w-4 text-primary"
              />
              <span className="ml-2">Gemini</span>
            </label>
            <label className="inline-flex items-center">
              <input
                type="radio"
                value="deepseek"
                checked={settings.ai_provider === 'deepseek'}
                onChange={(e) => handleUpdateProvider(e.target.value as Settings['ai_provider'])}
                className="form-radio h-4 w-4 text-primary"
              />
              <span className="ml-2">Deepseek</span>
            </label>
            <label className="inline-flex items-center">
              <input
                type="radio"
                value="openrouter"
                checked={settings.ai_provider === 'openrouter'}
                onChange={(e) => handleUpdateProvider(e.target.value as Settings['ai_provider'])}
                className="form-radio h-4 w-4 text-primary"
              />
              <span className="ml-2">OpenRouter</span>
            </label>
          </div>
        </div>

        {message && (
          <div className={`mt-6 p-4 rounded-md ${
            message.type === 'error' ? 'bg-red-50 text-red-700' : 'bg-green-50 text-green-700'
          }`}>
            <p className="text-sm">{message.text}</p>
          </div>
        )}

        <div className="border-t border-gray-200 pt-6 mt-6">
          <h3 className="text-lg font-medium text-gray-900 mb-4">Gemini Settings</h3>
          
          <form onSubmit={handleSaveGemini} className="space-y-4">
            <div>
              <label htmlFor="geminiApiKey" className="block text-sm font-medium text-gray-700">
                Gemini API Key
              </label>
              <div className="mt-1 relative">
                <input
                  type={showGeminiKey ? 'text' : 'password'}
                  id="geminiApiKey"
                  value={settings.gemini_api_key}
                  onChange={(e) => handleInputChange('gemini_api_key', e.target.value)}
                  className={`${inputClassName} pr-24`}
                  placeholder="Enter your Gemini API key"
                />
                <div className="absolute inset-y-0 right-0 flex items-center">
                  <button
                    type="button"
                    onClick={() => setShowGeminiKey(!showGeminiKey)}
                    className="pr-3 flex items-center text-gray-400 hover:text-gray-500"
                  >
                    {showGeminiKey ? (
                      <EyeOff className="h-5 w-5" aria-hidden="true" />
                    ) : (
                      <Eye className="h-5 w-5" aria-hidden="true" />
                    )}
                  </button>
                </div>
              </div>
            </div>

            <div>
              <label htmlFor="geminiPrompt" className="block text-sm font-medium text-gray-700">
                Gemini Prompt
              </label>
              <div className="mt-1">
                <textarea
                  id="geminiPrompt"
                  rows={10}
                  value={settings.gemini_prompt}
                  onChange={(e) => handleInputChange('gemini_prompt', e.target.value)}
                  className={inputClassName}
                  placeholder="Enter the system prompt for Gemini"
                />
              </div>
            </div>

            <div className="flex justify-end">
              <button
                type="submit"
                disabled={isSavingGemini}
                className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-gray-900 bg-primary hover:bg-primary-dark focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary disabled:opacity-50 disabled:cursor-not-allowed"
              >
                {isSavingGemini ? (
                  <>
                    <Loader2 className="h-4 w-4 mr-2 animate-spin" />
                    Saving...
                  </>
                ) : (
                  <>
                    <Plus className="h-4 w-4 mr-2" />
                    Save Gemini Settings
                  </>
                )}
              </button>
            </div>
          </form>
        </div>

        <div className="border-t border-gray-200 pt-6 mt-6">
          <h3 className="text-lg font-medium text-gray-900 mb-4">Deepseek Settings</h3>
          
          <form onSubmit={handleSaveDeepseek} className="space-y-4">
            <div>
              <label htmlFor="deepseekApiKey" className="block text-sm font-medium text-gray-700">
                Deepseek API Key
              </label>
              <div className="mt-1 relative">
                <input
                  type={showDeepseekKey ? 'text' : 'password'}
                  id="deepseekApiKey"
                  value={settings.deepseek_api_key}
                  onChange={(e) => handleInputChange('deepseek_api_key', e.target.value)}
                  className={`${inputClassName} pr-24`}
                  placeholder="Enter your Deepseek API key"
                />
                <div className="absolute inset-y-0 right-0 flex items-center">
                  <button
                    type="button"
                    onClick={() => setShowDeepseekKey(!showDeepseekKey)}
                    className="pr-3 flex items-center text-gray-400 hover:text-gray-500"
                  >
                    {showDeepseekKey ? (
                      <EyeOff className="h-5 w-5" aria-hidden="true" />
                    ) : (
                      <Eye className="h-5 w-5" aria-hidden="true" />
                    )}
                  </button>
                </div>
              </div>
            </div>

            <div>
              <label htmlFor="deepseekPrompt" className="block text-sm font-medium text-gray-700">
                Deepseek Prompt
              </label>
              <div className="mt-1">
                <textarea
                  id="deepseekPrompt"
                  rows={10}
                  value={settings.deepseek_prompt}
                  onChange={(e) => handleInputChange('deepseek_prompt', e.target.value)}
                  className={inputClassName}
                  placeholder="Enter the system prompt for Deepseek"
                />
              </div>
            </div>

            <div className="flex justify-end">
              <button
                type="submit"
                disabled={isSavingDeepseek}
                className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-gray-900 bg-primary hover:bg-primary-dark focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary disabled:opacity-50 disabled:cursor-not-allowed"
              >
                {isSavingDeepseek ? (
                  <>
                    <Loader2 className="h-4 w-4 mr-2 animate-spin" />
                    Saving...
                  </>
                ) : (
                  <>
                    <Plus className="h-4 w-4 mr-2" />
                    Save Deepseek Settings
                  </>
                )}
              </button>
            </div>
          </form>
        </div>

        <div className="border-t border-gray-200 pt-6 mt-6">
          <h3 className="text-lg font-medium text-gray-900 mb-4">OpenRouter Settings</h3>
          
          <form onSubmit={handleSaveOpenRouter} className="space-y-4">
            <div>
              <label htmlFor="openrouterApiKey" className="block text-sm font-medium text-gray-700">
                OpenRouter API Key
              </label>
              <div className="mt-1 relative">
                <input
                  type={showOpenRouterKey ? 'text' : 'password'}
                  id="openrouterApiKey"
                  value={settings.openrouter_api_key}
                  onChange={(e) => handleInputChange('openrouter_api_key', e.target.value)}
                  className={`${inputClassName} pr-24`}
                  placeholder="Enter your OpenRouter API key"
                />
                <div className="absolute inset-y-0 right-0 flex items-center">
                  <button
                    type="button"
                    onClick={() => setShowOpenRouterKey(!showOpenRouterKey)}
                    className="pr-3 flex items-center text-gray-400 hover:text-gray-500"
                  >
                    {showOpenRouterKey ? (
                      <EyeOff className="h-5 w-5" aria-hidden="true" />
                    ) : (
                      <Eye className="h-5 w-5" aria-hidden="true" />
                    )}
                  </button>
                </div>
              </div>
            </div>

            <div>
              <label htmlFor="openrouterPrompt" className="block text-sm font-medium text-gray-700">
                OpenRouter Prompt
              </label>
              <div className="mt-1">
                <textarea
                  id="openrouterPrompt"
                  rows={10}
                  value={settings.openrouter_prompt}
                  onChange={(e) => handleInputChange('openrouter_prompt', e.target.value)}
                  className={inputClassName}
                  placeholder="Enter the system prompt for OpenRouter"
                />
              </div>
            </div>

            <div>
              <label htmlFor="siteUrl" className="block text-sm font-medium text-gray-700">
                Site URL
              </label>
              <div className="mt-1">
                <input
                  type="url"
                  id="siteUrl"
                  value={settings.site_url}
                  onChange={(e) => handleInputChange('site_url', e.target.value)}
                  className={inputClassName}
                  placeholder={window.location.origin}
                />
              </div>
              <p className="mt-1 text-sm text-gray-500">
                Optional. Used for rankings on openrouter.ai
              </p>
            </div>

            <div>
              <label htmlFor="siteName" className="block text-sm font-medium text-gray-700">
                Site Name
              </label>
              <div className="mt-1">
                <input
                  type="text"
                  id="siteName"
                  value={settings.site_name}
                  onChange={(e) => handleInputChange('site_name', e.target.value)}
                  className={inputClassName}
                  placeholder="BananaDB"
                />
              </div>
              <p className="mt-1 text-sm text-gray-500">
                Optional. Used for rankings on openrouter.ai
              </p>
            </div>

            <div className="flex justify-end">
              <button
                type="submit"
                disabled={isSavingOpenRouter}
                className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-gray-900 bg-primary hover:bg-primary-dark focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary disabled:opacity-50 disabled:cursor-not-allowed"
              >
                {isSavingOpenRouter ? (
                  <>
                    <Loader2 className="h-4 w-4 mr-2 animate-spin" />
                    Saving...
                  </>
                ) : (
                  <>
                    <Plus className="h-4 w-4 mr-2" />
                    Save OpenRouter Settings
                  </>
                )}
              </button>
            </div>
          </form>
        </div>

        <div className="border-t border-gray-200 pt-6 mt-6">
          <DataSourcesManager />
        </div>
      </div>
    </div>
  );
}