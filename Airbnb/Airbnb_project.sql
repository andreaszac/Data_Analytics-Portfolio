/*
Edinburgh Airbnb Data Exploration
Skills used: Joins, CTE's, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
*/

-- Look at the data
SELECT TOP(10)*
FROM PortfolioProject..listing_cleansed;


-- Count room types and percentage. 6767 is the total number of accommodations listed
SELECT room_type,COUNT(room_type) AS "Number", ROUND(CONVERT(float, COUNT(room_type))/6767*100,2) AS Percentage, ROUND(AVG(Accommodates),2) AS Accommodates
FROM PortfolioProject..listing_cleansed
GROUP BY room_type
ORDER BY 2 DESC;


-- Average price for the 5 neighbourhoods with most accommodations
SELECT TOP(5) neighbourhood_cleansed, COUNT(neighbourhood_cleansed) AS number_of_accommodations, ROUND(AVG(price),2) AS average_price 
FROM PortfolioProject..listing_cleansed
GROUP BY neighbourhood_cleansed
ORDER BY 2 DESC;


-- Find the average availability in 30 days for the 5 neighbourhoods with highest accommodations. 
-- Calculate occupancy rate and Gross Monthly Income
SELECT neighbourhood_cleansed, ROUND(AVG(availability_30),2) AS "Average Availability in 30 days",
ROUND(100-(AVG(availability_30)/30*100),2) AS "Occupancy Rate", ROUND((30-AVG(availability_30)) *AVG(price),2) AS "Gross Monthly Income"
FROM PortfolioProject..listing_cleansed
WHERE neighbourhood_cleansed IN ('Old Town, Princes Street and Leith Street', 'Deans Village', 'Tollcross', 'Hillside and Calton Hill', 'New Town West')
AND availability_365 <> 0
GROUP BY neighbourhood_cleansed
ORDER BY 4 DESC;


-- Most profitable neighbourhoods per month to invest in for property of 4 people 
-- Exlclude neighbourhoods with low number of listings
SELECT neighbourhood_cleansed, COUNT(id) AS "Number of Listings", ROUND(AVG(price),2) AS "Average Price", 
30-ROUND(AVG(availability_30),2) AS "Average Unavailability in 30 days", 
ROUND(AVG(price) * (30-AVG(availability_30)),2) AS "Gross Monthly Income"
FROM PortfolioProject..listing_cleansed
WHERE accommodates = 4 
AND availability_365 <> 0
GROUP BY neighbourhood_cleansed
HAVING COUNT(id) > 20 AND AVG(price) * (30-AVG(availability_30)) > 3000
ORDER BY 5 DESC;


/* A new dataset was downloaded in order to assign the 111 neighbourhood_cleansed into broader_areas so it can give better visuals.
   After checking the 111 neighbourhoods, "Siverknowes and Davidson's Mains" needs to be updated to "Silverknowes and Davidson''s Mains" 
   in order to match with the new dataset
*/

UPDATE PortfolioProject..listing_cleansed
SET neighbourhood_cleansed = REPLACE(neighbourhood_cleansed, 'Siverknowes and Davidson''s Mains', 'Silverknowes and Davidson''s Mains')


-- Join broader_area and listing_cleansed tables to find number of accommodations and average price per broader area
SELECT br.broader_area, COUNT(li.neighbourhood_cleansed) AS "Number of accommodations", ROUND(AVG(li.price),2) AS "Average Price"
FROM PortfolioProject..broader_areas AS br
JOIN PortfolioProject..listing_cleansed as li
ON br.neighbourhood_cleansed = li.neighbourhood_cleansed
GROUP BY br.broader_area
ORDER BY 2 DESC;


