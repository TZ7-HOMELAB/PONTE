-- Dados fictícios: execute somente em um projeto de demonstração, nunca misture com dados reais.
-- Antes, crie um professor e um estudante pelo Auth e troque os UUIDs abaixo.
do $$ declare teacher_id uuid := '00000000-0000-0000-0000-000000000001'; student_id uuid := '00000000-0000-0000-0000-000000000002'; class_id uuid := gen_random_uuid(); math_id uuid; portuguese_id uuid; biology_id uuid; lesson_math uuid; begin
  if not exists (select 1 from public.profiles where id=teacher_id) or not exists (select 1 from public.profiles where id=student_id) then raise notice 'Dados de demonstração não inseridos: substitua teacher_id e student_id por usuários de teste reais.'; return; end if;
  insert into public.classes(id,name,school_year) values (class_id,'2º Ano A — Demonstração',2);
  insert into public.subjects(name) values ('Matemática'),('Português'),('Biologia') on conflict(name) do nothing;
  select id into math_id from public.subjects where name='Matemática'; select id into portuguese_id from public.subjects where name='Português'; select id into biology_id from public.subjects where name='Biologia';
  update public.profiles set role='teacher' where id=teacher_id; insert into public.class_members(class_id,user_id,member_role) values (class_id,teacher_id,'teacher'),(class_id,student_id,'student');
  insert into public.lessons(class_id,subject_id,lesson_date,title,summary,material_text,teacher_id) values (class_id,math_id,current_date-10,'Funções do 1º grau','Revisão de gráficos e coeficientes.','Leia o resumo e resolva os exemplos.',teacher_id) returning id into lesson_math;
  insert into public.lessons(class_id,subject_id,lesson_date,title,summary,material_text,teacher_id) values (class_id,portuguese_id,current_date-8,'Leitura e argumentação','Como reconhecer uma tese e seus argumentos.','Revise as anotações de aula.',teacher_id),(class_id,biology_id,current_date-5,'Ecologia e cadeias alimentares','Relações entre seres vivos e ambiente.','Monte um mapa mental.',teacher_id);
  insert into public.tasks(class_id,subject_id,lesson_id,title,description,due_date,estimated_minutes,priority,created_by) values (class_id,math_id,lesson_math,'Lista de funções','Resolver exercícios 1 a 6.',current_date+2,45,'high',teacher_id),(class_id,portuguese_id,null, 'Rascunho de texto','Escrever um parágrafo argumentativo.',current_date+4,35,'high',teacher_id),(class_id,biology_id,null, 'Mapa mental de ecologia','Organizar conceitos principais.',current_date+5,30,'medium',teacher_id),(class_id,math_id,null, 'Revisar exemplos','Refazer dois exemplos vistos em aula.',current_date+7,20,'low',teacher_id),(class_id,biology_id,null, 'Questionário de biologia','Responder ao questionário de revisão.',current_date+8,40,'medium',teacher_id);
  insert into public.task_progress(student_id,task_id,status,completed_at)
  select student_id,id,'completed',now() from public.tasks where created_by=teacher_id and title in ('Revisar exemplos','Mapa mental de ecologia');
  insert into public.help_requests(student_id,task_id,description,status)
  select student_id,id,'Não entendi como encontrar o coeficiente no gráfico.','open' from public.tasks where created_by=teacher_id and title='Lista de funções';
  insert into public.help_requests(student_id,task_id,description,status)
  select student_id,id,'Posso conferir se meu parágrafo tem uma tese clara?','in_progress' from public.tasks where created_by=teacher_id and title='Rascunho de texto';end $$;



