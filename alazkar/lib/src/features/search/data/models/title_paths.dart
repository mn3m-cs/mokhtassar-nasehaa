import 'package:alazkar/src/core/models/zikr_title.dart';

Map<int, String> buildTitlePaths(List<ZikrTitle> titles) {
  final titlesById = {for (final title in titles) title.id: title};
  return {
    for (final title in titles) title.id: _buildTitlePath(title, titlesById),
  };
}

/// Path of the categories above [title], empty for a top-level section.
String buildParentPath(ZikrTitle title, List<ZikrTitle> titles) {
  final titlesById = {for (final title in titles) title.id: title};
  final parent = title.parentId == null ? null : titlesById[title.parentId];
  return parent == null
      ? ''
      : _buildTitlePath(parent, titlesById, separator: ' › ');
}

String _buildTitlePath(
  ZikrTitle title,
  Map<int, ZikrTitle> titlesById, {
  String separator = ' ← ',
}) {
  final names = <String>[];
  ZikrTitle? current = title;
  while (current != null) {
    names.add(current.name);
    current = current.parentId == null ? null : titlesById[current.parentId]!;
  }
  return names.reversed.join(separator);
}
