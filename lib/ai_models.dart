import 'package:flutter_edge_ai/flutter_edge_ai.dart';

/// Um modelo de IA local (.litertlm) que o app sabe baixar.
class AiModel {
  /// Identificador estável (usado nas preferências).
  final String id;

  /// Nome que aparece para o usuário.
  final String name;

  /// Repositório no Hugging Face (permite o plugin escolher a melhor variante
  /// para o aparelho: GPU, NPU ou CPU).
  final String repo;

  /// URL direta do arquivo .litertlm (usada como reserva se a resolução
  /// automática da variante falhar).
  final String url;

  /// Tamanho aproximado do download, em GB.
  final double sizeGb;

  /// Memória RAM recomendada.
  final String ram;

  /// Família do modelo (define o template de conversa).
  final ModelType type;

  /// Observação curta mostrada na lista.
  final String note;

  /// Se o modelo foi treinado exclusivamente para Stardew Valley.
  final bool isFineTuned;

  const AiModel({
    required this.id,
    required this.name,
    required this.repo,
    required this.url,
    required this.sizeGb,
    required this.ram,
    required this.type,
    this.note = '',
    this.isFineTuned = false,
  });

  String get sizeLabel => sizeGb < 1
      ? '${(sizeGb * 1000).round()} MB'
      : '${sizeGb.toStringAsFixed(1).replaceAll('.', ',')} GB';
}

/// Catálogo de modelos. O primeiro da lista é o padrão do app.
const List<AiModel> aiModels = [
  AiModel(
    id: 'stardew-qwen-05b',
    name: 'Espírito do Vale',
    repo: 'brunoantunes100/stardew-guia-qwen-0.5b',
    url: 'https://huggingface.co/brunoantunes100/stardew-guia-qwen-0.5b/resolve/main/stardew_qwen_0.5b.litertlm',
    sizeGb: 0.65,
    ram: '2 GB+',
    type: ModelType.qwen,
    note: 'IA nativa treinada especialmente para Stardew Valley. Respostas instantâneas, leve e 100% offline.',
    isFineTuned: true,
  ),
  AiModel(
    id: 'gemma4-e4b',
    name: 'Gemma 4 E4B',
    repo: 'litert-community/gemma-4-E4B-it-litert-lm',
    url: 'https://huggingface.co/litert-community/gemma-4-E4B-it-litert-lm/resolve/main/gemma-4-E4B-it.litertlm',
    sizeGb: 3.66,
    ram: '8 GB+',
    type: ModelType.gemma4,
    note: 'Recomendado para celulares com 8 GB ou mais de RAM.',
  ),
  AiModel(
    id: 'gemma4-e2b',
    name: 'Gemma 4 E2B',
    repo: 'litert-community/gemma-4-E2B-it-litert-lm',
    url: 'https://huggingface.co/litert-community/gemma-4-E2B-it-litert-lm/resolve/main/gemma-4-E2B-it.litertlm',
    sizeGb: 2.59,
    ram: '4 GB+',
    type: ModelType.gemma4,
    note: 'Versão mais leve do Gemma 4: mais rápida, um pouco menos esperta.',
  ),
  AiModel(
    id: 'qwen3-4b',
    name: 'Qwen3 4B',
    repo: 'litert-community/Qwen3-4B',
    url: 'https://huggingface.co/litert-community/Qwen3-4B/resolve/main/qwen3_4b_mixed_int4.litertlm',
    sizeGb: 2.66,
    ram: '6 GB+',
    type: ModelType.qwen3,
    note: 'Alternativa leve, rápida e muito boa em português.',
  ),
  AiModel(
    id: 'lfm25-12b',
    name: 'LFM2.5 1.2B',
    repo: 'litert-community/LFM2.5-1.2B-Instruct',
    url: 'https://huggingface.co/litert-community/LFM2.5-1.2B-Instruct/resolve/main/LFM2.5-1.2B-Instruct_int4.litertlm',
    sizeGb: 0.74,
    ram: '3 GB+',
    type: ModelType.general,
    note: 'Bem pequeno: ideal para aparelhos com pouca memória ou internet lenta.',
  ),
  AiModel(
    id: 'qwen3-06b',
    name: 'Qwen3 0.6B',
    repo: 'litert-community/Qwen3-0.6B',
    url: 'https://huggingface.co/litert-community/Qwen3-0.6B/resolve/main/Qwen3-0.6B_dynamic_wi4b32_afp32.litertlm',
    sizeGb: 0.34,
    ram: '2 GB+',
    type: ModelType.qwen3,
    note: 'O menor de todos: baixa na internet e roda em qualquer aparelho.',
  ),
  AiModel(
    id: 'gemma4-12b',
    name: 'Gemma 4 12B',
    repo: 'litert-community/gemma-4-12B-it-litert-lm',
    url: 'https://huggingface.co/litert-community/gemma-4-12B-it-litert-lm/resolve/main/gemma-4-12B-it.litertlm',
    sizeGb: 6.88,
    ram: '16 GB+',
    type: ModelType.gemma4,
    note: 'O mais inteligente da lista, mas pesado: só para celulares muito fortes.',
  ),
];

/// Modelo padrão do app (o primeiro da lista).
AiModel get defaultAiModel => aiModels.first;

/// Procura um modelo pelo id.
AiModel? aiModelById(String id) {
  for (final m in aiModels) {
    if (m.id == id) return m;
  }
  return null;
}

/// Procura um modelo pelo endereço do arquivo.
AiModel? aiModelByUrl(String url) {
  final u = url.trim();
  for (final m in aiModels) {
    if (m.url == u) return m;
    if (m.repo == u) return m;
  }
  // também aceita o repositório do Hugging Face
  for (final m in aiModels) {
    if (u.endsWith(m.repo) || u.contains(m.repo)) return m;
  }
  return null;
}
