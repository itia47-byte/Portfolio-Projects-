CREATE VIEW vw_invoices AS
SELECT
doc_id AS InvoiceId,
cust_number AS CustomerNumber,
name_customer AS CustomerName,
business_code AS BusinessCode,
invoice_currency AS Currency,
cust_payment_terms AS PaymentTerms,
CAST(posting_date AS DATE) AS PostingDate,
CONVERT(DATE, CAST(CAST(due_in_date AS BIGINT) AS CHAR(8)), 112) AS 
DueDate,
CAST(clear_date AS DATE) AS ClearDate,
CASE WHEN invoice_currency = 'CAD' THEN total_open_amount * 0.75
ELSE total_open_amount END AS AmountUSD
FROM invoices_clean; 





SELECT TOP 10 * FROM invoices_raw;

SELECT doc_id, COUNT(*) AS Copies
FROM invoices_raw
GROUP BY doc_id
HAVING COUNT(*) > 1;

SELECT DISTINCT *
INTO invoices_clean
FROM invoices_raw;
SELECT COUNT(*) FROM invoices_raw;    -- before
SELECT COUNT(*) FROM invoices_clean;  -- after


