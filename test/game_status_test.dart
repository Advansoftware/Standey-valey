import 'package:flutter_test/flutter_test.dart';

import 'package:stardew_guia/game_api.dart';
import 'package:stardew_guia/game_status.dart';
import 'package:stardew_guia/repository.dart';

late Repository repo;

const _snapshot = ApiSnapshot(
  world: ApiWorld(
    season: 0,
    day: 12,
    year: 1,
    weather: 'Sunny',
    farmName: 'Fazenda',
    dayOfWeek: 'Monday',
  ),
  player: ApiPlayer(
    name: 'Bruno',
    farmName: 'Fazenda',
    money: 1200,
    location: 'Farm',
    relationships: [],
    stamina: 200,
    maxStamina: 270,
    health: 90,
    maxHealth: 100,
    skills: [ApiSkill(id: 0, name: 'Farming', level: 2)],
    quests: [
      ApiQuest(
        title: '',
        description: '',
        hasReward: false,
        hasMoneyReward: false,
        currentObjective: '',
        isTimedQuest: false,
      ),
    ],
  ),
  inventory: [
    ApiItem(
      name: 'Parsnip',
      displayName: 'Pastinaca',
      qualifiedItemId: '(O)24',
      stackSize: 3,
    ),
  ],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    repo = await Repository.load();
  });

  test('parseAiObjectives transforma linhas em até 3 objetivos de missão', () {
    final objectives = parseAiObjectives(
      'AGORA\n'
      '1. Regar as plantas | Fazenda | O dia está ensolarado\n'
      '- Visitar a Abigail | Vila Pelicanos | Ela está quase no próximo coração\n'
      '3. Minerar cobre | Minas | Falta cobre para a primeira melhoria\n'
      '4. Este quarto objetivo deve ser ignorado | Extra | Limite',
    );

    expect(objectives, hasLength(3));
    expect(objectives[0].action, 'Regar as plantas');
    expect(objectives[0].place, 'Fazenda');
    expect(objectives[0].detail, 'O dia está ensolarado');
    expect(objectives[1].action, 'Visitar a Abigail');
    expect(objectives[1].place, 'Vila Pelicanos');
    expect(objectives[2].action, 'Minerar cobre');
  });

  test('parseAiObjectives aceita parágrafo e separadores com travessão', () {
    final objectives = parseAiObjectives(
      'Regar as plantas — Fazenda. Visitar a Abigail — Vila Pelicanos. '
      'Minerar cobre — Minas.',
    );

    expect(objectives, hasLength(3));
    expect(objectives.first.action, 'Regar as plantas');
    expect(objectives.first.detail, contains('Fazenda'));
    expect(objectives.last.action, 'Minerar cobre');
  });

  test(
    'parseAiObjectives limpa markdown e devolve vazio para resposta vazia',
    () {
      expect(parseAiObjectives('   '), isEmpty);
      expect(parseAiObjectives('<think>planejando</think>'), isEmpty);
      final objectives = parseAiObjectives(
        '**Pescar** | **Praia** | `Chovendo`',
      );
      expect(objectives.single.action, 'Pescar');
      expect(objectives.single.place, 'Praia');
      expect(objectives.single.detail, 'Chovendo');
    },
  );

  test('o prompt do conselheiro usa o guia e exige objetivos em linhas', () {
    final location = locationInfo(_snapshot.player.location);
    final next = recommendedNextStep(_snapshot, repo);
    final tips = buildStatusTips(_snapshot, repo);
    final prompt = buildStatusPrompt(
      snap: _snapshot,
      location: location,
      next: next,
      tips: tips,
      repo: repo,
    );

    expect(prompt, contains('Culturas da estação no guia'));
    expect(prompt, contains('AÇÃO CURTA | LUGAR | MOTIVO CURTO'));
    expect(prompt, contains('SOMENTE'));
    expect(prompt, contains('Pastinaca'));
    expect(prompt, isNot(contains('título curto "AGORA"')));
  });
}
