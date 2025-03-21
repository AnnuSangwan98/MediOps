#!/bin/bash

# Create and activate virtual environment
cd "$(dirname "$0")"
python3 -m venv ./email_venv
source ./email_venv/bin/activate

# Install required packages
pip install flask flask-cors

# Run the Flask email server
python3 ./MediOps/MediOps/Services/email_sender.py 