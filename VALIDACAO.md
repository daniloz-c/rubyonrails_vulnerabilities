# Roteiro de validação de vulnerabilidades

Este documento descreve testes manuais reproduzíveis para o laboratório Ruby on Rails: **XSS refletido, XSS armazenado, SQL Injection e CSRF**.

> Execute somente neste projeto, em ambiente próprio/autorizado e com dados fictícios. Não exponha os servidores à rede. Este roteiro foi elaborado a partir do código; os resultados abaixo são os resultados esperados, não um registro de testes já executados.

## 1. Preparação

Na raiz do projeto:

```bash
bundle install
bin/rails db:prepare
bin/rails server -b 127.0.0.1
```

Acesse <http://127.0.0.1:3000>.

Na primeira preparação do banco, os seeds criam os usuários `alice`, `bob` e `carol`, além de uma conta com 100 créditos fictícios. Em um banco já utilizado, os dados e o saldo podem ser diferentes.

### Como registrar evidências

Para cada teste, registre:

- Data, navegador e versão/commit do projeto.
- URL, método HTTP e entrada utilizada.
- Estado anterior e posterior, quando houver alteração de dados.
- Captura de tela e requisição/resposta no DevTools → Network.
- Resultado observado: confirmado, não reproduzido ou inconclusivo.
- Resultado do controle seguro, quando disponível.

Os testes de XSS armazenado criam comentários persistentes. Os testes de CSRF reduzem o saldo. Use apenas o banco de laboratório.

## 2. XSS refletido

### Objetivo

Confirmar que uma entrada enviada na requisição é inserida na resposta como HTML e permite execução de JavaScript.

### Ponto vulnerável

- Rota: `POST /xss/reflected`.
- Entrada: parâmetro `message`.
- Controlador: `app/controllers/xss_controller.rb`, ação `reflected`.
- Template: `app/views/xss/reflected.html.erb`.

```erb
<%= raw(@message) %>
```

### Procedimento

1. Abra <http://127.0.0.1:3000/xss>.
2. No formulário **XSS refletido**, preencha a mensagem com:

   ```html
   <script>alert('XSS refletido - laboratório')</script>
   ```

3. Clique em **Enviar**.
4. Observe o navegador e a resposta de `POST /xss/reflected` no DevTools.

### Resultado esperado e critério de confirmação

O navegador apresenta um alerta com a mensagem `XSS refletido - laboratório`. A resposta HTML contém o script sem escape.

A execução do alerta confirma XSS. Apenas renderizar uma tag como `<b>teste</b>` comprova injeção de HTML, mas não comprova execução de JavaScript.

### Controle seguro

O projeto não possui uma rota equivalente de reflexão segura. O escape padrão pode ser comparado na página `/secure`, usando o teste de comentários da próxima seção.

## 3. XSS armazenado

### Objetivo

Confirmar que uma entrada persistida no banco executa JavaScript quando o comentário é exibido posteriormente.

### Ponto vulnerável

- Gravação: `POST /xss/comments`, parâmetro `body`.
- Exibição: `GET /xss`.
- Controlador: `app/controllers/xss_controller.rb`.
- Template: `app/views/xss/index.html.erb`.

```erb
<%= raw(comment.body) %>
```

### Procedimento

1. Abra <http://127.0.0.1:3000/xss>.
2. No campo **Comentário**, insira:

   ```html
   <script>alert('XSS armazenado - laboratório')</script>
   ```

3. Clique em **Salvar comentário**.
4. Feche o alerta, se exibido.
5. Acesse `/xss` novamente, sem reenviar o formulário.

### Resultado esperado e critério de confirmação

O alerta aparece após o salvamento e volta a aparecer ao visitar `/xss`. A execução em uma nova visita confirma que o conteúdo foi persistido e executado na exibição.

### Controle seguro

1. Acesse <http://127.0.0.1:3000/secure>.
2. Localize o mesmo comentário.
3. Confirme que o payload aparece como texto e não executa JavaScript.

O template `app/views/secure/index.html.erb` usa o escape padrão do Rails:

```erb
<%= comment.body %>
```

**Importante:** `/xss` e `/secure` exibem comentários da mesma tabela. Um comentário salvo pelo formulário seguro também pode executar ao ser exibido em `/xss`. Neste exemplo, a proteção está na saída escapada, não na remoção do conteúdo ao salvar.

