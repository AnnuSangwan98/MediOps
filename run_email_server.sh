#!/bin/bash

# =========================================
# MediOps Email Server Launch Script
# =========================================

# Navigate to project root directory
cd "$(dirname "$0")"

# Create virtual environment if it doesn't exist
if [ ! -d "email_venv" ]; then
    echo "Creating new virtual environment..."
    python3 -m venv email_venv
fi

# Activate virtual environment
source email_venv/bin/activate

# Install required packages
pip install flask flask-cors

# Run the email server
echo "Starting email server..."
python3 MediOps/MediOps/Services/email_sender.py

# This script will run until you press Ctrl+C to stop it 