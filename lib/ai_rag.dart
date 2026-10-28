import 'ai_cloud.dart';
import 'search.dart';

/// Palavras de conversa que não dizem o assunto ("estou tentando fazer…",
/// "faz tempo", "não sei onde levar"). Sem tirá-las, a busca acha as falas
/// dos moradores, que usam as mesmas palavras.
const _chatStop = <String>{
  'estou', 'to', 'tou', 'esta', 'estava', 'tentando', 'tentei', 'tento', 'fazer', 'faco', 'faz',
  'fiz', 'consigo', 'consegui', 'conseguir', 'consegue', 'nao', 'mas', 'mesmo', 'ainda', 'ja',
  'aqui', 'la', 'ai', 'agora', 'tempo', 'travado', 'travada', 'preso', 'presa', 'pedia', 'pediu',
  'pede', 'sei', 'vou', 'vai', 'pra', 'pro', 'ate', 'tudo', 'nada', 'algum', 'alguma', 'coisa',
  'jeito', 'forma', 'acontecer', 'forcar', 'ajuda', 'ajudar', 'alguem', 'gente', 'voce', 'voces',
  'stardew', 'valley', 'jogando', 'jogo', 'muito', 'mais', 'menos', 'bem', 'bom', 'bons', 'boa',
  'boas', 'ter', 'teria', 'tenho', 'tem', 'dar', 'da', 'deu', 'precisa', 'preciso', 'pode',
  'posso', 'seria', 'fica', 'ficar', 'oi', 'ola', 'obrigado', 'entao', 'tipo', 'ne', 'qual',
  'eles', 'elas', 'isso', 'esse', 'essa', 'este', 'cada', 'quero', 'queria', 'levar',
};

/// Nomes populares que não batem com os da wiki em português.
const _synonyms = <String, String>{
  'orvalho': 'vale stardew feira',
  'mineirando': 'minerando minas',
  'minerando': 'minas',
  'grange': 'exposicao feira',
  'upgrade': 'melhoria',
  'demolir': 'demolir demolicao',
};

/// A pergunta só com as palavras que dizem o assunto.
String focusQuery(String question) {
  final out = <String>[];
  for (final t in tokenize(question)) {
    if (_chatStop.contains(t)) continue;
    out.add(t);
    final syn = _synonyms[t];
    if (syn != null) out.add(syn);
  }
  return out.join(' ');
}

bool _sameWord(String a, String b) =>
    a == b || (a.length >= 4 && (a == '${b}s' || b == '${a}s' || a == '${b}es' || b == '${a}es'));

/// Trecho com falas de morador (muitas aspas): só serve se o morador for citado.
bool _isDialogue(Doc d) => '“'.allMatches(d.text).length >= 3;

