WITH app_signup AS
(SELECT COUNT(DISTINCT app_download_key) AS app_download, COUNT(DISTINCT s.user_id) AS signup, age_range,
COUNT(DISTINCT rr.user_id) AS ride_requested,
        COUNT(DISTINCT
        CASE
            WHEN rr.dropoff_ts IS NOT NULL
            THEN rr.user_id
        END) as completed_rides
FROM app_downloads AS ad
LEFT JOIN signups AS s
ON ad.app_download_key = s.session_id
LEFT JOIN ride_requests AS rr
ON s.user_id = rr.user_id
GROUP BY age_range)


SELECT age_range, app_download, signup, ride_requested, completed_rides
FROM app_signup;



/* platform downloads and signups and percentage conversion */

SELECT
    platform,
    downloads,
    SUM(downloads) OVER () AS total_downloads,
    downloads::float /
        SUM(downloads) OVER () AS pct_of_downloads, signup,
        SUM(signup) OVER () AS total_signup,
    signup::float /
        SUM(signup) OVER () AS pct_of_signup
FROM (
    SELECT
        platform,
        COUNT(*) AS downloads,
        COUNT(s.user_id) AS signup
        
    FROM app_downloads AS a
    LEFT JOIN signups AS s
    ON a.app_download_key = s.session_id
   
    GROUP BY platform
) result;



SELECT age_range, app_download,SUM(app_download) OVER () AS total_downloads,
    app_download::float /
        SUM(app_download) OVER () AS pct_of_downloads, 
        signup, SUM(signup) OVER () AS total_signups,
    signup::float /
        SUM(signup) OVER () AS pct_of_signups,
        ride_requested, SUM(ride_requested) OVER () AS total_rides,
    ride_requested::float /
        SUM(ride_requested) OVER () AS pct_of_rides_requested,
        completed_rides,SUM(completed_rides) OVER () AS total_ride_completed,
    completed_rides::float /
        SUM(completed_rides) OVER () AS pct_of_rides_completed
FROM 
(SELECT COUNT(DISTINCT app_download_key) AS app_download, COUNT(DISTINCT s.user_id) AS signup, age_range,
COUNT(DISTINCT rr.user_id) AS ride_requested,
        COUNT(DISTINCT
        CASE
            WHEN rr.dropoff_ts IS NOT NULL
            THEN rr.user_id
        END) as completed_rides
FROM app_downloads AS ad
LEFT JOIN signups AS s
ON ad.app_download_key = s.session_id
LEFT JOIN ride_requests AS rr
ON s.user_id = rr.user_id
GROUP BY age_range) AS result;



WITH complete AS
(SELECT COUNT(DISTINCT app_download_key) AS app_download, COUNT(DISTINCT s.user_id) AS signup, age_range,
COUNT(DISTINCT rr.user_id) AS ride_requested,
        COUNT(DISTINCT
        CASE
            WHEN rr.dropoff_ts IS NOT NULL
            THEN rr.user_id
        END) as completed_rides
FROM app_downloads AS ad
LEFT JOIN signups AS s
ON ad.app_download_key = s.session_id
LEFT JOIN ride_requests AS rr
ON s.user_id = rr.user_id
GROUP BY age_range)

SELECT age_range, app_download,SUM(app_download) OVER () AS total_downloads,
    app_download::float /
        SUM(app_download) OVER () AS pct_of_downloads, 
        signup, SUM(signup) OVER () AS total_signups,
    signup::float /
        SUM(signup) OVER () AS pct_of_signups,
        ride_requested, SUM(ride_requested) OVER () AS total_rides,
    ride_requested::float /
        SUM(ride_requested) OVER () AS pct_of_rides_requested,
        completed_rides,SUM(completed_rides) OVER () AS total_ride_completed,
    completed_rides::float /
        SUM(completed_rides) OVER () AS pct_of_rides_completed
FROM complete;




WITH complete AS
(SELECT COUNT(DISTINCT app_download_key) AS app_download, COUNT(DISTINCT s.user_id) AS signup, platform,
COUNT(DISTINCT rr.user_id) AS ride_requested,
        COUNT(DISTINCT
        CASE
            WHEN rr.dropoff_ts IS NOT NULL
            THEN rr.user_id
        END) as completed_rides
FROM app_downloads AS ad
LEFT JOIN signups AS s
ON ad.app_download_key = s.session_id
LEFT JOIN ride_requests AS rr
ON s.user_id = rr.user_id
GROUP BY platform)

SELECT platform, app_download,SUM(app_download) OVER () AS total_downloads,
    app_download::float /
        SUM(app_download) OVER () AS pct_of_downloads, 
        signup, SUM(signup) OVER () AS total_signups,
    signup::float /
        SUM(signup) OVER () AS pct_of_signups,
        ride_requested, SUM(ride_requested) OVER () AS total_rides,
    ride_requested::float /
        SUM(ride_requested) OVER () AS pct_of_rides_requested,
        completed_rides,SUM(completed_rides) OVER () AS total_ride_completed,
    completed_rides::float /
        SUM(completed_rides) OVER () AS pct_of_rides_completed
FROM complete
ORDER BY app_download DESC;




/* funnel stages based on platform, using peercent of previous approach*/


