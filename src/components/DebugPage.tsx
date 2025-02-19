import React, { useState } from 'react';
import { Loader2, AlertCircle, Check, X } from 'lucide-react';
import { supabase } from '../lib/supabase';

interface GeminiStatus {
  hasKey: boolean;
  hasPrompt: boolean;
}

export function DebugPage() {
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [status, setStatus] = useState<GeminiStatus | null>(null);

  const checkGeminiKey = async () => {
    setLoading(true);
    setError(null);

    try {
      console.log('Checking Gemini key status...');
      const { data, error } = await supabase.rpc('check_gemini_key');

      if (error) {
        console.error('Database error:', error);
        throw error;
      }

      console.log('Status response:', data);

      setStatus({
        hasKey: data.has_key,
        hasPrompt: data.has_prompt
      });
    } catch (err) {
      console.error('Error checking Gemini key:', err);
      setError(err instanceof Error ? err.message : 'Failed to check Gemini API key');
    } finally {
      setLoading(false);
    }
  };

  // Check on component mount
  React.useEffect(() => {
    checkGeminiKey();
  }, []);

  if (loading) {
    return (
      <div className="max-w-4xl mx-auto py-6">
        <div className="bg-white shadow-sm rounded-lg p-6">
          <div className="flex items-center justify-center h-32">
            <Loader2 className="h-6 w-6 animate-spin text-primary" />
          </div>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="max-w-4xl mx-auto py-6">
        <div className="bg-red-50 border-l-4 border-red-400 p-4">
          <div className="flex">
            <div className="flex-shrink-0">
              <AlertCircle className="h-5 w-5 text-red-400" />
            </div>
            <div className="ml-3">
              <p className="text-sm text-red-700">{error}</p>
            </div>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="max-w-4xl mx-auto py-6">
      <div className="bg-white shadow-sm rounded-lg p-6">
        <h2 className="text-lg font-medium text-gray-900 mb-6">Gemini API Status</h2>
        
        <div className="space-y-6">
          <div className="bg-gray-50 rounded-lg p-4 space-y-4">
            <div className="flex items-center justify-between">
              <span className="text-sm text-gray-600">API Key:</span>
              <div className="flex items-center">
                {status?.hasKey ? (
                  <Check className="h-4 w-4 text-green-500" />
                ) : (
                  <X className="h-4 w-4 text-red-500" />
                )}
                <span className="ml-2 text-sm">
                  {status?.hasKey ? 'Configured' : 'Not configured'}
                </span>
              </div>
            </div>

            <div className="flex items-center justify-between">
              <span className="text-sm text-gray-600">System Prompt:</span>
              <div className="flex items-center">
                {status?.hasPrompt ? (
                  <Check className="h-4 w-4 text-green-500" />
                ) : (
                  <X className="h-4 w-4 text-red-500" />
                )}
                <span className="ml-2 text-sm">
                  {status?.hasPrompt ? 'Configured' : 'Not configured'}
                </span>
              </div>
            </div>
          </div>

          <div className="flex justify-end">
            <button
              onClick={checkGeminiKey}
              className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-gray-900 bg-primary hover:bg-primary-dark focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary"
            >
              Refresh Status
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}