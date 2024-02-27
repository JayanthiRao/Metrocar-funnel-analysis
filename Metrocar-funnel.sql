/* How many times was the app downloaded? */

SELECT DISTINCT COUNT(*) 
FROM app_downloads;

/* How many users signed up on the app? */

SELECT DISTINCT COUNT(*) 
FROM signups;

/* How many rides were requested through the app? */

SELECT COUNT(*) AS ride_request_thru_app
FROM ride_requests;

/* How many rides were requested and completed through the app? */

SELECT COUNT(*) AS ride_request_completed
FROM ride_requests
WHERE cancel_ts IS NULL;

/* How many rides were requested and how many unique users requested a ride? */

SELECT COUNT(*) AS ride_request_thru_app,COUNT( DISTINCT user_id) AS distinct_user
FROM ride_requests;

/* What is the average time of a ride from pick up to drop off? */

SELECT AVG(dropoff_ts - pickup_ts) AS avg_duration
FROM ride_requests;

/* How many rides were accepted by a driver? */

SELECT COUNT(accept_ts) AS rides_accepted
FROM ride_requests;

/* How many rides did we successfully collect payments and how much was collected? */

SELECT COUNT(transaction_id) AS payment_collected, SUM(purchase_amount_usd) AS total_amount
FROM transactions
WHERE charge_status = 'Approved';

/* How many ride requests happened on each platform? */

SELECT platform, COUNT(r.*) AS ride_request
FROM signups AS s
JOIN app_downloads AS a
ON a.app_download_key = s.session_id
JOIN ride_requests AS r
ON r.user_id = s.user_id
GROUP BY platform;

/*What is the drop-off from users signing up to users requesting a ride? */

WITH sign_up_count AS (
SELECT COUNT(user_id) AS count_signups
FROM signups
),
ride_request_count AS (
SELECT COUNT(DISTINCT user_id) AS count_riderequest
FROM ride_requests
)
SELECT (1-(count_riderequest::float/ count_signups::float)) *100 AS drop_off_rate
FROM sign_up_count, ride_request_count;




/* Of the users that signed up on the app, what percentage these users completed a ride? */ 

 WITH rides AS 
  (SELECT (SELECT COUNT(*) AS total_signups
          FROM signups),
         COUNT(DISTINCT
            CASE
                WHEN rr.dropoff_ts IS NOT NULL
                THEN rr.user_id
            END) AS completed_ride
  FROM ride_requests AS rr)

  SELECT completed_ride/total_signups::float AS conversion
  FROM rides

/* Using the percent of previous approach, what are the user-level conversion rates for the 
first 3 stages of the funnel (app download to signup and signup to ride requested)? */

WITH steps AS
(SELECT 'app_download' AS step, COUNT(*) from app_downloads
UNION
SELECT 'signup' AS step, COUNT(*) from signups
UNION
SELECT 'ride' AS step, COUNT(DISTINCT user_id) from ride_requests
UNION
SELECT 'ride_completed' AS step, COUNT(DISTINCT
                                    CASE
                                        WHEN dropoff_ts IS NOT NULL
                                        THEN user_id
                                    END) FROM ride_requests
ORDER BY count DESC
)
SELECT step, count, 
    lag(count,1) OVER(),
    round((count::numeric/lag(count, 1) over ()),3) AS conversion_rate
FROM steps

/* Using the percent of top approach, what are the user-level conversion rates for the 
first 3 stages of the funnel (app download to signup and signup to ride requested)? */

WITH steps AS
(SELECT 'app_download' AS step, COUNT(*) from app_downloads
UNION
SELECT 'signup' AS step, COUNT(*) from signups
UNION
SELECT 'ride' AS step, COUNT(DISTINCT user_id) from ride_requests
ORDER BY count DESC
)
SELECT step, count, 
    FIRST_VALUE(count) OVER(),
    round((count::numeric/FIRST_VALUE(count) over ()),3) AS conversion_rate
FROM steps  

/* Using the percent of previous approach, what are the user-level conversion rates for the 
following 3 stages of the funnel? 1. signup, 2. ride requested, 3. ride completed */

WITH steps AS
(SELECT 'signup' AS step, COUNT(*) from signups
UNION
SELECT 'ride' AS step, COUNT(DISTINCT user_id) from ride_requests
UNION
SELECT 'ride_completed' AS step, COUNT(DISTINCT
                                    CASE
                                        WHEN dropoff_ts IS NOT NULL
                                        THEN user_id
                                    END) FROM ride_requests
ORDER BY count DESC
)
SELECT step, count, 
    lag(count,1) OVER(),
    round((count::numeric/lag(count, 1) over ()),3) AS conversion_rate
