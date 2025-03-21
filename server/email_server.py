from flask import Flask, request, jsonify, render_template_string
import smtplib
import os
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from datetime import datetime

app = Flask(__name__)

# Define roles dictionary to match frontend configuration
roles = {
    "hospital_admin": "Hospital Administrator",
    "doctor": "Doctor"
}

def get_email_template(role, otp):
    templates = {
        "hospital_admin": {
            "subject": "MediOps HMS - Hospital Administrator Account Verification",
            "body": f"Dear Hospital Administrator,\n\n"
                   f"Welcome to MediOps Hospital Management System!\n\n"
                   f"Your account verification code is: {otp}\n\n"
                   f"As a Hospital Administrator, you will have access to:\n"
                   f"• Hospital-wide dashboard and analytics\n"
                   f"• Staff management\n"
                   f"• Department administration\n"
                   f"• Resource allocation\n"
                   f"• System configuration\n\n"
                   f"This code will expire in 5 minutes.\n\n"
                   f"Best regards,\n"
                   f"MediOps HMS Team"
        },
        "doctor": {
            "subject": "MediOps HMS - Doctor Account Verification",
            "body": f"""
Dear Healthcare Professional,

Welcome to MediOps Hospital Management System!

Your account verification code is: {otp}

As a Doctor, you will have access to:
• Patient records
• Appointment scheduling
• Prescription management
• Medical history
• Lab test results

This code will expire in 5 minutes.

Best regards,
MediOps HMS Team
            """
        },
        "patient": {
            "subject": "MediOps HMS - Patient Account Verification",
            "body": f"""
Dear Patient,

Welcome to MediOps Hospital Management System!

Your account verification code is: {otp}

As a Patient, you will have access to:
• Book appointments
• View medical records
• Download test results
• Online consultations
• Prescription history

This code will expire in 5 minutes.

Best regards,
MediOps HMS Team
            """
        },
        "lab_admin": {
            "subject": "MediOps HMS - Laboratory Administrator Account Verification",
            "body": f"""
Dear Laboratory Administrator,

Welcome to MediOps Hospital Management System!

Your account verification code is: {otp}

As a Lab Administrator, you will have access to:
• Test management
• Sample tracking
• Results publishing
• Inventory management
• Quality control

This code will expire in 5 minutes.

Best regards,
MediOps HMS Team
            """
        }
    }
    return templates.get(role, templates["patient"])

@app.route('/send-email', methods=['POST'])
def send_email():
    try:
        data = request.json
        role = data.get("role", "patient")
        otp = data.get("otp", "000000")
        username = data.get("username", "")
        password = data.get("password", "")
        
        template = get_email_template(role, otp)
        
        # Add credentials to the email body
        template["body"] += f"\n\nYour login credentials:\nUsername: {username}\nPassword: {password}"
        
        message = MIMEMultipart()
        message["From"] = "aryanshukla0024@gmail.com"
        message["To"] = data["to"]
        message["Subject"] = template["subject"]
        
        # Read HTML template
        with open('server/templates/email_template.html', 'r') as file:
            html_template = file.read()
        
        # Replace placeholder with email body
        html_content = html_template.replace('{{body}}', template['body'].replace('\n', '<br>'))
        
        message.attach(MIMEText(html_content, "html"))
        
        server = smtplib.SMTP("smtp.gmail.com", 587)
        server.starttls()
        server.login("aryanshukla0024@gmail.com", "jqlj tdhn rmjs vyha")
        
        server.send_message(message)
        server.quit()
        
        return jsonify({"status": "success"}), 200
        
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500

@app.route('/send-credentials', methods=['POST'])
def send_credentials():
    try:
        data = request.json
        role = data.get("role", "")
        
        # Select template based on role
        template_file = f"server/templates/{role}_credentials.html"
        if not os.path.exists(template_file):
            template_file = "server/templates/credential_template.html"
            
        with open(template_file, 'r') as file:
            html_template = file.read()
            
        # Replace placeholders
        html_content = html_template.replace('{{username}}', data.get('username', ''))
        html_content = html_content.replace('{{password}}', data.get('password', ''))
        
        message = MIMEMultipart()
        message["From"] = "aryanshukla0024@gmail.com"
        message["To"] = data["to"]
        message["Subject"] = f"MediOps HMS - Your {roles.get(role, 'User')} Account Credentials"
        
        message.attach(MIMEText(html_content, "html"))
        
        server = smtplib.SMTP("smtp.gmail.com", 587)
        server.starttls()
        server.login("aryanshukla0024@gmail.com", "jqlj tdhn rmjs vyha")
        
        server.send_message(message)
        server.quit()
        
        return jsonify({"status": "success"}), 200
        
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8085, debug=True)
