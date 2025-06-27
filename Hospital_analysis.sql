USE hospital_data;

-- Inserts columns with month names and respective number to appointments table
ALTER TABLE appointments 
ADD appointment_month VARCHAR(25),
ADD month_number INT;

UPDATE appointments
SET	appointment_month = MONTHNAME(appointment_date),
	month_number = MONTH(appointment_date);


-- Two patients had no appointment scheduled so the year of the appointments was used to calculate the age of the patients
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
	WHEN '2023' - YEAR(date_of_birth) BETWEEN 15 AND 24 THEN 'Young adults'
    WHEN '2023' - YEAR(date_of_birth) BETWEEN 25 AND 54 THEN 'Working age'
    WHEN '2023' - YEAR(date_of_birth) BETWEEN 55 AND 64 THEN 'Older working age'
    ELSE 'Elderly'
END AS age_group

FROM patients 
ORDER BY patient_id;


-- Checking number of appointments per month
CREATE OR REPLACE VIEW sum_appointments_month AS
SELECT 
	appointment_month,
	COUNT(*) AS sum_appointments_month,
    month_number
FROM appointments
GROUP BY appointment_month, month_number
ORDER BY month_number;


-- Checking appointment status 
SELECT 
	ap.status,
    pa.gender,
    COUNT(*) AS occurrences,
    round(COUNT(*) *100/sum(count(*)) OVER(PARTITION BY status), 1) AS percentage_by_gender,
    round(COUNT(*) *100/sum(count(*)) OVER(), 1) AS total_percentage
FROM hospital_data.appointments ap
JOIN patients pa USING (patient_id)
GROUP BY status, gender
ORDER BY status;


-- Checking type of appointment by dr specialization
SELECT 
	do.specialization,
    ap.reason_for_visit,
    COUNT(*) AS number_of_appointments,
    round(COUNT(*) *100/sum(count(*)) OVER(PARTITION BY specialization), 1) AS percentage_specialization,
    round(COUNT(*) *100/sum(count(*)) OVER(), 1) AS total_percentage
FROM appointments ap
JOIN doctors do USING(doctor_id)
GROUP BY specialization, reason_for_visit
ORDER BY specialization;


-- Amount of debt by patient and insurance
CREATE OR REPLACE VIEW patient_insurance_debt AS
SELECT 
	pg.patient_id,
	pg.full_name,
    pg.age,
    pg.insurance_provider,
    bi.payment_method,
    bi.payment_status,
	ROUND(SUM(amount), 2) AS debt
FROM billing bi
JOIN patients_age pg USING(patient_id)
WHERE payment_status != 'Paid'
GROUP BY 
	pg.patient_id,
    pg.full_name, 
    pg.age,
    pg.insurance_provider,
    bi.payment_method,
    bi.payment_status
ORDER BY full_name, debt DESC;


-- payment method vs payment status
SELECT 
	payment_method,
    payment_status,
    ROUND(SUM(amount),2) AS total_pay
FROM billing
GROUP BY payment_method, payment_status
ORDER BY payment_method;


-- specialization by gender and age
SELECT
	do.specialization,
    pg.gender,
    ROUND(AVG(pg.age)) AS average_age
FROM doctors do
JOIN appointments ap USING(doctor_id)
JOIN patients_age pg USING(patient_id)
GROUP BY do.specialization,  pg.gender;


-- treatment by cost
SELECT 
	treatment_type,
    ROUND(AVG(cost),2) AS average_cost
FROM hospital_data.treatments
GROUP BY treatment_type;


-- specialization by cost
SELECT 
	do.specialization,
    tr.treatment_type,
    tr.cost
FROM doctors do
JOIN appointments ap USING(doctor_id)
JOIN treatments tr USING(appointment_id);


-- treatment type vs payment method
SELECT
	tr.treatment_type,
    bi.payment_method,
    tr.cost
FROM treatments tr
JOIN billing bi USING(treatment_id)
ORDER BY tr.treatment_type, bi.payment_method;


-- age and treatment
SELECT 
	treatment_type,
    ROUND(AVG(pg.age)) AS average_age  
FROM patients_age pg
JOIN billing bi USING(patient_id)
JOIN treatments tr USING(treatment_id)
GROUP BY treatment_type;


-- age and reasonforvisit
SELECT 
	ap.reason_for_visit,
    ROUND(AVG(pg.age)) AS average_age  
FROM patients_age pg
JOIN appointments ap USING(patient_id)
GROUP BY ap.reason_for_visit;


-- hospital procedure cost
CREATE OR REPLACE VIEW hospital_procedure_cost AS 
SELECT DISTINCT
	do.hospital_branch,
    tr.treatment_type,
    ROUND(AVG(tr.cost),2) AS average_cost
FROM doctors do
JOIN appointments ap USING(doctor_id)
JOIN treatments tr USING(appointment_id)
GROUP BY do.hospital_branch, tr.treatment_type
ORDER BY do.hospital_branch, tr.treatment_type;
