-- Jeffa Triana Putra
-- Query ini dibuat dengan menggunakan SQL Shell (psql)
-- Membuat rekap nilai query dalam SQL untuk memperoleh rekap nilai untuk setiap pelajaran
-- Data diolah berdasarkan tabel subject dan exam yang sudah tersedia

-- TODO 1 : Membuat table subject dan exam untuk menyimpan data dari file CSV
CREATE TABLE subject (
	subject_id BIGSERIAL NOT NULL PRIMARY KEY,
	subject_name VARCHAR(100) NOT NULL
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
\copy subject FROM '/Users/dzno9/Desktop/subject.csv' DELIMITER ',' CSV HEADER;
\copy exam FROM '/Users/dzno9/Desktop/exam_result.csv' DELIMITER ',' CSV HEADER;

-- TODO 3 : 
-- Dibutuhkan kolom nama subject dari tabel subject, rata-rata ujian secara terpisah (exam_1 dan exam_2), dan rata-rata ujian digabung dari tabel exam
-- Lakukan left join berdasarkan subject_id yang tertera pada tabel student dan tabel exam
-- Lakukan grouping berdasarkan nama subject, id subject, dan exam_event supaya dapat mengumpulkan rata-rata nilai ujian per siswa dan per exam_event
-- Urutkan berdasarkan exam_event supaya mendapatkan rata-rata ujian per siswa dan per exam_event secara berurut
-- Lakukan dengan limit 6 supaya mendapatkan nilai rata-rata ujian 1 saja (total ada 6 subject yang mengadakan 2 ujian)
SELECT s.subject_id, s.subject_name,round(avg(e.exam_score),2) as average_exam_1, e.exam_event 
FROM subject AS s 
LEFT join exam AS e ON s.subject_id=e.subj_id 
GROUP BY s.subject_id, s.subject_name, e.exam_event 
ORDER BY exam_event ASC LIMIT 6;

-- TODO 4 : Lakukan hal serupa untuk ujian 2 (dengan offset 6 sehingga hanya ujian 2 yang diambil)
SELECT s.subject_id, s.subject_name,round(avg(e.exam_score),2) as average_exam_2, e.exam_event 
FROM subject AS s 
LEFT join exam AS e ON s.subject_id=e.subj_id 
GROUP BY s.subject_id, s.subject_name, e.exam_event 
ORDER BY exam_event ASC OFFSET 6 LIMIT 12;

-- TODO 5 : Export tabel yang sudah berisikan kolom yang diperlukan untuk tabel rata-rata ujan 1 dan 2 berdasarkan subject menjadi CSV
\copy (SELECT s.subject_id, s.subject_name,round(avg(e.exam_score),2) as average_exam_1, e.exam_event  FROM subject AS s  LEFT join exam AS e ON s.subject_id=e.subj_id  GROUP BY s.subject_id, s.subject_name, e.exam_event  ORDER BY exam_event ASC LIMIT 6) TO '/Users/dzno9/Desktop/subject_exam_1.csv' DELIMITER ',' CSV HEADER;
\copy (SELECT s.subject_id, s.subject_name,round(avg(e.exam_score),2) as average_exam_2, e.exam_event  FROM subject AS s  LEFT join exam AS e ON s.subject_id=e.subj_id  GROUP BY s.subject_id, s.subject_name, e.exam_event  ORDER BY exam_event ASC OFFSET 6 LIMIT 12) TO '/Users/dzno9/Desktop/subject_exam_2.csv' DELIMITER ',' CSV HEADER;

-- TODO 6 : Buat tabel yang menghimpun nilai ujian 1 dan 2 subject yang sudah dirata-rata
CREATE TABLE subject_exam_1 (
	subject_id BIGSERIAL NOT NULL PRIMARY KEY,
	subject_name VARCHAR(100) NOT NULL,
	average_exam_1 NUMERIC(5,2) NOT NULL,
	exam_event VARCHAR(100) NOT NULL
);

CREATE TABLE subject_exam_2 (
	subject_id BIGSERIAL NOT NULL PRIMARY KEY,
	subject_name VARCHAR(100) NOT NULL,
	average_exam_2 NUMERIC(5,2) NOT NULL,
	exam_event VARCHAR(100) NOT NULL
);

-- TODO 7 : Import kembali tabel csv ke subject_exam_1 dan subject_exam_2
\copy subject_exam_1 FROM '/Users/dzno9/Desktop/subject_exam_1.csv' DELIMITER ',' CSV HEADER;
\copy subject_exam_2 FROM '/Users/dzno9/Desktop/subject_exam_2.csv' DELIMITER ',' CSV HEADER;

-- TODO 8 : Join subject_exam_1 dan subject_exam_2 untuk mendapatkan nilai rata-rata seluruh ujian dari masing-masing subject
SELECT s.subject_name,s.average_exam_1,e.average_exam_2, round((s.average_exam_1+e.average_exam_2)/2,2) as average
FROM subject_exam_1 as s
LEFT JOIN subject_exam_2 AS e ON s.subject_name=e.subject_name 
GROUP BY s.subject_name, s.average_exam_1, e.average_exam_2, average
ORDER BY s.subject_name;

-- TODO 9 : Buat tabel untuk menyimpan nilai rata-rata keselurhan dan export hasilnya menjadi tabel csv yakni report_subject_keseluruhan
CREATE TABLE report_subject_keseluruhan (
	subject_name VARCHAR(100) NOT NULL,
	average_exam_1 NUMERIC(5, 2) NOT NULL,
	average_exam_2 NUMERIC(5, 2) NOT NULL,
	average NUMERIC(5, 2) NOT NULL
);
\copy (SELECT s.subject_name,s.average_exam_1,e.average_exam_2, round((s.average_exam_1+e.average_exam_2)/2,2) as average FROM subject_exam_1 as s LEFT JOIN subject_exam_2 AS e ON s.subject_name=e.subject_name GROUP BY s.subject_name, s.average_exam_1, e.average_exam_2, average ORDER BY s.subject_name) TO '/Users/dzno9/Desktop/report_subject_keseluruhan.csv' DELIMITER ',' CSV HEADER;

-- TODO 10 : Import report_keseluruhan ke tabel lalu buat grading berdasarkan kondisi nilai rata-rata keseluruhan
\copy report_subject_keseluruhan FROM '/Users/dzno9/Desktop/report_subject_keseluruhan.csv' DELIMITER ',' CSV HEADER;

SELECT subject_name as Subject,Average_Exam_1 ,Average_Exam_2, average as Average_Exam_Score,
CASE
	WHEN average>=90 THEN 'A'
	WHEN average BETWEEN 80 AND 90 THEN 'B'
	WHEN average BETWEEN 70 AND 80 THEN 'C'
	WHEN average BETWEEN 50 AND 70 THEN 'D'
	ELSE 'F' 
END AS Grade
FROM report_subject_keseluruhan;

-- TODO 11 : Export tabel yang sudah melalui proses grading menjadi report subject final dalam bentuk csv
\copy (SELECT subject_name as subject,average_exam_1, average_exam_2, average as Average_Exam_Score, CASE WHEN average>=90 THEN 'A' WHEN average BETWEEN 80 AND 90 THEN 'B' WHEN average BETWEEN 70 AND 80 THEN 'C' WHEN average BETWEEN 50 AND 70 THEN 'D' ELSE 'F' END AS Grade FROM report_subject_keseluruhan) TO '/Users/dzno9/Desktop/TechnicalTestDE_Jeffa Triana Putra/output/report_subject_from_sql.csv' DELIMITER ',' CSV HEADER;
