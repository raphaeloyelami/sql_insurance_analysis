# sql_insurance_claim_analysis

![Alt text](https://banwo-ighodalo.com/assets/grey-matter/cf55f4188d891e7b5dd05fd20e55a501.jpg)

This is capstone project for the [Complete Guide to SQL for Data Engineering: from Beginner to Advanced](https://www.linkedin.com/learning/complete-guide-to-sql-for-data-engineering-from-beginner-to-advanced/sql-for-data-engineering) course I completed on LinkedIn Learning taught by [Deepak Goyal](https://www.linkedin.com/in/deepak-goyal-93805a17/). The goal of this project was to apply SQL concepts to analyze and manage insurance claim data, simulating a real-world use case of an insurance company’s claims processing system.

## Prerequisites

- [PostgreSQL](https://www.postgresql.org/download/)

## Overview:

The insurance database consists of four tables: **Customers**, **PolicyTypes**, **Policies**, and **Claims**, designed to manage data related to customers, policies, and claims.
### 1. Customers Table
Stores customer information.

- **CustomerID:** Unique identifier (Primary Key).
- **FirstName, LastName:** Customer's name.
- **DateOfBirth:** Customer's birthdate.
- **Gender:** Customer's gender.
- **Address, City, State, ZipCode:** Customer's address details.

### 2. PolicyTypes Table
Defines different types of insurance policies.

- **PolicyTypeID:** Unique identifier (Primary Key).
- **PolicyTypeName:** Name of the policy type (e.g., Auto, Home).
- **Description:** Details about the policy type.

### 3. Policies Table
Stores details about policies purchased by customers.

- **PolicyID:** Unique identifier (Primary Key).
- **CustomerID:** References Customers(CustomerID).
- **PolicyTypeID:** References PolicyTypes(PolicyTypeID).
- **PolicyStartDate, PolicyEndDate:** Coverage period.
- **Premium:** Amount paid for the policy.

### 4. Claims Table
Tracks claims made on policies.

- **ClaimID:** Unique identifier (Primary Key).
- **PolicyID:** References Policies(PolicyID).
- **ClaimDate:** Date the claim was made.
- **ClaimAmount:** Amount requested in the claim.
- **ClaimDescription:** Details of the claim.
- **ClaimStatus:** Current status (e.g., Pending, Approved).

## Objective:
The objective of this project is to showcase advanced SQL querying techniques to solve real-world business problems in a database-driven environment. By using a sample database of customer information, policies, claims, and policy types, this project demonstrates how various advanced SQL concepts can be applied to analyze data effectively and efficiently. Key techniques and solutions include:

- **Window Functions:** To calculate cumulative values, running totals, and ranks.
- **Common Table Expressions (CTEs):** For simplifying complex queries and improving readability.
- **CASE WHEN:** To categorize and summarize data based on conditions.
- **COALESCE:** For handling `NULL` values by providing default values in queries.
- **User Roles:** To manage access control and security for sensitive data.

The project covers a range of business queries, from tracking premiums over time and calculating claim amounts to managing claims' statuses and creating user-specific roles for database access. It aims to provide both a practical understanding of advanced SQL techniques and solutions to business scenarios in a relational database system.

The project is designed for those who wish to understand how to solve complex data problems and perform detailed analysis using SQL in real-world situations, with a focus on performance, security, and effective data management.

## Business Problems:

## 1. What are the top 5 customers who have the highest premium totals in 2023?
### Scenario:
Your company wants to know which customers are contributing the most in terms of premium payments. This helps identify high-value customers for potential targeted marketing or offers.
``` sql
SELECT CONCAT(c.FirstName, ' ', c.LastName) AS full_name,
       SUM(p.Premium) AS TotalPremium
FROM Policies p
JOIN Customers c
ON p.CustomerID = c.CustomerID
WHERE p.PolicyStartDate BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY c.CustomerID
ORDER BY TotalPremium DESC
LIMIT 5;
```
![top_5_premium](https://github.com/user-attachments/assets/1fb9826e-a2a1-4262-87a6-4c567d0ee550)

## 2. How many claims have a status of 'Approved' and were made in the last 12 months?
### Scenario:
Your business needs to assess how many claims have been approved recently to evaluate payout trends and claim processing efficiency.
``` sql
SELECT COUNT(*) AS ApprovedClaimsLast12Months
FROM Claims
WHERE ClaimStatus = 'Approved'
  AND ClaimDate >= CURRENT_DATE - INTERVAL '12 months';
```
![2024_approvedclaims](https://github.com/user-attachments/assets/bff99696-f411-471e-bcfb-6d22bf7e6fc4)


## 3. What is the total premium for policies that have claims pending or approved status?
### Scenario:
The company wants to know the total premium income coming from policies that have either pending or approved claims. This helps in risk assessment for policies with claims.
``` sql
SELECT SUM(p.Premium) AS TotalPremium
FROM Policies p
JOIN Claims cl ON p.PolicyID = cl.PolicyID
WHERE cl.ClaimStatus IN ('Approved', 'Pending');
```
![totalpremium](https://github.com/user-attachments/assets/a6f1ff62-fe09-4762-b619-34f96091ca35)

## 4. What is the running total of premiums for each customer ordered by policy start date?
### Scenario:
The business wants to track the cumulative premium collected over time for each customer. This helps analyze how premiums accumulate over time, and could be useful for reporting or forecasting.
``` sql
SELECT c.CustomerID,
       CONCAT(c.FirstName, ' ', c.LastName) AS full_name, 
       p.PolicyStartDate,
       p.Premium,
       SUM(p.Premium) OVER (PARTITION BY c.CustomerID ORDER BY p.PolicyStartDate) AS RunningTotal
FROM Policies p
JOIN Customers c
ON p.CustomerID = c.CustomerID
ORDER BY c.CustomerID, p.PolicyStartDate;
```
![premium_running_total](https://github.com/user-attachments/assets/c8520b75-f894-413a-9bc6-8bd374b4e1b2)

## 5. What is the average claim amount for each customer, including those who have not yet filed any claims?
### Scenario:
The company needs to analyze the average claim amount for each customer, even for those who have no claims. This helps in risk assessment and identifying customers who might need policy adjustments or engagement.
``` sql
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
```
![avg_claim_cust](https://github.com/user-attachments/assets/2a9d41dd-4dc3-4155-9b7e-6c01447e3cf0)

## 6. Which customers have had a claim amount greater than $5000 for the last two claims they made?
### Scenario:
The business wants to identify customers who have had large claims ($5000 or more) in their last two claims. This is valuable for assessing high-risk customers.
``` sql
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
```
![more_than_5k](https://github.com/user-attachments/assets/4354b328-7069-48f5-8610-6436aeabe333)

## 7. How can we segment customers based on their total premium spending and age to create targeted marketing campaigns?
### Scenerio:
Segment customers into **Low**, **Medium**, and **High Spenders** based on total premiums and into **Young**, **Middle-aged**, and **Senior** groups based on age, for personalized marketing and tailored policy offers.
``` sql
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
```
![customer_segmentation](https://github.com/user-attachments/assets/2aa6600e-fbcf-4a36-96dc-8302f23e540c)

## 8. How would you handle an error when inserting a record with a null claim amount?
### Scenario: When inserting claims into the database, the company requires that a claim amount must not be `NULL`. This query ensures that the system prevents inserting such invalid records.
``` sql
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
```
- Run a query
```sql
CALL InsertClaimWithCheck(41,'2025-01-21',NULL,'Car accidents','Pending');
```
![stored_procedure](https://github.com/user-attachments/assets/c54d73fc-e76a-4099-8629-ffda826649c1)

## 9. What is the performance impact of frequent querying of large claims data? How would you optimize query performance?
### Scenario: With large amounts of claims data, frequent queries might result in slow performance. Indexing frequently queried columns such as `ClaimDate` and `ClaimStatus` will improve query performance.
``` sql
CREATE INDEX idx_claim_date ON Claims (ClaimDate, ClaimStatus);
```
- To analyze and show the query execution plan.
``` sql
EXPLAIN SELECT * FROM claims WHERE ClaimDate > '2023-12-31' AND claimstatus = 'Pending';
```
![explain_query](https://github.com/user-attachments/assets/de06ab69-d954-45cd-ba89-ab83adb683c2)

## 10. Create a user role that allows access only to customer names and claim amounts (no policy details).
### Scenario: A business needs to create a restricted user role in the database that can only access customer names and their claim amounts, without revealing sensitive policy information.
- Create the role:
``` sql
CREATE ROLE ClaimAccessUser;
```
- Grant permissions:
``` sql
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
```
- Assign role to a user:
``` sql
CREATE USER "ClaimAccessUser" WITH PASSWORD 'password';

-- Grant SELECT permission on Customers_View
GRANT SELECT ON Customers_View TO ClaimAccessUser;

-- Grant SELECT permission on Claims_View
GRANT SELECT ON Claims_View TO ClaimAccessUser;
```
- If the user already has broader permissions or you need to revoke other permissions (for example, if the user has INSERT or UPDATE rights they shouldn't have), you can revoke those as well:
``` sql
-- Revoke any unwanted permissions
REVOKE INSERT, UPDATE, DELETE ON Customers_View FROM ClaimAccessUser;
REVOKE INSERT, UPDATE, DELETE ON Claims_View FROM ClaimAccessUser;
```

## Future Enhancements
- Data Visualization: Integrate with BI tools like Power BI or Tableau for advanced data visualization.
- Automated Reporting: Set up automated reports using Python or SQL Server Reporting Services (SSRS).

# Conclusion:
This project demonstrated the application of advanced SQL techniques to solve real-world business problems using customer, policy, and claims data. While the dataset used in this project is small, the queries and techniques employed are highly efficient and scalable. When applied to larger datasets, these same methods—such as **Window Functions**, **CASE WHEN**, **COALESCE**, **CTEs**, **INDEXES**, and optimized joins—ensure that the system can handle more extensive data efficiently without sacrificing performance.

By using best practices for query optimization, indexing, and data segmentation, businesses can perform fast, reliable data analysis even with large datasets, helping improve decision-making, target marketing efforts, and enhance customer service.
