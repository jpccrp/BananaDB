export interface ParsedCarListing {
  make: string;
  model: string;
  year: number;
  mileage: number;
  price: number;
  co2?: number;
  fuel_type?: string;
  first_registration_date?: string;
  power_kw?: number;
  power_hp?: number;
  gear_type?: string;
  number_of_doors?: number;
  number_of_seats?: number;
  seller?: string;
  location?: string;
  listing_url?: string;
}