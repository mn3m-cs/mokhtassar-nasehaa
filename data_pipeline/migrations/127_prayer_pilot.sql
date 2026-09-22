PRAGMA foreign_keys = ON;
BEGIN;

INSERT INTO titles (id, `order`, name, freq, parentId, nodeType)
VALUES (96, 96, 'الصلاة', 'd', NULL, 'category');

INSERT INTO titles (id, `order`, name, freq, parentId, nodeType)
VALUES (97, 2, 'أذكار داخل الصلاة — تصنيف تنظيمي', 'd', 96, 'category');

UPDATE titles SET parentId = 97, `order` = 1 WHERE id = 10;
UPDATE titles SET parentId = 97, `order` = 2 WHERE id = 11;
UPDATE titles SET parentId = 97, `order` = 3 WHERE id = 12;
UPDATE titles SET parentId = 97, `order` = 4 WHERE id = 13;
UPDATE titles SET parentId = 97, `order` = 5 WHERE id = 17;
UPDATE titles SET parentId = 97, `order` = 6 WHERE id = 14;
UPDATE titles SET parentId = 97, `order` = 7 WHERE id = 15;
UPDATE titles SET parentId = 96, `order` = 3 WHERE id = 16;

UPDATE titles SET `order` = 12 WHERE id = 96;

INSERT INTO titles (id, `order`, name, freq, parentId, nodeType)
VALUES (98, 1, 'تمهيد أذكار الصلاة', 'd', 96, 'content');

INSERT INTO contents (
  id, titleId, `order`, body, count, source, hokm, fadl, search, sourceIndex
) VALUES (
  1006,
  98,
  1,
  'هذا ما ورد من الأذكار في دعاء التوجه، فيستحب الجمع بينها كلها لمن صلى منفردًا، وللإمام إذا أذن له المأمومون، فأما إذا لم يأذنوا له فلا يطول عليهم، بل يقتصر على بعض ذلك.',
  0,
  'تمهيد أذكار الصلاة. (ص49)',
  '',
  '',
  'هذا ما ورد من الأذكار في دعاء التوجه فيستحب الجمع بينها كلها لمن صلى منفردا وللإمام إذا أذن له المأمومون فأما إذا لم يأذنوا له فلا يطول عليهم بل يقتصر على بعض ذلك',
  ''
);

PRAGMA user_version = 127;
COMMIT;
