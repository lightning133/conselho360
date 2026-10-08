-- Conselho360 — Supabase
-- Execute no SQL Editor do projeto.
-- O script é idempotente para tabelas/policies principais e cria o perfil
-- automaticamente quando um usuário é criado pelo Supabase Auth.

create extension if not exists "uuid-ossp";
create schema if not exists private;

do $$ begin
  create type public.tipo_usuario as enum ('professor','pedagogo','direcao','admin');
exception when duplicate_object then null; end $$;
do $$ begin
  create type public.status_avaliacao as enum ('rascunho','finalizada','enviada');
exception when duplicate_object then null; end $$;
do $$ begin
  create type public.status_item as enum ('pendente','em_acompanhamento','resolvido','encaminhado');
exception when duplicate_object then null; end $$;
do $$ begin
  create type public.tipo_dificuldade as enum ('aprendizagem','participacao','frequencia','comportamento','conteudo_especifico','apoio','outro');
exception when duplicate_object then null; end $$;
do $$ begin
  create type public.motivo_destaque as enum ('participacao','responsabilidade','protagonismo','evolucao','desempenho','colaboracao','outro');
exception when duplicate_object then null; end $$;

create table if not exists public.usuarios (
  id uuid primary key references auth.users(id) on delete cascade,
  nome text not null,
  email text not null unique,
  tipo public.tipo_usuario not null default 'professor',
  created_at timestamptz not null default now()
);

