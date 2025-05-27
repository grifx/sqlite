# JSX-like Syntax in SELECT Statements

## Introduction

SQLite supports a JSX-like syntax directly within the expression list of `SELECT` statements. This feature provides syntactic sugar, transforming the familiar XML/JSX-like notation into standard SQLite function calls. It is designed for developers who wish to generate structured output (like HTML or XML) by leveraging user-defined functions (UDFs) in a more declarative style.

This syntax itself does not perform rendering; it relies on UDFs (typically created with extensions like `sqlean/define`) that are designed to accept data in a specific format derived from the JSX structure.

## Syntax Overview

The JSX-like syntax allows you to write elements resembling XML or JSX tags as expressions in the `SELECT` clause.

**Basic Structure:**

1.  **Elements with children:**
    ```sql
    <TagName attribute1="value1" attribute2={expression1} ... >
      Child1_Text
      {child_expression1}
      <NestedTag attribute3="value3" />
      Child2_Text
      ...
    </TagName>
    ```

2.  **Self-closing elements:**
    ```sql
    <TagName attribute1="value1" attribute2={expression2} ... />
    ```

**Usage in SELECT Statements:**

JSX elements can be used as result columns in a `SELECT` statement:

```sql
SELECT
  <MyComponent id={t.id} class="item">
    Value: {t.value}
    <SubComponent data-value={t.value * 10} />
  </MyComponent> AS component_output
FROM my_table t;
```

## Transformation to Function Calls (Desugaring)

The JSX-like syntax is purely syntactic sugar. Each JSX element is transformed by the parser into a standard SQLite function call.

*   **Tag Name**: The JSX tag name (e.g., `MyComponent`, `div`, `box`) becomes the name of the SQL function to be called.
*   **Arguments**: The function is always called with **two arguments**:
    1.  **Attributes Object**: A JSON object string containing all attributes of the JSX element. This object is constructed by an implicit call to `jsonb_object()`.
        *   Attribute names become JSON object keys (strings).
        *   Attribute values are evaluated:
            *   String literals (e.g., `class="item"`) become JSON string values.
            *   Expressions in braces (e.g., `id={t.id}`) are evaluated, and their results become JSON values (number, string, boolean, or NULL, or nested JSON if the expression returns it).
    2.  **Children Array**: A JSON array string containing all children of the JSX element. This array is constructed by an implicit call to `json_array()`.
        *   **Literal text children**: Become JSON string values in the array.
        *   **`{expression}` children**: The expression is evaluated, and its result is added to the JSON array.
        *   **Nested JSX elements**: Are recursively parsed into their own function calls. The *string result* of that nested function call is then added as a JSON string value to the parent's children array.

**Example Transformation:**

Consider the following JSX-like syntax:

```sql
SELECT
  <MyTag attr1={column_a + 5} attr2="literal value">
    Plain text child.
    {column_b}
    <NestedChildTag score={column_c * 100} />
    Another text.
  </MyTag>
FROM my_data_table;
```

This is desugared by the parser into the following equivalent function call:

```sql
SELECT
  MyTag(
    jsonb_object(
      'attr1', column_a + 5,
      'attr2', 'literal value'
    ),
    json_array(
      'Plain text child.',
      column_b,
      NestedChildTag(
        jsonb_object('score', column_c * 100),
        json_array() -- Assuming NestedChildTag is self-closing or has no children here
      ),
      'Another text.'
    )
  )
FROM my_data_table;
```

## Attributes

Attributes provide properties for a JSX element.

**Syntax:**

*   `name="literal_string_value"`
*   `name={'quoted_string_literal_value'}` (Note: the expression braces are for an SQL expression; if a literal string is desired, it must be an SQL string literal)
*   `name={any_sql_expression}`

**Details:**

*   **Attribute Names**: Treated as identifiers. If an attribute name needs to contain special characters or match an SQL keyword, it should be quoted according to standard SQL identifier quoting rules (e.g., `"data-value"` or `` `data-value` ``). The parser will then use the dequoted string as the JSON key.
*   **Attribute Values**:
    *   **String Literals**: Values enclosed in single or double quotes (e.g., `class="my-class"`) are treated as SQL string literals.
    *   **Expressions**: SQL expressions enclosed in curly braces `{}` are evaluated at runtime. Their result is used as the attribute value. (e.g., `id={t.id}`, `count={ (SELECT COUNT(*) FROM other_table) }`).

## Children

Children define the content within a JSX element.

**Allowed Children Types:**

1.  **Literal Text**: Raw text between tags (or between a tag and an expression, or between expressions) is treated as an SQL string literal.
    ```sql
    <MyTag>This is literal text.</MyTag> 
    -- child: json_array('This is literal text.')
    ```
2.  **SQL Expressions**: SQL expressions enclosed in curly braces `{}` are evaluated, and their results are included as children.
    ```sql
    <MyTag>Value: {t.column1 + 100}</MyTag>
    -- child: json_array('Value: ', t.column1 + 100)
    ```
