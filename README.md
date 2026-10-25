# Security PoC Lab — Ruby on Rails

Aplicação **intencionalmente vulnerável**, isolada para estudo local de XSS, CSRF e SQL Injection. Use somente em ambiente próprio/autorizado.

## Requisitos
- Ruby compatível com Rails 7.1 (Ruby 3.2+ recomendado)
- Bundler
- SQLite3

## Instalar dependências (Linux Mint 22 / Ubuntu 24.04)
```bash
sudo apt update
sudo apt install -y ruby-full ruby-dev ruby-bundler sqlite3 libsqlite3-dev build-essential libyaml-dev libssl-dev zlib1g-dev libreadline-dev pkg-config
```

## Executar
```bash
bundle config set --local path vendor/bundle
bundle install
bin/rails db:prepare
bin/rails server -b 127.0.0.1
```

As gems são instaladas em `vendor/bundle`, sem precisar de `sudo`. O comando
`db:prepare` cria o banco SQLite e, na primeira execução, carrega os usuários
fictícios `alice`, `bob` e `carol`, além da conta de demonstração.

Para verificar o carregamento das classes: `bin/rails zeitwerk:check`.
Acesse http://127.0.0.1:3000. O binding em `127.0.0.1` evita expor o laboratório à rede.

## Rotas
- `/` — índice do laboratório
- `/xss` — demonstração de XSS refletido e armazenado
- `/csrf` — demonstração didática de formulário de alteração de estado sem proteção CSRF
- `/sqli` — demonstração de SQL injection em consulta de usuários
- `/secure` — exemplos corrigidos para comparação

## Avisos de segurança
- Não faça deploy desta aplicação na internet, em VPS pública ou em ambiente corporativo.
- Não use dados reais, credenciais reais ou segredos.
- O laboratório é intencionalmente inseguro. O Rails CSRF forgery protection é desabilitado **somente no controlador didático `CsrfController`**.
- Para XSS, o laboratório renderiza texto não confiável como HTML apenas na rota vulnerável.
- Para SQLi, o laboratório usa interpolação SQL em uma consulta didática. A rota segura usa parâmetros.
- Ao terminar, pare o servidor com Ctrl+C.

## Estrutura
- `app/controllers/` — endpoints da PoC
- `app/views/` — telas didáticas
- `app/models/` — modelos SQLite
- `db/migrate/` — schema
