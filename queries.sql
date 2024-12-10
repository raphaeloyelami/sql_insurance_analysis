--- sql queries 

-- 1. What are the top 5 customers who have the highest premium totals in 2023?

SELECT CONCAT(c.FirstName, ' ', c.LastName) AS full_name,
       SUM(p.Premium) AS TotalPremium
FROM Policies p
JOIN Customers c
ON p.CustomerID = c.CustomerID
WHERE p.PolicyStartDate BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY c.CustomerID
ORDER BY TotalPremium DESC
LIMIT 5;

-- 2. How many claims have a status of 'Approved' and were made in the last 12 months?

SELECT COUNT(*) AS ApprovedClaimsLast12Months
FROM Claims
WHERE ClaimStatus = 'Approved'
  AND ClaimDate >= CURRENT_DATE - INTERVAL '12 months';

-- 3. What is the total premium for policies that have claims pending or approved status?

SELECT SUM(p.Premium) AS TotalPremium
FROM Policies p
JOIN Claims cl ON p.PolicyID = cl.PolicyID
WHERE cl.ClaimStatus IN ('Approved', 'Pending');

-- 4. What is the running total of premiums for each customer ordered by policy start date?

SELECT c.CustomerID,
       CONCAT(c.FirstName, ' ', c.LastName) AS full_name, 
       p.PolicyStartDate,
       p.Premium,
       SUM(p.Premium) OVER (PARTITION BY c.CustomerID ORDER BY p.PolicyStartDate) AS RunningTotal
FROM Policies p
JOIN Customers c
ON p.CustomerID = c.CustomerID
ORDER BY c.CustomerID, p.PolicyStartDate;

-- 5. What is the average claim amount for each customer, including those who have not yet filed any claims?

WITH ClaimData AS (
    SELECT c.CustomerID,
           AVG(cl.ClaimAmount) AS AverageClaimAmount
    FROM Customers c
    LEFT JOIN Policies p
    ON c.CustomerID = p.CustomerID
    LEFT JOIN Claims cl
    ON p.PolicyID = cl.PolicyID
    GROUP BY c.CustomerID
)
SELECT c.FirstName,
       c.LastName,
       ROUND(COALESCE(cd.AverageClaimAmount, 0), 2) AS AverageClaimAmount
FROM Customers c
LEFT JOIN ClaimData cd
ON c.CustomerID = cd.CustomerID
ORDER BY c.LastName;

-- 6. Which customers have had a claim amount greater than $5000 for the last two claims they made?

WITH RankedClaims AS (
    SELECT cl.ClaimID,
           p.CustomerID,
           cl.ClaimAmount,
           cl.ClaimDate,
           ROW_NUMBER() OVER (PARTITION BY p.CustomerID ORDER BY cl.ClaimDate DESC) AS ClaimRank
    FROM Claims cl
    JOIN Policies p 
      ON cl.PolicyID = p.PolicyID
)
SELECT CONCAT(c.FirstName, ' ', c.LastName) AS full_name,
       rc.ClaimAmount,
       rc.ClaimDate
FROM RankedClaims rc
JOIN Customers c
  ON rc.CustomerID = c.CustomerID
WHERE rc.ClaimRank <= 2
  AND rc.ClaimAmount > 5000
ORDER BY full_name, rc.ClaimDate DESC;

-- 7. How can we segment customers based on their total premium spending and age to create targeted marketing campaigns?

SELECT 
    c.CustomerID, 
    CONCAT(c.FirstName, ' ', c.LastName) AS full_name,
    c.DateOfBirth, 
    DATE_PART('year', AGE(c.DateOfBirth)) AS Age, 
    SUM(p.Premium) AS TotalPremium,
    CASE 
        WHEN SUM(p.Premium) < 2000 THEN 'Low Spender'
        WHEN SUM(p.Premium) BETWEEN 2000 AND 5000 THEN 'Medium Spender'
        ELSE 'High Spender'
    END AS PremiumLevel,
    CASE 
        WHEN DATE_PART('year', AGE(c.DateOfBirth)) < 30 THEN 'Young'
        WHEN DATE_PART('year', AGE(c.DateOfBirth)) BETWEEN 30 AND 60 THEN 'Middle-aged'
        ELSE 'Senior'
    END AS AgeGroup
FROM Customers c
LEFT JOIN Policies p ON c.CustomerID = p.CustomerID
GROUP BY c.CustomerID, c.FirstName, c.LastName, c.DateOfBirth
ORDER BY TotalPremium DESC;

-- 8. How would you handle an error when inserting a record with a null claim amount?

CREATE OR REPLACE PROCEDURE InsertClaimWithCheck(
    p_PolicyID INT, 
    p_ClaimDate DATE, 
    p_ClaimAmount DECIMAL, 
    p_ClaimDescription TEXT, 
    p_ClaimStatus VARCHAR
)
LANGUAGE plpgsql
AS
$$
BEGIN
    IF p_ClaimAmount IS NULL THEN
        RAISE EXCEPTION 'Claim amount cannot be null';
    ELSE
        INSERT INTO Claims (PolicyID, ClaimDate, ClaimAmount, ClaimDescription, ClaimStatus)
        VALUES (p_PolicyID, p_ClaimDate, p_ClaimAmount, p_ClaimDescription, p_ClaimStatus);
    END IF;
END;
$$;


CALL InsertClaimWithCheck(41,'2025-01-21',NULL,'Car accidents','Pending');

-- 9. What is the performance impact of frequent querying of large claims data? How would you optimize query performance?

CREATE INDEX idx_claim_date ON Claims (ClaimDate, ClaimStatus);

EXPLAIN SELECT * FROM claims WHERE ClaimDate > '2023-12-31' AND claimstatus = 'Pending';

-- 10. Create a user role that allows access only to customer names and claim amounts (no policy details).

CREATE ROLE ClaimAccessUser;

-- Grant permissions:

-- Create Customers_View with only the required columns
CREATE OR REPLACE VIEW Customers_View AS
SELECT FirstName, LastName
FROM Customers;

-- Create Claims_View with only the required column
CREATE OR REPLACE VIEW Claims_View AS
SELECT ClaimAmount
FROM Claims;

-- Grant SELECT on the views to ClaimAccessUser
GRANT SELECT ON Customers_View TO ClaimAccessUser;
GRANT SELECT ON Claims_View TO ClaimAccessUser;

-- Assign role to a user:

CREATE USER "ClaimAccessUser" WITH PASSWORD 'password';

-- Grant SELECT permission on Customers_View
GRANT SELECT ON Customers_View TO ClaimAccessUser;

-- Grant SELECT permission on Claims_View
GRANT SELECT ON Claims_View TO ClaimAccessUser;

-- If the user already has broader permissions or you need to revoke other permissions (for example, if the user has INSERT or UPDATE rights 
-- they shouldn't have), you can revoke those as well:

-- Revoke any unwanted permissions
REVOKE INSERT, UPDATE, DELETE ON Customers_View FROM ClaimAccessUser;
REVOKE INSERT, UPDATE, DELETE ON Claims_View FROM ClaimAccessUser;