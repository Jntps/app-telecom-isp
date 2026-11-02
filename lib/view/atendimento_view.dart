import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../data/models/chamado_model.dart';
import '../services/photo_service.dart';
import '../viewModel/atendimento_viewmodel.dart';

class AtendimentoView extends StatefulWidget {
  const AtendimentoView({super.key});

  @override
  State<AtendimentoView> createState() => _AtendimentoViewState();
}

class _AtendimentoViewState extends State<AtendimentoView> {
  final _formKey = GlobalKey<FormState>();
  final _descricao = TextEditingController();
  final _fotos = PhotoService();
  String? _categoria;
  String? _fotoPath;

  static const categorias = [
    'Conector / fibra óptica',
    'Roteador ou Wi-Fi',
    'Instalação / cabeamento',
    'Equipamento defeituoso',
    'Configuração de rede',
    'Outro',
  ];

  @override
  void dispose() {
    _descricao.dispose();
    super.dispose();
  }

  Future<void> _escolherFoto() async {
    final origem = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(children: [
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('Tirar foto'),
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Escolher da galeria'),
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
        ]),
      ),
    );
    if (origem == null) return;
    try {
      final caminho = await _fotos.selecionar(origem);
      if (mounted && caminho != null) setState(() => _fotoPath = caminho);
    } catch (erro) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível salvar a foto: $erro')),
      );
    }
  }

  Future<void> _finalizar(ChamadoModel chamado) async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Corrija os campos destacados.')),
      );
      return;
    }
    final vm = context.read<AtendimentoViewModel>();
    final sucesso = await vm.concluir(
      chamadoId: chamado.id,
      categoria: _categoria!,
      descricao: _descricao.text,
      fotoPath: _fotoPath,
    );
    if (!mounted) return;
    if (sucesso) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(vm.erro ?? 'Erro ao salvar o atendimento.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final chamado = ModalRoute.of(context)!.settings.arguments as ChamadoModel;
    final salvando = context.watch<AtendimentoViewModel>().salvando;

    return Scaffold(
      appBar: AppBar(title: Text('Atendimento #${chamado.id}')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(chamado.nome,
                        style: Theme.of(context).textTheme.titleLarge),
                    Text('Cliente: ${chamado.codigoCliente}'),
                    Text('Problema: ${chamado.resumo}'),
                    Text('Endereço: ${chamado.enderecoCompleto}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _categoria,
              decoration: const InputDecoration(
                labelText: 'Categoria do parecer técnico *',
                border: OutlineInputBorder(),
              ),
              items: categorias
                  .map((texto) =>
                      DropdownMenuItem(value: texto, child: Text(texto)))
                  .toList(),
              onChanged: (valor) => setState(() => _categoria = valor),
              validator: (valor) =>
                  valor == null ? 'Selecione a categoria' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descricao,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Procedimento realizado *',
                hintText: 'Descreva o que foi constatado e realizado',
                border: OutlineInputBorder(),
              ),
              validator: (texto) =>
                  (texto?.trim().length ?? 0) < 10
                      ? 'Escreva pelo menos 10 caracteres válidos'
                      : null,
            ),
            const SizedBox(height: 12),
            Text('Conclusão: ${DateTime.now().toLocal().toString().substring(0, 16)}'),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: salvando ? null : _escolherFoto,
              icon: const Icon(Icons.add_a_photo),
              label: const Text('Anexar foto (câmera ou galeria)'),
            ),
            if (_fotoPath != null) ...[
              const SizedBox(height: 12),
              Image.file(
                File(_fotoPath!),
                height: 160,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const Text('Foto indisponível'),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: salvando ? null : () => _finalizar(chamado),
              icon: salvando
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_circle),
              label: const Text('CONCLUIR E SALVAR OFFLINE'),
            ),
          ],
        ),
      ),
    );
  }
}
