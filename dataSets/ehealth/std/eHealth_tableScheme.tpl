CREATE TABLE patient( pat_id varchar(8) PRIMARY KEY, pat_name text, pat_last1 text, pat_last2 text, pat_gen varchar(1), pat_zip varchar(5));
CREATE TABLE episode(ep_id varchar(10) PRIMARY KEY, ep_pat varchar(8) REFERENCES patient(pat_id) ON DELETE CASCADE, ep_age int, ep_range varchar(2));
CREATE TABLE discharge_report(dis_id varchar(20), dis_ver varchar(2), CONSTRAINT discharge_report_pk PRIMARY KEY (dis_id, dis_ver), dis_ep varchar(10) REFERENCES episode(ep_id) ON DELETE CASCADE, dis_serv varchar(3), dis_adm date, dis_dis date, dis_days int, dis_adtp varchar(2), dis_dest varchar(2), dis_sig1 varchar(6), dis_sig2 varchar(6), dis_pdf text);
CREATE TABLE diagnose_cie9mc(dia_id varchar(6) PRIMARY KEY, dia_desc text);
CREATE TABLE document_diagnose (dis_id varchar(20), dis_ver varchar(2), CONSTRAINT discharge_fk FOREIGN KEY (dis_id, dis_ver) REFERENCES discharge_report(dis_id, dis_ver) ON DELETE CASCADE, dia_id varchar(6) REFERENCES diagnose_cie9mc(dia_id));
CREATE TABLE lab_result(lab_id varchar(20), lab_ver varchar(2), CONSTRAINT lab_pk PRIMARY KEY (lab_id, lab_ver), lab_ep varchar(10) REFERENCES episode(ep_id) ON DELETE CASCADE, lab_pdf text);
CREATE TABLE medical_service_loinc(ms_id varchar(7) PRIMARY KEY, ms_desc text, ms_unit text, ms_ref text);
CREATE TABLE document_ms(lab_id varchar(20), lab_ver varchar(2), CONSTRAINT lab_fk FOREIGN KEY (lab_id, lab_ver) REFERENCES lab_result(lab_id, lab_ver) ON DELETE CASCADE, ms_id varchar(7) REFERENCES medical_service_loinc(ms_id), res_val decimal, res_abn varchar(2));
