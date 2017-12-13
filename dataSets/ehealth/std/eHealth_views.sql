/* Discharge report simple */
CREATE OR REPLACE VIEW discharge_simple AS
SELECT p.pat_id, p.pat_name, p.pat_last1, p.pat_last2, e.ep_id, dr.dis_id, dr.dis_ver, dr.dis_pdf 
FROM patient p
INNER JOIN episode e ON e.ep_pat = p.pat_id
INNER JOIN discharge_report dr ON dr.dis_ep = e.ep_id;

/* Discharge report advanced */
CREATE OR REPLACE VIEW discharge_advanced AS
SELECT p.pat_id, p.pat_name, p.pat_last1, p.pat_last2, p.pat_gen, p.pat_zip, e.ep_id, e.ep_age, e.ep_range, dr.dis_id, dr.dis_ver, dr.dis_serv,
dr.dis_adm, dr.dis_dis, dr.dis_days, dr.dis_adtp, dr.dis_dest, dr.dis_sig1, dr.dis_sig2, dr.dis_pdf, dia.dia_id, dia.dia_desc 
FROM patient p
INNER JOIN episode e ON e.ep_pat = p.pat_id
INNER JOIN discharge_report dr ON dr.dis_ep = e.ep_id
INNER JOIN document_diagnose doc ON (doc.dis_id, doc.dis_ver) = (dr.dis_id, dr.dis_ver)
INNER JOIN diagnose_cie9mc dia ON dia.dia_id = doc.dia_id;

/* Lab result simple */
CREATE OR REPLACE VIEW lab_simple AS
SELECT p.pat_id, p.pat_name, p.pat_last1, p.pat_last2, e.ep_id, lab.lab_id, lab.lab_ver, lab.lab_pdf
FROM patient p
INNER JOIN episode e ON e.ep_pat = p.pat_id
INNER JOIN lab_result lab ON lab.lab_ep = e.ep_id;

/* Lab result advanced */
CREATE OR REPLACE VIEW lab_advanced AS
SELECT p.pat_id, p.pat_name, p.pat_last1, p.pat_last2, p.pat_gen, p.pat_zip, e.ep_id, e.ep_age, e.ep_range, lab.lab_id, lab.lab_ver, lab.lab_pdf, ms.ms_id,
ms.ms_desc, ms.ms_unit, ms.ms_ref, doc.res_val, doc.res_abn 
FROM patient p
INNER JOIN episode e ON e.ep_pat = p.pat_id
INNER JOIN lab_result lab ON lab.lab_ep = e.ep_id
INNER JOIN document_ms doc ON (doc.lab_id, doc.lab_ver) = (lab.lab_id, lab.lab_ver)
INNER JOIN medical_service_loinc ms ON ms.ms_id = doc.ms_id;
