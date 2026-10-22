import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'models.dart';
import 'repository.dart';

const _from = 'àáâãäåèéêëìíîïòóôõöùúûüçñ';
const _to = 'aaaaaaeeeeiiiiooooouuuucn';

const _stop = <String>{
  'de', 'da', 'do', 'das', 'dos', 'a', 'o', 'as', 'os', 'e', 'em', 'no', 'na',
  'nos', 'nas', 'um', 'uma', 'que', 'para', 'por', 'com', 'como', 'qual',
  'quais', 'onde', 'quando', 'se', 'eu', 'meu', 'minha', 'ao', 'ou', 'the',
  'of', 'to', 'in', 'is', 'sao', 'ser', 'tem', 'ter', 'posso', 'devo',
};

/// Remove acentos e coloca em minúsculas.
String normalize(String s) {
  final b = StringBuffer();
  for (final r in s.toLowerCase().runes) {
    final ch = String.fromCharCode(r);
    final i = _from.indexOf(ch);
    b.write(i >= 0 ? _to[i] : ch);
  }
  return b.toString();
}

final _wordRe = RegExp(r'[a-z0-9]+');

List<String> tokenize(String s) {
  final out = <String>[];
  for (final m in _wordRe.allMatches(normalize(s))) {
    var t = m.group(0)!;
    if (t.length < 2 || _stop.contains(t)) continue;
    if (t.length > 3 && t.endsWith('s')) t = t.substring(0, t.length - 1);
    out.add(t);
  }
  return out;
}

class Doc {
  final String title;
  final String text;
  final String? entryId;
  final String? pageTitle;
  final String? pageUrl;
  const Doc({required this.title, required this.text, this.entryId, this.pageTitle, this.pageUrl});
}

class Hit {
  final Doc doc;
  final double score;
  const Hit(this.doc, this.score);
}

/// Índice BM25 simples, 100% local.
class Bm25Index {
  final List<Doc> docs = [];
  final List<int> _len = [];
  // termo -> [doc, tf, doc, tf, ...]
  final Map<String, List<int>> _post = {};
  double _avg = 1;
  static const _k1 = 1.4;
  static const _b = 0.75;

  void add(Doc d, {int titleBoost = 3}) {
    final id = docs.length;
    docs.add(d);
    final tf = <String, int>{};
    final titleTokens = tokenize(d.title);
    for (var i = 0; i < titleBoost; i++) {
      for (final t in titleTokens) {
        tf[t] = (tf[t] ?? 0) + 1;
      }
    }
    final bodyTokens = tokenize(d.text);
    for (final t in bodyTokens) {
      tf[t] = (tf[t] ?? 0) + 1;
    }
    _len.add(titleTokens.length * titleBoost + bodyTokens.length);
    tf.forEach((term, f) {
      (_post[term] ??= <int>[]).addAll([id, f]);
    });
  }

  void finish() {
    if (_len.isEmpty) {
      _avg = 1;
      return;
    }
    var sum = 0;
    for (final l in _len) {
      sum += l;
    }
    _avg = sum / _len.length;
  }

  List<Hit> search(String query, {int limit = 10, bool Function(Doc)? where}) {
    final qTokens = tokenize(query);
    if (qTokens.isEmpty || docs.isEmpty) return const [];
    final n = docs.length;
    final scores = <int, double>{};

    void scoreTerm(String term, double weight) {
      final post = _post[term];
      if (post == null) return;
      final df = post.length ~/ 2;
      final idf = math.log(1 + (n - df + 0.5) / (df + 0.5));
      for (var i = 0; i < post.length; i += 2) {
        final d = post[i];
        final tf = post[i + 1];
        final norm = tf + _k1 * (1 - _b + _b * _len[d] / _avg);
        scores[d] = (scores[d] ?? 0) + weight * idf * (tf * (_k1 + 1)) / norm;
      }
    }

    for (final q in qTokens) {
      scoreTerm(q, 1.0);
      if (q.length >= 3) {
        var count = 0;
        for (final term in _post.keys) {
          if (term != q && term.startsWith(q)) {
            scoreTerm(term, 0.5);
            if (++count >= 25) break;
          }
        }
      }
    }

    final list = scores.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final out = <Hit>[];
    for (final e in list) {
      final doc = docs[e.key];
      if (where != null && !where(doc)) continue;
      out.add(Hit(doc, e.value));
      if (out.length >= limit) break;
    }
    return out;
  }
}

class WikiPage {
  final String title;
  final String url;
  final List<String> chunks;
  const WikiPage(this.title, this.url, this.chunks);
  String get text => chunks.join('\n\n');
}

List<dynamic> _decodeWiki(Uint8List bytes) =>
    jsonDecode(utf8.decode(gzip.decode(bytes))) as List<dynamic>;

/// Busca sobre a enciclopédia embutida e, se existir, sobre a wiki baixada.
class SearchService extends ChangeNotifier {
  final Repository repo;
  Bm25Index _index = Bm25Index();
  final Map<String, WikiPage> pages = {};
  bool wikiLoading = false;
  bool wikiLoaded = false;
  bool wikiAvailable = false;

  SearchService(this.repo) {
    _index = _buildIndex(const []);
  }

  Bm25Index _buildIndex(List<WikiPage> wiki) {
    final idx = Bm25Index();
    for (final e in repo.all) {
      idx.add(Doc(title: '${e.name} ${e.en}', text: e.fullText, entryId: e.id));
    }
    for (final p in wiki) {
      for (final c in p.chunks) {
        idx.add(Doc(title: p.title, text: c, pageTitle: p.title, pageUrl: p.url), titleBoost: 2);
      }
    }
    idx.finish();
    return idx;
  }

  /// Carrega a wiki offline (assets/wiki/pages.json.gz) se ela existir.
  Future<void> loadWiki() async {
    if (wikiLoaded || wikiLoading) return;
    wikiLoading = true;
    notifyListeners();
    try {
      final data = await rootBundle.load('assets/wiki/pages.json.gz');
      final raw = await compute(_decodeWiki, data.buffer.asUint8List());
      final list = <WikiPage>[];
      for (final p in raw) {
        final m = p as Map<String, dynamic>;
        final page = WikiPage(
          (m['t'] as String?) ?? '',
          (m['u'] as String?) ?? '',
          ((m['c'] as List?) ?? const []).map((e) => e.toString()).toList(),
        );
        list.add(page);
        pages[page.title] = page;
      }
      _index = _buildIndex(list);
      wikiAvailable = list.isNotEmpty;
    } catch (_) {
      wikiAvailable = false;
    }
    wikiLoaded = true;
    wikiLoading = false;
    notifyListeners();
  }

  List<Hit> search(String q, {int limit = 20, bool entriesOnly = false}) {
    return _index.search(q, limit: limit, where: entriesOnly ? (d) => d.entryId != null : null);
  }

  Entry? entryOf(Doc d) => d.entryId == null ? null : repo.byId[d.entryId!];
}
