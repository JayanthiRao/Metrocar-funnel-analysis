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









WITH complete AS
(SELECT COUNT(DISTINCT app_download_key) AS app_download, COUNT(DISTINCT s.user_id) AS signup,
 age_range, platform, download_ts,
COUNT(DISTINCT rr.user_id) AS ride_requested, COUNT( rr.*) AS total_ride_requests,
COUNT( DISTINCT 
      CASE
      	WHEN rr.accept_ts IS NOT NULL
      	THEN rr.user_id
      END) AS accepted_rides,
 COUNT( 
      CASE
      	WHEN rr.accept_ts IS NOT NULL
      	THEN rr.user_id
      END) AS total_accepted_rides,
COUNT(DISTINCT
    CASE
        WHEN rr.dropoff_ts IS NOT NULL
        THEN rr.user_id
    END) as completed_rides,
 COUNT(
    CASE
        WHEN rr.dropoff_ts IS NOT NULL
        THEN rr.user_id
    END) as total_completed_rides,
COUNT(DISTINCT t.ride_id) AS payment,
 COUNT( DISTINCT r.user_id) AS review,
 COUNT(r.*) AS total_reviews
FROM app_downloads AS ad
LEFT JOIN signups AS s
ON ad.app_download_key = s.session_id
LEFT JOIN ride_requests AS rr
ON s.user_id = rr.user_id
LEFT JOIN transactions as t
ON rr.ride_id = t.ride_id
LEFT JOIN  reviews AS r
ON s.user_id = r.user_id
GROUP BY age_range, platform, download_ts),

funnel_stages AS (
    SELECT age_range,platform, download_ts AS download_date,
        1 AS funnel_step,
        'app_downloads' AS funnel_name,
        app_download AS user_count,
  			0 AS ride_count
    FROM complete

    UNION 

    SELECT age_range,platform, download_ts AS download_date,
        2 AS funnel_step,
        'signups' AS funnel_name,
        signup AS user_count,
  			0 AS ride_count
    FROM complete

    UNION

    SELECT age_range, platform, download_ts AS download_date,
        3 AS funnel_step,
        'ride_requested' AS funnel_name,
        ride_requested AS user_count,
  			total_ride_requests AS ride_count
    FROM complete

    UNION
  
  	SELECT age_range,platform, download_ts AS download_date,
        4 AS funnel_step,
        'accepted_rides' AS funnel_name,
        accepted_rides AS user_count,
  			total_accepted_rides AS ride_count
    FROM complete
  
  	UNION

    SELECT age_range,platform, download_ts AS download_date,
        5 AS funnel_step,
        'completed_ride' AS funnel_name,
        completed_rides AS user_count,
  			total_completed_rides AS ride_count
    FROM complete

  	UNION
  
  	SELECT age_range,platform, download_ts AS download_date,
        6 AS funnel_step,
        'payment' AS funnel_name,
        completed_rides AS user_count,
  			payment AS ride_count
    FROM complete
  
  	UNION
  
  SELECT age_range, platform, download_ts AS download_date,
        7 AS funnel_step,
        'review' AS funnel_name,
        review AS user_count,
  			total_reviews AS ride_count
    FROM complete)

SELECT *
FROM funnel_stages
ORDER BY  funnel_step, age_range, platform;



