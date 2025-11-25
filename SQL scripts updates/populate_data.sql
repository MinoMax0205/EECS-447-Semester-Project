-- =====================================================================
-- Library Management System - Sample Data Population Script
-- =====================================================================

SET FOREIGN_KEY_CHECKS = 0;

TRUNCATE TABLE Notification;
TRUNCATE TABLE Payment;
TRUNCATE TABLE Loan;
TRUNCATE TABLE Reservation;
TRUNCATE TABLE ItemAuthor;
TRUNCATE TABLE AuthorCreator;
TRUNCATE TABLE Book;
TRUNCATE TABLE Magazine;
TRUNCATE TABLE DigitalMedia;
TRUNCATE TABLE Item;
TRUNCATE TABLE Client;
TRUNCATE TABLE MembershipType;

SET FOREIGN_KEY_CHECKS = 1;

-- =====================================================================
-- Helper number table to simulate sequences (MySQL 5.x compatible)
-- =====================================================================
DROP TEMPORARY TABLE IF EXISTS TmpNumbers;
CREATE TEMPORARY TABLE TmpNumbers (
    n INT PRIMARY KEY
);

INSERT INTO TmpNumbers (n)
SELECT digit_units.n + digit_tens.n * 10 + digit_hundreds.n * 100 AS n
FROM (SELECT 0 AS n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
      UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) AS digit_units
CROSS JOIN (SELECT 0 AS n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
      UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) AS digit_tens
CROSS JOIN (SELECT 0 AS n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
      UNION ALL SELECT 5) AS digit_hundreds
WHERE digit_units.n + digit_tens.n * 10 + digit_hundreds.n * 100 <= 600;

-- =====================================================================
-- 1. MembershipType
-- =====================================================================
INSERT INTO MembershipType
    (MembershipTypeID, Name, MaxConcurrentLoans, LoanDurationDays, DailyLateFee, ReservationLimit)
VALUES
    (1, 'Student', 5, 21, 0.25, 3),
    (2, 'Adult',   8, 28, 0.35, 5),
    (3, 'Premium', 12, 35, 0.20, 8),
    (4, 'Research', 15, 42, 0.15, 10);

-- =====================================================================
-- 2. Client (50 generated members with varied memberships and statuses)
-- =====================================================================
INSERT INTO Client
    (ClientID, FullName, Email, Phone, Address, JoinDate, AccountStatus, MembershipTypeID)
SELECT
    n AS ClientID,
    CONCAT('Client ', LPAD(n, 2, '0')) AS FullName,
    CONCAT('client', LPAD(n, 3, '0'), '@example.com') AS Email,
    CONCAT('555-2', LPAD(n, 3, '0')) AS Phone,
    CONCAT(n, ' Library Ln, Lawrence, KS 6604', MOD(n, 10)) AS Address,
    DATE_SUB(CURDATE(), INTERVAL (n * 7 + CAST(RAND(n) * 14 AS SIGNED)) DAY) AS JoinDate,
    CASE
        WHEN n % 15 = 0 THEN 'Suspended'
        WHEN n % 11 = 0 THEN 'Closed'
        ELSE 'Active'
    END AS AccountStatus,
    CASE
        WHEN n % 4 = 0 THEN 4
        WHEN n % 3 = 0 THEN 3
        WHEN n % 2 = 0 THEN 2
        ELSE 1
    END AS MembershipTypeID
FROM TmpNumbers
WHERE n BETWEEN 1 AND 50;

-- =====================================================================
-- 3. Item: Books (20 titles)
-- =====================================================================
INSERT INTO Item
    (ItemID, Title, Genre, PublicationYear, AvailabilityStatus, Price, StockQuantity, ItemType)
