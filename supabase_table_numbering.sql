-- Run after supabase_reservations.sql. Keeps a per-account high-water mark,
-- including when a table is deleted. Existing numeric table names are retained.
create table if not exists public.cafe_table_number_counters (
  owner_id uuid primary key references auth.users(id) on delete cascade,
  last_number bigint not null default 0 check (last_number >= 0)
);
alter table public.cafe_table_number_counters enable row level security;
revoke all on public.cafe_table_number_counters from anon, authenticated;
grant select, insert, update on public.cafe_table_number_counters to authenticated;
drop policy if exists "Owners manage table numbering" on public.cafe_table_number_counters;
create policy "Owners manage table numbering" on public.cafe_table_number_counters
  for all to authenticated
  using ((select auth.uid()) = owner_id)
  with check ((select auth.uid()) = owner_id);

create or replace function public.peek_next_cafe_table_number()
returns bigint language sql security invoker set search_path = '' as $$
  select greatest(
    coalesce((select c.last_number from public.cafe_table_number_counters c where c.owner_id = (select auth.uid())), 0),
    coalesce((select max(t.name::bigint) from public.cafe_tables t where t.owner_id = (select auth.uid()) and t.name ~ '^[0-9]{1,9}$'), 0)
  ) + 1;
$$;

create or replace function public.create_numbered_cafe_table(p_name text, p_capacity integer, p_suggested_number bigint)
returns public.cafe_tables language plpgsql security invoker set search_path = '' as $$
declare
  current_max bigint;
  next_number bigint;
  chosen_name text := btrim(p_name);
  created public.cafe_tables;
begin
  if auth.uid() is null then raise exception 'Authentication required'; end if;
  if chosen_name is null or length(chosen_name) = 0 or length(chosen_name) > 80 then raise exception 'Invalid table name'; end if;
  if p_capacity is null or p_capacity < 1 or p_capacity > 100 then raise exception 'Invalid capacity'; end if;

  select coalesce(max(t.name::bigint), 0) into current_max
    from public.cafe_tables t
    where t.owner_id = (select auth.uid()) and t.name ~ '^[0-9]{1,9}$';
  insert into public.cafe_table_number_counters(owner_id, last_number)
    values ((select auth.uid()), current_max) on conflict (owner_id) do nothing;

  if chosen_name = p_suggested_number::text then
    update public.cafe_table_number_counters c
       set last_number = greatest(c.last_number, current_max) + 1
     where c.owner_id = (select auth.uid()) returning last_number into next_number;
    chosen_name := next_number::text;
  elsif chosen_name ~ '^[0-9]{1,9}$' then
    update public.cafe_table_number_counters c
       set last_number = greatest(c.last_number, current_max, chosen_name::bigint)
     where c.owner_id = (select auth.uid());
  end if;
  insert into public.cafe_tables(name, capacity) values (chosen_name, p_capacity) returning * into created;
  return created;
end;
$$;
revoke all on function public.peek_next_cafe_table_number() from public, anon;
revoke all on function public.create_numbered_cafe_table(text, integer, bigint) from public, anon;
grant execute on function public.peek_next_cafe_table_number() to authenticated;
grant execute on function public.create_numbered_cafe_table(text, integer, bigint) to authenticated;

-- Keep the counter in sync with numeric names entered by existing clients or edits.
create or replace function public.record_cafe_table_number()
returns trigger language plpgsql security invoker set search_path = '' as $$
begin
  if new.name ~ '^[0-9]{1,9}$' then
    insert into public.cafe_table_number_counters(owner_id, last_number)
      values (new.owner_id, new.name::bigint)
      on conflict (owner_id) do update
        set last_number = greatest(public.cafe_table_number_counters.last_number, excluded.last_number);
  end if;
  return new;
end;
$$;
revoke all on function public.record_cafe_table_number() from public, anon;
drop trigger if exists record_cafe_table_number on public.cafe_tables;
create trigger record_cafe_table_number after insert or update of name on public.cafe_tables
  for each row execute function public.record_cafe_table_number();

insert into public.cafe_table_number_counters(owner_id, last_number)
select owner_id, max(name::bigint) from public.cafe_tables
where name ~ '^[0-9]{1,9}$' group by owner_id
on conflict (owner_id) do update
  set last_number = greatest(public.cafe_table_number_counters.last_number, excluded.last_number);
