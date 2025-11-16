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
-- 1. MembershipType
-- =====================================================================
INSERT INTO MembershipType
    (MembershipTypeID, Name, MaxConcurrentLoans, LoanDurationDays, DailyLateFee, ReservationLimit)
VALUES
    (1, 'Student', 5, 21, 0.25, 3),
    (2, 'Adult',   8, 28, 0.35, 5),
    (3, 'Premium', 12, 35, 0.20, 8);

-- =====================================================================
-- 2. Client
-- =====================================================================
INSERT INTO Client
    (ClientID, FullName, Email, Phone, Address, JoinDate, AccountStatus, MembershipTypeID)
VALUES
    (1, 'Alice Chen',   'alice.chen@example.com',   '555-1001', '123 Elm St, Lawrence, KS 66044',        '2024-01-15', 'Active',    1),
    (2, 'Brian Johnson','brian.j@example.com',      '555-1002', '45 Maple Dr, Lawrence, KS 66044',       '2023-09-20', 'Active',    2),
    (3, 'Cathy Lopez',  'cathy.lopez@example.com',  '555-1003', '89 Oak Ave, Topeka, KS 66601',        '2023-08-05', 'Active',    1),
    (4, 'David Kim',    'david.kim@example.com',    '555-1004', '12 Pine Rd, Lawrence, KS 66045',        '2022-06-10', 'Active',    3),
    (5, 'Emily Nguyen', 'emily.nguyen@example.com', '555-1005', '777 Cedar Ln, Kansas City, MO 64101',      '2024-02-01', 'Active',    2),
    (6, 'Frank Miller', 'frank.m@example.com',      '555-1006', '90 Birch Ct, Lawrence, KS 66044',       '2023-03-18', 'Suspended', 2),
    (7, 'Grace Park',   'grace.park@example.com',   '555-1007', '321 Walnut St, Lawrence, KS 66044',     '2024-03-22', 'Active',    1),
    (8, 'Hannah Lee',    'hannah.lee@example.com',   '555-1008', '404 Chestnut Cir, Topeka, KS 66602',  '2022-11-30', 'Active',    3),
    (9, 'Ian Garcia',    'ian.garcia@example.com',   '555-1009', '505 Poplar Blvd, Lawrence, KS 66046',   '2023-12-05', 'Active',    2),
    (10,'Jenny Wang',   'jenny.wang@example.com',   '555-1010', '606 Spruce Way, Lawrence, KS 66044',    '2024-04-10', 'Active',    1);

-- =====================================================================
-- 3. Item (supertype)
--    ItemID 1-5: Books, 6-7: Magazines, 8-9: DigitalMedia
-- =====================================================================
INSERT INTO Item
    (ItemID, Title, Genre, PublicationYear, AvailabilityStatus,
     Price, StockQuantity, ItemType)
VALUES
    (1, 'Database Systems: Concepts and Design', 'Technology', 2020, 'Available',  89.99, 3, 'Book'),
    (2, 'Introduction to Algorithms',            'Technology', 2019, 'OnLoan',     99.50, 2, 'Book'),
    (3, 'The Great Gatsby',                      'Fiction',    2004, 'Available',  12.99, 5, 'Book'),
    (4, 'To Kill a Mockingbird',                 'Fiction',    2006, 'Reserved',    10.99, 4, 'Book'),
    (5, 'Clean Code',                            'Technology', 2010, 'Available',  45.00, 2, 'Book'),
    (6, 'Science Weekly - April 2024',           'Science',    2024, 'Available',   5.99,10, 'Magazine'),
    (7, 'History Monthly - March 2024',          'History',    2024, 'Available',   6.99, 8, 'Magazine'),
    (8, 'Learn SQL in 24 Hours (eBook)',         'Technology', 2021, 'Available',  19.99,20, 'DigitalMedia'),
    (9, 'World War II Documentary (Video)',      'History',    2018, 'Available',  14.99,15, 'DigitalMedia');

-- =====================================================================
-- 4. Book
-- =====================================================================
INSERT INTO Book
    (ItemID, ISBN, Publisher)
VALUES
    (1, '978-0-123456-47-2', 'McGraw-Hill Education'),
    (2, '978-0-262033-84-8', 'MIT Press'),
    (3, '978-0-743273-56-5', 'Scribner'),
    (4, '978-0-060931-46-7', 'Harper Perennial'),
    (5, '978-0-132350-88-4', 'Prentice Hall');

-- =====================================================================
-- 5. Magazine
-- =====================================================================
INSERT INTO Magazine
    (ItemID, IssueDate, Publisher)
VALUES
    (6, '2024-04-01', 'Global Science Press'),
    (7, '2024-03-01', 'History World Media');

-- =====================================================================
-- 6. DigitalMedia
-- =====================================================================
INSERT INTO DigitalMedia
    (ItemID, MediaType, Publisher)
VALUES
    (8, 'EBook', 'Tech Publications'),
    (9, 'Video', 'Documentary Films Inc');