FROM steps

/* Using the percent of top approach, what are the user-level conversion rates for the 
following 3 stages of the funnel? 1. signup, 2. ride requested, 3. ride completed (hint: signup is t
he top of this funnel) This question is required. */

WITH steps AS
(SELECT 'signup' AS step, COUNT(*) from signups
UNION
SELECT 'ride' AS step, COUNT(DISTINCT user_id) from ride_requests
UNION
SELECT 'ride_completed' AS step, COUNT(DISTINCT
                                    CASE
                                        WHEN dropoff_ts IS NOT NULL
                                        THEN user_id
                                    END) FROM ride_requests
ORDER BY count DESC
)
SELECT step, count, 
    FIRST_VALUE(count) OVER(),
    round((count::numeric/FIRST_VALUE(count) over ()),3) AS conversion_rate
FROM steps ;



/* platform user_level */

WITH complete AS
(SELECT COUNT(DISTINCT app_download_key) AS app_download, COUNT(DISTINCT s.user_id) AS signup,
 platform,
COUNT(DISTINCT rr.user_id) AS ride_requested,
COUNT( DISTINCT 
      CASE
      	WHEN rr.accept_ts IS NOT NULL
      	THEN rr.user_id
      END) AS accepted_rides,
COUNT(DISTINCT
    CASE
        WHEN rr.dropoff_ts IS NOT NULL
        THEN rr.user_id
    END) as completed_rides,
COUNT(DISTINCT t.ride_id) AS payment,
 COUNT( DISTINCT r.user_id) AS review
FROM app_downloads AS ad
LEFT JOIN signups AS s
ON ad.app_download_key = s.session_id
LEFT JOIN ride_requests AS rr
ON s.user_id = rr.user_id
LEFT JOIN transactions as t
ON rr.ride_id = t.ride_id
LEFT JOIN  reviews AS r
ON s.user_id = r.user_id
GROUP BY platform),

funnel_stages AS (
    SELECT platform,
        1 AS funnel_step,
        'app_downloads' AS funnel_name,
        app_download AS user_count
    FROM complete

    UNION 

    SELECT platform,
        2 AS funnel_step,
        'signups' AS funnel_name,
        signup AS user_count
    FROM complete

    UNION

    SELECT platform,
        3 AS funnel_step,
        'ride_requested' AS funnel_name,
        ride_requested AS user_count
    FROM complete

    UNION
  
  	SELECT platform,
        4 AS funnel_step,
        'accepted_rides' AS funnel_name,
        accepted_rides AS user_count
    FROM complete
  
  	UNION

    SELECT platform,
        5 AS funnel_step,
        'completed_ride' AS funnel_name,
        completed_rides AS user_count
    FROM complete

  	UNION
  
  	SELECT platform,
        6 AS funnel_step,
        'payment' AS funnel_name,
        completed_rides AS user_count
    FROM complete
  
  	UNION
  
  SELECT platform,
        7 AS funnel_step,
        'review' AS funnel_name,
        review AS user_count
    FROM complete)

SELECT *
FROM funnel_stages
ORDER BY  funnel_step;




/* age_range_funnel user_level*/
WITH complete AS
(SELECT COUNT(DISTINCT app_download_key) AS app_download, COUNT(DISTINCT s.user_id) AS signup,
 age_range,
COUNT(DISTINCT rr.user_id) AS ride_requested,
COUNT( DISTINCT 
      CASE
      	WHEN rr.accept_ts IS NOT NULL
      	THEN rr.user_id
      END) AS accepted_rides,
COUNT(DISTINCT
    CASE
        WHEN rr.dropoff_ts IS NOT NULL
        THEN rr.user_id
    END) as completed_rides,
COUNT(DISTINCT t.ride_id) AS payment,
 COUNT( DISTINCT r.user_id) AS review
FROM app_downloads AS ad
LEFT JOIN signups AS s
ON ad.app_download_key = s.session_id
LEFT JOIN ride_requests AS rr
ON s.user_id = rr.user_id
LEFT JOIN transactions as t
ON rr.ride_id = t.ride_id
LEFT JOIN  reviews AS r
ON s.user_id = r.user_id
GROUP BY age_range),

