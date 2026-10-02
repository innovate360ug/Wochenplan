-- Lernkarten-Tool (lernkarten.html): einmal im Supabase SQL Editor ausführen.
-- Karten teilen sich alle angemeldeten Nutzer, der Lernfortschritt gehört jedem selbst.

create table if not exists public.lern_cards (
  id text primary key,
  deck text, topic text, type text,
  prio int default 0,
  q text, a text, cloze text,
  items jsonb default '[]'::jsonb,
  note text, src text,
  sort_order int default 0,
  created_by uuid default auth.uid() references auth.users(id) on delete set null,
  updated_at timestamptz default now()
);
alter table public.lern_cards enable row level security;
create policy "cards lesen"    on public.lern_cards for select to authenticated using (true);
create policy "cards anlegen"  on public.lern_cards for insert to authenticated with check (true);
create policy "cards aendern"  on public.lern_cards for update to authenticated using (true) with check (true);
create policy "cards loeschen" on public.lern_cards for delete to authenticated using (true);

create table if not exists public.lern_progress (
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  card_id text not null references public.lern_cards(id) on delete cascade,
  due bigint default 0,
  ivl int default 0,
  ease float default 2.5,
  reps int default 0,
  lapses int default 0,
  seen text,
  updated_at timestamptz default now(),
  primary key (user_id, card_id)
);
alter table public.lern_progress enable row level security;
create policy "progress lesen"    on public.lern_progress for select to authenticated using (auth.uid() = user_id);
create policy "progress anlegen"  on public.lern_progress for insert to authenticated with check (auth.uid() = user_id);
create policy "progress aendern"  on public.lern_progress for update to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "progress loeschen" on public.lern_progress for delete to authenticated using (auth.uid() = user_id);

-- Live-Updates (die Seite hat zusätzlich eine Abfrage alle 45 s, falls das fehlt):
alter table public.lern_cards replica identity full;
alter table public.lern_progress replica identity full;
alter publication supabase_realtime add table public.lern_cards;
alter publication supabase_realtime add table public.lern_progress;
