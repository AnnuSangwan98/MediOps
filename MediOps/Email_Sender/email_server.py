from flask import Flask, request, jsonify
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
import os
from datetime import datetime, timedelta
import random
import string
from threading import Lock
from typing import Dict, Tuple

# Secure in-memory storage for doctor credentials
class CredentialStore:
    def __init__(self):
        self._store: Dict[str, Tuple[str, datetime]] = {}
        self._lock = Lock()
        self._expiry_time = timedelta(hours=1)
    
    def store_credentials(self, doctor_id: str, password: str) -> None:
        with self._lock:
            self._store[doctor_id] = (password, datetime.now())
            self._cleanup_expired()
    
    def validate_credentials(self, doctor_id: str, password: str) -> bool:
        with self._lock:
            self._cleanup_expired()
            if doctor_id not in self._store:
                return False
            stored_password, _ = self._store[doctor_id]
            return stored_password == password
    
    def _cleanup_expired(self) -> None:
        current_time = datetime.now()
        expired = [doc_id for doc_id, (_, timestamp) in self._store.items()
                  if current_time - timestamp > self._expiry_time]
        for doc_id in expired:
            del self._store[doc_id]

# Initialize credential store
credential_store = CredentialStore()

app = Flask(__name__)

# Configure server for better network handling and mobile hotspot connections
app.config.update(
    PROPAGATE_EXCEPTIONS = True,
    MAX_CONTENT_LENGTH = 16 * 1024 * 1024,  # 16MB max request size
    REQUEST_TIMEOUT = 120,  # 120 seconds timeout for slower connections
    PREFERRED_URL_SCHEME = 'http',
    SESSION_COOKIE_SECURE = False,  # Allow non-HTTPS connections
    MAX_KEEP_ALIVE_COUNT = 5,  # Limit keep-alive connections
    SEND_FILE_MAX_AGE_DEFAULT = 0,  # Disable caching for development
    SERVER_NAME = None,  # Allow all hostnames
    APPLICATION_ROOT = '/',  # Set application root
    JSONIFY_PRETTYPRINT_REGULAR = False  # Disable pretty printing for smaller responses
)

# Configure server to handle network interruptions
app.config['TRAP_HTTP_EXCEPTIONS'] = True
app.config['TRAP_BAD_REQUEST_ERRORS'] = True

last_email_sent = {}

# Email configuration
SMTP_SERVER = "smtp.gmail.com"
SMTP_PORT = 587
SENDER_EMAIL = "mediops.infosys@gmail.com"
SENDER_PASSWORD = "zofa bied qcsx alnd"

def generate_doctor_id():
    number = random.randint(1, 999)
    return f'DOC{str(number).zfill(3)}'

def generate_secure_password():
    upper = random.choice(string.ascii_uppercase)
    lower = random.choice(string.ascii_lowercase)
    digit = random.choice(string.digits)
    special = random.choice("!@#$%^&*()")
    rest = ''.join(random.choices(string.ascii_letters + string.digits + "!@#$%^&*()", k=4))
    password = upper + lower + digit + special + rest
    return ''.join(random.sample(password, len(password)))

def send_email(to_email, subject, html_content):
    try:
        msg = MIMEMultipart('mixed')
        msg['From'] = SENDER_EMAIL
        msg['To'] = to_email
        msg['Subject'] = subject
        msg['Date'] = datetime.now().strftime('%a, %d %b %Y %H:%M:%S %z')
        msg['Message-ID'] = f'<{datetime.now().strftime("%Y%m%d%H%M%S")}.{random.randint(1000,9999)}@mediops.com>'
        msg.attach(MIMEText(html_content, 'html', 'utf-8'))

        retry_count = 3
        retry_delay = 2  # seconds

        while retry_count > 0:
            try:
                with smtplib.SMTP(SMTP_SERVER, SMTP_PORT, timeout=30) as server:
                    server.ehlo()
                    server.starttls()
                    server.ehlo()
                    server.login(SENDER_EMAIL, SENDER_PASSWORD)
                    server.send_message(msg)
                    print(f"Email sent successfully to {to_email}")
                return True
            except (smtplib.SMTPServerDisconnected, smtplib.SMTPConnectError) as e:
                retry_count -= 1
                if retry_count > 0:
                    print(f"Connection error, retrying in {retry_delay} seconds...")
                    time.sleep(retry_delay)
                    retry_delay *= 2  # Exponential backoff
                else:
                    raise e
    except smtplib.SMTPAuthenticationError as e:
        print(f"SMTP Authentication Error: {e}")
        return False
    except smtplib.SMTPException as e:
        print(f"SMTP Error: {e}")
        return False
    except Exception as e:
        print(f"Error sending email: {e}")
        return False

@app.route('/send-email', methods=['POST'])
def handle_send_email():
    try:
        data = request.json
        to_email = data.get('to')
        otp = str(data.get('otp')).zfill(6)

        # Prevent spam within 5 seconds window
        current_time = datetime.now()
        if to_email in last_email_sent:
            time_diff = current_time - last_email_sent[to_email]
            if time_diff.total_seconds() < 5:
                return jsonify({"status": "success", "message": "Email already sent recently"}), 200

        # Load OTP template
        template_path = os.path.join(os.path.dirname(__file__), 'templates/email_template.html')
        print(f"Loading template from {os.path.abspath(template_path)}")
        with open(template_path, 'r') as file:
            html_content = file.read()
        print("Successfully loaded template")
        
        # Fill OTP placeholders {1} to {6}
        for idx, digit in enumerate(otp, start=1):
            html_content = html_content.replace(f'{{{idx}}}', digit)

        if send_email(to_email, "MediOps - Your OTP Verification Code", html_content):
            last_email_sent[to_email] = current_time
            return jsonify({"status": "success"}), 200
        else:
            return jsonify({"status": "error", "message": "Failed to send OTP email"}), 500

    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500

