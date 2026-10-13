-- One active reset OTP per user (stored hashed, short lived, limited attempts)
ALTER TABLE users
    ADD COLUMN reset_otp_hash VARCHAR(255),
    ADD COLUMN reset_otp_expires_at TIMESTAMPTZ,
    ADD COLUMN reset_otp_attempts INT NOT NULL DEFAULT 0;
