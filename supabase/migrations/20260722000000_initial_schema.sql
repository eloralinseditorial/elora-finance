-- Estrutura inicial do Elora Financeiro.
-- Todas as tabelas financeiras pertencem a uma organização.

create extension if not exists pgcrypto;

create table public.organizations (
  id uuid primary key default gen_random_uuid(),
  name text not null check (char_length(trim(name)) >= 2),
  slug text not null unique check (slug = lower(slug) and slug ~ '^[a-z0-9]+(?:-[a-z0-9]+)*$'),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.organization_members (
  organization_id uuid not null references public.organizations(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null default 'member' check (role in ('owner', 'admin', 'member', 'viewer')),
  created_at timestamptz not null default now(),
  primary key (organization_id, user_id)
);

create table public.accounts (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  name text not null check (char_length(trim(name)) >= 1),
  kind text not null check (kind in ('checking', 'savings', 'cash', 'credit_card', 'investment', 'other')),
  currency_code char(3) not null default 'BRL' check (currency_code = upper(currency_code)),
  opening_balance numeric(14, 2) not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.categories (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  name text not null check (char_length(trim(name)) >= 1),
  type text not null check (type in ('income', 'expense')),
  color text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (organization_id, name, type)
);

create table public.transactions (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  account_id uuid not null references public.accounts(id) on delete restrict,
  category_id uuid references public.categories(id) on delete set null,
  type text not null check (type in ('income', 'expense', 'transfer')),
  description text not null check (char_length(trim(description)) >= 1),
  amount numeric(14, 2) not null check (amount > 0),
  transaction_date date not null default current_date,
  status text not null default 'posted' check (status in ('draft', 'posted', 'void')),
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.budgets (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  category_id uuid not null references public.categories(id) on delete cascade,
  reference_month date not null check (extract(day from reference_month) = 1),
  amount numeric(14, 2) not null check (amount >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (organization_id, category_id, reference_month)
);

create index accounts_organization_id_idx on public.accounts (organization_id);
create index categories_organization_id_idx on public.categories (organization_id);
create index transactions_organization_date_idx on public.transactions (organization_id, transaction_date desc);
create index budgets_organization_month_idx on public.budgets (organization_id, reference_month);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create or replace function public.is_organization_member(target_organization_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.organization_members
    where organization_id = target_organization_id
      and user_id = auth.uid()
  );
$$;

create or replace function public.can_manage_organization(target_organization_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.organization_members
    where organization_id = target_organization_id
      and user_id = auth.uid()
      and role in ('owner', 'admin')
  );
$$;

create or replace function public.add_creator_as_organization_owner()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'Uma pessoa autenticada é necessária para criar uma organização';
  end if;

  insert into public.organization_members (organization_id, user_id, role)
  values (new.id, auth.uid(), 'owner');
  return new;
end;
$$;

create trigger organizations_add_creator_as_owner
  after insert on public.organizations
  for each row execute function public.add_creator_as_organization_owner();

create trigger organizations_set_updated_at before update on public.organizations
  for each row execute function public.set_updated_at();
create trigger accounts_set_updated_at before update on public.accounts
  for each row execute function public.set_updated_at();
create trigger categories_set_updated_at before update on public.categories
  for each row execute function public.set_updated_at();
create trigger transactions_set_updated_at before update on public.transactions
  for each row execute function public.set_updated_at();
create trigger budgets_set_updated_at before update on public.budgets
  for each row execute function public.set_updated_at();

alter table public.organizations enable row level security;
alter table public.organization_members enable row level security;
alter table public.accounts enable row level security;
alter table public.categories enable row level security;
alter table public.transactions enable row level security;
alter table public.budgets enable row level security;

create policy "Authenticated people can create organizations"
  on public.organizations for insert to authenticated with check (true);
create policy "Members can view their organizations"
  on public.organizations for select to authenticated
  using (public.is_organization_member(id));
create policy "Admins can update organizations"
  on public.organizations for update to authenticated
  using (public.can_manage_organization(id))
  with check (public.can_manage_organization(id));

create policy "Members can view organization members"
  on public.organization_members for select to authenticated
  using (public.is_organization_member(organization_id));

create policy "Members can view accounts"
  on public.accounts for select to authenticated using (public.is_organization_member(organization_id));
create policy "Admins can manage accounts"
  on public.accounts for all to authenticated using (public.can_manage_organization(organization_id))
  with check (public.can_manage_organization(organization_id));

create policy "Members can view categories"
  on public.categories for select to authenticated using (public.is_organization_member(organization_id));
create policy "Admins can manage categories"
  on public.categories for all to authenticated using (public.can_manage_organization(organization_id))
  with check (public.can_manage_organization(organization_id));

create policy "Members can view transactions"
  on public.transactions for select to authenticated using (public.is_organization_member(organization_id));
create policy "Admins can manage transactions"
  on public.transactions for all to authenticated using (public.can_manage_organization(organization_id))
  with check (public.can_manage_organization(organization_id));

create policy "Members can view budgets"
  on public.budgets for select to authenticated using (public.is_organization_member(organization_id));
create policy "Admins can manage budgets"
  on public.budgets for all to authenticated using (public.can_manage_organization(organization_id))
  with check (public.can_manage_organization(organization_id));
