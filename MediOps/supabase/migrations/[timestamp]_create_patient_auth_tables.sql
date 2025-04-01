-- Enable UUID extension
create extension if not exists "uuid-ossp";

-- Create custom auth tables alongside existing schema
create table if not exists public.users (
    id uuid primary key default uuid_generate_v4(),
    email text unique not null,
    role text not null,
    username text,
    password_hash text not null,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

-- Modify existing patients table to work with our custom auth
alter table if exists public.patients
    add column if not exists user_id uuid references public.users(id) on delete cascade;

-- Create indexes
create index if not exists idx_users_email on public.users(email);
create index if not exists idx_patients_user_id on public.patients(user_id);

-- Create updated_at trigger function if it doesn't exist
create or replace function public.handle_updated_at()
returns trigger as $$
begin
    new.updated_at = now();
    return new;
end;
$$ language plpgsql;

-- Create triggers
create trigger handle_users_updated_at
    before update on public.users
    for each row
    execute function public.handle_updated_at();

-- RLS Policies for custom auth
alter table public.users enable row level security;

create policy "Users can view their own data"
    on public.users for select
    using (id = current_user_id());

create policy "Anyone can create a user"
    on public.users for insert
    with check (true);

-- Grant permissions
grant usage on schema public to anon, authenticated;
grant all on public.users to anon, authenticated; 