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
