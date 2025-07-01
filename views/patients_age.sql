CREATE OR REPLACE VIEW patients_age AS
SELECT 
	patient_id,
	CONCAT(first_name," ",last_name) AS full_name,
    gender,
    address,
    registration_date,
    insurance_provider,
    '2023' - YEAR(date_of_birth) AS age,
CASE 
	WHEN '2023' - YEAR(date_of_birth) BETWEEN 15 AND 24 THEN 'young adults'
    WHEN '2023' - YEAR(date_of_birth) BETWEEN 25 AND 54 THEN 'working age'
    WHEN '2023' - YEAR(date_of_birth) BETWEEN 55 AND 64 THEN 'older working age'
    ELSE 'elderly'
END AS age_group

FROM patients 
ORDER BY patient_id;