WITH user_ride_status AS (
    SELECT
        user_id, dropoff_ts
    FROM ride_requests
    GROUP BY user_id,2
),
totals AS (
    SELECT
        platform,COUNT(DISTINCT a.app_download_key) AS total_app_downloads,
        COUNT(DISTINCT s.user_id) AS total_users_signed_up,
        COUNT(DISTINCT urs.user_id) AS total_users_ride_requested,
        COUNT(DISTINCT 
            CASE
                WHEN dropoff_ts IS NOT NULL
                THEN urs.user_id
            END) AS ride_completed
    FROM app_downloads AS a
    LEFT JOIN signups AS s
    ON a.app_download_key = s.session_id
    LEFT JOIN user_ride_status urs ON
        s.user_id = urs.user_id
    GROUP BY platform

),
funnel_stages AS (
    SELECT platform,
        1 AS funnel_step,
        'app_downloads' AS funnel_name,
        total_app_downloads AS value
    FROM totals

    UNION 

    SELECT platform,
        2 AS funnel_step,
        'signups' AS funnel_name,
        total_users_signed_up AS value
    FROM totals

    UNION

    SELECT platform,
        3 AS funnel_step,
        'ride_requested' AS funnel_name,
        total_users_ride_requested AS value
    FROM totals

    UNION

    SELECT platform,
        4 AS funnel_step,
        'completed_ride' AS funnel_name,
        ride_completed AS value
    FROM totals

)
SELECT *,
    value::float / LAG(value) OVER (PARTITION BY platform
        ORDER BY funnel_step
    ) AS previous_value
FROM funnel_stages

ORDER BY platform, funnel_step;


/* */

WITH user_ride_status AS (
    SELECT
        user_id, dropoff_ts
    FROM ride_requests
    GROUP BY user_id,2
),
totals AS (
    SELECT
        age_range,COUNT(DISTINCT a.app_download_key) AS total_app_downloads,
        COUNT(DISTINCT s.user_id) AS total_users_signed_up,
        COUNT(DISTINCT urs.user_id) AS total_users_ride_requested,
        COUNT(DISTINCT 
            CASE
                WHEN dropoff_ts IS NOT NULL
                THEN urs.user_id
            END) AS ride_completed
    FROM app_downloads AS a
    LEFT JOIN signups AS s
    ON a.app_download_key = s.session_id
    LEFT JOIN user_ride_status urs ON
        s.user_id = urs.user_id
    GROUP BY age_range

),
funnel_stages AS (
    SELECT age_range,
        1 AS funnel_step,
        'app_downloads' AS funnel_name,
        total_app_downloads AS value
    FROM totals

    UNION 

    SELECT age_range,
        2 AS funnel_step,
        'signups' AS funnel_name,
        total_users_signed_up AS value
    FROM totals

    UNION

    SELECT age_range,
        3 AS funnel_step,
        'ride_requested' AS funnel_name,
        total_users_ride_requested AS value
    FROM totals

    UNION

    SELECT age_range,
        4 AS funnel_step,
        'completed_ride' AS funnel_name,
        ride_completed AS value
    FROM totals

)
SELECT *,
    value::float / LAG(value+0.1) OVER (PARTITION BY age_range
        ORDER BY funnel_step
    ) AS previous_value
FROM funnel_stages

ORDER BY age_range, funnel_step;











WITH user_ride_status AS (
    SELECT
        user_id, dropoff_ts
    FROM ride_requests
    GROUP BY user_id,2
),
totals AS (
    SELECT
        age_range,COUNT(DISTINCT a.app_download_key) AS total_app_downloads,
        COUNT(DISTINCT s.user_id) AS total_users_signed_up,
        COUNT(DISTINCT urs.user_id) AS total_users_ride_requested,
        COUNT(DISTINCT 
            CASE
                WHEN dropoff_ts IS NOT NULL
                THEN urs.user_id
            END) AS ride_completed,
  		  COUNT(DISTINCT t.transaction_id) AS payment,
  			COUNT(DISTINCT r.user_id) AS total_review
    FROM app_downloads AS a
    LEFT JOIN signups AS s
    ON a.app_download_key = s.session_id
    LEFT JOIN user_ride_status urs ON
        s.user_id = urs.user_id
  	LEFT JOIN reviews AS r
  	ON s.user_id = r.user_id
  	LEFT JOIN transactions AS T
  	ON t.ride_id= r.ride_id
    GROUP BY age_range

),
funnel_stages AS (
    SELECT age_range,
        1 AS funnel_step,
        'app_downloads' AS funnel_name,
        total_app_downloads AS user_count
    FROM totals

    UNION 

    SELECT age_range,
        2 AS funnel_step,
        'signups' AS funnel_name,
        total_users_signed_up AS user_count
    FROM totals

    UNION

    SELECT age_range,
        3 AS funnel_step,
        'ride_requested' AS funnel_name,
        total_users_ride_requested AS user_count
    FROM totals

    UNION

    SELECT age_range,
        4 AS funnel_step,
        'completed_ride' AS funnel_name,
        ride_completed AS user_count
    FROM totals

  	UNION
  
  	SELECT age_range,
        5 AS funnel_step,
        'payment' AS funnel_name,
        payment AS user_count
    FROM totals
  
  	UNION
  
  SELECT age_range,
        6 AS funnel_step,
        'review' AS funnel_name,
        total_review AS user_count
    FROM totals
)
SELECT *,
    user_count::float / LAG(user_count+0.1) OVER (PARTITION BY age_range
        ORDER BY funnel_step
    ) AS percentage
FROM funnel_stages

ORDER BY age_range, funnel_step;
