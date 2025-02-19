export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export interface Database {
  public: {
    Tables: {
      projects: {
        Row: {
          id: string
          make: string
          model: string
          year_range_start: number
          year_range_end: number
          engine_capacity_start: number
          engine_capacity_end: number
          fuel_type: string
          co2_emissions: number
          doors_config: string
          freename: string
          created_at: string
          user_id: string
        }
        Insert: {
          id?: string
          make: string
          model: string
          year_range_start: number
          year_range_end: number
          engine_capacity_start: number
          engine_capacity_end: number
          fuel_type: string
          co2_emissions: number
          doors_config: string
          freename: string
          created_at?: string
          user_id: string
        }
        Update: {
          id?: string
          make?: string
          model?: string
          year_range_start?: number
          year_range_end?: number
          engine_capacity_start?: number
          engine_capacity_end?: number
          fuel_type?: string
          co2_emissions?: number
          doors_config?: string
          freename?: string
          created_at?: string
          user_id?: string
        }
      }
      data_sources: {
        Row: {
          id: number
          name: string
          country: string
          created_at: string
        }
        Insert: {
          id?: number
          name: string
          country: string
          created_at?: string
        }
        Update: {
          id?: number
          name?: string
          country?: string
          created_at?: string
        }
      }
      car_listings: {
        Row: {
          id: string
          make: string
          model: string
          year: number
          mileage: number
          co2: number | null
          price: number
          unique_identifier: string
          source: string
          fuel_type: string | null
          first_registration_date: string | null
          power_kw: number | null
          power_hp: number | null
          gear_type: string | null
          number_of_doors: number | null
          number_of_seats: number | null
          seller: string | null
          location: string | null
          listing_url: string | null
          listing_date: string | null
          is_favorite: boolean
          created_at: string
          project_id: string | null
          user_id: string
        }
        Insert: {
          id?: string
          make: string
          model: string
          year: number
          mileage: number
          co2?: number | null
          price: number
          unique_identifier: string
          source: string
          fuel_type?: string | null
          first_registration_date?: string | null
          power_kw?: number | null
          power_hp?: number | null
          gear_type?: string | null
          number_of_doors?: number | null
          number_of_seats?: number | null
          seller?: string | null
          location?: string | null
          listing_url?: string | null
          listing_date?: string | null
          is_favorite?: boolean
          created_at?: string
          project_id?: string | null
          user_id: string
        }
        Update: {
          id?: string
          make?: string
          model?: string
          year?: number
          mileage?: number
          co2?: number | null
          price?: number
          unique_identifier?: string
          source?: string
          fuel_type?: string | null
          first_registration_date?: string | null
          power_kw?: number | null
          power_hp?: number | null
          gear_type?: string | null
          number_of_doors?: number | null
          number_of_seats?: number | null
          seller?: string | null
          location?: string | null
          listing_url?: string | null
          listing_date?: string | null
          is_favorite?: boolean
          created_at?: string
          project_id?: string | null
          user_id?: string
        }
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      get_data_sources: {
        Returns: {
          id: number
          name: string
          country: string
          created_at: string
        }[]
      }
      get_available_data_sources: {
        Returns: {
          id: number
          name: string
          country: string
        }[]
      }
      [_ in never]: never
    }
    Enums: {
      [_ in never]: never
    }
  }
}