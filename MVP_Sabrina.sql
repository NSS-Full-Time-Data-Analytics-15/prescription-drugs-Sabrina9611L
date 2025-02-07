--- Q1 A. 1881634483, 99707

SELECT *
FROM drug

SELECT COUNT(drug_name) FROM drug

SELECT COUNT(DISTINCT drug_name) FROM drug

SELECT npi, SUM (total_claim_count) as total_claim_count
FROM prescription
GROUP BY 1
ORDER BY total_claim_count DESC
LIMIT 1;

--- Q1 B. BRUCE, PENDLEY, Family Practice, 99707

SELECT nppes_provider_first_name, nppes_provider_last_org_name, specialty_description, 
SUM (total_claim_count) as total_claim_count
FROM prescription
INNER JOIN prescriber USING (npi)
GROUP BY 1, 2, 3
ORDER BY total_claim_count DESC
LIMIT 1;

--- Q2 A. family practice

SELECT specialty_description, 
SUM (total_claim_count) as total_claim_count
FROM prescription
INNER JOIN prescriber USING (npi)
GROUP BY 1
ORDER BY total_claim_count DESC
LIMIT 1;

--- Q2 B. nurse practitioner

SELECT specialty_description, 
SUM (total_claim_count) as total_claim_count
FROM prescription
INNER JOIN prescriber USING (npi)
INNER JOIN drug USING (drug_name)
WHERE drug.opioid_drug_flag = 'Y' 
GROUP BY 1
ORDER BY total_claim_count DESC
LIMIT 1;

--- Q2 C. yes

SELECT specialty_description
FROM prescriber
EXCEPT
SELECT specialty_description
FROM prescription
INNER JOIN prescriber USING (npi);

--- Q2 D.   "Case Manager/Care Coordinator"	72.00000000000000000000
---			"Orthopaedic Surgery"	68.98263027295285359800
---			"Interventional Pain Management"	59.47343594402417931800
---			"Anesthesiology"	58.51897960075132136500
---			"Pain Management"	58.08075930856567384500
 
WITH opioid_total AS 
(SELECT specialty_description, 
SUM(CASE WHEN opioid_drug_flag = 'Y' THEN (prescription.total_claim_count) END) AS opioid_count,
SUM(prescription.total_claim_count) AS total_count
FROM prescriber
INNER JOIN prescription USING (npi)
INNER JOIN drug USING (drug_name)
GROUP BY 1)
SELECT specialty_description, COALESCE((opioid_count/ total_count)*100,0) AS percent_opioid
FROM opioid_total
ORDER BY percent_opioid DESC;


--- Q3 A. "INSULIN GLARGINE,HUM.REC.ANLOG"	$104,264,066.35

SELECT d.generic_name, SUM (p.total_drug_cost)::money
FROM prescription AS p
INNER JOIN drug AS d USING (drug_name)
GROUP BY 1
ORDER BY sum DESC
LIMIT 1;

--- Q3 B. "ASFOTASE ALFA"	$139,776.00

SELECT d.generic_name, ((p.total_drug_cost) / p.total_30_day_fill_count)::money AS daily_cost
FROM prescription AS p
INNER JOIN drug AS d USING (drug_name)
ORDER BY daily_cost DESC
LIMIT 1;

--- Q4 A.

SELECT drug_name, 
CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid' 
WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic' 
ELSE 'neither' END AS drug_type
FROM drug;

--- Q4 B. opioid

SELECT  
CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid' 
WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic' 
ELSE 'neither' END AS drug_type, SUM (prescription.total_drug_cost)::money
FROM drug
INNER JOIN prescription USING (drug_name)
GROUP BY 1;

--- Q5 A. 10

SELECT *
FROM fips_county

SELECT COUNT (DISTINCT cbsa)
FROM cbsa
INNER JOIN fips_county USING (fipscounty)
WHERE fips_county.state = 'TN';

--- Q5 B. "Nashville-Davidson--Murfreesboro--Franklin, TN"	1830410, "Morristown, TN"	116352

SELECT cbsaname, SUM (population)
FROM cbsa
INNER JOIN population USING (fipscounty)
INNER JOIN fips_county USING (fipscounty)
WHERE fips_county.state = 'TN'
GROUP BY 1
ORDER BY sum DESC
LIMIT 1;

