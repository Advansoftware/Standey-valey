part of 'status_screen.dart';

/// Modal detalhado para Amizades e Moradores com presentes amados.
void showVillagerDetailDialog(BuildContext context, ApiRelationship rel, Entry? entry) {
  final name = entry?.name ?? rel.npcName;
  final status = rel.isMarried
      ? '💍 Casado(a)'
      : rel.isEngaged
          ? '💎 Noivo(a)'
          : rel.isDating
              ? '💖 Namorando'
              : rel.isRoommate
                  ? '🏠 Colega'
                  : 'Morador';

  showStatusDetailDialog(
    context,
    title: name,
    emoji: '👤',
    tag: '${rel.hearts} / ${rel.isMarried ? 14 : 10} ♥',
    tagColor: const Color(0xFFC2185B),
    content: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 52,
              height: 52,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: const Color(0xFFC2185B).withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFC2185B), width: 2),
              ),
              child: entry != null
                  ? Center(child: EntryImage(entry: entry, size: 46))
                  : Center(
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                      ),
                    ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontFamily: 'PixelifySans',
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: _ink,
                    ),
                  ),
                  Text(
                    status,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFC2185B),
                    ),
                  ),
                  Text(
                    '${rel.points} pontos de amizade',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF6B5238)),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: _paper2,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFFDCC79E)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    rel.hasBeenGivenGiftToday
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    size: 15,
                    color: rel.hasBeenGivenGiftToday ? _green : Color(0xFF8D6E63),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    rel.hasBeenGivenGiftToday
                        ? 'Presente de hoje já entregue!'
                        : 'Ainda não recebeu presente hoje.',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: rel.hasBeenGivenGiftToday ? _green : _ink,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Presentes dados nesta semana: ${rel.giftsGivenThisWeek} de 2 permitidos',
                style: const TextStyle(fontSize: 11, color: Color(0xFF5B4630)),
              ),
            ],
          ),
        ),
        if (entry != null && entry.desc.isNotEmpty) ...[
          const SizedBox(height: 10),
          const Text(
            'SOBRE O MORADOR',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: Color(0xFF7A5826),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            entry.desc,
            style: const TextStyle(fontSize: 12.5, height: 1.3, color: Color(0xFF3E2818)),
          ),
        ],
      ],
    ),
  );
}

/// Modal detalhado para Habilidades e Profissões.
void showSkillDetailDialog(BuildContext context, ApiSkill skill) {
  final name = skillNamePt(skill);
  final professions = skill.professions;

  showStatusDetailDialog(
    context,
    title: 'Habilidade: $name',
    emoji: skillEmoji(skill),
    tag: 'NÍVEL ${skill.level} / 10',
    tagColor: _green,
    content: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(skillEmoji(skill), style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontFamily: 'PixelifySans',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: clamp01(skill.level / 10),
                      minHeight: 6,
                      backgroundColor: const Color(0xFFDCC79E),
                      valueColor: const AlwaysStoppedAnimation(_green),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        const Text(
          'PROFISSÕES ESCOLHIDAS',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: Color(0xFF7A5826),
          ),
        ),
        const SizedBox(height: 6),
        if (professions.isEmpty)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _paper2,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'Nenhuma profissão desbloqueada ainda. Atinja os níveis 5 e 10 para escolher especializações.',
              style: TextStyle(fontSize: 11.5, color: Color(0xFF6B5238)),
            ),
          )
        else
          ...professions.map(
            (p) => Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _paper2,
                borderRadius: BorderRadius.circular(6),
                border: const Border(left: BorderSide(color: _green, width: 3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    professionNamePt(p.name),
                    style: const TextStyle(
                      fontFamily: 'PixelifySans',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _ink,
                    ),
                  ),
                  if (p.description.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      p.description,
                      style: const TextStyle(fontSize: 11.5, color: Color(0xFF4E3926)),
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    ),
  );
}