funnel_stages AS (
    SELECT age_range,
        1 AS funnel_step,
        'app_downloads' AS funnel_name,
        app_download AS user_count
    FROM complete

    UNION 

    SELECT age_range,
        2 AS funnel_step,
        'signups' AS funnel_name,
        signup AS user_count
    FROM complete

    UNION

    SELECT age_range,
        3 AS funnel_step,
        'ride_requested' AS funnel_name,
        ride_requested AS user_count
    FROM complete

    UNION
  
  	SELECT age_range,
        4 AS funnel_step,
        'accepted_rides' AS funnel_name,
        accepted_rides AS user_count
    FROM complete
  
  	UNION

    SELECT age_range,
        5 AS funnel_step,
        'completed_ride' AS funnel_name,
        completed_rides AS user_count
    FROM complete

  	UNION
  
  	SELECT age_range,
        6 AS funnel_step,
        'payment' AS funnel_name,
        completed_rides AS user_count
    FROM complete
  
  	UNION
  
  SELECT age_range,
        7 AS funnel_step,
        'review' AS funnel_name,
        review AS user_count
    FROM complete)

SELECT *
FROM funnel_stages
ORDER BY  funnel_step, age_range;



/* platform and age_range user and ride levels */

WITH complete AS
(SELECT COUNT(DISTINCT app_download_key) AS app_download, COUNT(DISTINCT s.user_id) AS signup,
 age_range, platform, 
COUNT(DISTINCT rr.user_id) AS ride_requested, COUNT(  DISTINCT rr.ride_id) AS total_ride_requests,
COUNT( DISTINCT 
      CASE
      	WHEN rr.accept_ts IS NOT NULL
      	THEN rr.user_id
      END) AS accepted_rides,
 COUNT( DISTINCT
      CASE
      	WHEN rr.accept_ts IS NOT NULL
      	THEN rr.ride_id
      END) AS total_accepted_rides,
COUNT(DISTINCT
    CASE
        WHEN rr.dropoff_ts IS NOT NULL
        THEN rr.user_id
    END) as completed_rides,
 COUNT(DISTINCT
    CASE
        WHEN rr.dropoff_ts IS NOT NULL
        THEN rr.ride_id
    END) as total_completed_rides,
COUNT(DISTINCT t.ride_id) AS payment,
 COUNT( DISTINCT r.user_id) AS review,
 COUNT(DISTINCT r.ride_id) AS total_reviews
FROM app_downloads AS ad
LEFT JOIN signups AS s
ON ad.app_download_key = s.session_id
LEFT JOIN ride_requests AS rr
ON s.user_id = rr.user_id
LEFT JOIN transactions as t
ON rr.ride_id = t.ride_id
LEFT JOIN  reviews AS r
ON s.user_id = r.user_id
GROUP BY age_range, platform),

funnel_stages AS (
    SELECT age_range,platform, 
        1 AS funnel_step,
        'app_downloads' AS funnel_name,
        app_download AS user_count,
  			0 AS ride_count
    FROM complete

    UNION 

    SELECT age_range,platform, 
        2 AS funnel_step,
        'signups' AS funnel_name,
        signup AS user_count,
  			0 AS ride_count
    FROM complete

    UNION

    SELECT age_range, platform, 
        3 AS funnel_step,
        'ride_requested' AS funnel_name,
        ride_requested AS user_count,
  			total_ride_requests AS ride_count
    FROM complete

    UNION
  
  	SELECT age_range,platform,
        4 AS funnel_step,
        'accepted_rides' AS funnel_name,
        accepted_rides AS user_count,
  			total_accepted_rides AS ride_count
    FROM complete
  
  	UNION

    SELECT age_range,platform, 
        5 AS funnel_step,
        'completed_ride' AS funnel_name,
        completed_rides AS user_count,
  			total_completed_rides AS ride_count
    FROM complete

  	UNION
  
  	SELECT age_range,platform, 
        6 AS funnel_step,
        'payment' AS funnel_name,
        completed_rides AS user_count,
  			payment AS ride_count
    FROM complete
  
  	UNION
  
  SELECT age_range, platform, 
        7 AS funnel_step,
        'review' AS funnel_name,
        review AS user_count,
  			total_reviews AS ride_count
    FROM complete)

SELECT *
FROM funnel_stages
ORDER BY  funnel_step, age_range, platform;
