import 'package:flutter/material.dart';

/// Renderiza o Markdown simples que a IA costuma devolver no chat:
/// **negrito**, *itálico*, `código`, títulos com # e listas com •, - ou *.
///
/// É de propósito bem pequeno: não precisa de pacote externo e cobre o que
/// aparece nas respostas do modelo sem mostrar os asteriscos na tela.
class MarkdownLite extends StatelessWidget {
  final String text;
  final TextStyle? style;

  const MarkdownLite(this.text, {super.key, this.style});

  @override
  Widget build(BuildContext context) {
    final base = style ?? DefaultTextStyle.of(context).style;
    return SelectableText.rich(
      TextSpan(style: base, children: _blocks(text, base)),
    );
  }

  static final _inlineRe = RegExp(
    r'(\*\*\*.+?\*\*\*|\*\*.+?\*\*|\*[^*\n]+?\*|__.+?__|_[^_\n]+?_|`[^`\n]+?`|~~.+?~~)',
  );

  static List<InlineSpan> _inline(String line, TextStyle base) {
    final spans = <InlineSpan>[];
    var last = 0;
    for (final m in _inlineRe.allMatches(line)) {
      if (m.start > last) spans.add(TextSpan(text: line.substring(last, m.start)));
      final token = m.group(0)!;
      if (token.startsWith('***') && token.endsWith('***')) {
        spans.add(TextSpan(
          text: token.substring(3, token.length - 3),
          style: base.copyWith(fontWeight: FontWeight.w700, fontStyle: FontStyle.italic),
        ));
      } else if (token.startsWith('**') && token.endsWith('**')) {
        spans.add(TextSpan(
          text: token.substring(2, token.length - 2),
          style: base.copyWith(fontWeight: FontWeight.w700),
        ));
      } else if (token.startsWith('__') && token.endsWith('__')) {
        spans.add(TextSpan(
          text: token.substring(2, token.length - 2),
          style: base.copyWith(fontWeight: FontWeight.w700),
        ));
      } else if (token.startsWith('*') && token.endsWith('*')) {
        spans.add(TextSpan(
          text: token.substring(1, token.length - 1),
          style: base.copyWith(fontStyle: FontStyle.italic),
        ));
      } else if (token.startsWith('_') && token.endsWith('_')) {
        spans.add(TextSpan(
          text: token.substring(1, token.length - 1),
          style: base.copyWith(fontStyle: FontStyle.italic),
        ));
      } else if (token.startsWith('`') && token.endsWith('`')) {
        spans.add(TextSpan(
          text: token.substring(1, token.length - 1),
          style: base.copyWith(
            fontFamily: 'monospace',
            backgroundColor: Colors.black12,
          ),
        ));
      } else if (token.startsWith('~~') && token.endsWith('~~')) {
        spans.add(TextSpan(
          text: token.substring(2, token.length - 2),
          style: base.copyWith(decoration: TextDecoration.lineThrough),
        ));
      } else {
        spans.add(TextSpan(text: token));
      }
      last = m.end;
    }
    if (last < line.length) spans.add(TextSpan(text: line.substring(last)));
    return spans;
  }

  static final _headingRe = RegExp(r'^\s*(#{1,3})\s+(.*)$');
  static final _bulletRe = RegExp(r'^\s*[•*\-]\s+(.*)$');
  static final _numberRe = RegExp(r'^\s*(\d+[.)])\s+(.*)$');

  static List<InlineSpan> _blocks(String text, TextStyle base) {
    final out = <InlineSpan>[];
    final lines = text.replaceAll('\r\n', '\n').split('\n');
    for (var i = 0; i < lines.length; i++) {
      final raw = lines[i].trimRight();
      final heading = _headingRe.firstMatch(raw);
      if (heading != null) {
        final level = heading.group(1)!.length;
        out.add(TextSpan(
          text: '${heading.group(2)}\n',
          style: base.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: (base.fontSize ?? 14) + (level == 1 ? 3 : level == 2 ? 2 : 1),
          ),
        ));
        continue;
      }
      final bullet = _bulletRe.firstMatch(raw);
      final numbered = _numberRe.firstMatch(raw);
      if (bullet != null) {
        out.add(const TextSpan(text: '•  '));
        out.addAll(_inline(bullet.group(1)!, base));
        out.add(const TextSpan(text: '\n'));
      } else if (numbered != null) {
        out.add(TextSpan(text: '${numbered.group(1)}  '));
        out.addAll(_inline(numbered.group(2)!, base));
        out.add(const TextSpan(text: '\n'));
      } else if (raw.trim() == '---' || raw.trim() == '***') {
        out.add(TextSpan(text: '────────────\n', style: base.copyWith(color: base.color?.withValues(alpha: 0.4))));
      } else {
        out.addAll(_inline(raw, base));
        out.add(const TextSpan(text: '\n'));
      }
    }
    // Remove a última quebra de linha para o balão não ficar com espaço extra.
    if (out.isNotEmpty) {
      final last = out.removeLast();
      if (last is TextSpan && last.text == '\n') {
        // ok: era só a quebra final
      } else {
        out.add(last);
      }
    }
    return out;
  }
}
