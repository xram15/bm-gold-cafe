-- Reservation tables are private to the authenticated account that created them.
create table if not exists public.cafe_tables (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  name text not null check (length(trim(name)) between 1 and 80),
  capacity integer not null default 2 check (capacity between 1 and 100),
  booked boolean not null default false,
  guest_name text,
  guest_phone text,
  booked_for timestamptz,
  created_at timestamptz not null default now(),
  constraint cafe_tables_booking_details check (booked or (guest_name is null and guest_phone is null and booked_for is null))
);
create index if not exists cafe_tables_owner_created_idx on public.cafe_tables (owner_id, created_at);
alter table public.cafe_tables enable row level security;
revoke all on public.cafe_tables from anon, authenticated;
grant select, insert, update, delete on public.cafe_tables to authenticated;
drop policy if exists "Owners manage tables" on public.cafe_tables;
create policy "Owners manage tables" on public.cafe_tables
  for all to authenticated
  using ((select auth.uid()) = owner_id)
  with check ((select auth.uid()) = owner_id);

-- Lecture publique limitée au statut d'UNE table (scan du QR code).
-- Seule la personne possédant l'UUID (contenu dans le QR) peut interroger ;
-- aucune autre donnée ni liste n'est exposée aux utilisateurs anonymes.
create or replace function public.get_cafe_table_status(p_id uuid)
returns table (booked boolean, name text, guest_name text, booked_for timestamptz, capacity integer)
language sql
stable
security definer
set search_path = public
as $$
  select t.booked, t.name, t.guest_name, t.booked_for, t.capacity
  from public.cafe_tables t
  where t.id = p_id;
$$;

revoke all on function public.get_cafe_table_status(uuid) from public;
grant execute on function public.get_cafe_table_status(uuid) to anon, authenticated;

-- Liste publique des tables (nom + statut) pour « scanner/choisir une autre table ».
create or replace function public.list_cafe_tables_status()
returns table (id uuid, name text, booked boolean, capacity integer)
language sql
stable
security definer
set search_path = public
as $$
  select t.id, t.name, t.booked, t.capacity
  from public.cafe_tables t
  order by t.created_at;
$$;

revoke all on function public.list_cafe_tables_status() from public;
grant execute on function public.list_cafe_tables_status() to anon, authenticated;
