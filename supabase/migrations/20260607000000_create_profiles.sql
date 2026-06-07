create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  name text not null,
  username text not null unique,
  bio text not null default '',
  location text not null default '',
  image_path text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index if not exists profiles_username_lower_idx
on public.profiles (lower(username));

alter table public.profiles enable row level security;

drop policy if exists "Authenticated users can read profiles" on public.profiles;
create policy "Authenticated users can read profiles"
on public.profiles
for select
to authenticated
using (true);

drop policy if exists "Users can create their own profile" on public.profiles;
create policy "Users can create their own profile"
on public.profiles
for insert
to authenticated
with check ((select auth.uid()) = id);

drop policy if exists "Users can update their own profile" on public.profiles;
create policy "Users can update their own profile"
on public.profiles
for update
to authenticated
using ((select auth.uid()) = id)
with check ((select auth.uid()) = id);

create or replace function public.is_username_taken(check_username text)
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1
    from public.profiles
    where lower(username) = lower(regexp_replace(btrim(check_username), '^@+', ''))
  );
$$;

revoke all on function public.is_username_taken(text) from public;
grant execute on function public.is_username_taken(text) to anon, authenticated;

create or replace function public.handle_new_user_profile()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, name, username, bio, location)
  values (
    new.id,
    coalesce(nullif(new.raw_user_meta_data ->> 'name', ''), 'Circul User'),
    coalesce(
      nullif(new.raw_user_meta_data ->> 'username', ''),
      'user_' || substr(new.id::text, 1, 8)
    ),
    '',
    ''
  )
  on conflict (id) do nothing;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created_create_profile on auth.users;
create trigger on_auth_user_created_create_profile
after insert on auth.users
for each row execute function public.handle_new_user_profile();
