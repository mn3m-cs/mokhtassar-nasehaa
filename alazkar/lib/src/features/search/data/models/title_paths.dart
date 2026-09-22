import 'package:alazkar/src/core/models/zikr_title.dart';

Map<int, String> buildTitlePaths(List<ZikrTitle> titles) {
  final titlesById = {for (final title in titles) title.id: title};
  return {
    for (final title in titles) title.id: _buildTitlePath(title, titlesById),
  };
}

String _buildTitlePath(
  ZikrTitle title,
  Map<int, ZikrTitle> titlesById,
) {
  final names = <String>[];
  ZikrTitle? current = title;
  while (current != null) {
    names.add(current.name);
    current = current.parentId == null ? null : titlesById[current.parentId]!;
  }
  return names.reversed.join(' ← ');
}