## 4. SQL Injection

### Objetivo

Confirmar que a entrada do usuário altera a lógica da consulta SQL, em vez de ser tratada apenas como dado.

### Ponto vulnerável

- Rota: `GET /sqli/search`.
- Entrada: parâmetro `q`.
- Arquivo: `app/controllers/sqli_controller.rb`, ação `search`.

```ruby
@sql_preview = "SELECT id, username, role FROM lab_users WHERE username = '#{term}'"
@users = LabUser.find_by_sql(@sql_preview)
```

### Procedimento

#### A. Busca normal de referência

Acesse:

```text
http://127.0.0.1:3000/sqli/search?q=alice
```

**Esperado:** somente o usuário `alice`, se os seeds estiverem presentes.

#### B. Entrada que modifica a condição

No formulário de `/sqli`, pesquise por:

```sql
' OR 1=1 -- 
```

Alternativamente, execute:

```bash
curl -G 'http://127.0.0.1:3000/sqli/search' \
  --data-urlencode "q=' OR 1=1 -- "
```

A consulta resultante fica equivalente a:

```sql
SELECT id, username, role
FROM lab_users
WHERE username = '' OR 1=1 -- '
```

### Resultado esperado e critério de confirmação

A resposta lista todos os usuários existentes, inicialmente `alice`, `bob` e `carol`, em vez de procurar apenas um nome literal. Isso confirma a alteração da lógica SQL.

Um erro de SQL isolado não é suficiente para confirmar esse resultado: registre os usuários retornados e compare com a busca normal.

### Controle seguro

Envie o mesmo payload à rota parametrizada:

```bash
curl -G 'http://127.0.0.1:3000/secure/users' \
  --data-urlencode "q=' OR 1=1 -- "
```

**Esperado:** nenhum usuário, desde que não exista um usuário com esse nome literal. A busca normal por `alice` deve continuar retornando `alice`:

```bash
curl -G 'http://127.0.0.1:3000/secure/users' \
  --data-urlencode 'q=alice'
```

A implementação em `app/controllers/secure_controller.rb` separa os dados da estrutura da consulta:

```ruby
@users = LabUser.where("username = ?", term)
```

## 5. CSRF e alteração de estado sem token

### Objetivo

Verificar que o endpoint aceita uma alteração de estado sem token de autenticidade e permite submissão de formulário a partir de outra origem.

### Ponto vulnerável

- Rota: `POST /csrf/transfer`.
- Entrada: parâmetro `amount`.
- Arquivo: `app/controllers/csrf_controller.rb`.

```ruby
skip_forgery_protection
```

### Limitação da demonstração

O projeto não implementa login nem associa a conta a uma sessão de usuário. O endpoint modifica a primeira conta do banco, inclusive em requisições sem autenticação.

Assim, os testes demonstram **ausência de validação de token e alteração de estado aceita de outra origem**, mas não reproduzem integralmente um CSRF contra uma vítima autenticada. A alteração sem autenticação é uma limitação adicional deste laboratório.

### A. Validar uma requisição sem token

1. Abra <http://127.0.0.1:3000/csrf> e registre o saldo.
2. Garanta que há pelo menos 10 créditos fictícios.
3. Execute:

   ```bash
   curl -i 'http://127.0.0.1:3000/csrf/transfer' \
     --data-urlencode 'amount=10'
   ```

4. Atualize `/csrf` e registre o novo saldo.

**Esperado:** o saldo diminui em 10, sem envio de token de autenticidade. O redirecionamento HTTP, sozinho, não prova a alteração: confira o saldo.

### B. Validar submissão pelo navegador de outra origem

Em uma pasta separada da aplicação, crie um arquivo `csrf-poc.html`:

```html
<!doctype html>
<html lang="pt-BR">
  <meta charset="utf-8">
  <title>PoC local de CSRF</title>

  <form action="http://127.0.0.1:3000/csrf/transfer" method="post">
    <input type="hidden" name="amount" value="10">
    <button type="submit">Executar teste local de CSRF</button>
  </form>
</html>
```

Nessa pasta, execute em outro terminal:

```bash
python3 -m http.server 8000 --bind 127.0.0.1
```

