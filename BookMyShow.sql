CREATE DATABASE BookMyshow2

CREATE TABLE users
(
    U_ID            INT PRIMARY KEY,
    U_Name          VARCHAR(20) NOT NULL,
    Phone_Number    VARCHAR(20) UNIQUE,
    Age             INT,
    Gender          CHAR(1) CHECK (Gender = 'M' OR Gender = 'F'),
    City            VARCHAR(50),
    Email           VARCHAR(100)
)

INSERT INTO users VALUES (16, 'Mujeeb', '6536', 19, 'M', 'HYD', 'mujeeb@gmail.com'),
INSERT INTO users VALUES (2, 'Leela', '65306', 20, 'M', 'Vijayanagaram', 'leela@gmail.com'),
INSERT INTO users VALUES (6, 'karthik', '653123426', 18, 'M', 'chennai', 'karthik@gmail.com'),
INSERT INTO users VALUES (18, 'Gunadeep', '6589936', 26, 'M', 'Nuzvid', 'gunadeep@gmail.com'),
INSERT INTO users VALUES (8, 'praveen', '6511116', 20, 'M', 'Nellore', 'praveen@gmail.com'),
INSERT INTO users VALUES (99, 'Tejesh', '65399', 45, 'M', 'Ongole', 'tejesh@gmail.com'),
INSERT INTO users VALUES (12, 'Shobha', '65387', 30, 'F', 'Tirupati', 'shobha@gmail.com'),
INSERT INTO users VALUES (13, 'Niranjan', '655666', 23, 'M', 'Tirupati', 'niranjan@gmail.com'),
INSERT INTO users VALUES (32, 'Prakash', '6532226', 19, 'M', 'Machilipatnam', 'prakash@gmail.com'),
INSERT INTO users VALUES (39, 'Sandhya', '6532586', 23, 'F', 'Vishakapatnam', 'sandhya@gmail.com');


SELECT * FROM users;

SELECT *
FROM users
WHERE City = 'Tirupati';

SELECT U_Name, Phone_Number
FROM users
WHERE City = 'Hyderabad';

SELECT *
FROM users
WHERE City in ('Tirupati', 'Chennai');

SELECT *
FROM users
WHERE City = 'Tirupati'
  and Email like '%@gmail.com';

SELECT *
FROM users
WHERE City in ('Tirupati', 'Hyderabad')
  and Phone_Number IS NOT NULL;

SELECT U_ID, U_Name
FROM users
WHERE City = 'Tirupati';

UPDATE users
SET City = 'Chittoor'
WHERE U_ID = 12
  and City = 'Tirupati';

DELETE FROM users
WHERE U_ID = 12;

DELETE FROM users
WHERE City = 'Tirupati'
  and Email like '%@gmail.com';

SELECT count(*) AS Total_Customers
FROM users
WHERE City = 'Tirupati'
  and Email like '%@gmail.com';

SELECT count(*) AS Total_Customers
FROM users
WHERE City in ('Hyderabad', 'Chennai');

SELECT *
FROM users
WHERE U_Name like 'A%'
  and City = 'Tirupati';

SELECT *
FROM users
WHERE (U_Name like 'R%' or U_Name like 'S%')
  and City = 'Hyderabad';

SELECT *
FROM users
WHERE U_Name like '%an%'
  and Email like '%@gmail.com';

SELECT City, count(*) AS Total_Customers
FROM users
GROUP BY City
HAVING count(*) > 2;

SELECT 
    u.U_ID,
    u.U_Name,
    sum(b.Tickets) as Total_Tickets
from users u
join Bookings b
    on u.U_ID = b.U_ID
group by u.U_ID, u.U_Name
having sum(b.Tickets) > 5;


CREATE TABLE movies
(
    Movie_ID        INT PRIMARY KEY,
    Movie_Name      VARCHAR(100) NOT NULL,
    Director        VARCHAR(50) NOT NULL,
    Genere          VARCHAR(100),
    Language        VARCHAR(50),
    Duration_Min    INT CHECK (Duration_Min > 0)
)


