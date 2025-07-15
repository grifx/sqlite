.load /Users/joris/.sqlpkg/nalgeon/define/define.dylib

SELECT define('render', 'json(?1)');
SELECT define('ReusableComponent', '<Fragment>Hello {:props->>"displayName"}!</Fragment>');

.print "Comprehensive JSX Test"
.timer on

WITH 
invoice_items(description, quantity, price) AS (
  VALUES
    ('Item A', 2, 25.0),
    ('Item B', 1, 100.0),
    ('Item C', 3, 15.0)
),
line_items AS (
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
)
SELECT render(
  <div class="invoice">
    <h1>Invoice #{substr(abs(random()), 1, 5)}</h1>

    <table border="1" cellpadding="5">
      <caption>Invoice Line Items</caption>
      <tbody>
        {(
          SELECT jsonb_group_array(
            <tr>
              <td>{description}</td>
              <td>{quantity}</td>
              <td>{price}</td>
              <td>{total}</td>
            </tr>
          ) FROM line_items
        )}
      </tbody>
    </table>

    <ReusableComponent displayName="Joris" />
  </div>
) AS invoice;


SELECT define_free();