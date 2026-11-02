# Execute na pasta raiz do projeto, a mesma que contem pubspec.yaml.
# PowerShell: .\VERIFICAR_INSTALACAO.ps1

if (-not (Test-Path '.\pubspec.yaml')) {
    Write-Error 'Abra o terminal na pasta do projeto Flutter (com pubspec.yaml).'
    exit 1
}

$apiPath = '.\lib\data\datasources\remote_datasource.dart'
if (-not (Test-Path $apiPath)) {
    Write-Error "O arquivo $apiPath nao existe. Copie a pasta lib NOVA inteira."
    exit 1
}

$api = Get-Content $apiPath -Raw
if ($api -notmatch 'https://oquetemnomeucosmetico\.com\.br/api' -or
    $api -notmatch 'senha_hmac') {
    Write-Error 'A API oficial e o campo senha_hmac nao foram encontrados.'
    exit 1
}

$arquivosAntigos = Get-ChildItem '.\lib' -Filter '*.dart' -Recurse |
    Select-String -Pattern '10\.0\.2\.2|localhost:8000|127\.0\.0\.1:8000'

if ($arquivosAntigos) {
    Write-Host 'ATENCAO: ainda existem enderecos antigos:' -ForegroundColor Red
    $arquivosAntigos | ForEach-Object { Write-Host $_.Path ':' $_.LineNumber }
    exit 1
}

Write-Host 'OK: API HTTPS oficial configurada, senha_hmac presente e nenhum servidor local encontrado.' -ForegroundColor Green
Write-Host 'Proximos passos: flutter clean; flutter pub get; flutter analyze; flutter test; flutter run'