INSERT INTO movies VALUES (11, 'Tholi Prema', 'A. Karunakaran.', 'Romantic Drama', 'Telugu', 146),
INSERT INTO movies VALUES (22, 'Bheemla Nayak', 'Saagar K Chandra', 'action, drama, and thriller', 'Telugu', 145),
INSERT INTO movies VALUES (33, 'They Call Him OG', 'Sujeeth', 'Action, Crime, Drama, Thriller', 'Telugu, Tamli, Kannada, Hindi', 157),
INSERT INTO movies VALUES (44, 'Okkadu', 'Gunasekhar', 'Action', 'Telugu', 175),
INSERT INTO movies VALUES (55, 'Tumbbad', 'Rahi Anil Barve', 'Folk horror, fantasy, drama, thriller', 'Telugu, Hindi', 104),
INSERT INTO movies VALUES (66, 'Businessman', 'Puri', 'Action/Crime', 'Telugu', 160),
INSERT INTO movies VALUES (77, 'Dhurandhar', 'Aditya Dhar', 'Spy action thriller', 'Hindi/Telugu/Tamli', 190),
INSERT INTO movies VALUES (88, 'Doomsday', 'Anthony Russo', 'science fiction, action, thriller', 'English', 185),
INSERT INTO movies VALUES (99, 'Spider-Man', 'Marc Webb', 'Superhero action/Sc-Fi', 'English', 180),
INSERT INTO movies VALUES (10, 'Kill', 'Nikhil Nagesh Bhat', 'Action', 'Hindi/Telugu', 180);


SELECT * FROM movies

SELECT *
from movies
where language = 'Telugu';

SELECT Movie_Name, Genere
from movies
where Genere = 'Action';

SELECT Movie_Name
from movies
where Duration_Min > 150;

SELECT Movie_Name
from movies
where language = 'Telugu'
  and Genere = 'Action';

SELECT Movie_Name
from movies
where Duration_Min > 120
  and Duration_Min < 180;

SELECT Movie_Name, language, Genere
from movies
where Duration_Min > 120;

UPDATE movies
set Genere = 'Action'
where Movie_ID = 101;

DELETE from movies
where Duration_Min < 90;

UPDATE movies
set Duration_Min = Duration_Min + 10
where Duration_Min < 120;

UPDATE movies
set language = 'Telugu'
where language = 'English'
  and Genere = 'Drama';

UPDATE movies
set Genere = 'Action'
where language = 'Telugu'
  and Duration_Min > 120;

DELETE from movies
where language = 'English'
  and Duration_Min > 180;

SELECT COUNT(*) AS Total_Telugu_Action_Movies
from movies
where language = 'Telugu'
  and Genere = 'Action';

SELECT COUNT(*) AS Total_Movies
from movies
where Duration_Min > 120
  and Duration_Min < 180;

SELECT MIN(Duration_Min) AS Minimum_Duration
from movies
where language = 'Telugu'
  and Genere = 'Action';

SELECT MAX(Duration_Min) AS Maximum_Duration
from movies
where language IN ('English', 'Hindi');

SELECT AVG(Duration_Min) AS Average_Duration
from movies
where Duration_Min BETWEEN 120 AND 180;

SELECT Movie_Name
from movies
where Movie_Name LIKE 'S%'
  and language = 'Telugu';

SELECT language,
       AVG(Duration_Min) AS Average_Duration
from movies
where Duration_Min > 100
group by language;

SELECT language,
       COUNT(*) AS Total_Movies
from movies
group by language
having COUNT(*) > 3;

SELECT Genere,
       AVG(Duration_Min) AS Average_Duration
from movies
group by Genere
having AVG(Duration_Min) > 120;

SELECT Genere,
       COUNT(*) AS Total_Movies
from movies
where language = 'Telugu'
group by Genere
having COUNT(*) > 2;

SELECT Genere,
       COUNT(*) AS Total_Movies
from movies
group by Genere
order by Total_Movies DESC;

SELECT language,
       AVG(Duration_Min) AS Average_Duration
from movies
group by language
order by Average_Duration ASC;


CREATE TABLE Theaters
(
    Theater_ID      INT PRIMARY KEY,
    Theater_Name    VARCHAR(50) NOT NULL,
    Location        VARCHAR(100),
    City            VARCHAR(50) NOT NULL,
    Screens         INT,
    Rating          DECIMAL(2,1) CHECK (Rating BETWEEN 0.0 AND 5.0)
)


INSERT INTO Theaters VALUES (1, 'Dwaraka', 'Nuzvid', 'Nuzvid', 3, 4.0),
INSERT INTO Theaters VALUES (2, 'PVP', 'Vijayawada', 'Vijayawada', 6, 3.5),
INSERT INTO Theaters VALUES (3, 'Satyanarayana', 'Nuzvid', 'Nuzvid', 4, 3.6),
INSERT INTO Theaters VALUES (4, 'AMB', 'Ameerpet', 'HYD', 6, 5.0),
INSERT INTO Theaters VALUES (5, 'INOX', 'Hyderabad', 'Hyderabad', 4, 4.0),
INSERT INTO Theaters VALUES (6, 'MVR', 'Guntur', 'Guntur', 5, 3.9),
INSERT INTO Theaters VALUES (7, 'KMR', 'Chennai', 'Chennai', 4, 4.5),
INSERT INTO Theaters VALUES (8, 'SVC Cinemas', 'Chittor', 'Chittor', 2, 4.6),
INSERT INTO Theaters VALUES (9, 'AAA', 'HYD', 'HYD', 6, 4.8),
INSERT INTO Theaters VALUES (10, 'Aparna Cinemas', 'HYD', 'HYD', 5, 5.0);


