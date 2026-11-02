# Commits GitFlow - Projeto Telecom

**Não execute os comandos de push se o projeto já foi submetido e o professor
não autorizou mudanças após a entrega.**

Estes comandos são sugestões para o seu **repositório real**. O ZIP fornecido
não tem histórico `.git`; nenhum commit foi criado no seu GitHub por este
assistente.

Antes de começar, faça backup e confirme que instalou o pacote na pasta certa:

```bash
git status
git branch
```

Se já houver mudanças suas sem commit, preserve-as antes de trocar de branch.
Partindo de uma `develop` limpa, crie uma feature branch:

```bash
git switch develop
git switch -c feature/isp-offline-completo
```

Depois de copiar os arquivos, faça os commits em grupos:

### Commit 1 - Modelos e SQLite

```bash
git add -A lib/data/models lib/data/datasources/database_helper.dart lib/data/datasources/local_datasource.dart
git commit -m "implementa modelos e persistencia SQLite offline"
```

### Commit 2 - API e login seguro

```bash
git add lib/data/datasources/remote_datasource.dart lib/data/datasources/token_store.dart lib/data/repositories/auth_repository.dart lib/viewModel/auth_viewmodel.dart
git commit -m "corrige integracao com API e autenticacao HMAC"
```

### Commit 3 - Home e GPS

```bash
git add lib/data/repositories/chamados_repository.dart lib/viewModel/chamados_viewmodel.dart lib/services/location_service.dart lib/view/home_view.dart
git commit -m "implementa Home offline e ordenacao por proximidade"
```

### Commit 4 - Atendimento e foto

```bash
git add lib/services/photo_service.dart lib/data/repositories/atendimentos_repository.dart lib/viewModel/atendimento_viewmodel.dart lib/view/atendimento_view.dart
git commit -m "implementa formulario de atendimento e foto local"
```

### Commit 5 - Histórico e sincronização

```bash
git add lib/viewModel/historico_viewmodel.dart lib/view/historico_view.dart
git commit -m "implementa historico e sincronizacao multipart"
```

### Commit 6 - Aplicação e dependências

```bash
git add lib/main.dart lib/view/login_view.dart lib/view/splash_view.dart pubspec.yaml assets/images/logo.png assets/images/logo.svg
git commit -m "integra navegacao e dependencias do aplicativo"
```

### Commit 7 - Testes e documentação

```bash
git add test README.md CONFIGURAR_ANDROID.md CHECKLIST_ENTREGA.md GUIA_COMMITS.md VERIFICAR_INSTALACAO.ps1
git commit -m "adiciona testes e documentacao de entrega"
```

**Atenção às pastas antigas:** se os diretórios antigos `lib/models/`,
`lib/repositories/`, `lib/datasources/` e `lib/view/detalhes_view.dart`
estavam versionados e agora foram removidos ao substituir a pasta `lib/`,
registre a remoção em um commit próprio após revisar com `git status`:

```bash
git add -u lib
git commit -m "remove estrutura antiga substituida por MVVM"
```

Só execute esse commit se houver remoções versionadas. Não gere commits vazios.

## Verificar antes de publicar

```bash
flutter analyze
flutter test
git status
git log --oneline -8
```

## Integrar branches (apenas com autorização para publicar)

```bash
git push -u origin feature/isp-offline-completo
git switch develop
git merge --no-ff feature/isp-offline-completo
git push origin develop
git switch main
git merge --no-ff develop
git push origin main
```

Se o repositório exigir Pull Request, utilize esse fluxo em vez de forçar push.
Confirme que `rafaelhaguiar` e `lab365-operacao` têm acesso ao repositório
privado e que o vídeo e os links foram enviados pelo AVA.
