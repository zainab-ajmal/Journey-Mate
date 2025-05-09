

-- User table
create TABLE Users (
    UID INT PRIMARY KEY NOT NULL,
    Usertype CHAR(1) NOT NULL
);

-- Passenger table
CREATE TABLE Passenger (
    Name VARCHAR(32) UNIQUE,
    PID INT NOT NULL PRIMARY KEY,
    Password VARCHAR(40) UNIQUE,
    Phone_no CHAR(12),
    CNIC CHAR(16),
    Premium_status INT, -- 0/1
    INDEX Name_Index (Name)
);

-- Vehicle table
CREATE TABLE Vehicle (
    Vehicle_id INT PRIMARY KEY,
    Plate_no VARCHAR(7),
    Model VARCHAR(40),
    Vehicle_type VARCHAR(30),
    Premium INT,
    Go_mini INT
);

-- Driver table
CREATE TABLE Driver (
    Name VARCHAR(32) UNIQUE,
    DID INT NOT NULL PRIMARY KEY,
    Password VARCHAR(40) UNIQUE,
    Phone_no CHAR(12),
    CNIC CHAR(16),
    Vehicle_id INT,
    FOREIGN KEY (Vehicle_id) REFERENCES Vehicle(Vehicle_id) ON DELETE CASCADE ON UPDATE CASCADE
);

-- P_login table
CREATE TABLE P_login (
    P_loginID INT PRIMARY KEY,
    Name VARCHAR(30),
    Password VARCHAR(40)
);

-- D_login table
CREATE TABLE D_login (
    D_loginID INT PRIMARY KEY,
    Name VARCHAR(30),
    Password VARCHAR(40)
);

-- P_Location table
CREATE TABLE P_Location (
    pLoc_ID INT PRIMARY KEY NOT NULL,
    pid INT,
    p_Loc VARCHAR(100),
    dest_location VARCHAR(100),
    FOREIGN KEY (pid) REFERENCES Passenger(PID) ON DELETE CASCADE ON UPDATE CASCADE
);

-- D_location table
CREATE TABLE D_location (
    Dloc_ID INT PRIMARY KEY,
    DID INT,
    D_loc VARCHAR(100),
    FOREIGN KEY (DID) REFERENCES Driver(DID) ON DELETE CASCADE ON UPDATE CASCADE
);

-- MatchingofTime table
CREATE TABLE MatchingofTime (
    Match_ID INT PRIMARY KEY NOT NULL,
    DID INT,
    PID INT,
    Ploc_ID INT,
    Dloc_ID INT,
    Matchtime BOOLEAN,
    FOREIGN KEY (PID) REFERENCES Passenger(PID) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (DID) REFERENCES Driver(DID) ON DELETE CASCADE ON UPDATE CASCADE
);

-- Price_setting table
CREATE TABLE Price_setting (
    Price_ID INT NOT NULL PRIMARY KEY,
    Match_ID INT,
    Price INT,
    FOREIGN KEY (Match_ID) REFERENCES MatchingofTime(Match_ID) ON DELETE CASCADE ON UPDATE CASCADE
);

-- bookRide table
CREATE TABLE bookRide (
    Ride_ID INT PRIMARY KEY,
    PID INT,
    cancel_ride BOOLEAN,
    P_loc VARCHAR(100),
    Dest_location VARCHAR(40),
    Price_id INT,
    DID INT,
    D_loc VARCHAR(100),
    FOREIGN KEY (PID) REFERENCES Passenger(PID) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (Price_id) REFERENCES Price_setting(Price_ID) ON DELETE CASCADE ON UPDATE CASCADE
);

-- Rating table
CREATE TABLE Rating (
    Rate_ID INT PRIMARY KEY NOT NULL,
    DID INT,
    PID INT,
    Stars FLOAT,
    Average_rating FLOAT,
    Ride_ID INT,
    FOREIGN KEY (PID) REFERENCES Passenger(PID),
    FOREIGN KEY (DID) REFERENCES Driver(DID),
    FOREIGN KEY (Ride_ID) REFERENCES bookRide(Ride_ID)
);

-- Pre_booking table
CREATE TABLE Pre_booking (
    Prebook_ID INT NOT NULL PRIMARY KEY,
    Ride_ID INT,
    Pre_bookdate DATE,
    Ride_date DATE,
    FOREIGN KEY (Ride_ID) REFERENCES bookRide(Ride_ID) ON DELETE CASCADE ON UPDATE CASCADE
);

-- Accident table
CREATE TABLE Accident (
    Accident_id INT PRIMARY KEY,
    Ride_id INT,
    Compensation_amount INT,
    FOREIGN KEY (Ride_id) REFERENCES bookRide(Ride_ID)
);

-- Update_Average_Rating_OF_Driver procedure

DELIMITER //
CREATE PROCEDURE Update_Average_Rating_OF_Driver (
    IN DID INT,
    IN Rating FLOAT
)
BEGIN
    DECLARE Total_Rating FLOAT;
    DECLARE Count_Rating INT;
    DECLARE Average_Rating FLOAT;

    -- Select total rating
    SELECT SUM(Stars) INTO Total_Rating FROM Rating WHERE DID = DID;
    
    -- Select count rating
    SELECT COUNT(*) INTO Count_Rating FROM Rating WHERE DID = DID;

    -- Calculate average rating
    SET Average_Rating = (Total_Rating + Rating) / (Count_Rating + 1);

    -- Update average rating
    UPDATE Rating SET Average_rating = Average_Rating WHERE DID = DID;
