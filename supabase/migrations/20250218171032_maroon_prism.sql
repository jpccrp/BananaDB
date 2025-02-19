/*
  # Initial Schema Setup

  1. New Tables
    - `projects`
      - `id` (uuid, primary key)
      - `make` (text)
      - `model` (text)
      - `year_range_start` (integer)
      - `year_range_end` (integer)
      - `engine_capacity_start` (integer)
      - `engine_capacity_end` (integer)
      - `fuel_type` (text)
      - `co2_emissions` (numeric)
      - `doors_config` (text)
      - `freename` (text)
      - `created_at` (timestamptz)
      - `user_id` (uuid, references auth.users)

    - `car_listings`
      - `id` (uuid, primary key)
      - `make` (text)
      - `model` (text)
      - `year` (integer)
      - `mileage` (integer)
      - `co2` (numeric)
      - `price` (numeric)
      - `unique_identifier` (text, unique)
      - `source` (text)
      - `fuel_type` (text)
      - `first_registration_date` (date)
      - `power_kw` (integer)
      - `power_hp` (integer)
      - `gear_type` (text)
      - `number_of_doors` (integer)
      - `number_of_seats` (integer)
      - `seller` (text)
      - `location` (text)
      - `listing_url` (text)
      - `listing_date` (timestamptz)
      - `is_favorite` (boolean)
      - `created_at` (timestamptz)
      - `project_id` (uuid, references projects)
      - `user_id` (uuid, references auth.users)

  2. Security
    - Enable RLS on both tables
    - Add policies for authenticated users to manage their own data
*/

-- Create projects table
CREATE TABLE IF NOT EXISTS projects (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  make text NOT NULL,
  model text NOT NULL,
  year_range_start integer NOT NULL,
  year_range_end integer NOT NULL,
  engine_capacity_start integer NOT NULL,
  engine_capacity_end integer NOT NULL,
  fuel_type text NOT NULL,
  co2_emissions numeric NOT NULL DEFAULT 0,
  doors_config text NOT NULL,
  freename text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE
);

-- Create car_listings table
CREATE TABLE IF NOT EXISTS car_listings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  make text NOT NULL,
  model text NOT NULL,
  year integer NOT NULL,
  mileage integer NOT NULL,
  co2 numeric,
  price numeric NOT NULL,
  unique_identifier text NOT NULL UNIQUE,
  source text NOT NULL,
  fuel_type text,
  first_registration_date date,
  power_kw integer,
  power_hp integer,
  gear_type text,
  number_of_doors integer,
  number_of_seats integer,
  seller text,
  location text,
  listing_url text,
  listing_date timestamptz,
  is_favorite boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  project_id uuid REFERENCES projects(id) ON DELETE SET NULL,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_car_listings_project_id ON car_listings(project_id);
CREATE INDEX IF NOT EXISTS idx_car_listings_user_id ON car_listings(user_id);
CREATE INDEX IF NOT EXISTS idx_projects_user_id ON projects(user_id);
CREATE INDEX IF NOT EXISTS idx_car_listings_unique_identifier ON car_listings(unique_identifier);

-- Enable Row Level Security
ALTER TABLE projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE car_listings ENABLE ROW LEVEL SECURITY;

-- Create policies for projects
CREATE POLICY "Users can create their own projects"
  ON projects
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view their own projects"
  ON projects
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own projects"
  ON projects
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own projects"
  ON projects
  FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);

-- Create policies for car_listings
CREATE POLICY "Users can create their own car listings"
  ON car_listings
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view their own car listings"
  ON car_listings
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own car listings"
  ON car_listings
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own car listings"
  ON car_listings
  FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);