/// Modal detalhado para o Plano Estratégico da IA / Conselheiro.
void showAiPlanDetailDialog(
  BuildContext context,
  String rawText,
  List<AiObjective> objectives,
) {
  showStatusDetailDialog(
    context,
    title: 'Conselheiro do Vale',
    icon: Icons.auto_awesome_rounded,
    tag: 'IA LOCAL',
    tagColor: _blue,
    content: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'PLANO ESTRATÉGICO PARA O SEU SAVE',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: Color(0xFF7A5826),
          ),
        ),
        const SizedBox(height: 8),
        if (objectives.isNotEmpty) ...[
          ...objectives.asMap().entries.map((entry) {
            final idx = entry.key;
            final obj = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: _paper2,
                borderRadius: BorderRadius.circular(6),
                border: const Border(left: BorderSide(color: _blue, width: 3.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: _blue,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          'PASSO ${idx + 1}',
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      if ((obj.place ?? '').isNotEmpty) ...[
                        const SizedBox(width: 5),
                        _TinyTag(obj.place!, _green),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    obj.action,
                    style: const TextStyle(
                      fontFamily: 'PixelifySans',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _ink,
                    ),
                  ),
                  if ((obj.detail ?? '').isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      obj.detail!,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.25,
                        color: Color(0xFF4E3926),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
        ] else if (rawText.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _paper2,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              rawText,
              style: const TextStyle(fontSize: 13, height: 1.35, color: _ink),
            ),
          ),
        ],
      ],
    ),
  );
}

/// Modal detalhado para a Previsão da Sorte do Dia (Vidente da TV).
void showFortuneDetailDialog(BuildContext context, ApiPlayer p) {
  final phrase = luckPhrase(p.dailyLuck);
  final desc = p.dailyLuckDescription.trim().isNotEmpty
      ? p.dailyLuckDescription.trim()
      : 'Os espíritos influenciam a chance de achar escadas nas minas, minérios raros, tesouros na pesca e colheitas extras.';

  showStatusDetailDialog(
    context,
    title: 'Previsão da Vidente',
    icon: Icons.auto_awesome_rounded,
    tag: luckLabel(p),
    tagColor: const Color(0xFF7E57C2),
    content: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF7E57C2).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFF7E57C2).withValues(alpha: 0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                phrase,
                style: const TextStyle(
                  fontFamily: 'PixelifySans',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF4A148C),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                desc,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.3,
                  color: _ink,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'ONDE A SORTE AFETA O JOGO',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: Color(0xFF7A5826),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          '• Minas: Chance de encontrar escadas e poços sob as pedras.\n'
          '• Pesca: Qualidade e tesouros fisgados com a vara.\n'
          '• Coleta: Chance de dobrar itens coletados pelo chão.\n'
          '• Cassino do Deserto: Probabilidade de vitória nas máquinas.',
          style: TextStyle(fontSize: 12, height: 1.3, color: Color(0xFF5B4630)),
        ),
      ],
    ),
  );
}

