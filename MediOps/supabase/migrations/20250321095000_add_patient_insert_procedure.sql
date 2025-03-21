-- Create a stored procedure for inserting patients
create or replace function public.insert_patient(
    p_id uuid,
    p_user_id uuid,
    p_name text,
    p_age integer,
    p_gender text
) returns void as $$
begin
    insert into public.patients (
        id,
        user_id,
        name,
        age,
        gender
    ) values (
        p_id,
        p_user_id,
        p_name,
        p_age,
        p_gender
    );
end;
$$ language plpgsql security definer;

-- Grant execute permission to authenticated users
grant execute on function public.insert_patient to authenticated;

-- Add comment to the function
comment on function public.insert_patient(uuid, uuid, text, integer, text) is 'Inserts a new patient record with the given parameters'; 