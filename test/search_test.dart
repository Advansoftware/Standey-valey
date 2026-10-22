import 'package:flutter_test/flutter_test.dart';
import 'package:stardew_guia/search.dart';

void main() {
  test('normalize remove acentos', () {
    expect(normalize('Pimenta Ardência'), 'pimenta ardencia');
  });
  test('tokenize ignora stopwords', () {
    expect(tokenize('o que é a bolota').contains('bolota'), true);
  });
}
