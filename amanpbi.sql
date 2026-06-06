CREATE DATABASE hospital_db;

USE hospital_db;

SELECT *
FROM hospital_er;

SELECT *
FROM doctor_patients_data;

#15 

SELECT Doctor_Name, SUM(Total_Bill) AS Total_Revenue, COUNT(DISTINCT patient_id) AS No_of_patients
FROM doctor_patients_data
GROUP BY Doctor_Name
ORDER BY Total_Revenue DESC, No_of_patients ASC
LIMIT 5;

#16

WITH mycte AS (
    SELECT 
        department_referral,
        EXTRACT(MONTH FROM date) AS month_num,
        AVG(patient_waittime) AS current_month_avg_time
    FROM hospital_er
    GROUP BY department_referral, EXTRACT(MONTH FROM date)
),

mycte2 AS (
    SELECT 
        department_referral,
        month_num,
        current_month_avg_time,
        LAG(current_month_avg_time, 1) OVER (
            PARTITION BY department_referral ORDER BY month_num
        ) AS prev_month_avg_time,
        LAG(current_month_avg_time, 2) OVER (
            PARTITION BY department_referral ORDER BY month_num
        ) AS prev_2month_avg_time
    FROM mycte
)

SELECT DISTINCT department_referral
FROM mycte2
WHERE current_month_avg_time < prev_month_avg_time
  AND prev_month_avg_time < prev_2month_avg_time;
  
  
#17 

SELECT Doctor_Name, male_count, female_count, male_count / female_count AS male_female_ratio,
    RANK() OVER (ORDER BY male_count / female_count DESC) AS doctor_rank
FROM (SELECT d.Doctor_Name,
        SUM(CASE WHEN h.patient_gender = 'M' THEN 1 ELSE 0 END) AS male_count,
        SUM(CASE WHEN h.patient_gender = 'F' THEN 1 ELSE 0 END) AS female_count
    FROM doctor_patients_data d
    JOIN hospital_er h
        ON d.patient_id = h.patient_id
    GROUP BY d.Doctor_Name) t
WHERE female_count > 0;

#18

SELECT d.Doctor_Name, ROUND(AVG(h.patient_sat_score), 2) AS avg_satisfaction_score, COUNT(DISTINCT h.patient_id) AS Total_Visits
FROM doctor_patients_data d
JOIN hospital_er h
    ON d.patient_id = h.patient_id
GROUP BY d.Doctor_Name;

#19

SELECT d.Doctor_Name, COUNT(DISTINCT h.patient_race) AS Total_race_diversity_count
FROM doctor_patients_data d
JOIN hospital_er h
    ON d.patient_id = h.patient_id
WHERE h.patient_race IS NOT NULL
GROUP BY d.Doctor_Name
HAVING COUNT(DISTINCT h.patient_race) > 1;

#20

WITH cte1 AS (SELECT d.department_referral,
        SUM(CASE WHEN h.patient_gender = 'M' THEN d.Total_Bill ELSE 0 END) AS male_total_bill,
        SUM(CASE WHEN h.patient_gender = 'F' THEN d.Total_Bill ELSE 0 END) AS female_total_bill
    FROM doctor_patients_data d
    JOIN hospital_er h
        ON d.patient_id = h.patient_id
    GROUP BY d.department_referral)
SELECT department_referral, male_total_bill, female_total_bill,
    ROUND(male_total_bill / female_total_bill, 2) AS male_female_bill_ratio
FROM cte1
WHERE female_total_bill > 0;

#21

ALTER TABLE hospital_er
ADD COLUMN updated_sat_score DECIMAL(5,2);

UPDATE hospital_er
SET updated_sat_score =
    CASE
        WHEN LOWER(department_referral) = 'general practice'
             AND patient_waittime > 30
        THEN LEAST(COALESCE(patient_sat_score,0) + 2, 10)

        ELSE COALESCE(patient_sat_score,0)
    END;

SELECT 
    department_referral,
    patient_waittime,
    COALESCE(patient_sat_score,0) AS old_sat_score,
    updated_sat_score
FROM hospital_er
WHERE department_referral = 'General Practice';