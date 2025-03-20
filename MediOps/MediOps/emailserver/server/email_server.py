from flask import Flask, request, jsonify
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart

app = Flask(__name__)

# Email configuration
SMTP_SERVER = "smtp.gmail.com"
SMTP_PORT = 587
SENDER_EMAIL = "aryanshukla0024@gmail.com"  # Replace with your Gmail
SENDER_PASSWORD = "jqlj tdhn rmjs vyha"   # Replace with your app password

def send_otp_email(to_email, otp):
    msg = MIMEMultipart()
    msg['From'] = SENDER_EMAIL
    msg['To'] = to_email
    msg['Subject'] = "MediOps - Your OTP Verification Code"
    
    body = f"""
    Hello,
    
    Your OTP verification code is: {otp}
    
    This code will expire in 5 minutes.
    
    Best regards,
    MediOps Team
    """
    
    msg.attach(MIMEText(body, 'plain'))
    
    try:
        server = smtplib.SMTP(SMTP_SERVER, SMTP_PORT)
        server.starttls()
        server.login(SENDER_EMAIL, SENDER_PASSWORD)
        server.send_message(msg)
        server.quit()
        return True
    except Exception as e:
        print(f"Error sending email: {e}")
        return False

@app.route('/send-email', methods=['POST'])
def handle_send_email():
    try:
        data = request.json
        to_email = data.get('to')
        otp = data.get('otp')
        
        if send_otp_email(to_email, otp):
            return jsonify({"status": "success"}), 200
        else:
            return jsonify({"status": "error", "message": "Failed to send email"}), 500
            
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8082, debug=True)