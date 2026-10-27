-- PONTE — DADOS COMPLETOS DE DEMONSTRAÇÃO
-- Execute depois de sql/schema.sql, no SQL Editor do Supabase.
-- Antes de executar, crie uma conta pelo site usando o e-mail abaixo.
-- Este script não cria usuários, não cria senhas e não usa dados reais.
-- Para uma apresentação rápida, a mesma conta recebe acesso às áreas de estudante e professor.

do $$
declare
  demo_email text := 'terra.009362@gmail.com'; -- altere se usar outra conta de teste
  demo_user_id uuid;
  demo_class_id uuid;
  math_id uuid;
  portuguese_id uuid;
  biology_id uuid;
  functions_lesson_id uuid;
  reading_lesson_id uuid;
  ecology_lesson_id uuid;
  task_functions_id uuid;
  task_text_id uuid;
  task_ecology_id uuid;
  task_revision_id uuid;
  task_quiz_id uuid;
begin
  select id into demo_user_id from public.profiles where lower((select email from auth.users where id = profiles.id)) = lower(demo_email) limit 1;
  if demo_user_id is null then
    raise exception 'Nenhuma conta foi encontrada para %. Crie a conta no site, confirme o e-mail se necessário, faça login uma vez e execute novamente.', demo_email;
  end if;

  -- Conta demonstrativa autorizada como professora e incluída na turma de exemplo.
  update public.profiles set full_name = coalesce(nullif(full_name, ''), 'Conta de Demonstração'), role = 'teacher' where id = demo_user_id;

  insert into public.classes (name, school_year)
  values ('2º Ano A — Turma Demonstração', 2)
  on conflict (name) do update set school_year = excluded.school_year
  returning id into demo_class_id;

  insert into public.class_members (class_id, user_id, member_role)
  values (demo_class_id, demo_user_id, 'teacher')
  on conflict (class_id, user_id) do update set member_role = 'teacher';

  insert into public.subjects (name) values ('Matemática'), ('Português'), ('Biologia')
  on conflict (name) do nothing;
  select id into math_id from public.subjects where name = 'Matemática';
  select id into portuguese_id from public.subjects where name = 'Português';
  select id into biology_id from public.subjects where name = 'Biologia';

  insert into public.lessons (class_id, subject_id, lesson_date, title, summary, material_text, material_url, teacher_id)
  select demo_class_id, math_id, current_date - 10, 'Funções do 1º grau', 'Revisão de gráficos, coeficientes e resolução de problemas.', 'Leia o resumo, reveja os exemplos e resolva os exercícios propostos.', 'https://pt.khanacademy.org/math/algebra/x2f8bb11595b61c86:linear-equations-and-inequalities', demo_user_id
  where not exists (select 1 from public.lessons where class_id = demo_class_id and title = 'Funções do 1º grau');
  insert into public.lessons (class_id, subject_id, lesson_date, title, summary, material_text, teacher_id)
  select demo_class_id, portuguese_id, current_date - 8, 'Leitura e argumentação', 'Como reconhecer uma tese, argumentos e evidências em um texto.', 'Leia o texto-base e escreva uma ideia principal em suas palavras.', demo_user_id
  where not exists (select 1 from public.lessons where class_id = demo_class_id and title = 'Leitura e argumentação');
  insert into public.lessons (class_id, subject_id, lesson_date, title, summary, material_text, teacher_id)
  select demo_class_id, biology_id, current_date - 5, 'Ecologia e cadeias alimentares', 'Relações entre seres vivos, ambiente e fluxo de energia.', 'Monte um mapa mental com produtores, consumidores e decompositores.', demo_user_id
  where not exists (select 1 from public.lessons where class_id = demo_class_id and title = 'Ecologia e cadeias alimentares');

  select id into functions_lesson_id from public.lessons where class_id = demo_class_id and title = 'Funções do 1º grau';
  select id into reading_lesson_id from public.lessons where class_id = demo_class_id and title = 'Leitura e argumentação';
  select id into ecology_lesson_id from public.lessons where class_id = demo_class_id and title = 'Ecologia e cadeias alimentares';

  insert into public.tasks (lesson_id, class_id, subject_id, title, description, due_date, estimated_minutes, priority, created_by)
  select functions_lesson_id, demo_class_id, math_id, 'Lista de funções', 'Resolver os exercícios 1 a 6 e conferir os gráficos.', current_date + 2, 45, 'high', demo_user_id
  where not exists (select 1 from public.tasks where class_id = demo_class_id and title = 'Lista de funções');
  insert into public.tasks (lesson_id, class_id, subject_id, title, description, due_date, estimated_minutes, priority, created_by)
  select reading_lesson_id, demo_class_id, portuguese_id, 'Rascunho de texto', 'Escrever um parágrafo argumentativo com tese e pelo menos um argumento.', current_date + 4, 35, 'high', demo_user_id
  where not exists (select 1 from public.tasks where class_id = demo_class_id and title = 'Rascunho de texto');
  insert into public.tasks (lesson_id, class_id, subject_id, title, description, due_date, estimated_minutes, priority, created_by)
  select ecology_lesson_id, demo_class_id, biology_id, 'Mapa mental de ecologia', 'Organizar os conceitos principais em um mapa mental simples.', current_date + 5, 30, 'medium', demo_user_id
  where not exists (select 1 from public.tasks where class_id = demo_class_id and title = 'Mapa mental de ecologia');
  insert into public.tasks (class_id, subject_id, title, description, due_date, estimated_minutes, priority, created_by)
  select demo_class_id, math_id, 'Revisar exemplos', 'Refazer dois exemplos resolvidos durante a aula.', current_date + 7, 20, 'low', demo_user_id
  where not exists (select 1 from public.tasks where class_id = demo_class_id and title = 'Revisar exemplos');
  insert into public.tasks (class_id, subject_id, title, description, due_date, estimated_minutes, priority, created_by)
  select demo_class_id, biology_id, 'Questionário de biologia', 'Responder ao questionário curto de revisão.', current_date + 8, 40, 'medium', demo_user_id
  where not exists (select 1 from public.tasks where class_id = demo_class_id and title = 'Questionário de biologia');

  select id into task_functions_id from public.tasks where class_id = demo_class_id and title = 'Lista de funções';
  select id into task_text_id from public.tasks where class_id = demo_class_id and title = 'Rascunho de texto';
  select id into task_ecology_id from public.tasks where class_id = demo_class_id and title = 'Mapa mental de ecologia';
  select id into task_revision_id from public.tasks where class_id = demo_class_id and title = 'Revisar exemplos';
  select id into task_quiz_id from public.tasks where class_id = demo_class_id and title = 'Questionário de biologia';

  insert into public.task_progress (student_id, task_id, status, completed_at, needs_help)
  values
    (demo_user_id, task_ecology_id, 'completed', now() - interval '1 day', false),
    (demo_user_id, task_revision_id, 'completed', now() - interval '2 days', false),
    (demo_user_id, task_functions_id, 'in_progress', null, true),
    (demo_user_id, task_text_id, 'pending', null, false),
    (demo_user_id, task_quiz_id, 'pending', null, false)
  on conflict (student_id, task_id) do update set status = excluded.status, completed_at = excluded.completed_at, needs_help = excluded.needs_help;

  insert into public.help_requests (student_id, task_id, lesson_id, description, status, assigned_teacher_id)
  select demo_user_id, task_functions_id, functions_lesson_id, 'Não entendi como encontrar o coeficiente da reta no gráfico.', 'open', null
  where not exists (select 1 from public.help_requests where student_id = demo_user_id and task_id = task_functions_id);
  insert into public.help_requests (student_id, task_id, lesson_id, description, status, assigned_teacher_id)
  select demo_user_id, task_text_id, reading_lesson_id, 'Posso conferir se meu parágrafo apresenta uma tese clara?', 'in_progress', demo_user_id
  where not exists (select 1 from public.help_requests where student_id = demo_user_id and task_id = task_text_id);

  insert into public.absences (student_id, absence_date, reason)
  values (demo_user_id, current_date - 9, 'Registro de demonstração para organizar conteúdos pendentes.')
  on conflict (student_id, absence_date) do update set reason = excluded.reason;

  raise notice 'Dados de demonstração criados para %.', demo_email;
end $$;
