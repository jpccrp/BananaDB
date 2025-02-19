# BananaDB - Vehicle Research Platform

A robust, secure, and user-friendly platform for managing vehicle research projects and car listings. Built with React, TypeScript, and Supabase, following industry best practices for security, data integrity, and user experience.

## Features

### Authentication & Authorization
- Secure email/password authentication through Supabase Auth
- Role-based access control (RBAC) with user and admin roles
- Granular Row Level Security (RLS) policies for data access
- Session management with automatic token refresh
- Protected routes and authenticated API calls

### Project Management
- Create and manage vehicle research projects
- Intelligent project naming system with unique identifiers
- Comprehensive vehicle specifications tracking:
  - Make and model
  - Year range
  - Engine capacity range
  - Fuel type
  - CO2 emissions
  - Door/seat configuration

### Car Listings
- Track and manage car listings from multiple sources:
  - mobile.de
  - autoscout24
  - olx.pt
  - standvirtual.pt
- Detailed listing information including:
  - Price and mileage
  - Power specifications (kW/HP)
  - Registration details
  - Seller information
  - Location data
  - Listing URLs and dates

## Security Measures

### Database Security
- Row Level Security (RLS) enabled on all tables
- Strict policies for data access:
  - Users can only access their own data
  - Admins have elevated access privileges
  - No public access to any data
- Secure function execution with `SECURITY DEFINER`
- Protected admin functions with restricted execution permissions

### Authentication Security
- Secure password hashing through Supabase Auth
- Email verification capabilities
- Protected routes in the frontend
- Secure session management
- CSRF protection
- XSS prevention through React's built-in protections

### API Security
- Type-safe database interactions with generated TypeScript types
- Input validation and sanitization
- Error handling and logging
- Rate limiting through Supabase

## Data Normalization

### Database Schema
- Normalized database design following 3NF principles
- Clear separation of concerns between tables
- Proper foreign key constraints
- Indexed fields for optimal query performance

### Tables Structure
1. **projects**
   - Primary key: UUID
   - User association through foreign key
   - Comprehensive vehicle specifications
   - Timestamps for auditing

2. **car_listings**
   - Primary key: UUID
   - Project and user associations
   - Unique constraint on listing identifiers
   - Optional fields for varying data availability
   - Timestamps for tracking

### Indexing Strategy
- B-tree indexes on frequently queried columns
- Composite indexes for common query patterns
- Foreign key indexes for efficient joins
- Unique indexes for constraints

## Technical Stack

- **Frontend**
  - React 18
  - TypeScript
  - Tailwind CSS
  - Headless UI
  - Lucide React icons

- **Backend**
  - Supabase
  - PostgreSQL
  - Row Level Security
  - Supabase Auth

- **Development**
  - Vite
  - ESLint
  - TypeScript
  - Git

## Best Practices

- Strict TypeScript usage throughout the codebase
- Component-based architecture
- Custom hooks for data management
- Centralized state management
- Error boundary implementation
- Responsive design
- Accessibility considerations
- Performance optimizations

## Project Structure

```
src/
├── components/     # React components
├── hooks/         # Custom React hooks
├── lib/           # Library configurations
├── utils/         # Utility functions
└── types/         # TypeScript type definitions

supabase/
└── migrations/    # Database migrations
```

## Security Policies

### Row Level Security (RLS)
```sql
-- Example of our layered security approach
CREATE POLICY "Users can view own projects"
  ON projects
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Admins can view all projects"
  ON projects
  FOR SELECT
  TO authenticated
  USING (is_admin(auth.uid()));
```

### Admin Functions
```sql
-- Secure function for checking admin status
CREATE OR REPLACE FUNCTION get_user_admin_status()
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
  -- Implementation with security checks
$$;
```

## Development

1. Clone the repository
2. Install dependencies: `npm install`
3. Set up Supabase environment variables
4. Run development server: `npm run dev`

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit changes
4. Push to the branch
5. Create a Pull Request

## License

MIT License - see LICENSE file for details