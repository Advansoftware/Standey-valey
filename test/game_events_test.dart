import 'package:flutter_test/flutter_test.dart';
import 'package:stardew_guia/game_events.dart';

void main() {
  test('relógio do jogo no formato do jogo (6:00 am a 2:00 am)', () {
    expect(gameClockLabel(600), '6:00 am');
    expect(gameClockLabel(1310), '1:10 pm');
    expect(gameClockLabel(1200), '12:00 pm');
    expect(gameClockLabel(2400), '12:00 am');
    expect(gameClockLabel(2550), '1:50 am');
  });

  test('lê eventos do WebSocket em camelCase, como o mod envia', () {
    final e = LiveEvent.parse({
      'event': 'TimeChanged',
      'data': {'oldTime': 600, 'newTime': 610},
    })!;
    expect(e.name, 'TimeChanged');
    expect(e.intOf('newTime'), 610);
    expect(e.needsSync, isTrue);
    expect(LiveEvent.parse({'event': 'Connected'})!.needsSync, isFalse);
    expect(LiveEvent.parse({}), isNull);
  });

  test('mensagens da HUD em português para os eventos', () {
    final warp = hudMessageFor(
      const LiveEvent('PlayerWarped', {'newLocation': 'Beach'}),
      place: (raw) => raw == 'Beach' ? 'Praia' : raw,
    );
    expect(warp!.text, 'Chegou em Praia');

    final level = hudMessageFor(
      const LiveEvent('PlayerLevelChanged', {'skill': 'Pesca', 'newLevel': 4}),
    );
    expect(level!.text, contains('nível 4'));

    final items = hudMessageFor(const LiveEvent('PlayerInventoryChanged', {
      'added': [],
      'quantityChanged': [
        {
          'item': {'displayName': 'Madeira'},
          'oldSize': 10,
          'newSize': 15,
        },
      ],
    }));
    expect(items!.text, '+5 Madeira');

    // diminuir a pilha não gera mensagem
    expect(
      hudMessageFor(const LiveEvent('PlayerInventoryChanged', {
        'quantityChanged': [
          {'item': {'displayName': 'Madeira'}, 'oldSize': 10, 'newSize': 3},
        ],
      })),
      isNull,
    );
  });
}
