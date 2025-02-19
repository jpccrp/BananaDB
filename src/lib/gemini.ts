import type { ParsedCarListing } from './types';

// Generate a unique identifier for a listing
export function generateUniqueIdentifier(listing: ParsedCarListing, source: string): string {
  // Create a unique string from listing properties
  const uniqueString = [
    listing.make,
    listing.model,
    listing.mileage,
    listing.year,
    listing.price,
    listing.power_hp,
    listing.location
  ]
    .filter(Boolean)
    .join('')
    .toLowerCase()
    .replace(/[^a-z0-9]/g, '');
  
  // Use a simple hash function that works in the browser
  const hash = simpleHash(uniqueString);
  
  return `${source}-${hash}`;
}

// Simple hash function that works in the browser
function simpleHash(str: string): string {
  let hash = 0;
  for (let i = 0; i < str.length; i++) {
    const char = str.charCodeAt(i);
    hash = ((hash << 5) - hash) + char;
    hash = hash & hash; // Convert to 32-bit integer
  }
  // Convert to hex string and take last 12 characters
  return Math.abs(hash).toString(16).padStart(8, '0').slice(-12);
}