SELECT * from Theaters;

SELECT *
from Theaters
where city = 'Tirupati';

SELECT Theater_Name, city
from Theaters
where Screens > 3;

SELECT *
from Theaters
where city IN ('Tirupati', 'Hyderabad');

SELECT *
from Theaters
where city = 'Tirupati'
  and Screens > 2;

SELECT Theater_Name, city, Screens
from Theaters
where Screens > 3;

UPDATE Theaters
set Screens = Screens + 1
where Theater_ID = 101;

DELETE FROM Theaters
where Screens < 2
  and city = 'Tirupati';

UPDATE Theaters
SET Screens = Screens + 1
where Screens < 3;

UPDATE Theaters
set city = 'Tirupati'
where city = 'Chittoor'
  and Screens >= 3;

DELETE FROM Theaters
where city IN ('Hyderabad', 'Chennai')
  and Screens < 3;

SELECT COUNT(*) as Total_Theaters
from Theaters
where city = 'Tirupati'
  and Screens > 3;

SELECT MIN(Screens) as Minimum_Screens
from Theaters
where city = 'Tirupati'
  and Screens > 2;

SELECT MAX(Screens) as Maximum_Screens
from Theaters
where city IN ('Hyderabad', 'Chennai');

SELECT AVG(Screens) as Average_Screens
from Theaters
where city = 'Tirupati'
  and Screens >= 3;

SELECT DISTINCT city
from Theaters
where Screens > 2
  and Screens < 6;

SELECT city,
       COUNT(*) as Total_Theaters
from Theaters
where Screens >= 3
group by city;

SELECT city,
       AVG(Screens) as Average_Screens
from Theaters
where Screens > 2
group by city;

SELECT city,
       COUNT(*) as Total_Theaters
from Theaters
group by city
having COUNT(*) >= 2;


CREATE TABLE shows
(
    Show_ID         INT PRIMARY KEY,
    Movie_Name      VARCHAR(50) NOT NULL,
    Theater_Name    VARCHAR(60) NOT NULL,
    Show_Date       DATE NOT NULL,
    Ticket_price    DECIMAL(6,2) CHECK (Ticket_price > 0),
    show_time       TIME NOT NULL
)


INSERT INTO shows VALUES (1, 'Tholi Prema', 'Dwaraka', '2026-03-15', 260.00, '12:00:00'),
INSERT INTO shows VALUES (2, 'Bheemla Nayak', 'PVP', '2026-03-16', 300.00, '18:00:00'),
INSERT INTO shows VALUES 3, 'They Call Him OG', 'Satyanarayana', '2026-03-17', 450.00, '18:30:00'),
INSERT INTO shows VALUES (4, 'Okkadu', 'AMB', '2026-03-18', 150.00, '16:00:00'),
INSERT INTO shows VALUES (5, 'Tumbbad', 'AAA', '2026-03-19', 260.00, '17:30:00'),
INSERT INTO shows VALUES 6, 'Businessman', 'INOX', '2026-03-20', 200.00, '21:00:00'),
INSERT INTO shows VALUES (7, 'Dhurandhar', 'MVR', '2026-03-21', 120.00, '22:00:00'),
INSERT INTO shows VALUES (8, 'Doomsday', 'SVC Cinemas', '2026-03-22', 170.00, '00:30:00'),
INSERT INTO shows VALUES (9, 'Spider-Man', 'INOX', '2026-03-23', 360.00, '04:00:00'),
INSERT INTO shows VALUES (11, 'Kill', 'Aparna Cinemas', '2026-03-24', 200.00, '11:30:00');


SELECT * from shows;

SELECT *
from shows
where Show_Date = '2026-09-15';

SELECT *
from shows
where show_time > '18:00:00';

SELECT Show_ID, Movie_Name, show_time
from shows
where show_time > '18:00:00';

UPDATE shows
SET show_time = '18:00:00'
where Show_Date = '2026-09-15'
  and show_time < '18:00:00';