SELECT cbsaname, SUM (population)
FROM cbsa
INNER JOIN population USING (fipscounty)
INNER JOIN fips_county USING (fipscounty)
WHERE fips_county.state = 'TN'
GROUP BY 1
ORDER BY sum ASC
LIMIT 1;

--- Q5 C. "SEVIER" 95523

SELECT *
FROM fips_county
INNER JOIN population USING (fipscounty)
LEFT JOIN cbsa USING (fipscounty)
WHERE cbsa IS NULL
ORDER BY population DESC;

--- Q6 A. 
--- "OXYCODONE HCL"	4538
--- "LEVOTHYROXINE SODIUM"	3023
--- "HYDROCODONE-ACETAMINOPHEN" 3376
--- "LEVOTHYROXINE SODIUM"	3138
--- "MIRTAZAPINE"	3085
--- "LISINOPRIL"	3655
--- "LEVOTHYROXINE SODIUM"	3101
--- "GABAPENTIN"	3531
--- "FUROSEMIDE"	3083

SELECT drug_name, total_claim_count
FROM prescription
WHERE total_claim_count > 3000

--- Q6 B.   "OXYCODONE HCL"	4538	"opioid"
---			"LEVOTHYROXINE SODIUM"	3023	"other"
---			"HYDROCODONE-ACETAMINOPHEN"	3376	"opioid"
---			"GABAPENTIN"	3531	"other"
---			"LISINOPRIL"	3655	"other"
---			"FUROSEMIDE"	3083	"other"
---			"LEVOTHYROXINE SODIUM"	3101	"other"
---			"LEVOTHYROXINE SODIUM"	3138	"other"
---			"MIRTAZAPINE"	3085	"other"

SELECT drug_name, total_claim_count,
CASE WHEN drug.opioid_drug_flag = 'Y' THEN 'opioid' ELSE 'other' END AS drug_type
FROM prescription
INNER JOIN drug USING (drug_name)
WHERE total_claim_count > 3000;

--- Q6 C.   "OXYCODONE HCL"	4538	"opioid"	"COFFEY"	"DAVID"
---			"HYDROCODONE-ACETAMINOPHEN"	3376	"opioid"	"COFFEY"	"DAVID"
---			"MIRTAZAPINE"	3085	"other"	"PENDLEY"	"BRUCE"
---			"LISINOPRIL"	3655	"other"	"PENDLEY"	"BRUCE"
---			"LEVOTHYROXINE SODIUM"	3023	"other"	"PENDLEY"	"BRUCE"
---			"GABAPENTIN"	3531	"other"	"PENDLEY"	"BRUCE"
---			"LEVOTHYROXINE SODIUM"	3101	"other"	"HASEMEIER"	"ERIC"
---			"LEVOTHYROXINE SODIUM"	3138	"other"	"SHATTUCK"	"DEAVER"
---			"FUROSEMIDE"	3083	"other"	"COX"	"MICHAEL"

SELECT prescription.drug_name, total_claim_count, 
CASE WHEN drug.opioid_drug_flag = 'Y' THEN 'opioid' ELSE 'other' END, prescriber.nppes_provider_last_org_name, prescriber.nppes_provider_first_name
FROM prescription
INNER JOIN drug USING (drug_name)
INNER JOIN prescriber USING (npi)
WHERE total_claim_count > 3000;

--- Q7 A.

SELECT npi, drug_name
FROM prescriber
CROSS JOIN drug
WHERE specialty_description = 'Pain Management'
AND nppes_provider_city = 'NASHVILLE'
AND opioid_drug_flag = 'Y';

--- Q7 B.

SELECT prescriber.npi, drug.drug_name, prescription.total_claim_count
FROM prescriber
CROSS JOIN drug
INNER JOIN prescription USING (npi)
WHERE specialty_description = 'Pain Management'
AND nppes_provider_city = 'NASHVILLE'
AND opioid_drug_flag = 'Y';

--- Q7 C.

SELECT prescriber.npi, drug.drug_name, COALESCE (prescription.total_claim_count, 0)
FROM prescriber
CROSS JOIN drug
INNER JOIN prescription USING (npi)
WHERE specialty_description = 'Pain Management'
AND nppes_provider_city = 'NASHVILLE'
AND opioid_drug_flag = 'Y';