/// Recupera os trechos para a pergunta do chat.
///
/// 1. Páginas e fichas cujo nome aparece na pergunta ("fornalha", "argila",
///    "galinheiro") entram primeiro: o começo da página e o trecho dela que
///    mais combina com a pergunta.
/// 2. Depois, a busca BM25 com a pergunta sem as palavras de conversa; falas
///    de morador perdem peso quando o morador não foi citado.
/// 3. Perguntas de continuação ("e onde compro ela?") não têm o assunto: a
///    busca também roda com a pergunta anterior junto.
List<Hit> retrieveForChat(SearchService search, String question, List<ChatTurn> history, {int limit = 8}) {
  final prev = history.lastWhere((t) => t.user, orElse: () => const ChatTurn(true, '')).text;
  final hits = <Hit>[];
  final seen = <Doc>{};
  void add(Hit h) {
    if (seen.add(h.doc)) hits.add(h);
  }

  final focus = focusQuery(question);
  final qTokens = tokenize(focus).toSet();
  // Nome de página só vale se estiver escrito na pergunta (sem sinônimos).
  Set<String> words(String s) => tokenize(s).where((t) => !_chatStop.contains(t)).toSet();
  // Na continuação ("e quanto carvão ela gasta?") o assunto está na pergunta anterior.
  final named = <String>{..._namedPages(search, words(question)), if (prev.isNotEmpty) ..._namedPages(search, words(prev))}
      .take(4);
  for (final title in named) {
    if (title.startsWith('entry:')) {
      final id = title.substring(6);
      search.searchWhere(focus, (d) => d.entryId == id, limit: 1).forEach((h) => add(Hit(h.doc, 100)));
      continue;
    }
    // A ficha com o mesmo nome da página (Emily, Fornalha…) vem antes: é ela
    // que vira o botão de atalho embaixo da resposta.
    for (final e in search.repo.all) {
      if (e.name == title) {
        search.searchWhere(focus, (d) => d.entryId == e.id, limit: 1).forEach((h) => add(Hit(h.doc, 100)));
      }
    }
    final page = search.pages[title];
    if (page == null || page.chunks.isEmpty) continue;
    final first = search.searchWhere(title, (d) => d.pageTitle == title && d.text == page.chunks.first, limit: 1);
    if (first.isNotEmpty) add(Hit(first.first.doc, 100));
    for (final h in search.searchWhere(focus, (d) => d.pageTitle == title, limit: 2)) {
      add(Hit(h.doc, 90));
    }
  }

  List<Hit> ranked(String q, int n) {
    final raw = search.search(q, limit: n * 4);
    final rescored = [
      for (final h in raw)
        Hit(h.doc, _isDialogue(h.doc) && !qTokens.any(tokenize(h.doc.pageTitle ?? '').contains) ? h.score * 0.35 : h.score),
    ]..sort((a, b) => b.score.compareTo(a.score));
    return rescored.take(n).toList();
  }

  ranked(focus.isEmpty ? question : focus, limit).forEach(add);
  if (prev.isNotEmpty) {
    ranked('${focusQuery(prev)} $focus', (limit / 2).ceil()).forEach(add);
  }
  return hits;
}

/// Páginas da wiki (título) e fichas ('entry:id') cujo nome está na pergunta.
/// Nomes mais longos primeiro ("Isca Mágica" antes de "Isca"); no máximo 3.
List<String> _namedPages(SearchService search, Set<String> qTokens) {
  if (qTokens.isEmpty) return const [];
  final found = <(int, String)>[];
  bool contains(String name) {
    final words = tokenize(name);
    if (words.isEmpty) return false;
    if (words.length == 1 && words.first.length < 4) return false;
    return words.every((w) => qTokens.any((q) => _sameWord(q, w)));
  }

  for (final title in search.pages.keys) {
    if (contains(title)) found.add((tokenize(title).length, title));
  }
  for (final e in search.repo.all) {
    if (!search.pages.containsKey(e.name) && contains(e.name)) found.add((tokenize(e.name).length, 'entry:${e.id}'));
  }
  found.sort((a, b) => b.$1.compareTo(a.$1));
  return [for (final f in found.take(3)) f.$2];
}

