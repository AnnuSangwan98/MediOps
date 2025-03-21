#!/usr/bin/env python3
import os
import sys
import subprocess

def main():
    """Set up and run the Flask email server."""
    print("Setting up Flask email server...")
    
    # Install required packages
    try:
        print("Installing Flask and Flask-CORS...")
        subprocess.check_call([sys.executable, "-m", "pip", "install", "flask", "flask-cors"])
        print("Installation successful!")
    except subprocess.CalledProcessError:
        print("Failed to install packages. Check your internet connection and try again.")
        return 1
    
    # Get the path to the email_sender.py file
    script_dir = os.path.dirname(os.path.abspath(__file__))
    email_script = os.path.join(script_dir, "MediOps", "MediOps", "Services", "email_sender.py")
    
    if not os.path.exists(email_script):
        print(f"Error: Could not find {email_script}")
        return 1
    
    # Run the email server
    print(f"Starting email server from {email_script}...")
    try:
        subprocess.check_call([sys.executable, email_script])
    except subprocess.CalledProcessError:
        print("Failed to run the email server.")
        return 1
    
    return 0

if __name__ == "__main__":
    sys.exit(main()) 