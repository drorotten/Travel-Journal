-- Norway Travel Journal — Supabase schema
-- Run in the Supabase SQL editor (project → SQL → New query)

create table if not exists public.trips (
  id           text primary key,          -- e.g. 'norway-2026'
  title        text not null default 'נורווגיה 2026',
  pin          text not null default '7799',
  created_at   timestamptz not null default now()
);

create table if not exists public.days (
  id                  text primary key,          -- 'd2026-09-14'
  trip_id             text not null references public.trips(id) on delete cascade,
  day_number          int  not null,
  date                date not null,
  title               text default '',
  destination         text default '',
  hotel_name          text default '',
  map_url             text default '',
  attractions         text default '',
  distance_km         text default '',
  drive_time          text default '',
  ferries             text default '',
  weather_description text default '',
  sunrise_time        text default '',
  sunset_time         text default '',
  sun_manual          boolean default false,
  experiences         text default '',
  challenges          text default '',
  people_places       text default '',
  culinary            text default '',
  accommodation       text default '',
  lat                 double precision,
  lng                 double precision,
  located             boolean default false,
  route               jsonb default '[]'::jsonb,   -- daily route coordinates
  media               jsonb default '[]'::jsonb,   -- [{path, name, type}] in storage
  updated_at          timestamptz not null default now(),
  updated_by          text default '',
  unique (trip_id, date)
);

create index if not exists days_trip_date_idx on public.days (trip_id, date);

-- keep updated_at honest
create or replace function public.touch_updated_at() returns trigger as $$
begin new.updated_at = now(); return new; end;
$$ language plpgsql;

drop trigger if exists days_touch on public.days;
create trigger days_touch before update on public.days
  for each row execute function public.touch_updated_at();

-- ── Access model ─────────────────────────────────────────────────────────────
-- Family/friends: read-only with the anon key (the /view link).
-- The two of you: write with the anon key too, gated by the app PIN.
-- Tighten later by swapping the write policies for `auth.role() = 'authenticated'`.

alter table public.trips enable row level security;
alter table public.days  enable row level security;

drop policy if exists trips_read on public.trips;
create policy trips_read on public.trips for select using (true);

drop policy if exists days_read on public.days;
create policy days_read on public.days for select using (true);

drop policy if exists days_write on public.days;
create policy days_write on public.days for insert with check (true);

drop policy if exists days_update on public.days;
create policy days_update on public.days for update using (true) with check (true);

drop policy if exists days_delete on public.days;
create policy days_delete on public.days for delete using (true);

-- realtime push to every connected device
alter publication supabase_realtime add table public.days;

-- ── Storage ──────────────────────────────────────────────────────────────────
insert into storage.buckets (id, name, public)
values ('journal-media', 'journal-media', true)
on conflict (id) do nothing;

drop policy if exists media_read on storage.objects;
create policy media_read on storage.objects
  for select using (bucket_id = 'journal-media');

drop policy if exists media_write on storage.objects;
create policy media_write on storage.objects
  for insert with check (bucket_id = 'journal-media');

-- seed the trip row
insert into public.trips (id, title, pin)
values ('norway-2026', 'נורווגיה 2026', '7799')
on conflict (id) do nothing;
