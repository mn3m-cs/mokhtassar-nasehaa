PRAGMA foreign_keys = ON;

BEGIN IMMEDIATE;

ALTER TABLE titles
ADD COLUMN parentId INTEGER REFERENCES titles(id) ON UPDATE CASCADE ON DELETE RESTRICT;

ALTER TABLE titles
ADD COLUMN nodeType TEXT NOT NULL DEFAULT 'content'
CHECK (nodeType IN ('category', 'content'));

CREATE UNIQUE INDEX titles_root_order_unique
ON titles("order")
WHERE parentId IS NULL;

CREATE UNIQUE INDEX titles_sibling_order_unique
ON titles(parentId, "order")
WHERE parentId IS NOT NULL;

CREATE TRIGGER titles_parent_must_be_category_insert
BEFORE INSERT ON titles
WHEN NEW.parentId IS NOT NULL
BEGIN
  SELECT RAISE(ABORT, 'title parent must be a category')
  WHERE COALESCE(
    (SELECT nodeType FROM titles WHERE id = NEW.parentId),
    ''
  ) <> 'category';
END;

CREATE TRIGGER titles_parent_must_be_category_update
BEFORE UPDATE OF parentId ON titles
WHEN NEW.parentId IS NOT NULL
BEGIN
  SELECT RAISE(ABORT, 'title parent must be a category')
  WHERE COALESCE(
    (SELECT nodeType FROM titles WHERE id = NEW.parentId),
    ''
  ) <> 'category';
END;

CREATE TRIGGER titles_hierarchy_cycle_insert
BEFORE INSERT ON titles
WHEN NEW.parentId IS NOT NULL
BEGIN
  SELECT RAISE(ABORT, 'title hierarchy cycle')
  WHERE NEW.parentId = NEW.id;
END;

CREATE TRIGGER titles_hierarchy_cycle_update
BEFORE UPDATE OF parentId ON titles
WHEN NEW.parentId IS NOT NULL
BEGIN
  SELECT RAISE(ABORT, 'title hierarchy cycle')
  WHERE NEW.parentId = NEW.id
     OR EXISTS (
       WITH RECURSIVE ancestors(id, parentId) AS (
         SELECT id, parentId
         FROM titles
         WHERE id = NEW.parentId

         UNION ALL

         SELECT titles.id, titles.parentId
         FROM titles
         JOIN ancestors ON titles.id = ancestors.parentId
       )
       SELECT 1
       FROM ancestors
       WHERE id = NEW.id
     );
END;

CREATE TRIGGER titles_category_cannot_have_contents
BEFORE UPDATE OF nodeType ON titles
WHEN NEW.nodeType = 'category'
 AND EXISTS (SELECT 1 FROM contents WHERE titleId = NEW.id)
BEGIN
  SELECT RAISE(ABORT, 'category cannot have contents');
END;

CREATE TRIGGER titles_content_cannot_have_children
BEFORE UPDATE OF nodeType ON titles
WHEN NEW.nodeType = 'content'
 AND EXISTS (SELECT 1 FROM titles WHERE parentId = NEW.id)
BEGIN
  SELECT RAISE(ABORT, 'content title cannot have children');
END;

CREATE TRIGGER contents_title_must_be_content_insert
BEFORE INSERT ON contents
BEGIN
  SELECT RAISE(ABORT, 'contents require a content title')
  WHERE COALESCE(
    (SELECT nodeType FROM titles WHERE id = NEW.titleId),
    ''
  ) <> 'content';
END;

CREATE TRIGGER contents_title_must_be_content_update
BEFORE UPDATE OF titleId ON contents
BEGIN
  SELECT RAISE(ABORT, 'contents require a content title')
  WHERE COALESCE(
    (SELECT nodeType FROM titles WHERE id = NEW.titleId),
    ''
  ) <> 'content';
END;

PRAGMA user_version = 126;

COMMIT;
