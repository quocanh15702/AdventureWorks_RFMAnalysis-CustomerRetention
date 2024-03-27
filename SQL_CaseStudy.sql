/* Case study 1: Retention Corhot Analysis

Using Database AdventureWorksDW2020, table dbo.FactInternetSales 
Write a query that'll query Rention Cohort Analysis based on First time Customer Purchase in the period of Jan 2020 to Jan 2021.
*/ 


USE AdventureWorksDW2020

WITH OrderList AS (
SELECT 
	DISTINCT CustomerKey,
	OrderDate
FROM dbo.FactInternetSales
),
FirstPurchaseList AS (
SELECT
	CustomerKey,
	MIN(OrderDate) AS FirstPurchaseDate,
	FORMAT(MIN(OrderDate), 'yyyy-MM') AS FirstPurchaseMonth
FROM OrderList 
GROUP BY CustomerKey
),
CohortIdx AS (
SELECT
	DISTINCT OL.CustomerKey ,
	FPL.FirstPurchaseMonth,
	DATEDIFF(MONTH,FPL.FirstPurchaseDate,OL.OrderDate) AS CohortIndex  
FROM OrderList AS OL 
LEFT JOIN FirstPurchaseList AS FPL 
	ON OL.CustomerKey = FPL.CustomerKey 
)
SELECT
	FirstPurchaseMonth,
	FORMAT([0]/[0],'P') AS [0],
	FORMAT(1.0*[1]/ [0], 'P') AS [1],
	FORMAT(1.0*[2]/ [0], 'P') AS [2],
	FORMAT(1.0*[3]/ [0], 'P') AS [3],
	FORMAT(1.0*[4]/ [0], 'P') AS [4],
	FORMAT(1.0*[5]/ [0], 'P') AS [5],
	FORMAT(1.0*[6]/ [0], 'P') AS [6],
	FORMAT(1.0*[7]/ [0], 'P') AS [7],
	FORMAT(1.0*[8]/ [0], 'P') AS [8],
	FORMAT(1.0*[9]/ [0], 'P') AS [9],
	FORMAT(1.0*[10]/ [0], 'P') AS [10],
	FORMAT(1.0*[11]/ [0], 'P') AS [11],
	FORMAT(1.0*[12]/ [0], 'P') AS [12]
FROM CohortIdx
PIVOT (COUNT(CustomerKey) FOR CohortIndex IN (
	[0],
	[1],
	[2],
	[3],
	[4],
	[5],
	[6],
	[7],
	[8],
	[9],
	[10],
	[11],
	[12]
)) AS pvt 
WHERE FirstPurchaseMonth BETWEEN '2020-01' AND '2021-01'
ORDER BY FirstPurchaseMonth ;

 /* Case study 2: RFM Analysis

Using Database AdventureWorksDW2020, table dbo.FactInternetSales
Write a query that'll query to implement RFM analysis into serveral segmentation like:
Loyal
Promising
Big spenders
New customers
Potential churn
Lost
*/

WITH CustSeg AS (
SELECT
	CustomerKey, 
	COUNT(DISTINCT SalesOrderNumber) AS Frequency,
	SUM(SalesAmount) AS Monetary,
	DATEDIFF(DAY,MAX(OrderDate), (SELECT MAX(OrderDate) FROM dbo.FactInternetSales)) AS Recency
FROM dbo.FactInternetSales
GROUP BY CustomerKey
),
RFMgroup AS (
SELECT
	CustomerKey,
	NTILE(4) OVER (ORDER BY Recency DESC) AS RFM_Recency,
	NTILE(4) OVER (ORDER BY Frequency) AS RFM_Frequency,
	NTILE(4) OVER (ORDER BY Monetary) AS RFM_Monetary
FROM CustSeg 
),
RFMscore AS (
SELECT 
	CustomerKey,
	CONCAT(RFM_Recency,RFM_Frequency,RFM_Monetary) AS RFM_Score
FROM RFMgroup
)
SELECT
	CustomerKey,
	RFM_Score,
	CASE	
		WHEN RFM_Score LIKE '1__' THEN 'Lost'
		WHEN RFM_Score LIKE '[3,4][3,4][1,2]' THEN 'Promising'
		WHEN RFM_Score LIKE '[3,4][3,4][3,4]' THEN 'Loyal'
		WHEN RFM_Score LIKE '_[1,2][4]' THEN 'Big Spender'
		WHEN RFM_Score LIKE '[3,4][1,2]_' THEN 'New'
		WHEN RFM_Score LIKE '2__' THEN 'Potential Churn'
	END AS CustomerSegmentation
INTO #CustSegment
FROM RFMscore
SELECT
    CustomerSegmentation AS Segmentation,
    COUNT(CustomerKey) AS NumberOfCustomers,
	FORMAT(COUNT(CustomerKey)* 1.0  / (SELECT COUNT(*) FROM #CustSegment),'P') AS 'Percentage'
FROM #CustSegment
GROUP BY CustomerSegmentation
ORDER BY CustomerSegmentation;