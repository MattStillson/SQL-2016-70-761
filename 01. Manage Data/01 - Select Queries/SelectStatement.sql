/**
-- Return orders placed in June 2015
-- Tables involved: TSQLV4 database, Sales.Orders table

-- Desired output:
orderid     orderdate  custid      empid
----------- ---------- ----------- -----------
10555       2015-06-02 71          6
10556       2015-06-03 73          2
10557       2015-06-03 44          9
10558       2015-06-04 4           1
10559       2015-06-05 7           6
10560       2015-06-06 25          8
10561       2015-06-06 24          2
10562       2015-06-09 66          1
10563       2015-06-10 67          2
10564       2015-06-10 65          4
...

(30 row(s) affected)
**/

--Solution--
USE TSQLV4;
GO

-- Not good because of full table scan.
SELECT orderid, orderdate, custid, empid
FROM Sales.Orders
WHERE YEAR(orderdate) = 2015 AND MONTH(orderdate) = 6;