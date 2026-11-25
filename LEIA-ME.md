# Inventário Suporte Técnico — portal

Portal para buscar onde cada item está (porta, caixa, código), cadastrar, editar, emprestar, devolver, dar baixa e contar o inventário da sala 1106.

- **Página:** arquivo estático (`index.html`), publicado no GitHub Pages.
- **Dados:** banco Supabase (gratuito), com login por link no e-mail.
- **Acesso:** só entra quem estiver na tabela `membros`. O repositório não contém nenhum dado do inventário.

## Montar do zero (uma vez só, ~20 min)

### 1. Criar o banco no Supabase
1. Crie uma conta em <https://supabase.com> e clique em **New project**. Escolha um nome (ex.: `inventario-suporte`), uma senha para o banco e a região **South America (São Paulo)**.
2. No projeto, abra **SQL Editor › New query**, cole todo o conteúdo de [`supabase/schema.sql`](supabase/schema.sql) e clique em **Run**.
3. Abra outra query, cole o arquivo de importação `importacao-supabase.sql` e clique em **Run**. Esse arquivo fica na pasta `portal` do OneDrive e **não vai para o GitHub**, porque contém os dados. Ele carrega os 1.005 itens.
4. Libere os e-mails da equipe (rode no SQL Editor, trocando pelos e-mails reais):
   ```sql
   insert into membros (email, nome) values
     ('fulano@empresa.com.br', 'Fulano'),
     ('ciclano@empresa.com.br', 'Ciclano');
   -- Alguém só pode consultar? use pode_editar = false:
   insert into membros (email, nome, pode_editar) values ('visitante@empresa.com.br', 'Visitante', false);
   ```

### 2. Publicar a página no GitHub Pages
1. Crie uma conta em <https://github.com> e um repositório novo **público** (ex.: `inventario-suporte`), sem README.
2. Envie esta pasta para o repositório (comandos no final deste arquivo), ou use **Add file › Upload files** e arraste `index.html`, `config.js`, `LEIA-ME.md` e a pasta `supabase`.
3. No repositório: **Settings › Pages › Build and deployment › Source: Deploy from a branch**, branch `main`, pasta `/ (root)`, **Save**.
4. Em 1–2 minutos o endereço aparece no topo dessa tela, algo como `https://SEU-USUARIO.github.io/inventario-suporte/`.

### 3. Ligar a página ao banco
1. No Supabase, em **Project Settings › API**, copie a **Project URL** e a chave **anon public**.
2. Cole as duas no `config.js` (no GitHub dá para editar pelo ícone de lápis) e salve (commit).
3. No Supabase, em **Authentication › URL Configuration**:
   - **Site URL:** o endereço do GitHub Pages (ex.: `https://SEU-USUARIO.github.io/inventario-suporte/`)
   - **Redirect URLs:** adicione o mesmo endereço.

Pronto: abra o endereço, digite seu e-mail, clique no link que chega e o inventário carrega.

## Uso do dia a dia
- **Quem entra:** só e-mails da tabela `membros` (Supabase › Table Editor › membros). Para tirar alguém, apague a linha.
- **E-mails de login:** o Supabase gratuito envia poucos e-mails por hora (cerca de 3–4). Cada pessoa só precisa entrar uma vez por navegador: o login fica salvo. Se a equipe for grande, configure um SMTP próprio em **Authentication › Emails › SMTP Settings** (ex.: o e-mail da empresa).
- **Backup:** aba Contagem › **Exportar planilha (CSV)**, ou Supabase › Table Editor › itens › Export.
- **Projeto pausado:** no plano gratuito, o Supabase pausa o projeto depois de 7 dias sem nenhum acesso. Basta entrar no painel do Supabase e clicar em **Restore**; nada se perde.

## Enviar a pasta pelo Git (opcional)
Dentro desta pasta, depois de criar o repositório vazio no GitHub:
```bash
git remote add origin https://github.com/SEU-USUARIO/inventario-suporte.git
git push -u origin main
```