/// Modal detalhado para Energia e Cansaço.
void showEnergyDetailDialog(BuildContext context, ApiPlayer p) {
  final pct = p.maxStamina > 0 ? (p.stamina / p.maxStamina) : 0;
  showStatusDetailDialog(
    context,
    title: 'Energia do Fazendeiro',
    icon: Icons.bolt_rounded,
    tag: '${p.stamina.round()} / ${p.maxStamina}',
    tagColor: const Color(0xFF8BC34A),
    content: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Text('⚡', style: TextStyle(fontSize: 28)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pct < 0.2
                        ? 'Energia Crítica — Cansaço iminente!'
                        : pct < 0.5
                            ? 'Energia Moderada'
                            : 'Energia Cheia e Disposição!',
                    style: TextStyle(
                      fontFamily: 'PixelifySans',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: pct < 0.2 ? _red : _ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: clamp01(pct.toDouble()),
                      minHeight: 6,
                      backgroundColor: const Color(0xFFDCC79E),
                      valueColor: AlwaysStoppedAnimation(
                        pct < 0.2 ? _red : const Color(0xFF8BC34A),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Text(
          'COMO RECUPERAR ENERGIA',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: Color(0xFF7A5826),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          '• Comer alimentos: frutas, vegetais, peixes ou pratos cozidos.\n'
          '• Dormir na cama: restaura 100% da energia para o dia seguinte.\n'
          '• Spa na Ferrovia: ficar parado na água quente regenera rápido.\n'
          '• Cuidado: se a energia cair a zero, você fica exausto e perde velocidade.',
          style: TextStyle(fontSize: 12, height: 1.3, color: Color(0xFF5B4630)),
        ),
      ],
    ),
  );
}

/// Modal detalhado para Saúde e Vida.
void showHealthDetailDialog(BuildContext context, ApiPlayer p) {
  final pct = p.maxHealth > 0 ? (p.health / p.maxHealth) : 0;
  showStatusDetailDialog(
    context,
    title: 'Saúde e Vitalidade',
    icon: Icons.favorite_rounded,
    tag: '${p.health} / ${p.maxHealth}',
    tagColor: _red,
    content: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Text('❤️', style: TextStyle(fontSize: 28)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pct < 0.35 ? 'Vida Baixa — Risco de desmaio!' : 'Saúde Estável',
                    style: TextStyle(
                      fontFamily: 'PixelifySans',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: pct < 0.35 ? _red : _ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: clamp01(pct.toDouble()),
                      minHeight: 6,
                      backgroundColor: const Color(0xFFDCC79E),
                      valueColor: const AlwaysStoppedAnimation(_red),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Text(
          'DICAS DE SOBREVIVÊNCIA',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: Color(0xFF7A5826),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          '• Se a vida chegar a 0 nas Minas ou Caverna da Caveira, você desmaia, perde itens e acorda na clínica do Harvey.\n'
          '• Leve sempre comida de cura rápida (como Queijo, Saladas ou Poções de Vida) antes de descer andares profundos.',
          style: TextStyle(fontSize: 12, height: 1.3, color: Color(0xFF5B4630)),
        ),
      ],
    ),
  );
}

/// Modal detalhado para Dinheiro e Economia.
void showMoneyDetailDialog(BuildContext context, ApiPlayer p) {
  showStatusDetailDialog(
    context,
    title: 'Economia da Fazenda',
    emoji: '🪙',
    tag: moneyLabel(p.money),
    tagColor: _gold,
    content: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Saldo disponível: ${moneyLabel(p.money)}',
          style: const TextStyle(
            fontFamily: 'PixelifySans',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: _ink,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'DICAS FINANCEIRAS',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: Color(0xFF7A5826),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          '• Caixa de entregas: itens colocados nela são vendidos durante a noite.\n'
          '• Venda direta: Pierre compra colheitas na hora; Clint compra minérios; Willy compra peixes.\n'
          '• Reinvista nos primeiros dias em sementes de alto rendimento da estação.',
          style: TextStyle(fontSize: 12, height: 1.3, color: Color(0xFF5B4630)),
        ),
      ],
    ),
  );
}

/// Modal detalhado para o Próximo Passo.
void showNextStepDetailDialog(
  BuildContext context,
  StatusTip next,
  LocationInfo loc,
) {
  showStatusDetailDialog(
    context,
    title: next.title,
    emoji: next.emoji,
    tag: 'PRÓXIMO PASSO',
    tagColor: _gold,
    content: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          next.body,
          style: const TextStyle(fontSize: 13.5, height: 1.35, color: _ink),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: _paper2,
            borderRadius: BorderRadius.circular(6),
            border: const Border(left: BorderSide(color: _green, width: 3.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.place_rounded, color: _green, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'Local: ${loc.displayName} (${loc.region})',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Como chegar: ${loc.directions}',
                style: const TextStyle(fontSize: 11.5, color: Color(0xFF5B4630)),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