DELETE from shows
where Show_Date = '2026-09-15'
  and show_time < '17:00:00';

SELECT distinct Show_Date
from shows
where show_time > '18:00:00'
  and show_time < '22:00:00';


CREATE TABLE Bookings
(
    Booking_ID      INT PRIMARY KEY,
    U_ID            INT NOT NULL,
    Movie_ID        INT NOT NULL,
    Theater_ID      INT NOT NULL,
    Movie_Name      VARCHAR(50) NOT NULL,
    Booking_Date    DATE,
    Tickets         INT CHECK (Tickets BETWEEN 1 AND 10),

    FOREIGN KEY (U_ID) REFERENCES users(U_ID),
    FOREIGN KEY (Movie_ID) REFERENCES movies(Movie_ID),
    FOREIGN KEY (Theater_ID) REFERENCES Theaters(Theater_ID)
)


INSERT INTO Bookings VALUES (21, 16, 11, 4, 'Tholi Prema', '2026-06-30', 6),
INSERT INTO Bookings VALUES (22, 2, 22, 1, 'Bheemla Nayak', '2026-05-30', 4),
INSERT INTO Bookings VALUES 23, 6, 33, 2, 'They Call Him OG', '2026-06-15', 3),
INSERT INTO Bookings VALUES (24, 18, 44, 3, 'Okkadu', '2026-07-01', 2),
INSERT INTO Bookings VALUES (25, 8, 55, 5, 'Tumbbad', '2026-07-10', 5),
INSERT INTO Bookings VALUES 26, 99, 66, 6, 'Businessman', '2026-07-20', 1),
INSERT INTO Bookings VALUES 27, 12, 77, 7, 'Dhurandhar', '2026-08-05', 4),
INSERT INTO Bookings VALUES (28, 13, 88, 8, 'Doomsday', '2026-08-12', 2),
INSERT INTO Bookings VALUES 29, 32, 99, 9, 'Spider-Man', '2026-08-18', 7),
INSERT INTO Bookings VALUES (30, 39, 10, 10, 'Kill', '2026-08-25', 3);


SELECT * from Bookings;

SELECT *
from Bookings
where Tickets > 3;

SELECT Booking_ID, U_ID, Tickets
from Bookings
where Booking_Date > '2026-09-01';

SELECT *
from Bookings
where Tickets BETWEEN 2 AND 5;

DELETE from Bookings
where Tickets = 1
  and Booking_Date < '2026-09-01';

UPDATE Bookings
set Tickets = Tickets + 1
where Tickets < 3;

UPDATE Bookings
set Booking_Date = '2026-09-15'
where Tickets > 4
  and Booking_Date < '2026-09-01';

DELETE from Bookings
where Tickets > 4
  and Booking_Date < '2026-09-01';

SELECT COUNT(*) as Total_Bookings
from Bookings
where Tickets between 3 and 5;

SELECT MIN(Tickets) as Minimum_Tickets
from Bookings
where Tickets > 1
  and Tickets < 5;

SELECT MAX(Tickets) as Maximum_Tickets
from Bookings
where Booking_Date > '2026-09-01'
  and Tickets > 2;


CREATE TABLE Payments
(
    P_ID                INT PRIMARY KEY,
    U_ID                INT NOT NULL,
    Payment_Method      VARCHAR(100)
    Payment_Date        DATE,
    Amount              DECIMAL(6,2) CHECK (Amount > 0),
    Payment_Status      VARCHAR(100),

    FOREIGN KEY (U_ID) REFERENCES users(U_ID)
)



INSERT INTO Payments VALUES (101, 16, 'UPI', '2026-06-30', 560.16, 'successful'),
INSERT INTO Payments VALUES (102, 2, 'Credit Card', '2026-05-30', 200.00, 'processing'),
INSERT INTO Payments VALUES (103, 6, 'Debit Card', '2026-06-15', 150.00, 'successful'),
INSERT INTO Payments VALUES (104, 18, 'UPI', '2026-07-01', 250.12, 'failed'),
INSERT INTO Payments VALUES (105, 8, 'Net Banking', '2026-07-10', 560.30, 'failed'),
INSERT INTO Payments VALUES (106, 99, 'Credit Card', '2026-07-20', 200.36, 'successful'),
INSERT INTO Payments VALUES (107, 12, 'UPI', '2026-08-05', 120.16, 'successful'),
INSERT INTO Payments VALUES (108, 13, 'Debit Card', '2026-08-12', 170.15, 'failed'),
INSERT INTO Payments VALUES (109, 32, 'Net Banking', '2026-08-18', 560.00, 'successful'),
INSERT INTO Payments VALUES (110, 39, 'UPI', '2026-08-25', 200.00, 'failed');


