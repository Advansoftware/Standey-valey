import 'package:flutter/foundation.dart';

/// Um evento recebido pelo WebSocket `/events` da Stardew Web API.
///
/// O mod envia JSON em camelCase: `{"event": "TimeChanged", "data": {...}}`.
@immutable
class LiveEvent {
  final String name;
  final Map<String, dynamic> data;

  const LiveEvent(this.name, this.data);

  static LiveEvent? parse(Map<String, dynamic> raw) {
    final name = (raw['event'] ?? raw['Event'] ?? raw['name'] ?? '') as String;
    if (name.isEmpty) return null;
    final data = raw['data'] ?? raw['Data'];
    return LiveEvent(
      name,
      data is Map ? data.cast<String, dynamic>() : const <String, dynamic>{},
    );
  }

  int? intOf(String key) => (data[key] as num?)?.toInt();
  String strOf(String key) => '${data[key] ?? ''}';

  /// Eventos que mudam dados de /world, /players/main ou do inventário.
  bool get needsSync => const {
        'SaveLoaded',
        'DayStarted',
        'DayEnding',
        'TimeChanged',
        'PlayerWarped',
        'PlayerInventoryChanged',
        'PlayerLevelChanged',
        'FriendshipIncreased',
        'FriendshipDecreased',
        'MultipleFriendshipsIncreased',
        'MultipleFriendshipsDecreased',
        'PlayerStartedDating',
        'PlayerStoppedDating',
        'PlayerEngaged',
        'PlayerNoLongerEngaged',
        'PlayerMarried',
        'PlayerDivorced',
        'FestivalStarted',
        'FestivalEnded',
      }.contains(name);
}

/// Mensagem curta mostrada na tela, como as mensagens do canto do jogo.
@immutable
class HudMessage {
  final String icon;
  final String text;
  final DateTime at;

  const HudMessage(this.icon, this.text, this.at);
}

/// Hora do jogo (formato HHMM, de 600 a 2600) em texto, como no relógio do jogo.
String gameClockLabel(int time) {
  var h = time ~/ 100;
  final m = time % 100;
  final pm = h >= 12 && h < 24;
  h %= 12;
  if (h == 0) h = 12;
  return '$h:${m.toString().padLeft(2, '0')} ${pm ? 'pm' : 'am'}';
}

/// Transforma um evento numa mensagem em português (ou null se não precisa).
HudMessage? hudMessageFor(
  LiveEvent e, {
  String Function(String raw)? place,
  String Function(String raw)? npc,
}) {
  final now = DateTime.now();
  String p(String v) => place == null ? v : place(v);
  String n(String v) => npc == null ? v : npc(v);
  switch (e.name) {
    case 'SaveLoaded':
      return HudMessage('💾', 'Save carregado: ${e.strOf('farmName')}', now);
    case 'Saved':
      return HudMessage('💾', 'Jogo salvo', now);
    case 'DayStarted':
      return HudMessage('🌅', 'Um novo dia começou', now);
    case 'PlayerWarped':
      final to = e.strOf('newLocation');
      return to.isEmpty ? null : HudMessage('🧭', 'Chegou em ${p(to)}', now);
    case 'PlayerLevelChanged':
      return HudMessage(
        '⭐',
        '${e.strOf('skill')} subiu para o nível ${e.intOf('newLevel') ?? ''}!',
        now,
      );
    case 'PlayerInventoryChanged':
      final added = (e.data['added'] as List?) ?? const [];
      final changed = (e.data['quantityChanged'] as List?) ?? const [];
      if (added.isNotEmpty && added.first is Map) {
        final it = (added.first as Map).cast<String, dynamic>();
        final name = '${it['displayName'] ?? it['name'] ?? ''}';
        final qty = (it['stackSize'] as num?)?.toInt() ?? 1;
        return HudMessage('🎒', '+$qty $name', now);
      }
      if (changed.isNotEmpty && changed.first is Map) {
        final c = (changed.first as Map).cast<String, dynamic>();
        final it = ((c['item'] as Map?) ?? const {}).cast<String, dynamic>();
        final diff = ((c['newSize'] as num?) ?? 0) - ((c['oldSize'] as num?) ?? 0);
        if (diff <= 0) return null;
        return HudMessage(
          '🎒',
          '+${diff.toInt()} ${it['displayName'] ?? it['name'] ?? ''}',
          now,
        );
      }
      return null;
    case 'FriendshipIncreased':
      final who = ((e.data['npc'] as Map?)?['name'] ?? e.data['npcName'] ?? '').toString();
      return who.isEmpty ? null : HudMessage('💛', 'Amizade com ${n(who)} aumentou', now);
    case 'FriendshipDecreased':
      final who = ((e.data['npc'] as Map?)?['name'] ?? e.data['npcName'] ?? '').toString();
      return who.isEmpty ? null : HudMessage('💔', 'Amizade com ${n(who)} caiu', now);
    case 'PlayerStartedDating':
      return HudMessage('💐', 'Vocês começaram a namorar!', now);
    case 'PlayerEngaged':
      return HudMessage('💍', 'Noivado!', now);
    case 'PlayerMarried':
      return HudMessage('💒', 'Casamento!', now);
    case 'FestivalStarted':
      return HudMessage('🎪', 'O festival começou', now);
    case 'FestivalEnded':
      return HudMessage('🎪', 'O festival acabou', now);
  }
  return null;
}
