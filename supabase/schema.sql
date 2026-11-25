-- Inventário Suporte Técnico — estrutura do banco no Supabase
-- Rode este arquivo inteiro no Supabase: SQL Editor > New query > colar > Run.

-- Locais (portas, armário, sala…)
create table if not exists public.secoes (
  id    text primary key,
  nome  text not null,
  ordem int  not null default 99
);

-- Itens do inventário (uma linha por unidade etiquetada)
create table if not exists public.itens (
  id             uuid primary key default gen_random_uuid(),
  secao          text not null references public.secoes(id),
  codigo         text not null default '',
  num_item       text not null default '',
  tipo           text not null default '',
  descricao      text not null default '',
  descricao_sap  text not null default '',
  caixa          text not null default '',
  cadastrado_em  date,
  obs            text not null default '',
  emprestimo     jsonb,          -- {pessoa, desde, motivo, previsao, id} quando está emprestado
  removido       jsonb,          -- {em, motivo, destino, obs} quando teve baixa
  criado_por     uuid default auth.uid(),
  criado_em      timestamptz not null default now(),
  atualizado_por uuid,
  atualizado_em  timestamptz not null default now()
);
create index if not exists itens_codigo_idx   on public.itens (codigo);
create index if not exists itens_num_item_idx on public.itens (num_item);

-- Histórico de empréstimos e devoluções
create table if not exists public.emprestimos (
  id             uuid primary key default gen_random_uuid(),
  item_id        uuid references public.itens(id) on delete set null,
  codigo         text not null default '',
  descricao      text not null default '',
  pessoa         text not null,
  retirada       date,
  previsao       date,
  motivo         text not null default '',
  devolucao      date,
  obs_devolucao  text not null default '',
  transferido_de text not null default '',
  registrado_por uuid default auth.uid(),
  devolvido_por  uuid,
  criado_em      timestamptz not null default now()
);

-- Quem pode entrar no portal (e-mail usado no login)
create table if not exists public.membros (
  email       text primary key,
  nome        text not null default '',
  pode_editar boolean not null default true
);

-- Atualiza "atualizado_em" a cada alteração de item
create or replace function public.tocar_atualizado() returns trigger
language plpgsql as $$ begin new.atualizado_em := now(); return new; end $$;
drop trigger if exists itens_tocar on public.itens;
create trigger itens_tocar before update on public.itens
  for each row execute function public.tocar_atualizado();

-- O e-mail logado está na lista de membros? (editar = true exige permissão de edição)
create or replace function public.eh_membro(editar boolean default false) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.membros m
    where lower(m.email) = lower(coalesce(auth.jwt() ->> 'email', ''))
      and (not editar or m.pode_editar)
  );
$$;
grant execute on function public.eh_membro(boolean) to authenticated;

-- Regras de acesso: só membros leem; só membros com pode_editar gravam. Ninguém apaga pelo portal.
alter table public.secoes      enable row level security;
alter table public.itens       enable row level security;
alter table public.emprestimos enable row level security;
alter table public.membros     enable row level security;

drop policy if exists ler_secoes on public.secoes;
create policy ler_secoes on public.secoes for select to authenticated using (public.eh_membro());

drop policy if exists ler_itens on public.itens;
create policy ler_itens on public.itens for select to authenticated using (public.eh_membro());
drop policy if exists criar_itens on public.itens;
create policy criar_itens on public.itens for insert to authenticated with check (public.eh_membro(true));
drop policy if exists alterar_itens on public.itens;
create policy alterar_itens on public.itens for update to authenticated using (public.eh_membro(true)) with check (public.eh_membro(true));

drop policy if exists ler_emp on public.emprestimos;
create policy ler_emp on public.emprestimos for select to authenticated using (public.eh_membro());
drop policy if exists criar_emp on public.emprestimos;
create policy criar_emp on public.emprestimos for insert to authenticated with check (public.eh_membro(true));
drop policy if exists alterar_emp on public.emprestimos;
create policy alterar_emp on public.emprestimos for update to authenticated using (public.eh_membro(true)) with check (public.eh_membro(true));

drop policy if exists ler_membros on public.membros;
create policy ler_membros on public.membros for select to authenticated using (public.eh_membro());

-- Atualização ao vivo entre quem está com o portal aberto
do $$ begin
  begin alter publication supabase_realtime add table public.itens;       exception when duplicate_object then null; end;
  begin alter publication supabase_realtime add table public.emprestimos; exception when duplicate_object then null; end;
end $$;