-- Add rolling sum of each broader_area portion
SELECT br.broader_area AS Area, COUNT(li.neighbourhood_cleansed) AS "Number of Accommodations",
SUM(CONVERT(int, COUNT(li.neighbourhood_cleansed))) OVER (ORDER BY (COUNT(li.neighbourhood_cleansed))DESC) AS "Rolling Sum of Accommodations",
(ROUND((CAST(COUNT(li.neighbourhood_cleansed) AS float)/6767)*100,2)) AS "Area Percentage"
FROM PortfolioProject..listing_cleansed AS li, PortfolioProject..broader_areas AS br
WHERE li.neighbourhood_cleansed = br.neighbourhood_cleansed
GROUP BY br.broader_area;


-- Use CTE to perform calculation from a previous query
WITH Broadlist (Area, "Number of Accommodations", Rolling_Sum, "Area Percentage")
AS
(
SELECT br.broader_area AS Area, COUNT(li.neighbourhood_cleansed) AS "Number of Accommodations",
SUM(CONVERT(int, COUNT(li.neighbourhood_cleansed))) OVER (ORDER BY (COUNT(li.neighbourhood_cleansed))DESC) AS "Rolling Sum of Accommodations",
(ROUND((CAST(COUNT(li.neighbourhood_cleansed) AS float)/6767)*100,2)) AS area_percentage
FROM PortfolioProject..listing_cleansed AS li, PortfolioProject..broader_areas AS br
WHERE li.neighbourhood_cleansed = br.neighbourhood_cleansed
GROUP BY br.broader_area
)
SELECT *,ROUND((CAST(Rolling_Sum AS float)/6767)*100,2) AS "Rolling Percentage"
FROM Broadlist;


-- Join the two tables in order to use it in map visualisation
SELECT li.id, li.name, li.neighbourhood_cleansed, li.latitude, li.longitude, li.room_type, li.price, li.minimum_nights, br.broader_area
FROM PortfolioProject..listing_cleansed AS li
LEFT JOIN PortfolioProject..broader_areas AS br ON li.neighbourhood_cleansed = br.neighbourhood_cleansed;


-- Find competitors in Leith area
SELECT COUNT(li.id) AS "Number of Listings", ROUND(AVG(li.price),2) AS "Average Price", br.broader_area
FROM PortfolioProject..listing_cleansed AS li
LEFT JOIN PortfolioProject..broader_areas AS br ON li.neighbourhood_cleansed = br.neighbourhood_cleansed
WHERE broader_area = 'Leith'
GROUP BY broader_area;

-- Find Entire home/apt in the Leith area with specific amenities
SELECT li.id, li.listing_url, ROUND(li.price,2) AS Price
FROM PortfolioProject..listing_cleansed AS li
LEFT JOIN PortfolioProject..broader_areas AS br ON li.neighbourhood_cleansed = br.neighbourhood_cleansed
WHERE broader_area = 'Leith' AND room_type = 'Entire home/apt' AND
amenities LIKE '%BBQ grill%' AND amenities LIKE '%Coffee maker%'
ORDER BY 3 DESC;


-- Find amenities percentage and save it as a view for later use


-- Garden
CREATE VIEW Garden AS
SELECT COUNT(id) AS Number, ROUND(CONVERT(float, COUNT(id))/6767*100,0) AS Percentage
FROM PortfolioProject..listing_cleansed
WHERE amenities LIKE '%garden%';

-- Fireplace
CREATE VIEW Fireplace AS
SELECT COUNT(id) AS Number, ROUND(CONVERT(float, COUNT(id))/6767*100,0) AS Percentage
FROM PortfolioProject..listing_cleansed
WHERE amenities LIKE '%fireplace%';


-- Heating
CREATE VIEW Heating AS
SELECT COUNT(id) AS Number, ROUND(CONVERT(float, COUNT(id))/6767*100,0) AS Percentage
FROM PortfolioProject..listing_cleansed
WHERE amenities LIKE '%Heating%';


-- BBQ Grill
CREATE VIEW BBQ_grill AS
SELECT COUNT(id) AS Number, ROUND(CONVERT(float, COUNT(id))/6767*100,0) AS Percentage
FROM PortfolioProject..listing_cleansed
WHERE amenities LIKE '%BBQ grill%';


