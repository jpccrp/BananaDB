import { GoogleGenerativeAI } from '@google/generative-ai';
import { supabase } from './supabase';
import type { ParsedCarListing } from './types';

async function getSettings() {
  try {
    // Get provider first
    const { data: provider, error: providerError } = await supabase.rpc('get_ai_provider');
    if (providerError) throw providerError;

    const currentProvider = provider || 'gemini';
    
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
        return {
          gemini_api_key: apiKey || '',
          gemini_prompt: prompt || '',
          ai_provider: 'gemini'
        };
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
        return {
          deepseek_api_key: apiKey || '',
          deepseek_prompt: prompt || '',
          ai_provider: 'deepseek'
        };
      }
      case 'openrouter': {
        const [
          { data: apiKey, error: apiKeyError },
          { data: prompt, error: promptError },
          { data: siteUrl, error: siteUrlError },
          { data: siteName, error: siteNameError }
        ] = await Promise.all([
          supabase.rpc('get_openrouter_apikey'),
          supabase.rpc('get_openrouter_prompt'),
          supabase.rpc('get_openrouter_site_url'),
          supabase.rpc('get_openrouter_site_name')
        ]);
        if (apiKeyError) throw apiKeyError;
        if (promptError) throw promptError;
        if (siteUrlError) throw siteUrlError;
        if (siteNameError) throw siteNameError;
        return {
          openrouter_api_key: apiKey || '',
          openrouter_prompt: prompt || '',
          site_url: siteUrl || window.location.origin,
          site_name: siteName || 'BananaDB',
          ai_provider: 'openrouter'
        };
      }
      default:
        throw new Error(`Unknown AI provider: ${currentProvider}`);
    }
  } catch (error) {
    console.error('Failed to load settings:', error);
    throw error instanceof Error ? error : new Error('Failed to load AI settings');
  }
}

async function parseWithGemini(prompt: string, rawData: string, apiKey: string): Promise<ParsedCarListing[]> {
  if (!apiKey?.trim()) {
    throw new Error('Gemini API key is required');
  }

  console.log('Initializing Gemini...');
  const genAI = new GoogleGenerativeAI(apiKey.trim());
  const model = genAI.getGenerativeModel({ model: "gemini-pro" });

  try {
    console.log('Sending request to Gemini with prompt:', prompt);
    console.log('Raw data:', rawData);

    const result = await model.generateContent([
      { text: prompt },
      { text: rawData }
    ]);
    const response = await result.response;
    const text = response.text();
    
    console.log('Raw Gemini response:', text);
    return parseAIResponse(text);
  } catch (error) {
    console.error('Gemini parsing error:', error);
    throw error;
  }
}

async function parseWithDeepseek(prompt: string, rawData: string, apiKey: string): Promise<ParsedCarListing[]> {
  if (!apiKey?.trim()) {
    throw new Error('Deepseek API key is required');
  }

  console.log('Initializing Deepseek...');
  
  try {
    console.log('Sending request to Deepseek with prompt:', prompt);
    console.log('Raw data:', rawData);

    const response = await fetch('https://api.deepseek.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${apiKey.trim()}`
      },
      body: JSON.stringify({
        model: "deepseek-chat",
        messages: [
          {
            role: "system",
            content: prompt
          },
          {
            role: "user",
            content: rawData
          }
        ],
        temperature: 0.3,
        response_format: { type: "json_object" }
      })
    });

    if (!response.ok) {
      const error = await response.json();
      console.error('Deepseek error response:', error);
      throw new Error(error.error?.message || 'Failed to get response from Deepseek');
    }

    const data = await response.json();
    console.log('Raw Deepseek response:', data);

    const content = data.choices[0]?.message?.content;
    
    if (!content) {
      throw new Error('No content in Deepseek response');
    }

    console.log('Deepseek content:', content);
    return parseAIResponse(content);
  } catch (error) {
    console.error('Deepseek parsing error:', error);
    throw error;
  }
}

async function parseWithOpenRouter(prompt: string, rawData: string, apiKey: string, siteUrl: string, siteName: string): Promise<ParsedCarListing[]> {
  if (!apiKey?.trim()) {
    throw new Error('OpenRouter API key is required');
  }

  console.log('Initializing OpenRouter...');
  
  try {
    console.log('Sending request to OpenRouter with prompt:', prompt);
    console.log('Raw data:', rawData);

    const response = await fetch('https://openrouter.ai/api/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${apiKey.trim()}`,
        'HTTP-Referer': siteUrl,
        'X-Title': siteName
      },
      body: JSON.stringify({
        model: 'deepseek/deepseek-r1:free',
        messages: [
          {
            role: "system",
            content: prompt
          },
          {
            role: "user",
            content: rawData
          }
        ],
        temperature: 0.3,
        response_format: { type: "json_object" },
        fallbacks: ["anthropic/claude-3-sonnet", "gryphe/mythomax-l2-13b"]
      })
    });

    if (!response.ok) {
      const error = await response.json();
      console.error('OpenRouter error response:', error);
      throw new Error(error.error?.message || 'Failed to get response from OpenRouter');
    }

    const data = await response.json();
    console.log('Raw OpenRouter response:', data);

    const content = data.choices[0]?.message?.content;
    
    if (!content) {
      throw new Error('No content in OpenRouter response');
    }

    console.log('OpenRouter content:', content);
    return parseAIResponse(content);
  } catch (error) {
    console.error('OpenRouter parsing error:', error);
    throw error;
  }
}

