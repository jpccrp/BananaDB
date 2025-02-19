// Map of country names to their emoji flags
export const getCountryFlag = (country: string): string => {
  const countryMap: Record<string, string> = {
    'Germany': '🇩🇪',
    'Portugal': '🇵🇹',
    'Spain': '🇪🇸',
    'France': '🇫🇷',
    'Italy': '🇮🇹',
    'United Kingdom': '🇬🇧',
    // Add more countries as needed
  };

  return countryMap[country] || '🏳️';
};