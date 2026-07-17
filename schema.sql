-- ============================================================
-- DOCTOR VENDING — Operations Console
-- Run this once in Supabase → SQL Editor → New query → Run
-- ============================================================
create extension if not exists pgcrypto;

create table if not exists locations (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  city text,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists categories (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  created_at timestamptz not null default now()
);

create table if not exists suppliers (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  contact_person text, phone text, email text, notes text,
  created_at timestamptz not null default now()
);

create table if not exists products (
  id uuid primary key default gen_random_uuid(),
  sku text,
  name text not null,
  category_id uuid references categories(id) on delete set null,
  unit text not null default 'pc',
  cost_price numeric(12,4) not null default 0,
  sale_price numeric(12,4) not null default 0,
  min_stock numeric(12,3) not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists employees (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  phone text, role text,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists machines (
  id uuid primary key default gen_random_uuid(),
  code text,
  name text not null,
  type text not null default 'snacks' check (type in ('coffee','snacks','combo')),
  site text,
  location_id uuid references locations(id) on delete set null,
  status text not null default 'active' check (status in ('active','maintenance','inactive')),
  created_at timestamptz not null default now()
);

create table if not exists purchases (
  id uuid primary key default gen_random_uuid(),
  supplier_id uuid references suppliers(id),
  location_id uuid not null references locations(id),
  ref_no text,
  date date not null default current_date,
  notes text,
  created_at timestamptz not null default now()
);

create table if not exists transfers (
  id uuid primary key default gen_random_uuid(),
  date date not null default current_date,
  from_location_id uuid not null references locations(id),
  to_location_id uuid not null references locations(id),
  employee_id uuid references employees(id),
  notes text,
  created_at timestamptz not null default now()
);

-- Every receipt line is a batch with its own expiry & cost (FEFO)
create table if not exists batches (
  id uuid primary key default gen_random_uuid(),
  purchase_id uuid references purchases(id) on delete cascade,
  transfer_id uuid references transfers(id),
  product_id uuid not null references products(id),
  location_id uuid not null references locations(id),
  qty_received numeric(12,3) not null,
  qty_remaining numeric(12,3) not null,
  unit_cost numeric(12,4) not null default 0,
  expiry_date date,
  created_at timestamptz not null default now()
);

-- Refills: employee takes stock from a location into a machine
create table if not exists issues (
  id uuid primary key default gen_random_uuid(),
  date date not null default current_date,
  employee_id uuid references employees(id),
  machine_id uuid references machines(id),
  location_id uuid not null references locations(id),
  notes text,
  created_at timestamptz not null default now()
);

create table if not exists issue_items (
  id uuid primary key default gen_random_uuid(),
  issue_id uuid not null references issues(id) on delete cascade,
  product_id uuid not null references products(id),
  qty numeric(12,3) not null,
  unit_cost numeric(12,4) not null default 0,   -- FEFO weighted average cost
  unit_price numeric(12,4) not null default 0,  -- sale price snapshot
  alloc jsonb,                                  -- [{b: batch_id, q: qty}] for restore on delete
  created_at timestamptz not null default now()
);

create table if not exists transfer_items (
  id uuid primary key default gen_random_uuid(),
  transfer_id uuid not null references transfers(id) on delete cascade,
  product_id uuid not null references products(id),
  qty numeric(12,3) not null,
  unit_cost numeric(12,4) not null default 0,
  alloc jsonb,
  created_at timestamptz not null default now()
);

-- Cash collected from machines
create table if not exists collections (
  id uuid primary key default gen_random_uuid(),
  date date not null default current_date,
  machine_id uuid not null references machines(id),
  employee_id uuid references employees(id),
  amount numeric(12,2) not null default 0,
  notes text,
  created_at timestamptz not null default now()
);

-- Waste / expiry write-offs / count corrections
create table if not exists adjustments (
  id uuid primary key default gen_random_uuid(),
  date date not null default current_date,
  batch_id uuid references batches(id) on delete set null,
  product_id uuid not null references products(id),
  location_id uuid not null references locations(id),
  qty numeric(12,3) not null,
  reason text not null default 'other' check (reason in ('expired','damaged','correction','other')),
  notes text,
  created_at timestamptz not null default now()
);

create index if not exists idx_batches_prod_loc on batches(product_id, location_id);
create index if not exists idx_batches_expiry   on batches(expiry_date);
create index if not exists idx_issue_items_iss  on issue_items(issue_id);
create index if not exists idx_issues_date      on issues(date);
create index if not exists idx_collections_date on collections(date);

-- Row Level Security: any signed-in user has full access
do $$
declare t text;
begin
  foreach t in array array['locations','categories','suppliers','products','employees','machines',
    'purchases','batches','issues','issue_items','transfers','transfer_items','collections','adjustments']
  loop
    execute format('alter table %I enable row level security', t);
    execute format('drop policy if exists auth_all on %I', t);
    execute format('create policy auth_all on %I for all to authenticated using (true) with check (true)', t);
  end loop;
end $$;

-- Seed data
insert into locations (name, city) values
  ('Dubai Warehouse','Dubai'),
  ('Umm Al Quwain Warehouse','Umm Al Quwain'),
  ('Abu Dhabi Warehouse','Abu Dhabi');

insert into categories (name) values
  ('Coffee Beans'),('Snacks & Chips'),('Chocolate'),('Water & Drinks'),('Cups & Consumables'),('Other');
