WITH date_range AS (
  SELECT DATEADD(DAY, SEQ4(), '2018-01-01'::DATE) AS date
  FROM TABLE(GENERATOR(ROWCOUNT => 6574)) -- Number of days from 2018-01-01 to 2035-12-31
)
SELECT
  date::DATE AS date,
  TO_CHAR(date, 'YYYYMMDD') :: INTEGER AS date_code,
  TO_CHAR(date, 'YYYYMM') :: INTEGER   AS Year_Month_Num,
  TO_CHAR(DATEADD(MONTH, -1, date), 'YYYYMM') :: INTEGER AS Previous_Year_Month_Num,
  TO_CHAR(date, 'YYYY-MON') AS Year_Month,
  TO_CHAR(DATEADD(MONTH, -1, date), 'YYYY-MON') AS Previous_Year_Month,
  TO_CHAR(DATEADD(YEAR, -1, date), 'YYYY') AS Previous_Year,
  TO_CHAR('Q' || QUARTER(date) )  AS Quarter,
  TO_CHAR(date, 'YYYY') ||'-Q' || QUARTER(date)   AS Year_Quarter,
  DATE_TRUNC('WEEK', date)::DATE AS first_day_of_week,
  DATE_TRUNC('MONTH', date)::DATE AS first_day_of_month,
  DATE_TRUNC('QUARTER', date)::DATE AS first_day_of_quarter,
  DATE_TRUNC('YEAR', date)::DATE AS first_day_of_year,
  TO_CHAR(date, 'YYYY') :: INTEGER  as Year,
  CONCAT('W', LPAD(WEEKOFYEAR(date)::STRING, 2, '0'),'-',TO_CHAR(date, 'YYYY')) AS week_of_year,
  DAYNAME(date) AS day_name,
  MONTHNAME(date) AS Month_name,
  DAYOFWEEK(date) AS day_of_week_number,
  DAY(date) AS day_of_month
FROM date_range
WHERE date <= '2035-12-31'::DATE
ORDER BY date