-- PONTE: execute este arquivo integralmente no SQL Editor do Supabase.
-- A autorização de professor usa app_metadata. Nunca use user_metadata para papéis.
create extension if not exists pgcrypto;

create table if not exists public.classes (
  id uuid primary key default gen_random_uuid(),
  name text not null unique check (char_length(trim(name)) between 2 and 100),
  school_year smallint not null check (school_year between 1 and 3),
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null check (char_length(trim(full_name)) between 3 and 120),
  role text not null default 'student' check (role in ('student','teacher')),
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.class_members (
  id uuid primary key default gen_random_uuid(),
  class_id uuid not null references public.classes(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  member_role text not null check (member_role in ('student','teacher')),
  created_at timestamptz not null default now(),
  unique(class_id, user_id)
);
create table if not exists public.subjects (
  id uuid primary key default gen_random_uuid(), name text not null unique check (char_length(trim(name)) between 2 and 80),
  created_at timestamptz not null default now()
);
create table if not exists public.lessons (
  id uuid primary key default gen_random_uuid(), class_id uuid not null references public.classes(id) on delete cascade,
  subject_id uuid not null references public.subjects(id) on delete restrict, lesson_date date not null,
  title text not null check (char_length(trim(title)) between 2 and 160), summary text check (char_length(summary) <= 3000),
  material_text text check (char_length(material_text) <= 5000), material_url text check (material_url is null or material_url ~* '^https?://[^[:space:]]+$'),
  teacher_id uuid not null references public.profiles(id) on delete restrict, created_at timestamptz not null default now()
);
create table if not exists public.absences (
  id uuid primary key default gen_random_uuid(), student_id uuid not null references public.profiles(id) on delete cascade,
  absence_date date not null check (absence_date <= current_date), reason text check (char_length(reason) <= 300), created_at timestamptz not null default now(),
  unique(student_id, absence_date)
);
create table if not exists public.tasks (
  id uuid primary key default gen_random_uuid(), lesson_id uuid references public.lessons(id) on delete set null,
  class_id uuid not null references public.classes(id) on delete cascade, subject_id uuid not null references public.subjects(id) on delete restrict,
  title text not null check (char_length(trim(title)) between 2 and 160), description text check (char_length(description) <= 3000),
  due_date date, estimated_minutes integer not null default 30 check (estimated_minutes between 5 and 600),
  priority text not null default 'medium' check (priority in ('low','medium','high')),
  created_by uuid not null references public.profiles(id) on delete restrict, created_at timestamptz not null default now()
);
create table if not exists public.task_progress (
  id uuid primary key default gen_random_uuid(), student_id uuid not null references public.profiles(id) on delete cascade,
  task_id uuid not null references public.tasks(id) on delete cascade, status text not null default 'pending' check (status in ('pending','in_progress','completed')),
  completed_at timestamptz, needs_help boolean not null default false, created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
  unique(student_id, task_id), check ((status = 'completed' and completed_at is not null) or (status <> 'completed' and completed_at is null))
);
create table if not exists public.help_requests (
  id uuid primary key default gen_random_uuid(), student_id uuid not null references public.profiles(id) on delete cascade,
  task_id uuid references public.tasks(id) on delete set null, lesson_id uuid references public.lessons(id) on delete set null,
  description text not null check (char_length(trim(description)) between 5 and 1500), status text not null default 'open' check (status in ('open','in_progress','resolved')),
  assigned_teacher_id uuid references public.profiles(id) on delete set null, created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
  check (task_id is not null or lesson_id is not null or description is not null)
);
create index if not exists lessons_class_date_idx on public.lessons(class_id, lesson_date desc);
create index if not exists tasks_class_due_idx on public.tasks(class_id, due_date);
create index if not exists task_progress_student_idx on public.task_progress(student_id, status);
create index if not exists help_requests_student_idx on public.help_requests(student_id, status);
create index if not exists class_members_user_idx on public.class_members(user_id, class_id);

create or replace function public.set_updated_at() returns trigger language plpgsql set search_path = public as $$ begin new.updated_at = now(); return new; end; $$;
create trigger profiles_updated_at before update on public.profiles for each row execute function public.set_updated_at();
create trigger classes_updated_at before update on public.classes for each row execute function public.set_updated_at();
create trigger task_progress_updated_at before update on public.task_progress for each row execute function public.set_updated_at();
create trigger help_requests_updated_at before update on public.help_requests for each row execute function public.set_updated_at();

-- A conta pública sempre nasce como estudante; app_metadata só pode ser alterado com credenciais administrativas.
create or replace function public.handle_new_user() returns trigger language plpgsql security definer set search_path = public as $$
begin insert into public.profiles(id, full_name, role) values (new.id, coalesce(nullif(trim(new.raw_user_meta_data->>'full_name'), ''), 'Estudante'), 'student'); return new; end; $$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users for each row execute procedure public.handle_new_user();

create or replace function public.is_admin() returns boolean language sql stable security definer set search_path = public as $$ select coalesce((auth.jwt() -> 'app_metadata' ->> 'ponte_admin')::boolean, false); $$;
create or replace function public.is_class_member(target_class uuid) returns boolean language sql stable security definer set search_path = public as $$ select exists(select 1 from public.class_members where class_id=target_class and user_id=auth.uid()); $$;
create or replace function public.is_class_teacher(target_class uuid) returns boolean language sql stable security definer set search_path = public as $$ select exists(select 1 from public.class_members cm join public.profiles p on p.id=cm.user_id where cm.class_id=target_class and cm.user_id=auth.uid() and cm.member_role='teacher' and p.role='teacher'); $$;
create or replace function public.can_access_task(target_task uuid) returns boolean language sql stable security definer set search_path = public as $$ select exists(select 1 from public.tasks t where t.id=target_task and public.is_class_member(t.class_id)); $$;
create or replace function public.can_access_lesson(target_lesson uuid) returns boolean language sql stable security definer set search_path = public as $$ select exists(select 1 from public.lessons l where l.id=target_lesson and public.is_class_member(l.class_id)); $$;
create or replace function public.can_teach_help(target_help uuid) returns boolean language sql stable security definer set search_path = public as $$ select exists(select 1 from public.help_requests h left join public.tasks t on t.id=h.task_id left join public.lessons l on l.id=h.lesson_id where h.id=target_help and (public.is_class_teacher(t.class_id) or public.is_class_teacher(l.class_id))); $$;
create or replace function public.prevent_self_role_change() returns trigger language plpgsql security definer set search_path = public as $$ begin if auth.uid()=old.id and new.role<>old.role and not public.is_admin() then raise exception 'O papel da conta não pode ser alterado pelo próprio usuário'; end if; return new; end; $$;
create trigger profiles_role_guard before update on public.profiles for each row execute function public.prevent_self_role_change();

revoke all on function public.handle_new_user() from public;
revoke all on function public.is_admin(), public.is_class_member(uuid), public.is_class_teacher(uuid), public.can_access_task(uuid), public.can_access_lesson(uuid), public.can_teach_help(uuid), public.prevent_self_role_change() from public;
grant execute on function public.is_admin(), public.is_class_member(uuid), public.is_class_teacher(uuid), public.can_access_task(uuid), public.can_access_lesson(uuid), public.can_teach_help(uuid) to authenticated;

alter table public.profiles enable row level security; alter table public.classes enable row level security; alter table public.class_members enable row level security; alter table public.subjects enable row level security; alter table public.lessons enable row level security; alter table public.absences enable row level security; alter table public.tasks enable row level security; alter table public.task_progress enable row level security; alter table public.help_requests enable row level security;
create policy "profiles own or admin read" on public.profiles for select to authenticated using (id=auth.uid() or public.is_admin());
create policy "profiles own update" on public.profiles for update to authenticated using (id=auth.uid() or public.is_admin()) with check (id=auth.uid() or public.is_admin());
create policy "classes visible to members" on public.classes for select to authenticated using (public.is_class_member(id) or public.is_admin());
create policy "members visible to self or class teachers" on public.class_members for select to authenticated using (user_id=auth.uid() or public.is_class_teacher(class_id) or public.is_admin());
create policy "subjects readable" on public.subjects for select to authenticated using (true);
create policy "lessons readable in own class" on public.lessons for select to authenticated using (public.is_class_member(class_id) or public.is_admin());
create policy "teachers create lessons" on public.lessons for insert to authenticated with check (teacher_id=auth.uid() and public.is_class_teacher(class_id));
create policy "teachers change own class lessons" on public.lessons for update to authenticated using (public.is_class_teacher(class_id) or public.is_admin()) with check (teacher_id=auth.uid() and public.is_class_teacher(class_id) or public.is_admin());
create policy "teachers delete own class lessons" on public.lessons for delete to authenticated using (public.is_class_teacher(class_id) or public.is_admin());
create policy "students manage own absences" on public.absences for all to authenticated using (student_id=auth.uid()) with check (student_id=auth.uid());
create policy "tasks readable in own class" on public.tasks for select to authenticated using (public.is_class_member(class_id) or public.is_admin());
create policy "teachers create tasks" on public.tasks for insert to authenticated with check (created_by=auth.uid() and public.is_class_teacher(class_id));
create policy "teachers modify class tasks" on public.tasks for update to authenticated using (public.is_class_teacher(class_id) or public.is_admin()) with check ((created_by=auth.uid() and public.is_class_teacher(class_id)) or public.is_admin());
create policy "teachers delete class tasks" on public.tasks for delete to authenticated using (public.is_class_teacher(class_id) or public.is_admin());
create policy "students read own progress" on public.task_progress for select to authenticated using (student_id=auth.uid());
create policy "students create own accessible progress" on public.task_progress for insert to authenticated with check (student_id=auth.uid() and public.can_access_task(task_id));
create policy "students update own accessible progress" on public.task_progress for update to authenticated using (student_id=auth.uid()) with check (student_id=auth.uid() and public.can_access_task(task_id));
create policy "students delete own progress" on public.task_progress for delete to authenticated using (student_id=auth.uid());
create policy "students or assigned teachers read help" on public.help_requests for select to authenticated using (student_id=auth.uid() or public.can_teach_help(id) or public.is_admin());
create policy "students create own accessible help" on public.help_requests for insert to authenticated with check (student_id=auth.uid() and (task_id is null or public.can_access_task(task_id)) and (lesson_id is null or public.can_access_lesson(lesson_id)));
create policy "teachers manage visible help" on public.help_requests for update to authenticated using (public.can_teach_help(id) or public.is_admin()) with check ((assigned_teacher_id=auth.uid() and public.can_teach_help(id)) or public.is_admin());

-- Administradores confiáveis: no Dashboard/Auth do Supabase, defina app_metadata.ponte_admin=true para um usuário.
-- Depois, altere profiles.role='teacher' e crie class_members.member_role='teacher' pelo SQL Editor ou processo administrativo seguro.
-- RLS é a proteção real: esconder botões no navegador não concede acesso.
