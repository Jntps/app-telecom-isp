# Checklist de entrega - Projeto Telecom

## Código preparado neste pacote

- [x] RF01 - Models de usuário, chamado e atendimento.
- [x] RF02 - Splash com abertura e leitura de token.
- [x] RF03 - Login HMAC-SHA256 com chave compartilhada da turma.
- [x] RF04 - Persistência do token via flutter_secure_storage.
- [x] RF05 - SQLite e modo offline para os chamados carregados.
- [x] RF06 - Home com chamados ativos e ListView.builder.
- [x] RF07 - Distância GPS usando Haversine e ordenação.
- [x] RF08 - Detalhes do chamado e indicação de conexão offline.
- [x] RF09 - Formulário de atendimento com os campos solicitados.
- [x] RF10 - Validação obrigatória e descrição com 10 caracteres.
- [x] RF11 - Foto pela câmera/galeria, guardada no aplicativo.
- [x] RF12 - Conclusão offline e atualização do status no SQLite.
- [x] RF13 - Envio multipart POST /api/atendimento com HTTP 201.
- [x] RF14 - Histórico local e consulta da API.
- [x] RF15 - Pesquisa por número do chamado ou código do cliente.
- [x] RF16 - Visualização de foto local ou da API.
- [x] Testes unitários escritos para models, datasources e repositórios.
- [x] Dois testes de interface (`test/widget_views_test.dart`).
- [x] GridView, Image.asset, filtros/ordenação e README.
- [x] Roteiro com commits para GitFlow.

## A fazer no computador do aluno antes de entregar

- [ ] Substituir a pasta `lib/` inteira, não mesclar com o código antigo.
- [ ] Copiar `pubspec.yaml`, `assets/` e `test/` para a raiz.
- [ ] Configurar permissões Android e `compileSdk` no projeto original.
- [ ] Rodar `VERIFICAR_INSTALACAO.ps1` (ou verificar os caminhos manualmente).
- [ ] Executar `flutter clean`, `flutter pub get`, `flutter analyze` e corrigir
      eventuais problemas de SDK ou configurações locais.
- [ ] Executar `flutter test`; os testes ainda **não foram executados** aqui.
- [ ] Testar login com as credenciais fornecidas pelo professor.
- [ ] Testar o fluxo com e sem internet, localização, câmera e histórico.
- [ ] Revisar `git status` e criar os commits no repositório original.
- [ ] Fazer push seguindo o fluxo do professor e conferir permissões.
- [ ] Gravar o vídeo demonstrativo e entregar os links no AVA.

**Limite importante:** O SDK Flutter não está instalado no ambiente que
produziu este código, por isso os itens marcados como feitos significam
**implementados no código**, não validados em emulador ou aprovados pelo
professor. O Manifest Android não foi fornecido e exige edição manual.