SELECT
    n AS ItemID,
    CONCAT('Curated Book ', LPAD(n, 2, '0')) AS Title,
    CASE
        WHEN n % 3 = 0 THEN 'Technology'
        WHEN n % 3 = 1 THEN 'Fiction'
        ELSE 'History'
    END AS Genre,
    1995 + (n * 2 % 25) AS PublicationYear,
    'Available' AS AvailabilityStatus,
    ROUND(12 + RAND(n) * 45, 2) AS Price,
    FLOOR(2 + RAND(n * 7) * 4) AS StockQuantity,
    'Book' AS ItemType
FROM TmpNumbers
WHERE n BETWEEN 1 AND 20;

INSERT INTO Book (ItemID, ISBN, Publisher)
SELECT
    n AS ItemID,
    CONCAT('978-1-4477-', LPAD(n, 4, '0')) AS ISBN,
    CONCAT('Publisher ', ((n - 1) % 5) + 1) AS Publisher
FROM TmpNumbers
WHERE n BETWEEN 1 AND 20;

-- =====================================================================
-- 4. Item: Digital Media (20 items, ItemIDs 101-120)
-- =====================================================================
INSERT INTO Item
    (ItemID, Title, Genre, PublicationYear, AvailabilityStatus, Price, StockQuantity, ItemType)
SELECT
    100 + n AS ItemID,
    CONCAT('Digital Media ', LPAD(n, 2, '0')) AS Title,
    CASE
        WHEN n % 4 = 0 THEN 'Documentary'
        WHEN n % 4 = 1 THEN 'Technology'
        WHEN n % 4 = 2 THEN 'Wellness'
        ELSE 'Music'
    END AS Genre,
    2005 + (n * 3 % 18) AS PublicationYear,
    'Available' AS AvailabilityStatus,
    ROUND(8 + RAND(n + 100) * 35, 2) AS Price,
    FLOOR(3 + RAND(n + 200) * 6) AS StockQuantity,
    'DigitalMedia' AS ItemType
FROM TmpNumbers
WHERE n BETWEEN 1 AND 20;

INSERT INTO DigitalMedia (ItemID, MediaType, Publisher)
SELECT
    100 + n AS ItemID,
    CASE
        WHEN n % 3 = 0 THEN 'Video'
        WHEN n % 3 = 1 THEN 'EBook'
        ELSE 'AudioBook'
    END AS MediaType,
    CONCAT('Digital Publisher ', ((n - 1) % 6) + 1) AS Publisher
FROM TmpNumbers
WHERE n BETWEEN 1 AND 20;

-- =====================================================================
-- 5. Item: Magazines (20 issues, ItemIDs 201-220)
-- =====================================================================
INSERT INTO Item
    (ItemID, Title, Genre, PublicationYear, AvailabilityStatus, Price, StockQuantity, ItemType)
SELECT
    200 + n AS ItemID,
    CONCAT('Monthly Magazine ', LPAD(n, 2, '0')) AS Title,
    CASE
        WHEN n % 3 = 0 THEN 'Science'
        WHEN n % 3 = 1 THEN 'History'
        ELSE 'Lifestyle'
    END AS Genre,
    2020 + (n % 5) AS PublicationYear,
    'Available' AS AvailabilityStatus,
    ROUND(4 + RAND(n + 300) * 4, 2) AS Price,
    FLOOR(5 + RAND(n + 400) * 6) AS StockQuantity,
    'Magazine' AS ItemType
FROM TmpNumbers
WHERE n BETWEEN 1 AND 20;

INSERT INTO Magazine (ItemID, IssueDate, Publisher)
SELECT
    200 + n AS ItemID,
    DATE_SUB(CURDATE(), INTERVAL n MONTH) AS IssueDate,
    CONCAT('Periodical House ', ((n - 1) % 4) + 1) AS Publisher
FROM TmpNumbers
WHERE n BETWEEN 1 AND 20;

-- =====================================================================
-- 6. AuthorCreator (10 curated + 20 procedurally generated)
-- =====================================================================
INSERT INTO AuthorCreator
    (AuthorID, FullName, BirthYear, Country)
