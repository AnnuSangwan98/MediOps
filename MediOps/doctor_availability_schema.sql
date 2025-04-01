CREATE TABLE doctor_availability (
    id SERIAL PRIMARY KEY,
    doctor_id VARCHAR(255) NOT NULL,
    hospital_id VARCHAR(255) NOT NULL,
    date DATE NOT NULL,
    slot_time TIME NOT NULL,
    slot_end_time TIME NOT NULL,
    max_normal_patients INTEGER NOT NULL DEFAULT 5,
    max_premium_patients INTEGER NOT NULL DEFAULT 2,
    total_bookings INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    -- Note: If foreign key constraints fail, comment them out
    -- CONSTRAINT fk_doctor FOREIGN KEY (doctor_id) REFERENCES doctors(id) ON DELETE CASCADE,
    -- CONSTRAINT fk_hospital FOREIGN KEY (hospital_id) REFERENCES hospitals(id) ON DELETE CASCADE,
    CONSTRAINT valid_time_slot CHECK (slot_time < slot_end_time),
    CONSTRAINT valid_patients CHECK (max_normal_patients >= 0 AND max_premium_patients >= 0),
    CONSTRAINT valid_bookings CHECK (total_bookings >= 0 AND total_bookings <= (max_normal_patients + max_premium_patients)),
    CONSTRAINT unique_doctor_slot UNIQUE (doctor_id, date, slot_time)
);

-- Create an index for faster lookups by doctor
CREATE INDEX idx_doctor_availability_doctor ON doctor_availability(doctor_id);

-- Create an index for faster lookups by hospital
CREATE INDEX idx_doctor_availability_hospital ON doctor_availability(hospital_id);

-- Create an index for date-based lookups
CREATE INDEX idx_doctor_availability_date ON doctor_availability(date);

-- Create a function to auto-update the updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create a trigger to call the function
CREATE TRIGGER update_doctor_availability_updated_at
BEFORE UPDATE ON doctor_availability
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- Create a function to insert doctor availability with both doctor and hospital IDs
CREATE OR REPLACE FUNCTION insert_doctor_availability(
    p_doctor_id VARCHAR(255),
    p_hospital_id VARCHAR(255),
    p_date VARCHAR(255),
    p_slot_time VARCHAR(255),
    p_slot_end_time VARCHAR(255),
    p_max_normal INTEGER DEFAULT 5,
    p_max_premium INTEGER DEFAULT 2
) RETURNS VOID AS $$
BEGIN
    INSERT INTO doctor_availability (
        doctor_id, 
        hospital_id,
        date, 
        slot_time, 
        slot_end_time, 
        max_normal_patients, 
        max_premium_patients, 
        total_bookings
    ) VALUES (
        p_doctor_id,
        p_hospital_id,
        p_date::DATE,
        p_slot_time::TIME,
        p_slot_end_time::TIME,
        p_max_normal,
        p_max_premium,
        0
    );
    
    -- Log insertion for debugging (if supported by your database)
    RAISE NOTICE 'Inserted doctor availability: doctor_id=%, hospital_id=%, date=%, slot=%-%', 
        p_doctor_id, p_hospital_id, p_date, p_slot_time, p_slot_end_time;
END;
$$ LANGUAGE plpgsql; 