def generate_lab_admin_id():
    number = random.randint(1, 999)
    return f'LAB{str(number).zfill(3)}'

def generate_hospital_admin_id():
    number = random.randint(1, 999)
    return f'HOS{str(number).zfill(3)}'

@app.route('/send-credentials', methods=['POST'])
def handle_send_credentials():
    try:
        data = request.json
        if not data:
            return jsonify({"status": "error", "message": "No data provided"}), 400
            
        to_email = data.get('to')
        if not to_email:
            return jsonify({"status": "error", "message": "Email address is required"}), 400
            
        details = data.get('details', {})
        account_type = data.get('accountType')
        if not account_type:
            return jsonify({"status": "error", "message": "Account type is required"}), 400
            
        full_name = details.get('fullName')
        phone = details.get('phone')
        
        if not full_name:
            return jsonify({"status": "error", "message": "Full name is required"}), 400

        # Generate ID and password
        password = generate_secure_password()
        
        if account_type == 'doctor':
            doctor_id = generate_doctor_id()
            specialization = details.get('specialization')
            license_num = details.get('license')
            template_path = os.path.join(os.path.dirname(__file__), '../templates/doctor_credentials.html')
            print(f"Loading template from {os.path.abspath(template_path)}")
            subject = "MediOps - Your Doctor Account Credentials"
            placeholders = {
                '{{fullName}}': full_name,
                '{{doctorId}}': doctor_id,
                '{{email}}': to_email,
                '{{password}}': password,
                '{{specialization}}': specialization,
                '{{license}}': license_num,
                '{{phone}}': phone
            }
            generated_id = doctor_id
        elif account_type == 'hospital':
            admin_id = generate_hospital_admin_id()
            hospital_name = details.get('hospitalName')
            hospital_id = details.get('hospitalId')
            street = details.get('street')
            city = details.get('city')
            state = details.get('state')
            zip_code = details.get('zipCode')
            license_number = details.get('licenseNumber')
            template_path = os.path.join(os.path.dirname(__file__), '../templates/hospital_admin.html')
            print(f"Loading template from {os.path.abspath(template_path)}")
            subject = "MediOps - Your Hospital Admin Account Credentials"
            placeholders = {
                '{{fullName}}': full_name,
                '{{hospitalName}}': hospital_name,
                '{{hospitalId}}': hospital_id,
                '{{email}}': to_email,
                '{{password}}': password,
                '{{street}}': street,
                '{{city}}': city,
                '{{state}}': state,
                '{{zipCode}}': zip_code,
                '{{phone}}': phone,
                '{{licenseNumber}}': license_number
            }
            generated_id = admin_id
        else:  # Lab Admin
            admin_id = generate_lab_admin_id()
            lab_name = details.get('labName', 'Main Laboratory')
            lab_id = details.get('labId', 'LAB001')
            template_path = os.path.join(os.path.dirname(__file__), '../templates/lab_admin.html')
            print(f"Loading template from {os.path.abspath(template_path)}")
            subject = "MediOps - Your Lab Admin Account Credentials"
            placeholders = {
                '{{fullName}}': full_name,
                '{{adminId}}': admin_id,
                '{{email}}': to_email,
                '{{password}}': password,
                '{{labName}}': lab_name,
                '{{labId}}': lab_id,
                '{{phone}}': phone
            }
            generated_id = admin_id

        # Prevent spam within 5 seconds window
        current_time = datetime.now()
        if to_email in last_email_sent:
            time_diff = current_time - last_email_sent[to_email]
            if time_diff.total_seconds() < 5:
                return jsonify({"status": "success", "message": "Email already sent recently"}), 200

        # Load template and send email
        try:
            with open(template_path, 'r') as file:
                html_content = file.read()
        except FileNotFoundError:
            print(f"Template not found: {template_path}")
            return jsonify({"status": "error", "message": "Email template not found"}), 500
        except Exception as e:
            print(f"Error reading template: {str(e)}")
            return jsonify({"status": "error", "message": "Error reading email template"}), 500
        
        try:
            for key, value in placeholders.items():
                if value is None:
                    value = ''
                html_content = html_content.replace(key, str(value))
        except Exception as e:
            print(f"Error replacing placeholders: {str(e)}")
            return jsonify({"status": "error", "message": "Error processing email template"}), 500

        if send_email(to_email, subject, html_content):
            # Store credentials if it's a doctor account
            if account_type == 'doctor':
                credential_store.store_credentials(generated_id, password)
            return jsonify({
                "status": "success",
                "id": generated_id,
                "password": password
            }), 200
        else:
            return jsonify({"status": "error", "message": "Failed to send credentials email"}), 500

    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500

@app.route('/validate-doctor', methods=['POST'])
def validate_doctor_credentials():
    try:
        data = request.json
        if not data:
            return jsonify({"status": "error", "message": "No data provided"}), 400
            
        doctor_id = data.get('doctorId')
        password = data.get('password')
        
        if not doctor_id or not password:
            return jsonify({"status": "error", "message": "Doctor ID and password are required"}), 400
            
        is_valid = credential_store.validate_credentials(doctor_id, password)
        
        return jsonify({
            "status": "success",
            "valid": is_valid
        }), 200
            
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500

if __name__ == '__main__':
    app.run(
        host='0.0.0.0',
        port=8082,
        debug=True,
        threaded=True,
        use_reloader=True,
        ssl_context=None  # Disable SSL for development
    )

