.load /Users/joris/.sqlpkg/nalgeon/define/define.dylib
.timer on

-- SELECT define('h', '
--   "<" || ?1 ||
--   COALESCE(
--     (SELECT group_concat( " " || key || ''="'' || value || ''"'', "") FROM json_each(?2)),
--     ""
--   ) || ">" || 
--   CASE
--     WHEN json_valid(?3) AND json_type(?3) = ''array'' THEN COALESCE((SELECT group_concat(value, " ") FROM json_each(?3)), "")
--     ELSE ?3
--   END ||
--   "</" || ?1 || ">"
-- ');

-- WITH 
-- invoice_items(description, quantity, price) AS (
--   VALUES
--     ('Item A', 2, 25.0),
--     ('Item B', 1, 100.0),
--     ('Item C', 3, 15.0)
-- )
-- SELECT h('div', json_object('class', 'invoice'), json_array(
--   h('h1', null, 'Invoice #' || abs(random())),
--   h('table', json_object('border', '1', 'cellpadding', '5'), json_array(
--     h('tr', null, json_array(
--       h('th', null, 'Description'),
--       h('th', null, 'Quantity'),
--       h('th', null, 'Price'),
--       h('th', null, 'Total')
--     )),
--     (
--       SELECT group_concat(
--         h('tr', null, json_array(
--           h('td', null, description),
--           h('td', null, quantity),
--           h('td', null, price),
--           h('td', null, quantity * price)
--         )), ''
--       )
--       FROM invoice_items
--     )
--   ))
-- )) AS html_invoice;
-- SELECT define_free();

-- Define h(tag, attrs_json, children)
-- SELECT define('h', '
--   jsonb_array(
--     ?1,
--     IFNULL(NULL, jsonb(?2)),
--     CASE WHEN json_valid(?3, 0x08) AND json_type(?3) = ''array'' THEN jsonb(?3) ELSE jsonb_array(?3) END
--   )
-- ');

SELECT define('h', '
  jsonb_object(
    "type", ?1,
    "props", IFNULL(NULL, jsonb(?2)),
    "children", CASE WHEN json_valid(?3, 0x08) AND json_type(?3) = ''array'' THEN jsonb(?3) ELSE ?3 END
  )
');


SELECT define('to_array', '
  CASE
    WHEN typeof(?1) = ''null'' THEN jsonb_array("a")
    WHEN json_valid(?1) AND json_type(?1) = ''array'' THEN jsonb(?1)
    WHEN json_valid(?1) THEN jsonb_array(jsonb(?1))
    ELSE jsonb_array()
  END
');

SELECT define('array_merge', '
  CASE
    WHEN jsonb(?1) = jsonb_array() AND jsonb(?2) = jsonb_array() THEN jsonb_array()
    WHEN json(?1) = jsonb_array() THEN jsonb(?2)
    WHEN json(?2) = jsonb_array() THEN jsonb(?1)
    ELSE
      jsonb(
        ''['' ||
        substr(json(?1), 2, length(json(?1)) - 2) || '','' ||
        substr(json(?2), 2, length(json(?2)) - 2) ||
        '']''
      )
  END
');

SELECT define('list', '
  array_merge(to_array(?1), to_array(?2))
');

SELECT json(list(1, 2));               -- [1,2]
SELECT json(list('[1,2]', 3));         -- [1,2,3]
SELECT json(list(null, '"a"'));        -- ["a"]
SELECT json(list('{"x":1}', '[2,3]')); -- [{"x":1},2,3]
SELECT json(list('[1,2]', '[3,[4]]')); -- [1,2,3,[4]]

WITH 
invoice_items(description, quantity, price) AS (
  VALUES
    ('Item A', 2, 25.0),
    ('Item B', 1, 100.0),
    ('Item C', 3, 15.0)
),
table_header AS (
  SELECT jsonb_group_array(
    h('tr', null, jsonb_array(
      h('th', null, 'Description'),
      h('th', null, 'Quantity'),
      h('th', null, 'Price'),
      h('th', null, 'Total')
    ))
  )
),
table_rows AS (
  SELECT jsonb_group_array(
    h('tr', null, jsonb_array(
      h('td', null, description),
      h('td', null, quantity),
      h('td', null, price),
      h('td', null, quantity * price)
    ))
  ) FROM invoice_items
),
table_data AS (
  SELECT 
    'Description' AS description,
    'Quantity' AS quantity,
    'Price' AS price,
    'Total' AS total
  UNION ALL
  SELECT 
    description, 
    quantity, 
    price, 
    quantity * price AS total
  FROM invoice_items
),
invoice AS (
  SELECT
    h('div', jsonb_object('class', 'invoice'), jsonb_array(
      h('h1', null, 'Invoice #' || abs(random())),
      h('table', jsonb_object('border', '1', 'cellpadding', '5'),
        array_merge(
          (SELECT * from table_header),
          (SELECT * from table_rows)
        )
      ),
      h('table', jsonb_object('border', '1', 'cellpadding', '5'),
        list(
          h('caption', null, 'Invoice Items'),
          (
            SELECT jsonb_group_array(
              h('tr', null, jsonb_array(
                h('td', null, description),
                h('td', null, quantity),
                h('td', null, price),
                h('td', null, total)
              ))
            ) FROM table_data
          )
        )
      )
    )) AS tree
)
SELECT json(tree) FROM invoice;

SELECT define_free();