import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class PhotoService {
  final ImagePicker picker;
  PhotoService({ImagePicker? picker}) : picker = picker ?? ImagePicker();

  Future<String?> selecionar(ImageSource origem) async {
    final selecionada = await picker.pickImage(
      source: origem,
      imageQuality: 65,
      maxWidth: 1600,
      maxHeight: 1600,
      requestFullMetadata: false,
    );
    if (selecionada == null) return null;
    final foto = File(selecionada.path);
    const tamanhoMaximo = 5 * 1024 * 1024;
    if (await foto.length() > tamanhoMaximo) {
      throw StateError('A foto precisa ter no máximo 5 MB.');
    }

    final extensao = path.extension(selecionada.path).toLowerCase();
    if (!['.jpg', '.jpeg', '.png', '.webp'].contains(extensao)) {
      throw StateError('Use fotos JPG, PNG ou WEBP.');
    }
    final pasta = Directory(path.join(
      (await getApplicationDocumentsDirectory()).path,
      'fotos_atendimentos',
    ));
    await pasta.create(recursive: true);
    final destino = path.join(
      pasta.path,
      'foto_${DateTime.now().microsecondsSinceEpoch}$extensao',
    );
    await foto.copy(destino);
    return destino;
  }
}