VALUES
    (1, 'Abraham Silberschatz', 1952, 'USA'),
    (2, 'Thomas H. Cormen', 1956, 'USA'),
    (3, 'F. Scott Fitzgerald', 1896, 'USA'),
    (4, 'Harper Lee', 1926, 'USA'),
    (5, 'Robert C. Martin', 1952, 'USA'),
    (6, 'Mary Lou Jepsen', 1965, 'USA'),
    (7, 'Neil Gaiman', 1960, 'UK'),
    (8, 'Octavia Butler', 1947, 'USA'),
    (9, 'Yuval Noah Harari', 1976, 'Israel'),
    (10,'Chimamanda Ngozi Adichie', 1977, 'Nigeria');

INSERT INTO AuthorCreator
    (AuthorID, FullName, BirthYear, Country)
SELECT
    n AS AuthorID,
    CONCAT('Author ', LPAD(n, 2, '0')) AS FullName,
    1940 + (n * 3 % 60) AS BirthYear,
    CASE
        WHEN n % 4 = 0 THEN 'Canada'
        WHEN n % 4 = 1 THEN 'USA'
        WHEN n % 4 = 2 THEN 'UK'
        ELSE 'Australia'
    END AS Country
FROM TmpNumbers
WHERE n BETWEEN 11 AND 30;

-- =====================================================================
-- 7. ItemAuthor (link every item to at least one creator)
-- =====================================================================
INSERT INTO ItemAuthor (ItemID, AuthorID, Role)
SELECT
    i.ItemID,
    ((i.ItemID - 1) % 30) + 1 AS AuthorID,
    CASE
        WHEN i.ItemType = 'DigitalMedia' THEN 'Director'
        WHEN i.ItemType = 'Magazine' THEN 'Editor'
        ELSE 'Author'
    END AS Role
FROM Item i;

-- Additional collaborators for selected items
INSERT INTO ItemAuthor (ItemID, AuthorID, Role)
SELECT
    i.ItemID,
    ((i.ItemID + 7) % 30) + 1 AS AuthorID,
    'Author'
FROM Item i
WHERE i.ItemType <> 'Magazine'
  AND MOD(i.ItemID, 4) = 0;

-- =====================================================================
-- 8. Loan dataset (55 deterministic records)
-- =====================================================================
INSERT INTO Loan (LoanID, ClientID, ItemID, CheckedOutAt, DueAt, ReturnedAt, LateFeeCharged, Status)
SELECT
    ls.LoanID,
    ls.ClientID,
    ls.ItemID,
    ls.CheckedOutAt,
    DATE_ADD(ls.CheckedOutAt, INTERVAL mt.LoanDurationDays DAY) AS DueAt,
    CASE
        WHEN ls.ReturnOffsetDays IS NULL THEN NULL
        ELSE DATE_ADD(ls.CheckedOutAt, INTERVAL ls.ReturnOffsetDays DAY)
    END AS ReturnedAt,
    0 AS LateFeeCharged,
    'Open' AS Status
