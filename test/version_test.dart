import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:stardew_guia/updater_service.dart';

void main() {
  test('a versão de reserva do atualizador acompanha o pubspec', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final version = RegExp(r'^version:\s*([0-9.]+)', multiLine: true).firstMatch(pubspec)!.group(1);
    expect(currentAppVersion, version,
        reason: 'Atualize currentAppVersion em lib/updater_service.dart junto com o pubspec.');
  });
}
