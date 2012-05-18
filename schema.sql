CREATE TABLE comment (
    "id" INTEGER,
    "article_id" NUMERIC,
    "content" TEXT,
    "date_create" TIMESTAMP DEFAULT ('CURRENT_TIMESTAMP')
, "deleted" TEXT   DEFAULT (0));
CREATE TABLE article (
    "id" INTEGER,
    "title" TEXT,
    "content" TEXT,
    "date_create" TIMESTAMP DEFAULT ('CURRENT_TIMESTAMP'),
    "deleted" INTEGER DEFAULT (0)
);
