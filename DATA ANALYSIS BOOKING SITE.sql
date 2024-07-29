Use database1;
---company revenue by year---
WITH sum_year AS (SELECT
	Year(createdon_date) as year, 
	round(sum(sysfee_total_usd), 2) as company_revenue 
	FROM analytic_test_booking
	GROUP BY Year(createdon_date))
SELECT 
	*, 
    ROUND((((company_revenue - LAG(company_revenue)over(order by year))/LAG(company_revenue)over(order by year))*100),2) as percent
FROM sum_year;

---MoM changes in Net price for top 10 routes in Asia---
/* find top 10 routes in Asia*/
/*common table expression(CTE), as we need to get top 10 values later in code*/
WITH in_asia AS
(SELECT  
	from_id, 
    to_id, 
    class_id,
    operator_id, 
    from_country_id, 
    to_country_id,
    count(bid) as amount 
    FROM analytic_test_booking
/* specify region using ISO codes taken from http://www.geocountries.com/country/codes/asia*/
	WHERE to_country_id IN ('YE','VN', 'UZ', 'AE','TM', 'TR', 'TH', 'TJ', 'TW', 'SY','LK', 'KR','SG','SA', 'QA','PH', 'PS','PK', 'OM', 'KP', 'NP', 'MM', 'MN', 'MV', 'MY', 'MO', 'LB', 'LA', 'KG', 'KW','KZ','JO', 'JP', 'IL', 'IQ','IR','ID','IN','HK','GE','CC','CN','KH','BN','IO','BT', 'BD','BH','AZ','AM','AF')
	AND from_country_id IN ('YE','VN', 'UZ', 'AE','TM', 'TR', 'TH', 'TJ', 'TW', 'SY','LK', 'KR','SG','SA', 'QA','PH', 'PS','PK', 'OM', 'KP', 'NP', 'MM', 'MN', 'MV', 'MY', 'MO', 'LB', 'LA', 'KG', 'KW','KZ','JO', 'JP', 'IL', 'IQ','IR','ID','IN','HK','GE','CC','CN','KH','BN','IO','BT', 'BD','BH','AZ','AM','AF')
/*as we need to find top 10 routes in Asia we need to group data by:*/
GROUP BY 
	from_id, 
	to_id, 
	dura, 
	class_id, 
	operator_id
ORDER BY amount DESC /* sort from max to min amount of billing id’s*/
LIMIT 10),/* find top 10*/
/* second CTE to sum net_price in each month and route, we will need it later to add in window function*/
sum_net_price AS(
SELECT 
	a.createdon_date as full_date, 
    year(a.createdon_date) as year, 
    quarter(a.createdon_date)as quarter, 
    month(a.createdon_date) as month, 
    SUM(a.netprice_usd) as net_price
FROM analytic_test_booking a
JOIN in_asia b ON
	a.from_id=b.from_id and a.to_id=b.to_id 
	AND a.class_id=b.class_id /*join table with top 10 routes in Asia*/
GROUP BY year, quarter, month)
/*last query to get sum for each month and for previous month and count MoM %*/
SELECT *,
	lag(net_price) OVER(order by year, quarter, month) AS previous_month, */sum of net price for previous month*/
	ROUND((((net_price - LAG(net_price) OVER(order by year, quarter,month))/LAG(net_price) OVER(order by year, quarter, month))*100),2) as MoM /* count MOM and round it*/
FROM sum_net_price 
WHERE year = 2023;/* select data only for 2023 year*/

---QoQ changes in Net price for top 10 routes in Asia---
/* find top 10 routes in Asia*/
/*common table expression (CTE), as we need to get top 10 values later in code*/
WITH in_asia AS
(SELECT 
	from_id,
    to_id, 
    class_id,
    operator_id,
    from_country_id,
    to_country_id, 
    count(bid) as amount 
FROM analytic_test_booking
/* specify region using ISO codes taken from http://www.geocountries.com/country/codes/asia*/
WHERE to_country_id IN ('YE','VN', 'UZ', 'AE','TM', 'TR', 'TH', 'TJ', 'TW', 'SY','LK', 'KR','SG','SA', 'QA','PH', 'PS','PK', 'OM', 'KP', 'NP', 'MM', 'MN', 'MV', 'MY', 'MO', 'LB', 'LA', 'KG', 'KW','KZ','JO', 'JP', 'IL', 'IQ','IR','ID','IN','HK','GE','CC','CN','KH','BN','IO','BT', 'BD','BH','AZ','AM','AF')
AND from_country_id IN ('YE','VN', 'UZ', 'AE','TM', 'TR', 'TH', 'TJ', 'TW', 'SY','LK', 'KR','SG','SA', 'QA','PH', 'PS','PK', 'OM', 'KP', 'NP', 'MM', 'MN', 'MV', 'MY', 'MO', 'LB', 'LA', 'KG', 'KW','KZ','JO', 'JP', 'IL', 'IQ','IR','ID','IN','HK','GE','CC','CN','KH','BN','IO','BT', 'BD','BH','AZ','AM','AF')
/*as we need to find top 10 routes outside Asia we need to group data by:*/
GROUP BY from_id, to_id, dura, class_id, operator_id
ORDER BY amount DESC /* sort from max to min amount of billing id’s*/
LIMIT 10),/* find top 10*/
/* second CTE to sum net_price in each quarter and route, we will need it later to add in window function*/
sum_net_price AS(
SELECT 
	a.createdon_date as full_date,
    year(a.createdon_date) as year, 
    quarter(a.createdon_date)as quarter, 
    SUM(a.netprice_usd) as net_price
FROM analytic_test_booking a
JOIN in_asia b ON 
a.from_id=b.from_id and a.to_id=b.to_id AND a.class_id=b.class_id /*join table with top 10 routes in Asia*/
GROUP BY year, quarter)
/*last query to get sum for each month and for previous quarter and count QoQ %*/
SELECT *,
	lag(net_price) OVER(order by year, quarter) AS previous_quarter, /*sum of net price for previous month*/
	ROUND((((net_price - LAG(net_price) OVER(order by year, quarter,))/LAG(net_price) OVER(order by year, quarter,))*100),2) as MoM /* count QoQ and round it*/
