#!/bin/bash

# Navigate to project directory
cd /Users/aryanshukla/Documents/GitHub/MediOps

# Create a new virtual environment in a new location
/opt/homebrew/bin/python3 -m venv mailvenv

# Activate the virtual environment
source mailvenv/bin/activate

# Install Flask in the virtual environment
pip install flask flask-cors

# Run the Flask server
python MediOps/MediOps/Services/email_sender.py
