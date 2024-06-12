-- Jeffa Triana Putra
-- Query ini dibuat dengan menggunakan SQL Shell (psql)
-- Membuat rekap nilai query dalam SQL untuk memperoleh rekap nilai untuk setiap siswa
-- Data diolah berdasarkan tabel student dan exam yang sudah tersedia

-- TODO 1 : Membuat tabel student dan tabel exam untuk menyimpan data dari file CSV

CREATE TABLE student (
	student_id BIGSERIAL NOT NULL PRIMARY KEY,
	student_name VARCHAR(100) NOT NULL,
	registered_class VARCHAR(100) NOT NULL,
	home_region VARCHAR(100) NOT NULL
);

CREATE TABLE exam (
	exam_result_id BIGSERIAL NOT NULL PRIMARY KEY,
	stud_id NUMERIC(5) NOT NULL,
	subj_id NUMERIC(5) NOT NULL,
	exam_date DATE NOT NULL,
	exam_event VARCHAR(100) NOT NULL,
	exam_score NUMERIC(5) NOT NULL,
	exam_submit_time TIMESTAMP NOT NULL
);

-- TODO 2 : Import data dari CSV ke tabel yang sudah tersedia
\copy student FROM '/Users/dzno9/Desktop/student.csv' DELIMITER ',' CSV HEADER;
\copy exam FROM '/Users/dzno9/Desktop/exam_result.csv' DELIMITER ',' CSV HEADER;

-- TODO 3 : 
-- Dibutuhkan kolom nama siswa dari tabel student, rata-rata ujian secara terpisah (exam_1 dan exam_2), dan rata-rata ujian digabung dari tabel exam
-- Lakukan left join berdasarkan student_id yang tertera pada tabel student dan tabel exam
-- Lakukan grouping berdasarkan nama siswa, id siswa, dan exam_event supaya dapat mengumpulkan rata-rata nilai ujian per siswa dan per exam_event
-- Urutkan berdasarkan exam_event supaya mendapatkan rata-rata ujian per siswa dan per exam_event secara berurut
-- Lakukan dengan limit 24 supaya mendapatkan nilai rata-rata ujian 1 saja (total ada 24 siswa mengikuti 2 ujian)
SELECT s.student_id, s.student_name,round(avg(e.exam_score),2) as average_exam_1, e.exam_event 
FROM student AS s 
LEFT join exam AS e ON s.student_id=e.stud_id 
GROUP BY s.student_id, s.student_name, e.exam_event 
ORDER BY exam_event ASC LIMIT 24;

-- TODO 4 : Lakukan hal serupa untuk ujian 2
SELECT s.student_id, s.student_name,round(avg(e.exam_score),2) as average_exam_2, e.exam_event 
FROM student AS s 
LEFT JOIN exam AS e ON s.student_id=e.stud_id 
GROUP BY s.student_id, s.student_name, e.exam_event 
ORDER BY exam_event ASC OFFSET 24 LIMIT 48;

-- TODO 5 : Export tabel yang sudah berisikan kolom yang diperlukan untuk tabel rata-rata ujan 1 dan 2 menjadi CSV
\copy (SELECT s.student_id, s.student_name,round(avg(e.exam_score),2) as average_exam_1, e.exam_event from student as s left join exam as e on s.student_id=e.stud_id GROUP BY s.student_id, s.student_name, e.exam_event ORDER BY exam_event asc LIMIT 24) TO '/Users/dzno9/Desktop/report_exam_1.csv' DELIMITER ',' CSV HEADER;
\copy (SELECT s.student_id, s.student_name,round(avg(e.exam_score),2) as average_exam_2, e.exam_event from student as s left join exam as e on s.student_id=e.stud_id GROUP BY s.student_id, s.student_name, e.exam_event ORDER BY exam_event asc OFFSET 24 LIMIT 48) TO '/Users/dzno9/Desktop/report_exam_2.csv' DELIMITER ',' CSV HEADER;

