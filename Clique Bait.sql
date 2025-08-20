Create database CliqueBait
---create users table
create table Users(User_id int primary key, cookie_id varchar(50), start_date datetime );
---create events table
create table Events(visit_id varchar(20),cookie_id varchar(50),page_id int, event_type int ,sequence_number int,event_time datetime);
---create event identifier table
create table EventIdentifier(event_type int,event_name varchar(20));
---create campaign identifier table
create table CampaignIdentifier(campaign_id int,products varchar(20), campaign_name varchar(50),start_date datetime,end_date datetime);
drop table CampaignIdentifier
---create campaign identifier table
create table CampaignIdentifier(campaign_id int,products varchar(20), campaign_name varchar(100),start_date datetime,end_date datetime);
---create page hierarchy table
create table HierarchyTable(page_id int, page_name varchar(20),product_category varchar(20),product_id int);
drop table HierarchyTable
---create page hierarchy table
create table PageHierarchy(page_id int, page_name varchar(50),product_category varchar(50),product_id int);

--insert users
insert into Users(user_id,cookie_id,start_date)values(397,'3759ff',2020-03-30),(215,'863329',2020-01-26),(191,'eefca9',2020-03-15),(89,'764796',2020-01-07),(127,'17ccc5',2020-01-22),(81,'b0b666',2020-03-01),(260,'94f236',2020-01-08),(203,'d1182f',2020-04-18),(23,'12dbc8',2020-01-18),(375,'f61d69',2020-01-03);
--insert events
insert into Events(visit_id,cookie_id,page_id,event_type,sequence_number,event_time)values('719fd3','3d83d3',5,1,4,2020-03-02),('fb1eb1','c5ff25',5,2,8,2020-01-22),('23fe81','1e8c2d',10,1,9,2020-03-21),
('ad91aa','648115',6,1,3,2020-04-27),('5576d7','ac418c',6,1,4,2020-01-18),('48308b','c686c1',8,1,5,2020-01-29),('46b17d','78f9b3',7,1,12,2020-02-16),
('9fd196','ccf057',4,1,5,2020-02-14),('edf853','f85454',1,1,1,2020-02-22),('3c6716','02e74f',3,2,5,2020-01-31);
--insert event identifier
insert into EventIdentifier(event_type,event_name)values(1,'Page View'),(2,'Add to Cart'),(3,'Purchase'),(4,'Ad Impression'),(5,'Ad Click');
--insert campaign identifier
insert into CampaignIdentifier(campaign_id,products,campaign_name,start_date,end_date)values(1,'1-3','BOGOF-Fishing For Compliments',2020-01-01,2020-01-14),(2,'4-5','25%Off- Living The Lux Life',2020-01-15,2020-01-28),(3,'6-8','Half Off-Treat Your Shellf(ish)',2020-02-01,2020-03-31);
--insert Page Hierarchy
insert into PageHierarchy(page_id,page_name,product_category,product_id)values(1,'HomePage','null',null),(2,'All Products','null',null),(3,'Salmon','Fish',1),
(4,'Kingfish','Fish',2),(5,'Tuna','Fish',3),(6,'Russian Caviar','Luxury',4),(7,'Black Truffle','Luxury',5),(8,'Abalone','Shellfish',6),(9,'Lobster','Shellfish',7),
(10,'Crab','Shellfish',8),(11,'Oyster','Shellfish',9),(12,'Checkout','null',null),(13,'Confirmation','null',null);

--How many users are there?
select COUNT(DISTINCT user_id)as total_users FROM Users;

--How many cookies does each user have on average?
SELECT 
    CAST(AVG(CAST(cookie_count AS FLOAT)) AS DECIMAL(10,2)) AS avg_cookies_per_user
FROM (
    SELECT 
        user_id, 
        COUNT(DISTINCT cookie_id) AS cookie_count
    FROM Users
    GROUP BY user_id
) AS user_cookie_counts;

 --what is the unique number of visits by all users per month?
SELECT 
    YEAR(event_time) AS visit_year,
    MONTH(event_time) AS visit_month,
    COUNT(DISTINCT visit_id) AS unique_visits
FROM events
GROUP BY YEAR(event_time), MONTH(event_time)
ORDER BY visit_year, visit_month;

---What is the number of events for each event type?
SELECT 
    e.event_type,
    ei.event_name,
    COUNT(*) AS total_events
FROM Events e
JOIN EventIdentifier ei
    ON e.event_type = ei.event_type
GROUP BY e.event_type, ei.event_name
ORDER BY total_events DESC;

--What is the percentage of visits which have a purchase event?
WITH visit_flags AS (
    SELECT 
        visit_id,
        MAX(CASE WHEN ei.event_name = 'Purchase' THEN 1 ELSE 0 END) AS has_purchase
    FROM Events e
    JOIN EventIdentifier ei 
        ON e.event_type = ei.event_type
    GROUP BY visit_id
)
SELECT 
    CAST(SUM(has_purchase) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS pct_visits_with_purchase
FROM visit_flags;

---What is the percentage of visits which view the checkout page but do not have a purchase event?
WITH visit_flags AS (
    SELECT 
        e.visit_id,
        MAX(CASE WHEN ph.page_name = 'Checkout' THEN 1 ELSE 0 END) AS saw_checkout,
        MAX(CASE WHEN ei.event_name = 'Purchase' THEN 1 ELSE 0 END) AS has_purchase
    FROM Events e
    JOIN PageHierarchy ph 
        ON e.page_id = ph.page_id
    JOIN EventIdentifier ei 
        ON e.event_type = ei.event_type
    GROUP BY e.visit_id
)
SELECT 
    CAST(SUM(CASE WHEN saw_checkout = 1 AND has_purchase = 0 THEN 1 ELSE 0 END) * 100.0 
         / NULLIF(SUM(CASE WHEN saw_checkout = 1 THEN 1 ELSE 0 END), 0) AS DECIMAL(5,2)) 
         AS pct_checkout_without_purchase
FROM visit_flags;

---What are the top 3 pages by number of views?
SELECT TOP 3
    ph.page_name,
    COUNT(*) AS total_views
FROM Events e
JOIN EventIdentifier ei 
    ON e.event_type = ei.event_type
JOIN PageHierarchy ph 
    ON e.page_id = ph.page_id
WHERE ei.event_name = 'Page View'
GROUP BY ph.page_name
ORDER BY total_views DESC;

---What is the number of views and cart adds for each product category?
SELECT 
    ph.product_category,
    SUM(CASE WHEN ei.event_name = 'Page View'   THEN 1 ELSE 0 END) AS total_views,
    SUM(CASE WHEN ei.event_name = 'Add to Cart' THEN 1 ELSE 0 END) AS total_adds
FROM Events e
JOIN EventIdentifier ei 
    ON e.event_type = ei.event_type
JOIN PageHierarchy ph 
    ON e.page_id = ph.page_id
GROUP BY ph.product_category
ORDER BY total_views DESC;

---What are the top 3 products by purchases?
SELECT TOP 3
    ph.page_name AS product_name,
    ph.product_id,
    COUNT(*) AS total_purchases
FROM Events e
JOIN EventIdentifier ei 
    ON e.event_type = ei.event_type
JOIN PageHierarchy ph 
    ON e.page_id = ph.page_id
WHERE ei.event_name = 'Purchase'
GROUP BY ph.page_name, ph.product_id
ORDER BY total_purchases DESC;