import 'package:flutter_test/flutter_test.dart';
import 'package:goodroads_desktop/core/utils/cpf_formatter.dart';

void main() {
  group('formatCpf', () {
    test('formata 11 digitos como 123.456.789-00', () {
      expect(formatCpf('12345678900'), '123.456.789-00');
    });

    test('retorna null quando a entrada e nula', () {
      expect(formatCpf(null), isNull);
    });

    test('retorna o valor original quando nao tem 11 digitos', () {
      expect(formatCpf('123'), '123');
    });
  });
}