-- TODO 6 : Buat tabel yang menghimpun nilai ujian 1 dan 2 yang sudah dirata-rata
CREATE TABLE report_exam_1 (
	student_id BIGSERIAL NOT NULL PRIMARY KEY,
	student_name VARCHAR(100) NOT NULL,
	average_exam_1 NUMERIC(5,2) NOT NULL,
	exam_event VARCHAR(100) NOT NULL
);

CREATE TABLE report_exam_2 (
	student_id BIGSERIAL NOT NULL PRIMARY KEY,
	student_name VARCHAR(100) NOT NULL,
	average_exam_2 NUMERIC(5,2) NOT NULL,
	exam_event VARCHAR(100) NOT NULL
);

-- TODO 7 : Import kembali tabel csv ke report_exam_1 dan report_exam_2
\copy report_exam_1 FROM '/Users/dzno9/Desktop/report_exam_1.csv' DELIMITER ',' CSV HEADER;

\copy report_exam_2 FROM '/Users/dzno9/Desktop/report_exam_2.csv' DELIMITER ',' CSV HEADER;

-- TODO 8 : Join report_exam_1 dan report_exam_2 untuk mendapatkan nilai rata-rata seluruh ujiandari masing-masing siswa
SELECT s.student_name,s.average_exam_1,e.average_exam_2, round((s.average_exam_1+e.average_exam_2)/2,2) as average
FROM report_exam_1 as s
LEFT JOIN report_exam_2 AS e ON s.student_name=e.student_name 
GROUP BY s.student_name, s.average_exam_1, e.average_exam_2, average
ORDER BY s.student_name;

-- TODO 9 : Buat tabel untuk menyimpan nilai rata-rata keselurhan dan export hasilnya menjadi tabel csv yakni report_keseluruhan
CREATE TABLE report_keseluruhan (
	student_name VARCHAR(100) NOT NULL,
	average_exam_1 NUMERIC(5, 2) NOT NULL,
	average_exam_2 NUMERIC(5, 2) NOT NULL,
	average NUMERIC(5, 2) NOT NULL
);
\copy (SELECT s.student_name,s.average_exam_1,e.average_exam_2, round((s.average_exam_1+e.average_exam_2)/2,2) as average FROM report_exam_1 as s LEFT JOIN report_exam_2 AS e ON s.student_name=e.student_name GROUP BY s.student_name, s.average_exam_1, e.average_exam_2, average ORDER BY s.student_name) TO '/Users/dzno9/Desktop/report_keseluruhan.csv' DELIMITER ',' CSV HEADER;
-- TODO 10 : Import report_keseluruhan ke tabel lalu buat grading berdasarkan kondisi nilai rata-rata keseluruhan
\copy report_keseluruhan FROM '/Users/dzno9/Desktop/report_keseluruhan.csv' DELIMITER ',' CSV HEADER;

SELECT student_name as Student,Average_Exam_1 ,Average_Exam_2, average as Average_Exam_Score,
CASE
	WHEN average>=90 THEN 'A'
	WHEN average BETWEEN 80 AND 90 THEN 'B'
	WHEN average BETWEEN 70 AND 80 THEN 'C'
	WHEN average BETWEEN 50 AND 70 THEN 'D'
	ELSE 'F' 
END AS Grade
FROM report_keseluruhan;

-- TODO 11 : Export tabel yang sudah melalui proses grading menjadi report final dalam bentuk csv
\copy (SELECT student_name as Student,average_exam_1, average_exam_2, average as Average_Exam_Score, CASE WHEN average>=90 THEN 'A' WHEN average BETWEEN 80 AND 90 THEN 'B' WHEN average BETWEEN 70 AND 80 THEN 'C' WHEN average BETWEEN 50 AND 70 THEN 'D' ELSE 'F' END AS Grade FROM report_keseluruhan) TO '/Users/dzno9/Desktop/TechnicalTestDE_Jeffa Triana Putra/output/report_student_from_sql.csv' DELIMITER ',' CSV HEADER;