FROM (
    SELECT 1 AS LoanID, 1 AS ClientID, 1 AS ItemID, '2024-07-05 10:00:00' AS CheckedOutAt, 18 AS ReturnOffsetDays
    UNION ALL SELECT 2, 1, 105, '2024-11-01 09:00:00', NULL
    UNION ALL SELECT 3, 1, 5, '2025-11-15 12:00:00', NULL
    UNION ALL SELECT 4, 2, 2, '2024-06-20 08:45:00', 50
    UNION ALL SELECT 5, 2, 6, '2025-11-02 14:10:00', NULL
    UNION ALL SELECT 6, 2, 108, '2024-12-01 16:30:00', 20
    UNION ALL SELECT 7, 3, 3, '2024-08-12 13:20:00', 55
    UNION ALL SELECT 8, 3, 112, '2024-10-10 10:05:00', NULL
    UNION ALL SELECT 9, 3, 205, '2025-11-01 11:40:00', NULL
    UNION ALL SELECT 10,4, 4, '2024-05-18 09:00:00', NULL
    UNION ALL SELECT 11,4, 109,'2024-09-01 12:15:00', 70
    UNION ALL SELECT 12,4, 115,'2025-11-10 15:00:00', NULL
    UNION ALL SELECT 13,5, 7, '2024-09-05 08:00:00', 22
    UNION ALL SELECT 14,5, 214,'2025-10-28 10:00:00', NULL
    UNION ALL SELECT 15,6, 9, '2024-04-02 10:30:00', NULL
    UNION ALL SELECT 16,6, 14,'2024-07-10 09:45:00', 80
    UNION ALL SELECT 17,6, 118,'2025-11-12 16:10:00', NULL
    UNION ALL SELECT 18,7, 10,'2024-12-15 14:50:00', 25
    UNION ALL SELECT 19,7, 16,'2025-11-05 13:25:00', NULL
    UNION ALL SELECT 20,8, 11,'2024-03-10 11:00:00', NULL
    UNION ALL SELECT 21,8, 202,'2025-10-30 09:10:00', NULL
    UNION ALL SELECT 22,8, 116,'2025-09-15 16:00:00', 40
    UNION ALL SELECT 23,9, 12,'2024-08-25 10:05:00', NULL
    UNION ALL SELECT 24,9, 117,'2025-11-04 15:45:00', NULL
    UNION ALL SELECT 25,10,13,'2024-09-03 12:34:00', 60
    UNION ALL SELECT 26,10,120,'2025-10-29 09:55:00', NULL
    UNION ALL SELECT 27,11,18,'2024-10-05 13:35:00', 21
    UNION ALL SELECT 28,11,203,'2025-11-08 10:20:00', NULL
    UNION ALL SELECT 29,12,19,'2024-07-01 08:25:00', NULL
    UNION ALL SELECT 30,12,204,'2025-08-15 09:00:00', 10
    UNION ALL SELECT 31,12,107,'2025-11-10 11:50:00', NULL
    UNION ALL SELECT 32,13,17,'2024-09-12 14:10:00', NULL
    UNION ALL SELECT 33,13,210,'2025-06-20 10:10:00', 30
    UNION ALL SELECT 34,14,211,'2024-10-01 17:00:00', NULL
    UNION ALL SELECT 35,14,111,'2025-07-04 09:15:00', 20
    UNION ALL SELECT 36,15,20,'2025-03-15 12:05:00', 25
    UNION ALL SELECT 37,15,114,'2025-11-05 08:00:00', NULL
    UNION ALL SELECT 38,16,101,'2025-10-10 10:00:00', 42
    UNION ALL SELECT 39,16,206,'2025-09-15 13:10:00', NULL
    UNION ALL SELECT 40,17,102,'2025-11-12 12:00:00', NULL
    UNION ALL SELECT 41,17,207,'2025-11-01 09:55:00', NULL
    UNION ALL SELECT 42,18,103,'2024-11-10 07:45:00', 30
    UNION ALL SELECT 43,18,208,'2025-10-02 16:25:00', NULL
    UNION ALL SELECT 44,19,104,'2024-08-18 15:15:00', NULL
    UNION ALL SELECT 45,19,209,'2025-11-06 11:35:00', NULL
    UNION ALL SELECT 46,20,110,'2024-07-22 10:10:00', 55
    UNION ALL SELECT 47,20,212,'2025-11-03 17:40:00', NULL
    UNION ALL SELECT 48,21,113,'2025-10-15 10:30:00', NULL
    UNION ALL SELECT 49,22,213,'2025-11-02 14:20:00', NULL
    UNION ALL SELECT 50,23,215,'2025-11-11 18:30:00', NULL
    UNION ALL SELECT 51,24,216,'2025-10-05 08:20:00', NULL
    UNION ALL SELECT 52,25,217,'2025-10-18 09:00:00', NULL
    UNION ALL SELECT 53,26,218,'2025-11-04 14:50:00', NULL
    UNION ALL SELECT 54,27,219,'2025-09-27 13:05:00', NULL
    UNION ALL SELECT 55,28,220,'2025-10-09 12:40:00', NULL
) AS ls
JOIN Client c ON c.ClientID = ls.ClientID
JOIN MembershipType mt ON mt.MembershipTypeID = c.MembershipTypeID
ORDER BY ls.LoanID;

