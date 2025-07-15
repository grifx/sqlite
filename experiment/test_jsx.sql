.load /Users/joris/.sqlpkg/nalgeon/define/define.dylib
-- .timer on

-- Define the h function for JSX elements
SELECT define('h', '
  jsonb_object(
    "type", ?1,
    "props", IFNULL(NULL, jsonb(?2)),
    "children", CASE WHEN json_valid(?3, 0x08) AND json_type(?3) = ''array'' THEN jsonb(?3) ELSE ?3 END
  )
');

-- Define common HTML element functions
SELECT define('div', 'h("div", ?1, ?2)');
SELECT define('span', 'h("span", ?1, ?2)');
SELECT define('p', 'h("p", ?1, ?2)');
SELECT define('h1', 'h("h1", ?1, ?2)');
SELECT define('h2', 'h("h2", ?1, ?2)');
SELECT define('button', 'h("button", ?1, ?2)');
SELECT define('input', 'h("input", ?1, ?2)');
SELECT define('table', 'h("table", ?1, ?2)');
SELECT define('tr', 'h("tr", ?1, ?2)');
SELECT define('td', 'h("td", ?1, ?2)');
SELECT define('th', 'h("th", ?1, ?2)');
SELECT define('thead', 'h("thead", ?1, ?2)');
SELECT define('tbody', 'h("tbody", ?1, ?2)');
SELECT define('form', 'h("form", ?1, ?2)');
SELECT define('label', 'h("label", ?1, ?2)');
SELECT define('article', 'h("article", ?1, ?2)');
SELECT define('header', 'h("header", ?1, ?2)');
SELECT define('section', 'h("section", ?1, ?2)');
SELECT define('main', 'h("main", ?1, ?2)');
SELECT define('nav', 'h("nav", ?1, ?2)');
SELECT define('a', 'h("a", ?1, ?2)');
SELECT define('time', 'h("time", ?1, ?2)');
SELECT define('img', 'h("img", ?1, ?2)');
SELECT define('br', 'h("br", ?1, ?2)');
SELECT define('strong', 'h("strong", ?1, ?2)');

SELECT define('to_array', '
  CASE
    WHEN typeof(?1) = ''null'' THEN jsonb_array()
    WHEN json_valid(?1) AND json_type(?1) = ''array'' THEN jsonb(?1)
    WHEN json_valid(?1) THEN jsonb_array(jsonb(?1))
    ELSE jsonb_array(?1)
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

-- Basic JSX Tests
.print "=== BASIC JSX TESTS ==="

.print "Test 1: Simple JSX element"
SELECT json(<div>hello</div>) as test, 
       json('{"type":"div","props":null,"children":"hello"}') as expected;

.print "\nTest 2: JSX with nested elements"
SELECT json(<div>hello <span>world</span></div>) as test,
       json('{"type":"div","props":null,"children":[{"type":"span","props":null,"children":"world"}]}') as expected;

.print "\nTest 3: JSX with attributes"
SELECT json(<div class="test">content</div>) as test,
       json('{"type":"div","props":{"class":"test"},"children":"content"}') as expected;

.print "\nTest 4: More complex nesting"
SELECT json(<div><h1>Title</h1><p>Paragraph</p></div>) as test,
       json('{"type":"div","props":null,"children":[{"type":"h1","props":null,"children":"Title"},{"type":"p","props":null,"children":"Paragraph"}]}') as expected;

.print "\nTest 5: Multiple siblings"
SELECT json(<div><span>First</span><span>Second</span></div>) as test,
       json('{"type":"div","props":null,"children":[{"type":"span","props":null,"children":"First"},{"type":"span","props":null,"children":"Second"}]}') as expected;

.print "\nTest 6: Mixed content"
SELECT json(<div>Before <span>middle</span> after</div>) as test,
       json('{"type":"div","props":null,"children":[{"type":"span","props":null,"children":"middle"}]}') as expected;

.print "\nTest 7: Empty element"
SELECT json(<div></div>) as test,
       json('{"type":"div","props":null,"children":null}') as expected;

.print "\nTest 8: Button with text"
SELECT json(<button>Click me</button>) as test,
       json('{"type":"button","props":null,"children":"Click me"}') as expected;

.print "\n=== JSX FRAGMENT TESTS ==="

.print "Test 9: Simple JSX Fragment"
SELECT json(<Fragment><span>First</span><span>Second</span></Fragment>) as test,
       json('[{"type":"span","props":null,"children":"First"},{"type":"span","props":null,"children":"Second"}]') as expected;

.print "\nTest 10: Fragment with mixed content"
SELECT json(<Fragment>Before <span>middle</span> after</Fragment>) as test,
       json('[{"type":"span","props":null,"children":"middle"}]') as expected;

.print "\nTest 11: Nested fragments"
SELECT json(
  <div>
    <Fragment>
      <h1>Title</h1>
      <p>Content</p>
    </Fragment>
  </div>
) as test,
json('{"type":"div","props":null,"children":[{"type":"h1","props":null,"children":"Title"},{"type":"p","props":null,"children":"Content"}]}') as expected;

.print "\nTest 12: Complex nesting with fragments"
SELECT json(
  <article>
    <header>
      <Fragment>
        <h1>Article Title</h1>
        <p>By Author</p>
      </Fragment>
    </header>
    <section>
      <p>Article content</p>
    </section>
  </article>
) as test,
json('{"type":"article","props":null,"children":[{"type":"header","props":null,"children":[{"type":"h1","props":null,"children":"Article Title"},{"type":"p","props":null,"children":"By Author"}]},{"type":"section","props":null,"children":{"type":"p","props":null,"children":"Article content"}}]}') as expected;

-- Advanced JSX Tests
.print "\n=== ADVANCED JSX TESTS ==="

.print "Test 13: Self-closing tags with attributes"
SELECT json(<img src="image.jpg" alt="Description"/>) as test,
       json('{"type":"img","props":{"src":"image.jpg","alt":"Description"},"children":null}') as expected;
       
SELECT json(<input type="text" placeholder="Enter name"/>) as test,
       json('{"type":"input","props":{"type":"text","placeholder":"Enter name"},"children":null}') as expected;
       
SELECT json(<br class="spacer"/>) as test,
       json('{"type":"br","props":{"class":"spacer"},"children":null}') as expected;

.print "\nTest 14: Multi-attribute elements"
SELECT json(<div class="container" id="main" style="color: red;">Styled content</div>) as test,
       json('{"type":"div","props":{"class":"container","id":"main","style":"color: red;"},"children":"Styled content"}') as expected;
       
SELECT json(<button type="submit" disabled>Submit</button>) as test,
       json('{"type":"button","props":{"type":"submit","disabled":true},"children":"Submit"}') as expected;
       
SELECT json(<a href="https://example.com" target="_blank">Link</a>) as test,
       json('{"type":"a","props":{"href":"https://example.com","target":"_blank"},"children":"Link"}') as expected;

.print "\nTest 15: Form elements with fragments"
SELECT json(
  <form>
    <Fragment>
      <label>Name</label>
      <input type="text"/>
    </Fragment>
    <Fragment>
      <label>Email</label>
      <input type="email"/>
    </Fragment>
    <button type="submit">Submit</button>
  </form>
) as test,
json('{"type":"form","props":null,"children":[{"type":"label","props":null,"children":"Name"},{"type":"input","props":{"type":"text"},"children":null},{"type":"label","props":null,"children":"Email"},{"type":"input","props":{"type":"email"},"children":null},{"type":"button","props":{"type":"submit"},"children":"Submit"}]}') as expected;

.print "\nTest 16: Table with fragments"
SELECT json(
  <table>
    <thead>
      <tr>
        <Fragment>
          <th>Name</th>
          <th>Age</th>
          <th>City</th>
        </Fragment>
      </tr>
    </thead>
    <tbody>
      <tr>
        <Fragment>
          <td>John</td>
          <td>25</td>
          <td>NYC</td>
        </Fragment>
      </tr>
    </tbody>
  </table>
) as test,
json('{"type":"table","props":null,"children":[{"type":"thead","props":null,"children":{"type":"tr","props":null,"children":[{"type":"th","props":null,"children":"Name"},{"type":"th","props":null,"children":"Age"},{"type":"th","props":null,"children":"City"}]}},{"type":"tbody","props":null,"children":{"type":"tr","props":null,"children":[{"type":"td","props":null,"children":"John"},{"type":"td","props":null,"children":"25"},{"type":"td","props":null,"children":"NYC"}]}}]}') as expected;

.print "\nTest 17: Deep nesting with fragments"
SELECT json(
  <div>
    <div>
      <Fragment>
        <div>
          <Fragment>
            <p>Deeply nested content</p>
            <span>With fragments</span>
          </Fragment>
        </div>
      </Fragment>
    </div>
  </div>
) as test,
json('{"type":"div","props":null,"children":{"type":"div","props":null,"children":{"type":"div","props":null,"children":[{"type":"p","props":null,"children":"Deeply nested content"},{"type":"span","props":null,"children":"With fragments"}]}}}') as expected;

.print "\nTest 18: Navigation with fragments"
SELECT json(
  <nav>
    <Fragment>
      <a href="/">Home</a>
      <a href="/about">About</a>
      <a href="/contact">Contact</a>
    </Fragment>
  </nav>
) as test,
json('{"type":"nav","props":null,"children":[{"type":"a","props":{"href":"/"},"children":"Home"},{"type":"a","props":{"href":"/about"},"children":"About"},{"type":"a","props":{"href":"/contact"},"children":"Contact"}]}') as expected;

.print "\nTest 19: Empty fragment"
SELECT json(<Fragment></Fragment>) as test,
       json('[]') as expected;

.print "\nTest 20: Fragment with single child"
SELECT json(<Fragment><div>Single child</div></Fragment>) as test,
       json('[{"type":"div","props":null,"children":"Single child"}]') as expected;

.print "\nTest 21: Make sure <> is not treated as JSX fragment"
SELECT 1 <> 2 as test, 1 as expected;

-- Additional Tests for Better Coverage
.print "\n=== ADDITIONAL JSX TESTS ==="

.print "Test 22: JSX with expressions in attributes"
SELECT json(<div id={'item_' || 42} class="active">Dynamic attributes</div>) as test,
       json('{"type":"div","props":{"id":"item_42","class":"active"},"children":"Dynamic attributes"}') as expected;

.print "\nTest 23: JSX with SQL functions in content"
SELECT json(<div>Time {datetime('now')} Random {random()}</div>) as test,
       'JSON with current time and random number' as expected_note;

.print "\nTest 24: JSX with different data types"
SELECT json(<div>Number {42} Boolean {1 = 1} Null {NULL} Text {'hello'}</div>) as test,
       json('{"type":"div","props":null,"children":"Number 42 Boolean 1 Null  Text hello"}') as expected;

.print "\nTest 25: JSX with mathematical expressions"
SELECT json(<div>Result {5 + 3 * 2} Square {4 * 4} Float {22.0 / 7}</div>) as test,
       json('{"type":"div","props":null,"children":"Result 11 Square 16 Float 3.14285714285714"}') as expected;

.print "\nTest 26: JSX with subqueries"
WITH test_data AS (SELECT 'Alice' as name, 30 as age UNION SELECT 'Bob', 25)
SELECT json(<div>Count {(SELECT COUNT(*) FROM test_data)} Max age {(SELECT MAX(age) FROM test_data)}</div>) as test,
       json('{"type":"div","props":null,"children":"Count 2 Max age 30"}') as expected;

.print "\nTest 27: JSX with conditional expressions"
SELECT json(<div class={CASE WHEN 10 > 5 THEN 'greater' ELSE 'lesser' END}>Conditional</div>) as test,
       json('{"type":"div","props":{"class":"greater"},"children":"Conditional"}') as expected;

.print "\nTest 28: JSX with JSON data"
SELECT json(<div>JSON {json_object('key', 'value', 'num', 123)}</div>) as test,
       json('{"type":"div","props":null,"children":"JSON {\"key\":\"value\",\"num\":123}"}') as expected;

.print "\nTest 29: JSX with special characters"
SELECT json(<div>Special {'Hello World & tags'} {char(10)} New line</div>) as test,
       'JSON with special characters and newline' as expected_note;

.print "\nTest 31: JSX with empty attributes"
SELECT json(<div class="" id={''}>Empty attributes</div>) as test,
       json('{"type":"div","props":{"class":"","id":""},"children":"Empty attributes"}') as expected;

.print "\nTest 32: JSX with nested expressions and functions"
SELECT json(<div>Length {length('hello')} Upper {upper('nested')}</div>) as test,
       json('{"type":"div","props":null,"children":"Length 5 Upper NESTED"}') as expected;

.print "\nTest 33: JSX with array-like content"
SELECT json(<div>{json_array('item1', 'item2', 'item3')}</div>) as test,
       json('{"type":"div","props":null,"children":"[\"item1\",\"item2\",\"item3\"]"}') as expected;

.print "\nTest 34: JSX with string concatenation"
SELECT json(<div>Full name {('John' || ' ' || 'Doe')}</div>) as test,
       json('{"type":"div","props":null,"children":"Full name John Doe"}') as expected;

.print "\nTest 35: JSX with multiple expressions in one element"
SELECT json(<div>A {1} B {2} C {3} Sum {1+2+3}</div>) as test,
       json('{"type":"div","props":null,"children":"A 1 B 2 C 3 Sum 6"}') as expected;

.print "\nTest 36: JSX fragments with expressions"
SELECT json(<Fragment><p>First {1}</p><p>Second {2}</p><p>Third {3}</p></Fragment>) as test,
       json('[{"type":"p","props":null,"children":"First 1"},{"type":"p","props":null,"children":"Second 2"},{"type":"p","props":null,"children":"Third 3"}]') as expected;

.print "\nTest 37: JSX with COALESCE and NULL handling"
SELECT json(<div>Value {COALESCE(NULL, 'default')} Null {NULL}</div>) as test,
       json('{"type":"div","props":null,"children":"Value default Null "}') as expected;

.print "\nTest 38: JSX with boolean expressions"
SELECT json(<div>True {1=1} False {1=0} Greater {5>3}</div>) as test,
       json('{"type":"div","props":null,"children":"True 1 False 0 Greater 1"}') as expected;

.print "\nTest 39: JSX with nested function calls"
SELECT json(<div>Nested {substr(upper('hello'), 1, 3)}</div>) as test,
       json('{"type":"div","props":null,"children":"Nested HEL"}') as expected;

.print "\nTest 40: JSX with expressions in self-closing tags"
SELECT json(<input type="text" value={42} placeholder={'Enter ' || 'value'} />) as test,
       json('{"type":"input","props":{"type":"text","value":42,"placeholder":"Enter value"},"children":null}') as expected;

-- Keyword Handling Tests
.print "\n=== KEYWORD HANDLING TESTS ==="

.print "Test 41: JSX with NULL keyword"
SELECT json(<div>NULL</div>) as test,
       json('{"type":"div","props":null,"children":"NULL"}') as expected;

.print "\nTest 42: JSX with all SQLite keywords"
SELECT json(<div>ABORT ACTION ADD AFTER ALL ALTER ANALYZE AND AS ASC ATTACH AUTOINCREMENT BEFORE BEGIN BETWEEN BY CASCADE CASE CAST CHECK COLLATE COLUMN COMMIT CONFLICT CONSTRAINT CREATE CROSS CURRENT_DATE CURRENT_TIME CURRENT_TIMESTAMP DATABASE DEFAULT DEFERRABLE DEFERRED DELETE DESC DETACH DISTINCT DROP EACH ELSE END ESCAPE EXCEPT EXCLUSIVE EXISTS EXPLAIN FAIL FALSE FILTER FIRST FOLLOWING FOR FOREIGN FROM FULL GLOB GROUP HAVING IF IGNORE IMMEDIATE IN INDEX INDEXED INITIALLY INNER INSERT INSTEAD INTERSECT INTO IS ISNULL JOIN KEY LEFT LIKE LIMIT MATCH NATURAL NO NOT NOTNULL NULL OF OFFSET ON OR ORDER OUTER PLAN PRAGMA PRIMARY QUERY RAISE RECURSIVE REFERENCES REGEXP REINDEX RELEASE RENAME REPLACE RESTRICT RIGHT ROLLBACK ROW ROWS SAVEPOINT SELECT SET TABLE TEMP TEMPORARY THEN TO TRANSACTION TRIGGER UNBOUNDED UNION UNIQUE UPDATE USING VACUUM VALUES VIEW VIRTUAL WHEN WHERE WINDOW WITH WITHOUT</div>) as test,
       json('{"type":"div","props":null,"children":"ABORT ACTION ADD AFTER ALL ALTER ANALYZE AND AS ASC ATTACH AUTOINCREMENT BEFORE BEGIN BETWEEN BY CASCADE CASE CAST CHECK COLLATE COLUMN COMMIT CONFLICT CONSTRAINT CREATE CROSS CURRENT_DATE CURRENT_TIME CURRENT_TIMESTAMP DATABASE DEFAULT DEFERRABLE DEFERRED DELETE DESC DETACH DISTINCT DROP EACH ELSE END ESCAPE EXCEPT EXCLUSIVE EXISTS EXPLAIN FAIL FALSE FILTER FIRST FOLLOWING FOR FOREIGN FROM FULL GLOB GROUP HAVING IF IGNORE IMMEDIATE IN INDEX INDEXED INITIALLY INNER INSERT INSTEAD INTERSECT INTO IS ISNULL JOIN KEY LEFT LIKE LIMIT MATCH NATURAL NO NOT NOTNULL NULL OF OFFSET ON OR ORDER OUTER PLAN PRAGMA PRIMARY QUERY RAISE RECURSIVE REFERENCES REGEXP REINDEX RELEASE RENAME REPLACE RESTRICT RIGHT ROLLBACK ROW ROWS SAVEPOINT SELECT SET TABLE TEMP TEMPORARY THEN TO TRANSACTION TRIGGER UNBOUNDED UNION UNIQUE UPDATE USING VACUUM VALUES VIEW VIRTUAL WHEN WHERE WINDOW WITH WITHOUT"}') as expected;

.print "\n=== JSX TESTS COMPLETE ==="

SELECT define_free();