import type { Database } from '../lib/database.types';

type Project = Database['public']['Tables']['projects']['Row'];

export function formatDate(date: string): string {
  const d = new Date(date);
  return d.toLocaleDateString('en-GB', {
    day: '2-digit',
    month: '2-digit',
    year: 'numeric'
  }).replace(/\//g, '.');
}

export function formatYearRange(start: number, end: number): string {
  if (start === end) return start.toString().slice(-2);
  return `${start.toString().slice(-2)}/${end.toString().slice(-2)}`;
}

export function getProjectName(project: Project): string {
  const date = formatDate(project.created_at);
  const yearRange = formatYearRange(project.year_range_start, project.year_range_end);
  return `${date}.${project.make.toUpperCase()}.${project.model.toUpperCase()}.${yearRange}.${project.freename.toUpperCase()}`;
}