END //
DELIMITER ;



-- Premium_Cars_View view
CREATE VIEW Premium_Cars_View AS
SELECT Driver.DID
FROM Driver
JOIN Vehicle ON Driver.Vehicle_id = Vehicle.Vehicle_id
WHERE Vehicle.Premium = 1;

-- Go_Mini_Rides_View view
CREATE VIEW Go_Mini_Rides_View AS
SELECT Driver.DID
FROM Driver
JOIN Vehicle ON Driver.Vehicle_id = Vehicle.Vehicle_id
WHERE Vehicle.Go_mini = 1;

-- Ride_Reminder trigger
DELIMITER //
CREATE TRIGGER Ride_Reminder
AFTER UPDATE ON Pre_booking
FOR EACH ROW
BEGIN
    IF NEW.Ride_date = CURDATE() THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Reminder: Your Ride is today!';
    END IF;
END //
DELIMITER ;

-- report_accident trigger
DELIMITER //
CREATE TRIGGER report_accident
AFTER INSERT ON Accident
FOR EACH ROW
BEGIN
    DECLARE ride_id_msg VARCHAR(100);

    SET ride_id_msg = CONCAT('An accident has occurred for ride ID: ', NEW.Ride_id);
    
    -- Insert the accident message into a log table
    INSERT INTO Accident_Log (Accident_Message) VALUES (ride_id_msg);
END;
//
DELIMITER ;



-- check_P_password trigger
DELIMITER //
CREATE TRIGGER check_P_password
AFTER INSERT ON P_login
FOR EACH ROW
BEGIN
    IF LENGTH(NEW.Password) < 8 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'The password is weak. Make sure the password is at least 8 characters.';
    ELSE
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'The password has been set.';
    END IF;
END;
//
DELIMITER ;

-- check_D_password trigger
DELIMITER //
CREATE TRIGGER check_D_password
AFTER INSERT ON D_login
FOR EACH ROW
BEGIN
    IF LENGTH(NEW.Password) < 8 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'The password is weak. Make sure the password is at least 8 characters.';
    ELSE
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'The password has been set.';
    END IF;
END;
//
DELIMITER ;

-- preBooking_procedure procedure
DELIMITER //
CREATE PROCEDURE preBooking_procedure (
    IN prebook_ID INT,
    IN ride_id INT,
    IN booking_date DATE,
    IN ride_date DATE
)
BEGIN
    IF DATEDIFF(booking_date, CURDATE()) > 1 THEN
        SELECT 'You can prebook rides for the same date or the next date only.' AS Message;
    ELSE
        INSERT INTO Pre_booking (Prebook_ID, Ride_ID, Pre_bookdate, Ride_date) VALUES (prebook_ID, ride_id, booking_date, ride_date);
        SELECT 'Your ride has been prebooked successfully.' AS Message;
    END IF;
END //
DELIMITER ;

-- passenger_and_driver view
CREATE VIEW passenger_and_driver AS
SELECT 
    Driver.DID, 
    Driver.Name AS driver_name, 
    Driver.Phone_no AS driver_phoneNO, 
    Passenger.Name AS passenger_name, 
    Passenger.PID, 
    Passenger.Phone_no AS passenger_phoneNo
FROM 
    (Driver JOIN bookRide ON Driver.DID = bookRide.DID) 
    JOIN Passenger ON Passenger.PID = bookRide.PID;

-- Match_Time_View view
CREATE VIEW Match_Time_View AS
SELECT 
    Driver.Name AS Driver_Name, 
    D_location.D_loc AS Driver_Location, 
    Passenger.Name AS Passenger_Name
FROM 
    MatchingofTime 
    JOIN Passenger ON Passenger.PID = MatchingofTime.PID 
    JOIN Driver ON Driver.DID = MatchingofTime.DID 
    JOIN D_location ON D_location.Dloc_ID = MatchingofTime.Dloc_ID
WHERE 
    MatchingofTime.Matchtime = 1;

-- Assigned_Driver view
CREATE VIEW Assigned_Driver AS
SELECT 
    Passenger.Name AS Passenger_Name, 
    Passenger.Phone_no AS passenger_phone_no, 
    Driver.Name AS Driver_Name, 
    Driver.Phone_no AS driver_phone_no, 
    Vehicle.Vehicle_type, 
    Vehicle.Model, 
    Vehicle.Plate_no
FROM 
    bookRide 
    JOIN Passenger ON Passenger.PID = bookRide.PID 
    JOIN Driver ON Driver.DID = bookRide.DID 
    JOIN Vehicle ON Vehicle.Vehicle_id = Driver.Vehicle_id;

-- Cancel_Ride trigger
DELIMITER //
CREATE TRIGGER Cancel_Ride
AFTER UPDATE ON bookRide
FOR EACH ROW
BEGIN
    IF NEW.cancel_ride = 1 THEN
        UPDATE bookRide SET ride_status = 'Cancelled' WHERE PID = NEW.PID;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ride has been cancelled.';
    END IF;
END //
DELIMITER ;
DELIMITER //
CREATE TRIGGER Cancel_Ride
AFTER UPDATE ON bookRide
FOR EACH ROW
BEGIN
    IF NEW.cancel_ride = 1 THEN
        UPDATE bookRide SET ride_status = 'Cancelled' WHERE PID = NEW.PID;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Ride has been cancelled.';
    END IF;
END //
DELIMITER ;


