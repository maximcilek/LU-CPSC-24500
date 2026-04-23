CREATE DATABASE IF NOT EXISTS usnf;
USE usnf;

CREATE TABLE names (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(255),
  year SMALLINT,
  sex CHAR(1),
  rank SMALLINT,
  count INT,
  UNIQUE KEY uk_usnf_names_name_sex_year (name, sex, year),
  INDEX idx_usnf_names_year_sex (year, sex)
);