function parseAIResponse(text: string): ParsedCarListing[] {
  try {
    console.log('Parsing AI response text:', text);
    const parsed = JSON.parse(text);
    console.log('Parsed JSON:', parsed);
    
    // Handle response format
    if (parsed.listings && Array.isArray(parsed.listings)) {
      console.log('Found listings array:', parsed.listings);
      return parsed.listings;
    } else if (Array.isArray(parsed)) {
      console.log('Found direct array:', parsed);
      return parsed;
    } else if (typeof parsed === 'object') {
      console.log('Found single object, converting to array:', [parsed]);
      return [parsed];
    }
    
    throw new Error('Invalid response format');
  } catch (parseError) {
    console.error('Failed to parse AI response:', parseError);
    throw new Error('Failed to parse AI response: ' + parseError.message);
  }
}

function validateListing(listing: any): listing is ParsedCarListing {
  try {
    if (!listing || typeof listing !== 'object') {
      console.log('Invalid listing - not an object:', listing);
      return false;
    }

    // Required fields
    const requiredFields = {
      make: listing.make,
      model: listing.model,
      year: listing.year,
      mileage: listing.mileage,
      price: listing.price
    };

    console.log('Checking required fields:', requiredFields);

    if (
      typeof listing.make !== 'string' || !listing.make.trim() ||
      typeof listing.model !== 'string' || !listing.model.trim() ||
      typeof listing.year !== 'number' || listing.year < 1900 || listing.year > new Date().getFullYear() + 1 ||
      typeof listing.mileage !== 'number' || listing.mileage < 0 ||
      typeof listing.price !== 'number' || listing.price < 0
    ) {
      console.log('Required fields validation failed');
      return false;
    }

    // Optional fields validation
    if (listing.co2 !== undefined) {
      console.log('Validating co2:', listing.co2);
      if (typeof listing.co2 !== 'number' || listing.co2 < 0) return false;
    }
    if (listing.power_kw !== undefined) {
      console.log('Validating power_kw:', listing.power_kw);
      if (typeof listing.power_kw !== 'number' || listing.power_kw < 0) return false;
    }
    if (listing.power_hp !== undefined) {
      console.log('Validating power_hp:', listing.power_hp);
      if (typeof listing.power_hp !== 'number' || listing.power_hp < 0) return false;
    }
    if (listing.number_of_doors !== undefined) {
      console.log('Validating number_of_doors:', listing.number_of_doors);
      if (typeof listing.number_of_doors !== 'number' || listing.number_of_doors < 0) return false;
    }
    if (listing.number_of_seats !== undefined) {
      console.log('Validating number_of_seats:', listing.number_of_seats);
      if (typeof listing.number_of_seats !== 'number' || listing.number_of_seats < 0) return false;
    }

    // Normalize fuel type
    if (listing.fuel_type) {
      console.log('Validating fuel_type:', listing.fuel_type);
      const fuelTypeMap: Record<string, string> = {
        'gasoline': 'Petrol',
        'gas': 'Petrol',
        'petrol': 'Petrol',
        'diesel': 'Diesel',
        'electric': 'Electric',
        'hybrid': 'Hybrid',
        'plug-in hybrid': 'Plug-in Hybrid',
        'plugin hybrid': 'Plug-in Hybrid',
        'phev': 'Plug-in Hybrid'
      };

      const normalizedFuelType = fuelTypeMap[listing.fuel_type.toLowerCase()];
      if (normalizedFuelType) {
        listing.fuel_type = normalizedFuelType;
      } else {
        console.log('Invalid fuel type:', listing.fuel_type);
        delete listing.fuel_type;
      }
    }

    console.log('Listing validation passed');
    return true;
  } catch (error) {
    console.error('Error validating listing:', error);
    return false;
  }
}

export async function parseCarListing(rawData: string): Promise<ParsedCarListing[]> {
  if (!rawData.trim()) {
    throw new Error("No data provided");
  }

  try {
    const settings = await getSettings();
    console.log('Using AI provider:', settings.ai_provider);
    
    let parsedListings: ParsedCarListing[];
    
    switch (settings.ai_provider) {
      case 'openrouter':
        if (!settings.openrouter_api_key) {
          throw new Error('OpenRouter API key is required');
        }
        if (!settings.openrouter_prompt) {
          throw new Error('OpenRouter prompt is required');
        }
        parsedListings = await parseWithOpenRouter(
          settings.openrouter_prompt,
          rawData,
          settings.openrouter_api_key,
          settings.site_url || window.location.origin,
          settings.site_name || 'BananaDB'
        );
        break;

      case 'deepseek':
        if (!settings.deepseek_api_key) {
          throw new Error('Deepseek API key is required');
        }
        if (!settings.deepseek_prompt) {
          throw new Error('Deepseek prompt is required');
        }
        parsedListings = await parseWithDeepseek(
          settings.deepseek_prompt,
          rawData,
          settings.deepseek_api_key
        );
        break;

      default: // gemini
        if (!settings.gemini_api_key) {
          throw new Error('Gemini API key is required');
        }
        if (!settings.gemini_prompt) {
          throw new Error('Gemini prompt is required');
        }
        parsedListings = await parseWithGemini(
          settings.gemini_prompt,
          rawData,
          settings.gemini_api_key
        );
    }

    // Validate each listing
    const validListings = parsedListings.filter(validateListing);
    console.log(`Validated ${validListings.length} of ${parsedListings.length} listings`);
    
    if (validListings.length === 0) {
      throw new Error('No valid listings found in the response');
    }
    
    return validListings;
  } catch (error) {
    console.error("Error in parseCarListing:", error);
    throw error instanceof Error ? error : new Error("Failed to parse car listing data");
  }
}