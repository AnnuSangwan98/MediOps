from flask import Flask, request, jsonify
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
import smtplib
from flask_cors import CORS
import sys
import uuid
import time

app = Flask(__name__)
CORS(app)

# Email configuration
SENDER_EMAIL = "mediops.infosys@gmail.com"
SENDER_PASSWORD = "zofa bied qcsx alnd"  # App password from Google Account settings
SMTP_SERVER = "smtp.gmail.com"
SMTP_PORT = 587

# Simple in-memory storage for reset tokens (would use a database in production)
reset_tokens = {}

@app.route('/send-otp', methods=['POST'])
def send_otp():
    try:
        data = request.json
        recipient = data.get('email')
        otp = data.get('otp')
        
        # Input validation
        if not recipient or not otp:
            return jsonify({"error": "Email and OTP are required"}), 400
            
        subject = data.get('subject', 'MediOps: Your Verification Code')
        
        # Create message
        message = MIMEMultipart()
        message["From"] = SENDER_EMAIL
        message["To"] = recipient
        message["Subject"] = subject

        # Create HTML body with improved styling
        html = f"""
        <html>
            <body style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
                <div style="background-color: #f8f9fa; padding: 20px; border-radius: 5px;">
                    <h2 style="color: #333;">MediOps Verification Code</h2>
                    <p>Your verification code is:</p>
                    <div style="background-color: #ffffff; padding: 15px; border-radius: 4px; text-align: center; margin: 20px 0;">
                        <span style="font-size: 24px; font-weight: bold; letter-spacing: 2px;">{otp}</span>
                    </div>
                    <p style="color: #666;">This code will expire in 10 minutes.</p>
                    <p style="color: #666; font-size: 12px;">If you didn't request this code, please ignore this email.</p>
                </div>
            </body>
        </html>
        """
        
        message.attach(MIMEText(html, 'html'))

        # Create SMTP session with context manager
        with smtplib.SMTP(SMTP_SERVER, SMTP_PORT) as server:
            server.starttls()
            server.login(SENDER_EMAIL, SENDER_PASSWORD)
            server.send_message(message)
            
        return jsonify({"message": "OTP sent successfully"}), 200
        
    except smtplib.SMTPException as e:
        print(f"SMTP Error: {str(e)}", file=sys.stderr)
        return jsonify({"error": "Failed to send email"}), 500
    except Exception as e:
        print(f"Error sending email: {str(e)}", file=sys.stderr)
        return jsonify({"error": "Internal server error"}), 500

@app.route('/send-password-reset', methods=['POST'])
def send_password_reset():
    try:
        data = request.json
        recipient = data.get('email')
        role = data.get('role', 'User')
        
        # Input validation
        if not recipient:
            return jsonify({"error": "Email is required"}), 400
            
        # Generate a unique token
        token = str(uuid.uuid4())
        
        # Store the token with expiration time (30 minutes)
        expiration = int(time.time()) + 1800  # 30 minutes in seconds
        reset_tokens[token] = {
            'email': recipient,
            'expires': expiration
        }
        
        # Create message
        message = MIMEMultipart()
        message["From"] = SENDER_EMAIL
        message["To"] = recipient
        message["Subject"] = f"MediOps: Password Reset Request"

        # Reset link would point to your app's password reset page
        reset_link = f"mediops://reset-password?token={token}"
        
        # Create HTML body with improved styling
        html = f"""
        <html>
            <body style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
                <div style="background-color: #f8f9fa; padding: 20px; border-radius: 5px;">
                    <h2 style="color: #333;">MediOps Password Reset</h2>
                    <p>Hello {role},</p>
                    <p>We received a request to reset your password for your MediOps account. Click the button below to reset your password:</p>
                    <div style="text-align: center; margin: 25px 0;">
                        <a href="{reset_link}" style="background-color: #4CAF50; color: white; padding: 10px 20px; text-decoration: none; border-radius: 4px; font-weight: bold;">Reset Password</a>
                    </div>
                    <p>If the button doesn't work, copy and paste this link in your browser:</p>
                    <p style="word-break: break-all; background-color: #ffffff; padding: 10px; border-radius: 4px;">{reset_link}</p>
                    <p style="color: #666;">This link will expire in 30 minutes.</p>
                    <p style="color: #666; font-size: 12px;">If you didn't request a password reset, please ignore this email.</p>
                </div>
            </body>
        </html>
        """
        
        message.attach(MIMEText(html, 'html'))

        # Create SMTP session with context manager
        with smtplib.SMTP(SMTP_SERVER, SMTP_PORT) as server:
            server.starttls()
            server.login(SENDER_EMAIL, SENDER_PASSWORD)
            server.send_message(message)
            
        return jsonify({
            "message": "Password reset link sent successfully", 
            "token": token  # Return token for testing purposes
        }), 200
        
    except smtplib.SMTPException as e:
        print(f"SMTP Error: {str(e)}", file=sys.stderr)
        return jsonify({"error": "Failed to send email"}), 500
    except Exception as e:
        print(f"Error sending email: {str(e)}", file=sys.stderr)
        return jsonify({"error": "Internal server error"}), 500

@app.route('/verify-reset-token', methods=['POST'])
def verify_reset_token():
    try:
        data = request.json
        token = data.get('token')
        
        if not token or token not in reset_tokens:
            return jsonify({"valid": False, "error": "Invalid token"}), 400
            
        token_data = reset_tokens[token]
        current_time = int(time.time())
        
        if current_time > token_data['expires']:
            # Clean up expired token
            del reset_tokens[token]
            return jsonify({"valid": False, "error": "Token expired"}), 400
            
        return jsonify({
            "valid": True, 
            "email": token_data['email']
        }), 200
        
    except Exception as e:
        print(f"Error verifying token: {str(e)}", file=sys.stderr)
        return jsonify({"valid": False, "error": "Internal server error"}), 500

if __name__ == '__main__':
    try:
        print("Starting email server on port 8089...")
        app.run(host='0.0.0.0', port=8089, debug=True)
    except Exception as e:
        print(f"Failed to start server: {str(e)}", file=sys.stderr)
        sys.exit(1)