1. Registre o saldo antes do teste e garanta que há pelo menos 10 créditos.
2. Abra <http://127.0.0.1:8000/csrf-poc.html>.
3. Abra o DevTools → Network e habilite a preservação do log, se necessário.
4. Clique em **Executar teste local de CSRF**.
5. Confira a requisição e o saldo em `/csrf`.

**Esperado:** a submissão é aceita e o saldo diminui em 10. A requisição não contém `authenticity_token` e parte da origem `http://127.0.0.1:8000` para `http://127.0.0.1:3000`.

**Nota:** portas diferentes representam origens diferentes (*cross-origin*), mas não necessariamente sites diferentes (*cross-site*). Este teste não avalia o comportamento de cookies `SameSite` em um cenário autenticado real. CORS não impede, por si só, a submissão desse formulário HTML.

### Controle com proteção CSRF padrão

Não existe uma transferência segura equivalente no projeto. Como comparação da proteção padrão do Rails, tente enviar um comentário à rota segura sem token:

```bash
curl -i 'http://127.0.0.1:3000/secure/comments' \
  --data-urlencode 'body=teste sem token'
```

**Esperado:** rejeição por falha na verificação de autenticidade, normalmente HTTP `422` em desenvolvimento. Confira também que o comentário não foi criado.

Esse controle compara a validação do token; não representa uma implementação completa de transferência segura.

## 6. Matriz de validação

Preencha a coluna final após executar os testes.

| ID | Teste | Resultado vulnerável esperado | Controle esperado | Resultado observado |
|---|---|---|---|---|
| XSS-01 | XSS refletido | Alerta executa ao enviar a mensagem | Sem rota refletida segura equivalente | A preencher |
| XSS-02 | XSS armazenado | Alerta executa novamente ao visitar `/xss` | `/secure` mostra o payload como texto | A preencher |
| SQLI-01 | Busca com condição sempre verdadeira | Todos os usuários são retornados | `/secure/users` trata o payload como dado | A preencher |
| CSRF-01 | POST sem token | Saldo diminui | POST sem token em `/secure/comments` é rejeitado | A preencher |
| CSRF-02 | Formulário de outra origem | Saldo diminui após submissão | Sem transferência segura equivalente | A preencher |

### Modelo de registro individual

```text
ID do teste:
Data e ambiente:
Commit/versão:
URL e método:
Entrada utilizada:
Estado anterior:
Resultado esperado:
Resultado observado:
Estado posterior:
Evidências (captura/requisição/resposta):
Controle seguro observado:
Conclusão: confirmado / não reproduzido / inconclusivo
Limitações:
```

## 7. Limpeza e encerramento

Depois de registrar as evidências, remova apenas o comentário criado com o payload deste roteiro:

```bash
bin/rails runner "Comment.where(body: %q{<script>alert('XSS armazenado - laboratório')</script>}).destroy_all"
```

O comando remove todos os comentários que correspondam exatamente a esse payload. Caso tenha usado outro conteúdo, adapte a seleção com cuidado. Não é necessário apagar o banco inteiro.

Se precisar repetir o teste de débito, restaure o saldo **somente no banco fictício do laboratório**:

```bash
bin/rails runner 'LabAccount.first&.update!(balance: 100)'
```

Esse comando altera o saldo existente; registre as evidências antes de executá-lo.

Encerre o servidor Rails e o servidor Python com `Ctrl+C`. Remova o arquivo `csrf-poc.html` da pasta separada quando não for mais necessário.

## 8. Correções de referência

- **XSS:** manter o escape padrão do Rails. Não usar `raw` ou `html_safe` em entrada não confiável. Quando HTML for necessário, aplicar sanitização apropriada com lista de permissões.
- **SQL Injection:** utilizar consultas parametrizadas ou APIs do Active Record, sem interpolar entrada na estrutura SQL.
- **CSRF:** manter a proteção de autenticidade do Rails e incluir tokens nos formulários que alteram estado. Em aplicações reais, implementar também autenticação, autorização e controles de sessão adequados; cookies `SameSite` são defesa adicional, não substituto universal da proteção CSRF.

Os testes acima validam as falhas didáticas apresentadas no projeto. Eles não constituem uma auditoria completa de dependências, configuração ou segurança da aplicação.
