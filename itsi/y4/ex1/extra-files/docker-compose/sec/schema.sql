create extension if not exists pgcrypto;
create extension if not exists pg_uuidv7;

create type user_role as enum ('admin', 'user');

create table if not exists users (
  id          uuid primary key default uuid_generate_v7(),
  email       text not null unique,
  username    text not null,
  password    text not null,
  role        user_role not null default 'user',
  bio         text,
  created_at  timestamptz not null default now()
);

create table if not exists refresh_tokens (
  id              uuid primary key default uuid_generate_v7(),
  user_id         uuid not null references users(id) on delete cascade,
  token_hash      bytea not null unique,
  created_at      timestamptz not null default now(),
  expires_at      timestamptz not null,
  revoked_at      timestamptz,
  replaced_by_id  uuid references refresh_tokens(id)
);

create index if not exists rt_user_idx on refresh_tokens (user_id);
create index if not exists rt_expires_idx on refresh_tokens (expires_at);

create table if not exists posts (
  id       uuid primary key default uuid_generate_v7(),
  title    text not null,
  content  text not null,
  user_id  uuid not null references users(id) on delete cascade
);

create or replace function authenticate_user_id(p_email text, p_pass text)
returns uuid
language sql
as $$
select u.id
from users u
where u.email = p_email
and u.password = crypt(p_pass, u.password)
$$;

-- i love security
insert into users (email, username, password, role)
values (
  'admin@example.com',
  'admin',
  crypt('Erm12345678!', gen_salt('bf', 12)), -- bcrypt hash via pgcrypto with cost 12
  'admin'
  );