create table if not exists public.periodos (
  id uuid primary key default uuid_generate_v4(),
  nome text not null,
  data_inicio date,
  data_fim date,
  ativo boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.turmas (
  id uuid primary key default uuid_generate_v4(),
  nome text not null,
  ano text,
  periodo text,
  created_at timestamptz not null default now()
);

create table if not exists public.alunos (
  id uuid primary key default uuid_generate_v4(),
  nome text not null,
  turma_id uuid references public.turmas(id) on delete cascade,
  situacao text not null default 'ativo',
  created_at timestamptz not null default now()
);

create table if not exists public.professor_turmas (
  id uuid primary key default uuid_generate_v4(),
  professor_id uuid not null references public.usuarios(id) on delete cascade,
  turma_id uuid not null references public.turmas(id) on delete cascade,
  unique(professor_id, turma_id)
);

create table if not exists public.avaliacoes (
  id uuid primary key default uuid_generate_v4(),
  professor_id uuid not null references public.usuarios(id) on delete cascade,
  turma_id uuid not null references public.turmas(id) on delete cascade,
  periodo text not null,
  aprendizagem text,
  participacao text,
  postura text,
  frequencia text,
  observacoes text,
  status public.status_avaliacao not null default 'rascunho',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.avaliacoes_alunos (
  id uuid primary key default uuid_generate_v4(),
  aluno_id uuid not null references public.alunos(id) on delete cascade,
  professor_id uuid references public.usuarios(id) on delete set null,
  turma_id uuid not null references public.turmas(id) on delete cascade,
  periodo text not null,
  aprendizagem text,
  participacao text,
  frequencia text,
  dificuldade text,
  observacoes text,
  created_at timestamptz not null default now()
);

create table if not exists public.destaques (
  id uuid primary key default uuid_generate_v4(),
  aluno_id uuid not null references public.alunos(id) on delete cascade,
  professor_id uuid references public.usuarios(id) on delete set null,
  periodo text,
  motivo public.motivo_destaque not null,
  descricao text,
  created_at timestamptz not null default now()
);

create table if not exists public.dificuldades (
  id uuid primary key default uuid_generate_v4(),
  aluno_id uuid not null references public.alunos(id) on delete cascade,
  professor_id uuid references public.usuarios(id) on delete set null,
  periodo text,
  tipo public.tipo_dificuldade not null,
  descricao text,
  conteudo_relacionado text,
  estrategia_realizada text,
  observacoes text,
  status public.status_item not null default 'pendente',
  created_at timestamptz not null default now()
);

create table if not exists public.encaminhamentos (
  id uuid primary key default uuid_generate_v4(),
  aluno_id uuid not null references public.alunos(id) on delete cascade,
  descricao text not null,
  responsavel_id uuid references public.usuarios(id) on delete set null,
  prazo date,
  status public.status_item not null default 'pendente',
  resultado text,
  observacoes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.acoes (
  id uuid primary key default uuid_generate_v4(),
  aluno_id uuid not null references public.alunos(id) on delete cascade,
  descricao text not null,
  responsavel_id uuid references public.usuarios(id) on delete set null,
  prazo date,
  status public.status_item not null default 'pendente',
  resultado text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.reunioes (
  id uuid primary key default uuid_generate_v4(),
  turma_id uuid not null references public.turmas(id) on delete cascade,
  data timestamptz not null,
  periodo text,
  participantes text,
  observacoes text,
  decisoes text,
  created_at timestamptz not null default now()
);

create index if not exists idx_alunos_turma_id on public.alunos(turma_id);
create index if not exists idx_professor_turmas_turma on public.professor_turmas(turma_id);
create index if not exists idx_avaliacoes_professor on public.avaliacoes(professor_id);
create index if not exists idx_avaliacoes_turma on public.avaliacoes(turma_id);
create index if not exists idx_avaliacoes_alunos_aluno on public.avaliacoes_alunos(aluno_id);
create index if not exists idx_avaliacoes_alunos_professor on public.avaliacoes_alunos(professor_id);
create index if not exists idx_avaliacoes_alunos_turma on public.avaliacoes_alunos(turma_id);
create index if not exists idx_dificuldades_aluno on public.dificuldades(aluno_id);
create index if not exists idx_dificuldades_professor on public.dificuldades(professor_id);
create index if not exists idx_destaques_aluno on public.destaques(aluno_id);
create index if not exists idx_destaques_professor on public.destaques(professor_id);
create index if not exists idx_encaminhamentos_aluno on public.encaminhamentos(aluno_id);
create index if not exists idx_encaminhamentos_responsavel on public.encaminhamentos(responsavel_id);
create index if not exists idx_acoes_aluno on public.acoes(aluno_id);
create index if not exists idx_acoes_responsavel on public.acoes(responsavel_id);
create index if not exists idx_reunioes_turma on public.reunioes(turma_id);

create or replace function private.current_tipo()
returns text
language sql stable security definer
set search_path = public, pg_temp
as $$
  select tipo::text
  from public.usuarios
  where id = (select auth.uid());
$$;

revoke all on function private.current_tipo() from public;
grant usage on schema private to authenticated;
grant execute on function private.current_tipo() to authenticated;

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  insert into public.usuarios(id, nome, email, tipo)
  values (
    new.id,
    coalesce(nullif(trim(new.raw_user_meta_data->>'nome'), ''), split_part(new.email, '@', 1)),
    new.email,
    'professor'
  )
  on conflict(id) do update set email = excluded.email;
  return new;
end;
$$;

revoke all on function public.handle_new_user() from public, anon, authenticated;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = public, pg_temp
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_avaliacoes_updated on public.avaliacoes;
create trigger trg_avaliacoes_updated before update on public.avaliacoes
for each row execute function public.set_updated_at();

drop trigger if exists trg_enc_updated on public.encaminhamentos;
create trigger trg_enc_updated before update on public.encaminhamentos
for each row execute function public.set_updated_at();

drop trigger if exists trg_acoes_updated on public.acoes;
create trigger trg_acoes_updated before update on public.acoes
for each row execute function public.set_updated_at();

alter table public.usuarios enable row level security;
alter table public.periodos enable row level security;
alter table public.turmas enable row level security;
alter table public.alunos enable row level security;
alter table public.professor_turmas enable row level security;
alter table public.avaliacoes enable row level security;
alter table public.avaliacoes_alunos enable row level security;
alter table public.dificuldades enable row level security;
alter table public.destaques enable row level security;
alter table public.encaminhamentos enable row level security;
alter table public.acoes enable row level security;
alter table public.reunioes enable row level security;

do $$
declare r record;
begin
  for r in
    select schemaname, tablename, policyname
    from pg_policies
    where schemaname='public'
      and tablename in (
        'usuarios','periodos','turmas','alunos','professor_turmas',
        'avaliacoes','avaliacoes_alunos','dificuldades','destaques',
        'encaminhamentos','acoes','reunioes'
      )
  loop
    execute format('drop policy if exists %I on %I.%I', r.policyname, r.schemaname, r.tablename);
  end loop;
end $$;

create policy usuarios_select on public.usuarios
for select to authenticated
using (id=(select auth.uid()) or private.current_tipo()='admin');

create policy usuarios_admin_update on public.usuarios
for update to authenticated
using (private.current_tipo()='admin')
with check (private.current_tipo()='admin');

create policy usuarios_admin_delete on public.usuarios
for delete to authenticated
using (private.current_tipo()='admin');

create policy periodos_select on public.periodos
for select to authenticated using (true);
create policy periodos_admin_insert on public.periodos
for insert to authenticated
with check (private.current_tipo()='admin');
create policy periodos_admin_update on public.periodos
for update to authenticated
using (private.current_tipo()='admin')
with check (private.current_tipo()='admin');
create policy periodos_admin_delete on public.periodos
for delete to authenticated
using (private.current_tipo()='admin');

create policy turmas_select on public.turmas
for select to authenticated using (true);
create policy turmas_admin_insert on public.turmas
for insert to authenticated
with check (private.current_tipo()='admin');
create policy turmas_admin_update on public.turmas
for update to authenticated
using (private.current_tipo()='admin')
with check (private.current_tipo()='admin');
create policy turmas_admin_delete on public.turmas
for delete to authenticated
using (private.current_tipo()='admin');

create policy alunos_select on public.alunos
for select to authenticated using (true);
create policy alunos_staff_insert on public.alunos
for insert to authenticated
with check (private.current_tipo() in ('admin','pedagogo'));
create policy alunos_staff_update on public.alunos
for update to authenticated
using (private.current_tipo() in ('admin','pedagogo'))
with check (private.current_tipo() in ('admin','pedagogo'));
create policy alunos_staff_delete on public.alunos
for delete to authenticated
using (private.current_tipo() in ('admin','pedagogo'));

create policy professor_turmas_select on public.professor_turmas
for select to authenticated
using (professor_id=(select auth.uid()) or private.current_tipo() in ('admin','pedagogo','direcao'));
create policy professor_turmas_admin_insert on public.professor_turmas
for insert to authenticated
with check (private.current_tipo()='admin');
create policy professor_turmas_admin_update on public.professor_turmas
for update to authenticated
using (private.current_tipo()='admin')
with check (private.current_tipo()='admin');
create policy professor_turmas_admin_delete on public.professor_turmas
for delete to authenticated
using (private.current_tipo()='admin');

create policy avaliacoes_select on public.avaliacoes
for select to authenticated
using (professor_id=(select auth.uid()) or private.current_tipo() in ('pedagogo','direcao','admin'));
create policy avaliacoes_insert on public.avaliacoes
for insert to authenticated
with check (professor_id=(select auth.uid()) or private.current_tipo() in ('pedagogo','direcao','admin'));
create policy avaliacoes_update on public.avaliacoes
for update to authenticated
using (professor_id=(select auth.uid()) or private.current_tipo() in ('pedagogo','direcao','admin'))
with check (professor_id=(select auth.uid()) or private.current_tipo() in ('pedagogo','direcao','admin'));
create policy avaliacoes_delete on public.avaliacoes
for delete to authenticated
using (professor_id=(select auth.uid()) or private.current_tipo() in ('pedagogo','direcao','admin'));

create policy avaliacoes_alunos_select on public.avaliacoes_alunos
for select to authenticated
using (professor_id=(select auth.uid()) or private.current_tipo() in ('pedagogo','direcao','admin'));
create policy avaliacoes_alunos_insert on public.avaliacoes_alunos
for insert to authenticated
with check (professor_id=(select auth.uid()) or private.current_tipo() in ('pedagogo','direcao','admin'));
create policy avaliacoes_alunos_update on public.avaliacoes_alunos
for update to authenticated
using (professor_id=(select auth.uid()) or private.current_tipo() in ('pedagogo','direcao','admin'))
with check (professor_id=(select auth.uid()) or private.current_tipo() in ('pedagogo','direcao','admin'));
create policy avaliacoes_alunos_delete on public.avaliacoes_alunos
for delete to authenticated
using (professor_id=(select auth.uid()) or private.current_tipo() in ('pedagogo','direcao','admin'));

create policy dificuldades_select on public.dificuldades
for select to authenticated using (true);
create policy dificuldades_insert on public.dificuldades
for insert to authenticated
with check (professor_id=(select auth.uid()) or private.current_tipo() in ('admin','pedagogo','direcao'));
create policy dificuldades_update on public.dificuldades
for update to authenticated
using (professor_id=(select auth.uid()) or private.current_tipo() in ('admin','pedagogo','direcao'))
with check (professor_id=(select auth.uid()) or private.current_tipo() in ('admin','pedagogo','direcao'));
create policy dificuldades_delete on public.dificuldades
for delete to authenticated
using (professor_id=(select auth.uid()) or private.current_tipo() in ('admin','pedagogo','direcao'));

create policy destaques_select on public.destaques
for select to authenticated using (true);
create policy destaques_insert on public.destaques
for insert to authenticated
with check (professor_id=(select auth.uid()) or private.current_tipo() in ('admin','pedagogo','direcao'));
create policy destaques_update on public.destaques
for update to authenticated
using (professor_id=(select auth.uid()) or private.current_tipo() in ('admin','pedagogo','direcao'))
with check (professor_id=(select auth.uid()) or private.current_tipo() in ('admin','pedagogo','direcao'));
create policy destaques_delete on public.destaques
for delete to authenticated
using (professor_id=(select auth.uid()) or private.current_tipo() in ('admin','pedagogo','direcao'));

create policy encaminhamentos_select on public.encaminhamentos
for select to authenticated using (true);
create policy encaminhamentos_insert on public.encaminhamentos
for insert to authenticated
with check (responsavel_id=(select auth.uid()) and private.current_tipo() in ('admin','pedagogo','professor','direcao'));
create policy encaminhamentos_update on public.encaminhamentos
for update to authenticated
using (responsavel_id=(select auth.uid()) or private.current_tipo() in ('admin','pedagogo','direcao'))
with check (responsavel_id=(select auth.uid()) or private.current_tipo() in ('admin','pedagogo','direcao'));
create policy encaminhamentos_delete on public.encaminhamentos
for delete to authenticated
using (responsavel_id=(select auth.uid()) or private.current_tipo() in ('admin','pedagogo','direcao'));

create policy acoes_select on public.acoes
for select to authenticated using (true);
create policy acoes_insert on public.acoes
for insert to authenticated
with check (responsavel_id=(select auth.uid()) and private.current_tipo() in ('admin','pedagogo','professor','direcao'));
create policy acoes_update on public.acoes
for update to authenticated
using (responsavel_id=(select auth.uid()) or private.current_tipo() in ('admin','pedagogo','direcao'))
with check (responsavel_id=(select auth.uid()) or private.current_tipo() in ('admin','pedagogo','direcao'));
create policy acoes_delete on public.acoes
for delete to authenticated
using (responsavel_id=(select auth.uid()) or private.current_tipo() in ('admin','pedagogo','direcao'));

create policy reunioes_select on public.reunioes
for select to authenticated using (true);
create policy reunioes_insert on public.reunioes
for insert to authenticated
with check (private.current_tipo() in ('admin','pedagogo','direcao'));
create policy reunioes_update on public.reunioes
for update to authenticated
using (private.current_tipo() in ('admin','pedagogo','direcao'))
with check (private.current_tipo() in ('admin','pedagogo','direcao'));
create policy reunioes_delete on public.reunioes
for delete to authenticated
using (private.current_tipo() in ('admin','pedagogo','direcao'));

grant select on all tables in schema public to authenticated;
grant insert, update, delete on public.periodos, public.turmas, public.alunos,
  public.professor_turmas, public.avaliacoes, public.avaliacoes_alunos,
  public.dificuldades, public.destaques, public.encaminhamentos, public.acoes,
  public.reunioes, public.usuarios to authenticated;

insert into public.periodos(nome,data_inicio,data_fim)
select * from (values
  ('1º Período'::text,'2026-02-01'::date,'2026-04-30'::date),
  ('2º Período','2026-05-01','2026-07-31'),
  ('3º Período','2026-08-01','2026-11-30')
) v(nome,data_inicio,data_fim)
where not exists(select 1 from public.periodos);

insert into public.turmas(nome,ano,periodo)
select * from (values
  ('6º A','2026','Manhã'),
  ('7º B','2026','Manhã'),
  ('8º C','2026','Tarde')
) v(nome,ano,periodo)
where not exists(select 1 from public.turmas);

insert into public.alunos(nome,turma_id)
select v.nome,(select id from public.turmas order by nome limit 1)
from (values
  ('Ana Souza'::text),('Bruno Lima'),('Carla Reis'),('Diego Alves')
) v(nome)
where not exists(select 1 from public.alunos);

-- Depois de criar sua conta no Auth, torne-a administradora:
-- update public.usuarios set tipo='admin' where email='seu@email.com';
