-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create patients table
CREATE TABLE IF NOT EXISTS public.patients (
    id uuid DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
    name text NOT NULL,
    age integer NOT NULL,
    gender text NOT NULL,
    created_at timestamptz DEFAULT now() NOT NULL,
    updated_at timestamptz DEFAULT now() NOT NULL,
    CONSTRAINT fk_user
        FOREIGN KEY (user_id)
        REFERENCES auth.users(id)
        ON DELETE CASCADE
);

-- Enable RLS
ALTER TABLE public.patients ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Users can insert their own patient record"
ON public.patients
FOR INSERT
WITH CHECK (
    auth.uid()::uuid = user_id
);

CREATE POLICY "Users can view own patient record"
ON public.patients
FOR SELECT
USING (
    auth.uid()::uuid = user_id
);

-- Create indexes
CREATE INDEX idx_patients_user_id ON public.patients(user_id);
CREATE INDEX idx_patients_created_at ON public.patients(created_at DESC);

-- Create trigger for updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_patients_updated_at
    BEFORE UPDATE ON public.patients
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

