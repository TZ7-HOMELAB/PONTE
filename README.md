# PONTE

> Uma ausência não precisa virar atraso.

A PONTE é uma plataforma estática para estudantes do ensino médio organizarem conteúdos e atividades perdidos. Ela usa HTML, CSS e JavaScript puro no navegador e Supabase para autenticação, banco PostgreSQL e políticas de segurança.

## Arquitetura

- `index.html`, `login.html` e `cadastro.html`: entrada e autenticação.
- `dashboard.html`: resumo e registro pessoal de ausência. Isso não substitui o sistema oficial da escola.
- `conteudos.html`, `plano.html` e `progresso.html`: recuperação do estudante.
- `professor.html`: publicação de conteúdos e atividades para turmas autorizadas.
- `sql/schema.sql`: banco, índices, gatilhos e RLS.
- `sql/demo-data.sql`: dados fictícios opcionais, próprios para um projeto de teste.

O plano de recuperação ordena tarefas pendentes por prioridade, prazo e data de criação. Ele as separa em dias conforme os minutos informados. É uma organização de estudos, não uma promessa de recuperação de notas.

## Configuração local

1. Crie um projeto no Supabase.
2. No SQL Editor, execute `sql/schema.sql` por inteiro.
3. Copie `js/config.example.js` para `js/config.js`.
4. No arquivo novo, preencha `SUPABASE_URL` e `SUPABASE_PUBLISHABLE_KEY` usando **Project URL** e a chave publicável (ou anon legada) em **Settings > API**.
5. Abra `index.html` por um servidor estático. Para desenvolvimento, a extensão Live Server do editor é suficiente; o site não precisa de Node.js em produção.

`config.js` está no `.gitignore`. Não publique `service_role`, senhas ou chaves administrativas.

## Autenticação e professores

Ative Email/Password em **Authentication > Providers**. Em **Authentication > URL Configuration**, cadastre:

- Site URL: `https://TZ7-HOMELAB.github.io/PONTE/`
- Redirect URLs: `https://TZ7-HOMELAB.github.io/PONTE/login.html` e a URL local de desenvolvimento usada por você.

Todo cadastro público cria um perfil `student`. Para autorizar um professor, uma pessoa administradora deve definir `app_metadata.ponte_admin=true` para uma conta confiável, depois atualizar `profiles.role` para `teacher` e inseri-la em `class_members` com `member_role='teacher'`. Nunca conceda esse papel com `user_metadata` ou por um campo do formulário público.

## Dados demonstrativos

Cadastre contas fictícias de professor e estudante no Supabase Auth. Troque os dois UUIDs no começo de `sql/demo-data.sql` pelos IDs dessas contas e execute o script em um projeto de demonstração. Ele não cria usuários ou usa dados reais.

## Publicação no GitHub Pages

1. Envie os arquivos ao repositório.
2. Em **Settings > Pages**, selecione **Deploy from a branch**, a branch `main` e a pasta `/(root)`.
3. Aguarde a URL HTTPS ficar disponível.
4. Atualize as URLs permitidas do Supabase conforme a seção anterior.
5. Mantenha links relativos (`./arquivo.html`), como já estão no projeto, para funcionar dentro de `/PONTE/`.

Após alterar arquivos, faça commit e push; o Pages republicará automaticamente. Use o Console do navegador para investigar falhas de rede ou configuração.

## Checklist manual

- [ ] Criar uma conta de estudante; verificar confirmação por e-mail quando habilitada.
- [ ] Entrar, sair e abrir uma página protegida sem sessão.
- [ ] Registrar uma ausência e verificar que ela aparece apenas para a própria conta no banco.
- [ ] Ver conteúdos da turma e testar filtros.
- [ ] Alterar os minutos/dia e conferir a nova organização do plano.
- [ ] Concluir uma atividade e conferir o progresso.
- [ ] Enviar uma dúvida e verificar que outro estudante não consegue lê-la.
- [ ] Testar conta de professor autorizada e outra não autorizada.
- [ ] Tentar ler ou alterar dados de outro estudante pelo painel/API: RLS deve negar.
- [ ] Tentar alterar o papel pelo cliente: o gatilho deve negar.
- [ ] Testar campos inválidos, ausência de internet e configuração sem `config.js`.
- [ ] Testar em celular, tablet e desktop, teclado e preferência de movimento reduzido.

## Demonstração para jurados

1. Entre com a conta fictícia de estudante e mostre o painel.
2. Registre uma ausência e abra a Central de conteúdos.
3. Defina o tempo disponível e mostre o plano criado.
4. Conclua uma atividade, veja o percentual crescer e envie uma dúvida.
5. Entre como professor autorizado e publique uma atividade.

Melhorias futuras: notificações opt-in, calendário escolar, anexos com Storage e relatórios agregados com proteção reforçada de privacidade.
