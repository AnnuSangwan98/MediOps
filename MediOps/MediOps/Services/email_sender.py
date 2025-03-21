from flask import Flask, request, jsonify
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
import smtplib
from flask_cors import CORS
import sys

app = Flask(__name__)
CORS(app)

# Email configuration
SENDER_EMAIL = "mediops.infosys@gmail.com"
SENDER_PASSWORD = "zofa bied qcsx alnd"  # App password from Google Account settings
SMTP_SERVER = "smtp.gmail.com"
SMTP_PORT = 587

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

if __name__ == '__main__':
    try:
        print("Starting email server on port 8089...")
        app.run(host='0.0.0.0', port=8089, debug=True)
    except Exception as e:
        print(f"Failed to start server: {str(e)}", file=sys.stderr)
        sys.exit(1)