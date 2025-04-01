-- Drop existing tables if they exist (be careful with this in production!)
drop table if exists public.patients cascade;
drop table if exists public.users cascade;

-- Enable UUID extension
create extension if not exists "uuid-ossp";

-- Create users table (custom auth table, not using Supabase Auth)
create table if not exists public.users (
    id uuid primary key default uuid_generate_v4(),
    email text unique not null,
    password_hash text not null,
    role text not null check (role in ('patient', 'doctor', 'admin')),
    email_verified boolean default false,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

-- Create patients table
create table if not exists public.patients (
    id uuid primary key default uuid_generate_v4(),
    user_id uuid references public.users(id) on delete cascade,
    name text not null,
    age integer not null check (age > 0),
    gender text not null,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

-- Create indexes for better query performance
create index if not exists idx_users_email on public.users(email);
create index if not exists idx_patients_user_id on public.patients(user_id);

-- Create updated_at trigger function
create or replace function public.handle_updated_at()
returns trigger as $$
begin
    new.updated_at = now();
    return new;
end;
$$ language plpgsql;

-- Create triggers for automatic updated_at
create trigger handle_users_updated_at
    before update on public.users
    for each row
    execute function public.handle_updated_at();

create trigger handle_patients_updated_at
    before update on public.patients
    for each row
    execute function public.handle_updated_at();

-- Create RLS policies
alter table public.users enable row level security;
alter table public.patients enable row level security;

-- Create policies for users table
create policy "Users can view their own data"
    on public.users for select
    using (auth.uid() = id);

create policy "Anyone can create a user"
    on public.users for insert
    with check (true);

-- Create policies for patients table
create policy "Patients can view their own data"
    on public.patients for select
    using (auth.uid() = user_id);

create policy "Patients can create their own data"
    on public.patients for insert
    with check (auth.uid() = user_id);

-- Grant necessary permissions
grant usage on schema public to anon, authenticated;
grant all on public.users to anon, authenticated;
grant all on public.patients to anon, authenticated;
grant usage on sequence public.users_id_seq to anon, authenticated;
grant usage on sequence public.patients_id_seq to anon, authenticated; 