-- Randomized historical loans to diversify late fee calculations
INSERT INTO Loan (LoanID, ClientID, ItemID, CheckedOutAt, DueAt, ReturnedAt, LateFeeCharged, Status)
SELECT
    500 + tn.n AS LoanID,
    30 + tn.n AS ClientID,
    1 + ((tn.n * 7) % 20) AS ItemID,
    DATE_SUB(NOW(), INTERVAL (60 + tn.n * 3) DAY) AS CheckedOutAt,
    DATE_ADD(DATE_SUB(NOW(), INTERVAL (60 + tn.n * 3) DAY), INTERVAL mt.LoanDurationDays DAY) AS DueAt,
    DATE_ADD(DATE_SUB(NOW(), INTERVAL (60 + tn.n * 3) DAY),
             INTERVAL (mt.LoanDurationDays + 2 + CAST(RAND(tn.n) * 4 AS SIGNED)) DAY) AS ReturnedAt,
    0 AS LateFeeCharged,
    'Closed' AS Status
FROM TmpNumbers tn
JOIN Client c ON c.ClientID = 30 + tn.n
JOIN MembershipType mt ON mt.MembershipTypeID = c.MembershipTypeID
WHERE tn.n BETWEEN 1 AND 5;

-- =====================================================================
-- 9. Reservation dataset (deterministic)
-- =====================================================================
INSERT INTO Reservation (ReservationID, ClientID, ItemID, PlacedAt, FulfilledAt, Status, QueuePosition)
SELECT
    rs.ReservationID,
    rs.ClientID,
    rs.ItemID,
    rs.PlacedAt,
    CASE
        WHEN rs.FulfilledOffsetDays IS NULL THEN NULL
        ELSE DATE_ADD(rs.PlacedAt, INTERVAL rs.FulfilledOffsetDays DAY)
    END AS FulfilledAt,
    rs.Status,
    rs.QueuePosition
FROM (
    SELECT 1 AS ReservationID, 5 AS ClientID, 2 AS ItemID, '2024-09-15 09:00:00' AS PlacedAt, 25 AS FulfilledOffsetDays, 'Fulfilled' AS Status, 1 AS QueuePosition
    UNION ALL SELECT 2, 7, 2, '2024-09-20 14:00:00', NULL, 'Active', 2
    UNION ALL SELECT 3, 9, 2, '2024-10-01 10:30:00', NULL, 'Active', 3
    UNION ALL SELECT 4, 3, 4, '2024-09-05 11:15:00', 12, 'Fulfilled', 1
    UNION ALL SELECT 5, 12,4, '2024-10-03 13:10:00', NULL, 'Active', 2
    UNION ALL SELECT 6, 15,8, '2024-11-02 16:45:00', NULL, 'Active', 1
    UNION ALL SELECT 7, 16,8, '2024-11-04 09:25:00', NULL, 'Active', 2
    UNION ALL SELECT 8, 21,5, '2025-01-12 08:40:00', 5, 'Fulfilled', 1
    UNION ALL SELECT 9, 22,6, '2025-02-01 12:00:00', NULL, 'Cancelled', 1
    UNION ALL SELECT 10,25,7, '2025-03-10 14:30:00', NULL, 'Active', 1
    UNION ALL SELECT 11,26,101,'2025-05-02 15:20:00', NULL, 'Active', 1
    UNION ALL SELECT 12,27,102,'2025-05-03 16:00:00', NULL, 'Active', 2
    UNION ALL SELECT 13,28,103,'2025-05-05 15:45:00', NULL, 'Active', 3
    UNION ALL SELECT 14,18,9, '2025-06-01 09:10:00', 3, 'Fulfilled', 1
    UNION ALL SELECT 15,19,12,'2025-08-20 11:55:00', NULL, 'Active', 1
    UNION ALL SELECT 16,20,13,'2025-09-02 10:05:00', NULL, 'Active', 1
    UNION ALL SELECT 17,23,14,'2025-09-05 12:45:00', NULL, 'Expired', 1
    UNION ALL SELECT 18,24,15,'2025-09-06 14:10:00', NULL, 'Active', 1
    UNION ALL SELECT 19,30,16,'2025-09-10 15:15:00', NULL, 'Active', 2
    UNION ALL SELECT 20,31,17,'2025-09-15 10:25:00', NULL, 'Active', 3
) AS rs;

