-- Create enum for user roles
CREATE TYPE user_role AS ENUM ('super_admin', 'hospital_admin', 'doctor', 'lab_admin', 'patient');

-- Create users table with role-based authentication
CREATE TABLE IF NOT EXISTS users (
    id UUID DEFAULT extensions.uuid_generate_v4() PRIMARY KEY,
    email TEXT UNIQUE NOT NULL,
    role user_role NOT NULL,
    username TEXT UNIQUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create patients table for additional patient information
CREATE TABLE IF NOT EXISTS patients (
    id UUID DEFAULT extensions.uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    age INTEGER NOT NULL,
    gender TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create hospital_admins table
CREATE TABLE IF NOT EXISTS hospital_admins (
    id UUID DEFAULT extensions.uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    hospital_name TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create doctors table
CREATE TABLE IF NOT EXISTS doctors (
    id UUID DEFAULT extensions.uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    specialization TEXT NOT NULL,
    hospital_admin_id UUID REFERENCES hospital_admins(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create lab_admins table
CREATE TABLE IF NOT EXISTS lab_admins (
    id UUID DEFAULT extensions.uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    lab_name TEXT NOT NULL,
    hospital_admin_id UUID REFERENCES hospital_admins(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create super_admin with fixed credentials
INSERT INTO users (email, role, username)
VALUES ('admin@mediops.com', 'super_admin', 'superadmin')
ON CONFLICT (email) DO NOTHING;

-- Create RLS policies
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE patients ENABLE ROW LEVEL SECURITY;
ALTER TABLE hospital_admins ENABLE ROW LEVEL SECURITY;
ALTER TABLE doctors ENABLE ROW LEVEL SECURITY;
ALTER TABLE lab_admins ENABLE ROW LEVEL SECURITY;

-- Policy for users table
CREATE POLICY "Users can view their own data" ON users
    FOR SELECT
    USING (auth.uid() = id);

-- Policy for patients table
CREATE POLICY "Patients can view and update their own data" ON patients
    FOR ALL
    USING (auth.uid() = user_id);

-- Policy for hospital_admins
CREATE POLICY "Hospital admins can manage their own data" ON hospital_admins
    FOR ALL
    USING (auth.uid() = user_id);

-- Policy for doctors
CREATE POLICY "Doctors can view their own data" ON doctors
    FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Hospital admins can manage doctors" ON doctors
    FOR ALL
    USING (EXISTS (
        SELECT 1 FROM hospital_admins
        WHERE hospital_admins.user_id = auth.uid()
        AND hospital_admins.id = doctors.hospital_admin_id
    ));

-- Policy for lab_admins
CREATE POLICY "Lab admins can view their own data" ON lab_admins
    FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Hospital admins can manage lab admins" ON lab_admins
    FOR ALL
    USING (EXISTS (
        SELECT 1 FROM hospital_admins
        WHERE hospital_admins.user_id = auth.uid()
        AND hospital_admins.id = lab_admins.hospital_admin_id
    ));