import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

/// Comprime a foto antes do upload — reduz consumo de dados em conexoes
/// ruins, comuns em zona rural (publico-alvo do app). Ver
/// docs/ARQUITETURA_GOODROADS.md, secao 7.6.
Future<File> compressImageFile(String sourcePath) async {
  final tempDir = await getTemporaryDirectory();
  final targetPath = '${tempDir.path}/goodroads_${DateTime.now().millisecondsSinceEpoch}.jpg';

  final result = await FlutterImageCompress.compressAndGetFile(
    sourcePath,
    targetPath,
    quality: 70,
    minWidth: 1280,
    minHeight: 1280,
  );

  return result != null ? File(result.path) : File(sourcePath);
}