-- Randomized reservations for additional diversity
INSERT INTO Reservation (ReservationID, ClientID, ItemID, PlacedAt, FulfilledAt, Status, QueuePosition)
SELECT
    300 + tn.n AS ReservationID,
    32 + tn.n AS ClientID,
    200 + tn.n AS ItemID,
    DATE_SUB(NOW(), INTERVAL (tn.n * 4) DAY) AS PlacedAt,
    NULL AS FulfilledAt,
    'Active' AS Status,
    1 + CAST(RAND(tn.n) * 3 AS SIGNED) AS QueuePosition
FROM TmpNumbers tn
WHERE tn.n BETWEEN 1 AND 5;

-- Clean up helper table
DROP TEMPORARY TABLE IF EXISTS TmpNumbers;

-- =====================================================================
-- 10. Payments reflecting assorted fines
-- =====================================================================
INSERT INTO Payment
    (PaymentID, ClientID, Amount, PaidAt, Method)
VALUES
    (1, 3,  6.25, '2024-10-21 10:15:00', 'Card'),
    (2, 5,  3.75, '2024-10-12 13:45:00', 'Cash'),
    (3, 2,  9.80, '2024-12-05 09:30:00', 'Online'),
    (4, 9,  2.00, '2024-10-18 15:10:00', 'Card'),
    (5, 4, 40.00, '2024-01-02 12:00:00', 'Online'),
    (6, 12, 5.25, '2025-02-14 08:15:00', 'Card'),
    (7, 15, 1.80, '2025-05-04 10:00:00', 'Cash'),
    (8, 18, 4.20, '2025-07-09 16:25:00', 'Online'),
    (9, 21, 7.10, '2025-09-18 11:55:00', 'Card'),
    (10,24, 2.40, '2025-10-02 14:05:00', 'Online');

-- =====================================================================
-- 11. Notifications (mix of due soon, overdue, reservations)
-- =====================================================================
INSERT INTO Notification
    (NotificationID, ClientID, Type, Message)
VALUES
    (1, 5, 'Overdue',
        'Your loan for "Curated Book 07" is overdue. Please return it as soon as possible.'),
    (2, 2, 'DueSoon',
        'Your loan for "Curated Book 02" is due in 3 days.'),
    (3, 3, 'ReservationAvailable',
        'Your reservation for "Curated Book 04" is now ready for pickup.'),
    (4, 9, 'Overdue',
        'Digital Media 17 is overdue. Late fees are accruing daily.'),
    (5, 7, 'DueSoon',
        'Reminder: "Curated Book 16" is due soon.'),
    (6, 12,'ReservationAvailable',
        'Magazine issue 204 has become available.'),
    (7, 15,'Overdue',
        'Please return "Digital Media 14"; fees apply after today.'),
    (8, 18,'DueSoon',
        '"Digital Media 03" is due in two days.'),
    (9, 20,'ReservationAvailable',
        'Your reservation for "Curated Book 13" has been fulfilled.'),
    (10,24,'DueSoon',
        '"Monthly Magazine 16" is due within 48 hours.');

-- =====================================================================
-- End of sample data population
-- =====================================================================