/// Contexto para os modelos web, que aceitam textos longos: os trechos inteiros
/// e, nas páginas da wiki mais relevantes, os trechos vizinhos da mesma página
/// (a resposta costuma estar no parágrafo de antes ou de depois).
String buildCloudContext(SearchService search, List<Hit> hits, {int budget = 24000}) {
  final b = StringBuffer();
  final used = <String>{};
  var total = 0;
  var expandedPages = 0;
  var i = 1;

  bool add(String title, String text) {
    // As tabelas da wiki vêm achatadas, uma célula por linha: " | " mantém as
    // células separadas (com espaço, "4 000 ouros 10 000 ouros" vira uma coisa só).
    final t = text
        .trim()
        .replaceAll(RegExp(r'[ \t]*\n\s*'), ' | ')
        .replaceAll(RegExp(r'[ \t]+'), ' ');
    if (t.isEmpty || !used.add(t)) return true;
    final cut = t.length > 2500 ? '${t.substring(0, 2500)}…' : t;
    if (total + cut.length > budget) return false;
    total += cut.length;
    b.writeln('[$i] $title: $cut');
    i++;
    return true;
  }

  for (final h in hits) {
    final d = h.doc;
    final entry = search.entryOf(d);
    final title = entry?.name ?? d.pageTitle ?? d.title;
    final page = d.pageTitle == null ? null : search.pages[d.pageTitle!];
    if (page == null || expandedPages >= 3) {
      if (!add(title, d.text)) break;
      continue;
    }
    expandedPages++;
    final at = page.chunks.indexOf(d.text);
    final from = at < 0 ? 0 : (at - 1).clamp(0, page.chunks.length - 1);
    final to = at < 0 ? -1 : (at + 1).clamp(0, page.chunks.length - 1);
    var ok = true;
    for (var c = from; c <= to && ok; c++) {
      ok = add(title, page.chunks[c]);
    }
    if (at < 0) ok = add(title, d.text);
    if (!ok) break;
  }
  return b.toString();
}

/// Instrução de sistema dos modelos web no chat.
const cloudSystemPrompt =
    'Você é o assistente do Guia do Vale, um guia de Stardew Valley (versão 1.6) em português do Brasil.\n'
    'Responda sempre em português do Brasil, como quem ajuda alguém que começou a jogar agora.\n'
    'Seja direto e resumido: comece pela resposta, depois só os passos ou dados que a pessoa precisa '
    '(em geral até 6 linhas). Sem introdução, sem repetir a pergunta e sem dicas que ninguém pediu. '
    'Termine quando a resposta acabar: nunca feche com pergunta, oferta ("se quiser, me diga…", '
    '"posso calcular…") ou pedido de mais informação. '
    'Se houver um engano por trás da pergunta (ex.: argila não sai de pedra; construção se melhora na Robin '
    'em vez de demolir), corrija em uma frase e dê o caminho certo.\n'
    'Nas tabelas dos trechos as células vêm separadas por " | ", na ordem das colunas: '
    'confira a que coluna cada número pertence.\n'
    'Cada pergunta vem com trechos do guia e da wiki em português. Baseie a resposta nesses trechos: '
    'são a fonte confiável de nomes, preços, datas e locais. Use os nomes em português que aparecem neles.\n'
    'Se os trechos não bastarem, pode completar com o que você sabe do jogo, mas sem inventar números; '
    'se não tiver certeza, diga isso.\n'
    'Quando vier o "Save do jogador", a pessoa está com o jogo conectado: use a data, o dinheiro, a mochila, '
    'as habilidades, as amizades e as missões para responder sobre o jogo dela ("o que eu faço agora?", '
    '"tenho o que preciso?"). Não repita o save inteiro; cite só o que importa para a pergunta.\n'
    'Leve em conta a conversa anterior: perguntas como "e ela?" ou "onde compro?" falam do assunto anterior.\n'
    'Não cite os números dos trechos ([1], [2]…) nem fale dos trechos, do guia ou do save como algo que a '
    'pessoa mandou: ela não vê nada disso. Se faltar um dado (ex.: valor exato de recompensa), só não o cite.\n'
    'Formate com parágrafos curtos e listas com hífen quando ajudar; use **negrito** para nomes e valores. '
    'Não use tabelas, HTML nem blocos de código.';

/// Mensagem do usuário para os modelos web: trechos + pergunta.
String buildCloudQuestion(String question, String context, {String? save}) {
  final b = StringBuffer();
  if (save != null && save.trim().isNotEmpty) {
    b.writeln('Save do jogador agora (dados ao vivo do jogo):');
    b.writeln(save.trim());
    b.writeln();
  }
  if (context.trim().isNotEmpty) b.writeln('Trechos do guia:\n$context');
  if (b.isEmpty) return question;
  b.write('Pergunta: $question');
  return b.toString();
}