-- =====================================================================
-- 7. AuthorCreator
-- =====================================================================
INSERT INTO AuthorCreator
    (AuthorID, FullName, BirthYear, Country)
VALUES
    (1, 'Abraham Silberschatz', 1952, 'USA'),
    (2, 'Thomas H. Cormen',     1956, 'USA'),
    (3, 'F. Scott Fitzgerald',  1896, 'USA'),
    (4, 'Harper Lee',           1926, 'USA'),
    (5, 'Robert C. Martin',     1952, 'USA'),
    (6, 'Various Contributors', NULL, 'Various');

-- =====================================================================
-- 8. ItemAuthor (many-to-many)
-- =====================================================================
INSERT INTO ItemAuthor
    (ItemID, AuthorID, Role)
VALUES
    (1, 1, 'Author'),   -- Database Systems
    (2, 2, 'Author'),   -- CLRS
    (3, 3, 'Author'),   -- The Great Gatsby
    (4, 4, 'Author'),   -- To Kill a Mockingbird
    (5, 5, 'Author'),   -- Clean Code
    (6, 6, 'Author'),   -- Science Weekly (contributors)
    (7, 6, 'Author'),   -- History Monthly (contributors)
    (8, 6, 'Author'),   -- SQL eBook
    (9, 6, 'Director'); -- Documentary

-- =====================================================================
-- 9. Loan
--    Some returned, some still on loan, some overdue
-- =====================================================================
INSERT INTO Loan
    (LoanID, ClientID, ItemID, CheckedOutAt, DueAt, ReturnedAt, LateFeeCharged, Status)
VALUES
    (1, 1, 2, '2024-10-01 10:00:00', '2024-10-22 10:00:00', '2024-10-18 14:30:00', 0.00, 'Closed'),
    (2, 2, 4, '2024-10-10 09:15:00', '2024-11-07 09:15:00', NULL,                     0.00, 'Open'),
    (3, 3, 3, '2024-09-15 11:20:00', '2024-10-06 11:20:00', '2024-10-20 16:45:00', 2.50, 'Closed'),
    (4, 5, 1, '2024-09-20 08:30:00', '2024-10-18 08:30:00', NULL,                     3.75, 'Overdue'),
    (5, 7, 5, '2024-10-05 13:00:00', '2024-10-26 13:00:00', NULL,                     0.00, 'Open'),
    (6, 8, 8, '2024-08-01 10:00:00', '2024-08-29 10:00:00', '2024-08-20 15:00:00', 0.00, 'Closed'),
    (7, 9, 9, '2024-09-25 14:30:00', '2024-10-30 14:30:00', NULL,                     2.00, 'Overdue'),
    (8, 10,3, '2024-10-12 10:00:00', '2024-11-02 10:00:00', NULL,                     0.00, 'Open');

-- =====================================================================
-- 10. Reservation
--    Multiple queue positions for the same Item
-- =====================================================================
INSERT INTO Reservation
    (ReservationID, ClientID, ItemID, PlacedAt, FulfilledAt, Status, QueuePosition)
VALUES
    (1, 3, 2, '2024-10-01 09:15:00', NULL,        'Active',   1),
    (2, 7, 2, '2024-10-02 10:30:00', NULL,        'Active',   2),
    (3, 1, 4, '2024-09-25 14:00:00', '2024-10-10 09:00:00', 'Fulfilled', 1),
    (4, 5, 4, '2024-10-01 16:20:00', NULL,        'Active',   2),
    (5, 9, 1, '2024-10-05 11:45:00', NULL,        'Cancelled',1);

-- =====================================================================
-- 11. Payment
-- =====================================================================
INSERT INTO Payment
    (PaymentID, ClientID, Amount, PaidAt, Method)
VALUES
    (1, 3,  2.50, '2024-10-21 10:15:00', 'Card'),
    (2, 5,  3.75, '2024-10-12 13:45:00', 'Cash'),
    (3, 2,  1.50, '2024-10-05 09:30:00', 'Online'),
    (4, 9,  2.00, '2024-10-18 15:10:00', 'Card'),
    (5, 4, 40.00, '2024-01-02 12:00:00', 'Online');

-- =====================================================================
-- 12. Notification
-- =====================================================================
INSERT INTO Notification
    (NotificationID, ClientID, Type, Message)
VALUES
    (1, 5, 'Overdue',
        'Your loan for "Database Systems: Concepts and Design" is overdue. Please return it as soon as possible.'),

    (2, 2, 'DueSoon',
        'Your loan for "To Kill a Mockingbird" is due in 3 days.'),

    (3, 3, 'ReservationAvailable',
        'Your reservation for "Introduction to Algorithms" is now available for pickup.'),

    (4, 9, 'Overdue',
        'Your loan for "World War II Documentary (Video)" is overdue. Fines are accruing daily.'),

    (5, 7, 'DueSoon',
        'Your loan for "Clean Code" is due soon. Please return or renew it.');

-- =====================================================================
-- End of sample data population
-- =====================================================================