-- Parking
CREATE VIEW Parking AS
SELECT COUNT(id) AS Number, ROUND(CONVERT(float, COUNT(id))/6767*100,0) AS Percentage
FROM PortfolioProject..listing_cleansed
WHERE amenities LIKE '%parking%';


-- Hot tub
CREATE VIEW Hot_tub AS
SELECT COUNT(id) AS Number, ROUND(CONVERT(float, COUNT(id))/6767*100,0) AS Percentage
FROM PortfolioProject..listing_cleansed
WHERE amenities LIKE '%hot tub%';

-- Hot tub
CREATE VIEW Coffee_maker AS
SELECT COUNT(id) AS Number, ROUND(CONVERT(float, COUNT(id))/6767*100,0) AS Percentage
FROM PortfolioProject..listing_cleansed
WHERE amenities LIKE '%Coffee maker%';

-- Wifi
CREATE VIEW Wifi AS
SELECT COUNT(id) AS Number, ROUND(CONVERT(float, COUNT(id))/6767*100,0) AS Percentage
FROM PortfolioProject..listing_cleansed
WHERE amenities LIKE '%Wifi%';

-- Bikes
CREATE VIEW Bikes AS
SELECT COUNT(id) AS Number, ROUND(CONVERT(float, COUNT(id))/6767*100,0) AS Percentage
FROM PortfolioProject..listing_cleansed
WHERE amenities LIKE '%Bikes%';

-- Self check-in
CREATE VIEW self_checkin AS
SELECT COUNT(id) AS Number, ROUND(CONVERT(float, COUNT(id))/6767*100,0) AS Percentage
FROM PortfolioProject..listing_cleansed
WHERE amenities LIKE '%Self check-in%';


-- Combine all views for vizualisation
SELECT * FROM Garden
UNION ALL 
SELECT * FROM Fireplace
UNION ALL
SELECT * FROM Heating
UNION ALL
SELECT * FROM BBQ_grill
UNION ALL
SELECT * FROM Parking
UNION ALL
SELECT * FROM Hot_tub
UNION ALL
SELECT * FROM Coffee_maker
UNION ALL
SELECT * FROM Wifi
UNION ALL
SELECT * FROM Bikes
UNION ALL
SELECT * FROM self_checkin;




-- At this point I will check the format of my third dataset

-- Look at the data
SELECT TOP(5) *
FROM PortfolioProject..all_calendar_data;


-- Change price column data type to float
ALTER TABLE PortfolioProject..all_calendar_data
ALTER COLUMN price FLOAT;


-- Change date column data type to date
ALTER TABLE PortfolioProject..all_calendar_data
ALTER COLUMN date date;


-- Create a view to store data for later use
CREATE VIEW CalendarListing AS
SELECT ca.listing_id, ca.date, ca.available, ca.price, ca.minimum_nights, li.room_type, li.accommodates
FROM PortfolioProject..all_calendar_data AS ca
LEFT JOIN PortfolioProject..listing_cleansed AS li ON ca.listing_id = li.id;


-- Average price per night for room types per date
SELECT room_type, AVG(price) AS "Average Price", date 
FROM CalendarListing
WHERE room_type IS NOT NULL
GROUP BY room_type, date
ORDER BY date, room_type;


-- Calculate the average price from calendar data
SELECT AVG(price) AS average_price, FORMAT(date, 'MM-yyyy') AS month_of_year
FROM PortfolioProject..all_calendar_data
GROUP BY FORMAT(date, 'MM-yyyy')
ORDER BY 
	CASE
		WHEN FORMAT(date, 'MM-yyyy') LIKE '%2021' THEN 0
		WHEN FORMAT(date, 'MM-yyyy') LIKE '%2022' THEN 1
		ELSE 2
END ASC,
FORMAT(date, 'MM-yyyy');

SELECT room_type, AVG(accommodates)
FROM CalendarListing
WHERE room_type IS NOT NULL
GROUP BY room_type;