3.  **Nested JSX Elements**: Other JSX elements can be nested as children. The nested element is fully resolved into its own function call, and the *string result* of that call becomes a child of the parent.
    ```sql
    <OuterTag>
      <InnerTag property="value" />
    </OuterTag>
    -- OuterTag children: json_array( InnerTag(jsonb_object('property','value'), json_array()) )
    ```
4.  **Mixed Content**: A mix of text, expressions, and nested elements is allowed. They will appear in the children JSON array in the order they are defined.
    ```sql
    <Paragraph>
      Count: {get_count()}, Item: <ListItemData id={x}/>.
    </Paragraph>
    -- children: json_array('Count: ', get_count(), ListItemData(jsonb_object('id',x),json_array()), '.')
    ```

## Self-Closing Tags

A tag can be self-closing if it has no children. The syntax is `<TagName attribute="value" />`.

This is equivalent to `<TagName attribute="value"></TagName>`. In terms of the function call transformation, it means the second argument (the children array) will be an empty JSON array, typically generated by `json_array()`.

Example:
```sql
SELECT <MyImage src="/images/logo.png" />
```
is equivalent to:
```sql
SELECT MyImage(
  jsonb_object('src', '/images/logo.png'),
  json_array()
)
```

## Integration with User-Defined Functions (e.g., `sqlean/define`)

This JSX syntax is primarily useful when combined with user-defined functions (UDFs) that can process the structured arguments (attributes object and children array). The `sqlean/define` extension is one such mechanism that allows creating template-based UDFs easily.

A UDF designed to work with this JSX syntax would typically:
1.  Be named after the JSX tag (e.g., UDF named `MyComponent` for `<MyComponent>`).
2.  Accept two text arguments: the JSON attributes string and the JSON children array string.
3.  Inside the UDF, use SQLite's JSON functions (e.g., `json_extract()`, or `->` and `->>` operators with `jsonb` values if `jsonb_object` was used) to access specific attributes and children for rendering or further processing.

**Example with `sqlean/define` conventions:**

If a UDF `MyDiv` is defined using `sqlean/define` like this (conceptual):
```sql
SELECT define('MyDiv', '
  <div id="{{ props->>id }}" class="{{ props->>class }}">
    {{ props->>children }}
  </div>
');
```
Then a JSX expression like:
```sql
SELECT <MyDiv id="main" class="container">Hello {user.name}</MyDiv>
```
would effectively pass:
*   `props`: `jsonb_object('id', 'main', 'class', 'container')`
*   `children`: `json_array('Hello ', user.name)` (Note: `sqlean/define` might have its own conventions for joining children array elements)

The `sqlean/define` extension often uses `props->>'attr_name'` to access attributes and a special template variable like `{:props->>children}` or similar to iterate/render children elements. Refer to the specific documentation of the UDF creation tool for exact templating syntax.

## Error Handling

*   **Parse-time Errors**: Syntax errors in the JSX-like structure (e.g., mismatched tags, malformed attributes, unclosed braces) will be caught by the SQLite parser and reported as standard syntax errors.
    ```sql
    SELECT <MyTag attr={unclosed_expr </MyTag> -- Syntax error near {
    SELECT <MyTag></NotMyTag> -- Error: JSX opening tag <MyTag> does not match closing tag </NotMyTag>
    ```
*   **Runtime Errors**:
    *   **Undefined Function**: If a tag name `SomeTag` is used, but no SQL function named `SomeTag` with two arguments is defined, SQLite will report an "unknown function" error at runtime.
    *   **UDF Errors**: If the UDF itself encounters issues (e.g., expecting different JSON structures, internal errors), it will be responsible for reporting those errors according to its implementation.

## Examples

1.  **Simple HTML-like structure:**
    ```sql
    -- Assuming UDFs 'html', 'head', 'title', 'body', 'h1', 'p' are defined
    SELECT
      <html>
        <head><title>My Page</title></head>
        <body>
          <h1>Welcome, {user.name}!</h1>
          <p class={CASE user.isAdmin WHEN 1 THEN "admin-text" ELSE "user-text" END}>
            Your last login was on {user.last_login_date}.
          </p>
          <MyCustomWidget data-id={user.id} />
        </body>
      </html>
    FROM logged_in_user user; 
    ```

2.  **Data Listing:**
    ```sql
    -- Assuming UDFs 'ul', 'li', 'strong' are defined
    SELECT
      <ul>
        {
          (SELECT group_concat(
            <li>
              <strong class="item-name">{name}</strong>: ${price}
            </li>
          ) FROM items WHERE category = 'electronics')
        }
      </ul>;
    ```
    *(Note: The above example with `group_concat` of JSX elements would require the `<li>` UDF to return text that `group_concat` can concatenate. This demonstrates a more complex use case where JSX results are further processed by SQL functions.)*

## Note on Documentation Placement

This documentation would ideally be placed in a new section dedicated to this syntax (e.g., in `lang_expr.html` under a heading like "JSX Expressions" or on a new page `lang_jsx.html`). Additionally, a brief mention and link should be added to the documentation for the `SELECT` statement (`lang_select.html`) in the section describing result expressions.