SELECT * from Payments;

SELECT *
from Payments
where Amount > 500;

SELECT P_ID, U_ID, Payment_Method
from Payments
where Payment_Method = 'UPI';

SELECT *
from Payments
where Payment_Status = 'Successful';

SELECT *
from Payments
where Amount > 7500
  and Payment_Status = 'Successful';

SELECT P_ID, Amount, Payment_Method
from Payments
where Payment_Method IN ('UPI', 'Credit Card');

SELECT P_ID, Amount, Payment_Status
from Payments
where Amount > 500;

UPDATE Payments
set Payment_Status = 'Successful'
where P_ID = 101;

UPDATE Payments
set Payment_Method = 'UPI'
where Payment_Status = 'Pending'
  and Amount < 500;

DELETE from Payments
where Payment_Status = 'Failed'
  and Amount < 2300;

UPDATE Payments
set Payment_Method = 'UPI'
where Payment_Method = 'Cash';

UPDATE Payments
set Payment_Status = 'Successful'
where Amount > 500
  and Payment_Status = 'Pending';

UPDATE Payments
set Payment_Status = 'Failed'
where Amount < 100
  and Payment_Status = 'Pending';

UPDATE Payments
set Amount = Amount + 250
where Payment_Method = 'UPI'
  and Amount < 500;

DELETE FROM Payments
where Payment_Status = 'Failed'
  and Amount > 71000;

SELECT AVG(Amount) as Average_Amount
from Payments
where Payment_Status = 'Successful'
  and Amount > 2500;

SELECT SUM(Amount) as Total_Amount
from Payments
where Payment_Status = 'Successful'
  and Amount > 500;

SELECT SUM(Amount) as Total_Amount
from Payments
where Payment_Method = 'UPI'
  and Amount > 300;

SELECT SUM(Amount) as Total_Amount
from Payments
where Payment_Method = 'UPI'
  and Payment_Status = 'Successful'
  and Amount > 500;

SELECT distinct Payment_Status
from Payments
where Payment_Method IN ('UPI', 'Credit Card');

SELECT Payment_Method,
       SUM(Amount) as Total_Amount
FROM Payments
where Payment_Status = 'Successful'
group by Payment_Method;

SELECT Payment_Method,
       SUM(Amount) as Total_Amount
FROM Payments
group by Payment_Method
having SUM(Amount) > 72000;

SELECT Payment_Method,
       AVG(Amount) as Average_Amount
FROM Payments
where Payment_Status = 'Successful'
group by Payment_Method
having AVG(Amount) > 500;

SELECT Payment_Method,
       SUM(Amount) as Total_Amount
from Payments
where Payment_Status = 'Successful'
 and Amount > 300
group by Payment_Method
having SUM(Amount) > 71000
order by Total_Amount desc;

--  sub queries  --
SELECT * from movies
where duration_min = (
      select MAX(Duration_min)
      from movies
      )

SELECT * from movies 
where Duration_min = (
           select MIN(Duration_min)
           from movies
           )

SELECT * from movies
where Duration_min = (
        select MAX(screens)
        from theaters
        )

SELECT * from theaters
where screens = (
       select MIN(screens)
       from theaters
       )

SELECT * from bookings
where tickets = (
       select MAX(tickets)
       from bookings
       )

SELECT * from bookings
where tickets = (
        select MIN(tickets)
        from bookings
        )

SELECT * from payments
where amount =(
       select MAX(amount)
       from payments 
       )

SELECT * from payments
where amount =(
       select MIN(amount)
       from payments 
       )

SELECT movie_name from movies
where Duration_min > (
       select avg(duration_min)
       from movies
       ) 

SELECT theater_name from theaters
where screens > (
       select avg(screens)
       from theaters
       )

SELECT movie_name from movies
where Duration_min > (
       select duration_min from movies
       where movie_id = 77
       ) 

SELECT theater_name from theaters
where screens > (
       select screens from Theaters 
       where theater_id = 9
       )

SELECT u_name from users 
where city = (
      select city from users
      where u_id = 12 
      )

SELECT * from bookings 
where tickets > (
      select tickets from bookings
      where booking_id = 28 
      )

SELECT * from payments 
where amount > (
      select amount from payments
      where p_id = 108 
      )

SELECT movie_name from movies 
where duration_min < (
       select avg(Duration_min)
       from movies 
       )

SELECT theater_name from theaters 
where screens < (
       select avg(screens)
       from theaters 
       )

