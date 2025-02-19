/*
  # Add Portuguese import cost fields

  1. Changes
    - Add transport_costs column to projects table
    - Add isv (Portuguese vehicle tax) column to projects table
    - Add portuguese_registration column to projects table
    - Add german_plates_insurance column to projects table

  2. Notes
    - All new fields are numeric with default value of 0
    - Existing RLS policies will automatically apply to new columns
*/

-- Add new columns for import costs
ALTER TABLE projects
ADD COLUMN IF NOT EXISTS transport_costs numeric NOT NULL DEFAULT 0,
ADD COLUMN IF NOT EXISTS isv numeric NOT NULL DEFAULT 0,
ADD COLUMN IF NOT EXISTS portuguese_registration numeric NOT NULL DEFAULT 0,
ADD COLUMN IF NOT EXISTS german_plates_insurance numeric NOT NULL DEFAULT 0;