FROM sum_net_price 
WHERE year = 2023;/* select data only for 2023 year*/

---checking for duplicates in station names(destinations)---
SELECT DISTINCT 
	from_station_name, 
    to_station_name, 
    count(*)
FROM analytic_test_booking
HAVING count(*) >1;

---how much we have refunded to the whole customer in each year---
/*% from total*/
SELECT 
	*, 
    round(((a.refund_sum/a.total)*100),2)/*count %*/ as percent 
	FROM(
		Select 
			year(createdon_date) year, 
			sum(refund_usd) as refund_sum , 
			sum(total_usd) as total 
		FROM analytic_test_booking
	GROUP BY year(createdon_date)
	HAVING sum(refund_usd)>0)a;

---top destinations for each month---
SELECT * FROM (
SELECT
	a.year, 
	a.month, 
	a.from_country_id,
	a.from_station_name, 
	a.to_country_id,
	a.to_station_name, 
	a.cntrow_number() over (partition by a.year, a.month order by a.cnt desc) as rnk /* gives row number starting with the highest value of counted destinations from the  previous query for each month in a year)*/
	FROM ( /*subquery to count the amount for each destination in each year and month*/
  		SELECT year(createdon_date) as year, 
         		month(createdon_date) as month, 
         		from_country_id,
         		from_station_name,
         		to_country_id,
         		to_station_name,
         		count(*) as cnt
         		FROM analytic_test_booking
         		GROUP BY year, month, to_country_id) a ) b 
  WHERE b. in (1) /*choose the highest destinations in the month*/
ORDER BY b.year, b.month, b.cnt;/* sort by data and amount of destinations that appeared in the result;


 /*anomalies 'DUMMY' values in station names*/
--is dummy date one route or not---
SELECT year(createdon_date) as year, 
         from_id,
         to_id,
         from_country_id,
         from_station_name,
         to_country_id,
         to_station_name,
         count(from_station_name),
         count(to_station_name),
         class_id,
         dura,
         operator_id
FROM analytic_test_booking
where from_station_name in ("DUMMY") and to_station_name in ("DUMMY")
group by class_id, operator_id;
/* dummy value belongs to different routes*/

---Repeat Purchase Rates 2023---
WITH cust AS ( /*CTE for clients who made more than 1 booking */
	SELECT count(b.cust_id) as cnt_a /* count clients id’s*/
	FROM ( 
		SELECT cust_id, /* get clients id’s with more than 1 booking in 2023 year*/
			   count(bid)                
		FROM analytic_test_booking
		WHERE year(createdon_date) = 2023
		GROUP BY cust_id 
		HAVING count(bid) > 1) b
		),
cust_total  AS ( /*get the total amount of  clients in 2023*/
	SELECT count(cust_id)  AS cnt_b 
    FROM analytic_test_booking 
    WHERE year(createdon_date) = 2023
	)
SELECT cnt_a/cnt_b  AS RPR FROM cust, cust_total; /* formula to count RPR*/

---Purchase Frequency---
WITH paid_orders AS (/*CTE to count all paid bookings in 2023*/
	SELECT count(paidon_date) AS cnt_a 
    FROM analytic_test_booking
	WHERE year(createdon_date) = 2023 
    AND paidon_date is not null),
unique_clients AS(select count(cust_id) AS cnt_b FROM(/*CTE count unique clients(who made 1 booking*/
           SELECT distinct 
				cust_id, 
				count(bid)  
		   FROM analytic_test_booking
           WHERE year(paidon_date) = 2023
           GROUP BY cust_id
           HAVING count(bid) = 1) b)
SELECT cnt_a/cnt_b AS Purchase_Frequency FROM paid_orders, unique_clients;/*formula to count Purchase Frequency*/



 




