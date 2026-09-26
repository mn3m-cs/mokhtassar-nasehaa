import 'package:alazkar/src/core/models/zikr_title.dart';
import 'package:alazkar/src/features/search/data/models/title_paths.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('deep results include every ancestor when sibling names repeat', () {
    const titles = [
      ZikrTitle(
        id: 1,
        order: 1,
        name: 'العبادات',
        freq: 'd',
        nodeType: ZikrTitleNodeType.category,
      ),
      ZikrTitle(
        id: 2,
        order: 1,
        name: 'الصلاة',
        freq: 'd',
        parentId: 1,
        nodeType: ZikrTitleNodeType.category,
      ),
      ZikrTitle(
        id: 3,
        order: 1,
        name: 'أذكار',
        freq: 'd',
        parentId: 2,
      ),
      ZikrTitle(
        id: 4,
        order: 2,
        name: 'المعاملات',
        freq: 'd',
        nodeType: ZikrTitleNodeType.category,
      ),
      ZikrTitle(
        id: 5,
        order: 1,
        name: 'أذكار',
        freq: 'd',
        parentId: 4,
      ),
    ];

    final paths = buildTitlePaths(titles);

    expect(paths[3], 'العبادات ← الصلاة ← أذكار');
    expect(paths[5], 'المعاملات ← أذكار');
  });

  test('the viewer header shows only the categories above a section', () {
    const category = ZikrTitle(
      id: 1,
      order: 1,
      name: 'العبادات',
      freq: 'd',
      nodeType: ZikrTitleNodeType.category,
    );
    const subcategory = ZikrTitle(
      id: 2,
      order: 1,
      name: 'الصلاة',
      freq: 'd',
      parentId: 1,
      nodeType: ZikrTitleNodeType.category,
    );
    const nested = ZikrTitle(
      id: 3,
      order: 1,
      name: 'أذكار',
      freq: 'd',
      parentId: 2,
    );
    const topLevel = ZikrTitle(id: 4, order: 2, name: 'الوضوء', freq: 'd');
    const titles = [category, subcategory, nested, topLevel];

    expect(buildParentPath(nested, titles), 'العبادات ← الصلاة');
    expect(buildParentPath(topLevel, titles), '');
  });
}
