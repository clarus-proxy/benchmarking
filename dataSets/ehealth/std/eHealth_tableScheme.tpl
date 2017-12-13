BEGIN;
CREATE TABLE patient(
	pat_id		varchar(8) PRIMARY KEY,
	pat_name	text,
	pat_last1	text,
	pat_last2	text,
	pat_gen		varchar(1),
	pat_zip		varchar(5)
);
