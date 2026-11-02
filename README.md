# Telecom ISP - Ordens de Serviço Offline-First

Aplicativo Android em Flutter para técnicos de telecomunicações, desenvolvido com
MVVM, SQLite, GPS, câmera, autenticação HMAC-SHA256 e sincronização com a API
oficial do SENAI.

## Funcionalidades

- Splash com recuperação do token em `flutter_secure_storage`.
- Login institucional com assinatura HMAC-SHA256 local.
- Carga dos chamados ativos em SQLite e consulta no modo avião.
- Home com `ListView.builder`, cards completos e ordenação por distância GPS.
- Atendimento com categoria, descrição (mínimo 10 caracteres), data e foto.
- Conclusão em transação SQLite, com status local `atendido` e pendência.
- Sincronização manual de atendimentos em `POST /api/atendimento` multipart.
- Histórico local/remoto com pesquisa por ID ou código e fotos locais/remotas.
- Testes unitários de modelos, API, repositórios, SQLite e duas telas.

## Arquitetura

```text
lib/
  data/
    models/
    datasources/         # SQLite, API HTTP e token seguro
    repositories/         # Coordena dados locais e remotos
  services/               # GPS e armazenamento de fotos
  viewModel/              # ChangeNotifier e regras de apresentação
  view/                   # Splash, Login, Home, Atendimento, Histórico
  main.dart
test/                     # Unitários e widget tests
assets/images/logo.png
```

Fluxo offline-first: tela -> ViewModel -> Repository -> SQLite.
O repositório consulta a API quando há rede e atualiza o SQLite, mas a tela
consegue usar o banco local sem conexão. Atendimentos são gravados primeiro no
SQLite e só depois enviados ao servidor.

## Instalação no projeto Flutter que já existe

**Este ZIP contém os arquivos de aplicação e não as pastas `android/`, `ios/`
ou o restante do projeto Flutter.** Utilize sua pasta original, aquela que
contém `pubspec.yaml`, `android/` e `lib/`.

1. Faça uma cópia de segurança do projeto inteiro.
2. Pare o aplicativo no VS Code (não faça apenas Hot Restart).
3. Renomeie a pasta antiga `lib` para `lib_backup` na sua cópia.
4. Extraia deste ZIP a nova pasta `lib` dentro da pasta principal correta.
5. Copie `test/`, `assets/`, `pubspec.yaml` e `README.md` para a mesma raiz.
6. Aplique as permissões indicadas em `CONFIGURAR_ANDROID.md`.
7. No terminal do VS Code, nessa mesma pasta, execute:

```bash
flutter clean
flutter pub get
flutter analyze
flutter test
flutter run
```

Confira que `lib/data/datasources/remote_datasource.dart` contém a URL HTTPS
oficial e o campo `senha_hmac`. Se a tela ou o terminal ainda mencionar
`10.0.2.2:8000`, o VS Code está executando a pasta antiga.

No Windows, execute `./VERIFICAR_INSTALACAO.ps1` no PowerShell para verificar
automaticamente se o projeto contém a URL correta. Se o PowerShell bloquear
scripts, faça a conferência manual em vez de alterar a política do sistema.

## Como demonstrar

1. Com internet, entre usando as credenciais individuais fornecidas pelo professor.
2. Aguarde carregar os chamados e confira o SQLite.
3. Ative o modo avião, atualize a Home e abra um chamado.
4. Preencha categoria, descrição e foto; finalize offline.
5. Confira no Histórico o badge **Pendente de envio**.
6. Desative o modo avião e toque no botão de sincronização do Histórico.
7. Confira o badge **Sincronizado** e o registro na API.

## Integração da API

Documentação oficial: https://oquetemnomeucosmetico.com.br/docs/

Base: `https://oquetemnomeucosmetico.com.br/api`

- `POST /login` com `email` e `senha_hmac`;
- `GET /chamados` com Bearer Token;
- `POST /atendimento` multipart com `chamado_id`, `categoria_tecnico`,
  `descricao_procedimento`, `data_resolucao` e `foto` opcional;
- `GET /historico` com Bearer Token.

Não coloque a senha institucional, tokens ou credenciais reais no GitHub.

## Testes e limites desta entrega

Os arquivos foram revisados estaticamente, mas **não foi possível executar
`flutter analyze`, `flutter test` ou `flutter run` neste ambiente**, porque
o SDK Flutter não está instalado. É indispensável realizar esses comandos no
computador do aluno e enviar as mensagens de erro, se houver.

O Manifest Android, a configuração Gradle e o histórico GitHub não foram
enviados; precisam ser conferidos no projeto original.

A sincronização mantém os registros pendentes quando a API falha. Em cenários
extremos, se o servidor receber um atendimento e a confirmação se perder,
uma nova tentativa pode receber HTTP 409; nesse caso, é necessário reconciliar
com `GET /historico` antes de marcar o registro como enviado.

## Melhorias futuras

- Reconciliação automática de requisições com confirmação perdida.
- Recuperação do estado do seletor de fotos após encerramento do Android.
- Notificações em segundo plano para sincronizar quando voltar a internet.
- Paginação e testes de integração em aparelho físico.

**Aviso da avaliação:** o PDF estabelece prazo em 30/10/2026 às 22h e
desautoriza alterações no repositório após a submissão. Consulte o professor
antes de fazer push, caso o trabalho já tenha sido entregue.
