/*Maghdie Petersen 
230600204
Class 3.I 
Last Date and Time worked on: Thursday 17 September 2026 03:18
*/
CREATE DATABASE IF NOT EXISTS connectly_db 
CHARACTER SET = utf8mb4
COLLATE = utf8mb4_unicode_ci;

USE connectly_db;

DROP TABLE IF EXISTS audit_logs;
DROP TABLE IF EXISTS ratings;
DROP TABLE IF EXISTS payments;
DROP TABLE IF EXISTS messages;
DROP TABLE IF EXISTS job_applications;
DROP TABLE IF EXISTS jobs;
DROP TABLE IF EXISTS job_categories;
DROP TABLE IF EXISTS users;

-- ===================================================
-- USERS TABLE
-- ===================================================
CREATE TABLE users (
user_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
first_name VARCHAR(50) NOT NULL,
last_name VARCHAR(50) NOT NULL,
phone_number VARCHAR(15) NOT NULL,
email VARCHAR(255) NOT NULL,
password_hash VARCHAR(255) NOT NULL,-- Salted Bcrypt
role ENUM('JOB_SEEKER', 'EMPLOYER', 'ADMIN') NOT NULL,
is_verified BOOLEAN DEFAULT FALSE,-- Prevents fake accounts and or identity fraud

-- Address and Geolocation for Belhar Geo-matching
street_address VARCHAR(150) NULL,
latitude DECIMAL(10, 8) NULL,
longitude DECIMAL(11, 8) NULL,

-- South african POPIA compliance tracking
popia_consent BOOLEAN NOT NULL DEFAULT FALSE,
popia_consent_at TIMESTAMP NULL,

account_status ENUM('ACTIVE', 'SUSPENDED', 'DELETED') NOT NULL DEFAULT 'ACTIVE',
created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

CONSTRAINT uq_phone UNIQUE (phone_number),
CONSTRAINT uq_email UNIQUE (email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ===================================================
-- JOB CATEGORIES TABLE
-- ===================================================
CREATE TABLE job_categories (
category_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
category_name VARCHAR(50) NOT NULL UNIQUE,
is_active BOOLEAN DEFAULT TRUE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Insert default categories specified in product scope
INSERT INTO job_categories (category_name) VALUES
('Cleaning'), ('Gardening'), ('Handyman'), ('Tutoring'), ('Caretaking'), ('Delivery'), ('Moving and Transport');

-- ===================================================
-- JOBS TABLE
-- ===================================================
CREATE TABLE jobs (
job_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
employer_id BIGINT UNSIGNED NOT NULL,
category_id INT UNSIGNED NOT NULL,
title VARCHAR(120) NOT NULL,
description TEXT NOT NULL,
street_address VARCHAR(150) NOT NULL,
latitude DECIMAL(10, 8) NULL,
longitude DECIMAL(11, 8) NULL,

pay_type ENUM('FIXED', 'HOURLY') NOT NULL DEFAULT 'FIXED',
budget_amount DECIMAL(10, 2) NOT NULL,

status ENUM('OPEN', 'ASSIGNED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED') NOT NULL DEFAULT 'OPEN',
created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

FOREIGN KEY (employer_id) REFERENCES users(user_id) ON DELETE CASCADE,
FOREIGN KEY (category_id) REFERENCES job_categories(category_id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ===================================================
-- JOB APPLICATIONS TABLE
-- ===================================================
CREATE TABLE job_applications (
application_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
job_id BIGINT UNSIGNED NOT NULL,
seeker_id BIGINT UNSIGNED NOT NULL,
status ENUM('PENDING', 'ACCEPTED', 'REJECTED', 'CANCELLED') NOT NULL DEFAULT 'PENDING',
applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

FOREIGN KEY (job_id) REFERENCES jobs(job_id) ON DELETE CASCADE,
FOREIGN KEY (seeker_id) REFERENCES users(user_id) ON DELETE CASCADE,
CONSTRAINT uq_job_seeker UNIQUE (job_id, seeker_id) -- Preventing double application
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ===================================================
-- MESSAGES TABLE
-- ===================================================
CREATE TABLE messages (
message_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
job_id BIGINT UNSIGNED NULL,
sender_id BIGINT UNSIGNED NOT NULL,
receiver_id BIGINT UNSIGNED NOT NULL,
message_text TEXT NOT NULL,
is_read BOOLEAN DEFAULT FALSE,
sent_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

FOREIGN KEY (job_id) REFERENCES jobs(job_id) ON DELETE SET NULL,
FOREIGN KEY (sender_id) REFERENCES users(user_id) ON DELETE CASCADE,
FOREIGN KEY (receiver_id) REFERENCES users(user_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ===================================================
-- PAYMENTS TABLE
-- ===================================================
CREATE TABLE payments (
payment_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
job_id BIGINT UNSIGNED NOT NULL,
payer_id BIGINT UNSIGNED NOT NULL,
payee_id BIGINT UNSIGNED NOT NULL,
amount DECIMAL(10, 2) NOT NULL,
platform_fee DECIMAL(10, 2) NOT NULL DEFAULT '0.00', -- Commission fee
payment_gateway ENUM('PAYFAST', 'OZOW', 'SNAPSCAN') NOT NULL,
gateway_reference VARCHAR(100) NULL,
status ENUM('PENDING', 'IN_ESCROW', 'RELEASED', 'REFUNDED', 'FAILED') NOT NULL DEFAULT 'PENDING',
created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

FOREIGN KEY (job_id) REFERENCES jobs(job_id) ON DELETE CASCADE,
FOREIGN KEY (payer_id) REFERENCES users(user_id) ON DELETE CASCADE,
FOREIGN KEY (payee_id) REFERENCES users(user_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ===================================================
-- RATINGS TABLE
-- ===================================================
CREATE TABLE ratings (
rating_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
job_id BIGINT UNSIGNED NOT NULL,
reviewer_id BIGINT UNSIGNED NOT NULL,
reviewee_id BIGINT UNSIGNED NOT NULL,
rating_score TINYINT UNSIGNED NOT NULL CHECK (rating_score BETWEEN 1 AND 5),
review_text TEXT NULL,
created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

FOREIGN KEY (job_id) REFERENCES jobs(job_id) ON DELETE CASCADE,
FOREIGN KEY (reviewer_id) REFERENCES users(user_id) ON DELETE CASCADE,
FOREIGN KEY (reviewee_id) REFERENCES users(user_id) ON DELETE CASCADE,
CONSTRAINT uq_job_reviewer UNIQUE (job_id, reviewer_id) 
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ===================================================
-- AUDIT LOGS TABLE
-- ===================================================
CREATE TABLE audit_logs (
log_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
user_id BIGINT UNSIGNED NULL,
action VARCHAR(100) NOT NULL,
ip_address VARCHAR(45) NULL,
user_agent VARCHAR(255) NULL,
created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ===================================================
-- PERFORMANCE AND SCALABILITY INDEXES
-- ===================================================
CREATE INDEX idx_jobs_status_category ON jobs(status, category_id, created_at DESC);

CREATE INDEX idx_applicatons_seeker_status ON job_applicatons(seeker_id, status);

CREATE INDEX idx_messages_conversation ON messages(sender_id, receiver_id, sent_at);

CREATE INDEX idx_jobs_location ON jobs(latitude, longitude);








