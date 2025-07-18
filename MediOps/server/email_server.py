from flask import Flask, request, jsonify
import time
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
import os
from datetime import datetime, time, timedelta
import random
import string
from threading import Lock
from typing import Dict, Tuple

# Secure in-memory storage for credentials
class CredentialStore:
    def __init__(self):
        self._store: Dict[str, Tuple[str, datetime, str]] = {}
        self._lock = Lock()
        self._expiry_time = timedelta(hours=1)
    
    def store_credentials(self, user_id: str, password: str, user_type: str):
        with self._lock:
            # Normalize user type for consistent storage
            normalized_type = user_type.lower()
            self._store[user_id] = (password, datetime.now(), normalized_type)
            print(f"Stored credentials for {user_type} user {user_id} with password {password}")
            self._cleanup_expired()
    
    def validate_credentials(self, user_id: str, password: str, user_type: str) -> Tuple[bool, str]:
        print(f"Validating credentials - userType: {user_type}, userId: {user_id}, password: {password}")
        with self._lock:
            self._cleanup_expired()
            if user_id not in self._store:
                print(f"Credentials not found for {user_type} user {user_id}")
                return False, f"Credentials not found for {user_type} user"
            
            stored_password, timestamp, stored_type = self._store[user_id]
            if datetime.now() - timestamp > self._expiry_time:
                del self._store[user_id]
                print(f"Credentials expired for user {user_id}")
                return False, "Credentials expired"
            
            # Normalize user types for comparison
            normalized_input_type = user_type.lower()
            normalized_stored_type = stored_type.lower()

            if normalized_stored_type == 'lab_admin':
                normalized_stored_type = 'lab'
            
            if normalized_stored_type != normalized_input_type:
                print(f"Type mismatch for user {user_id}: expected {normalized_stored_type}, got {normalized_input_type}")
                return False, "Invalid user type"
                
            if stored_password != password:
                print(f"Invalid password for user {user_id}")
                return False, "Invalid password"
                
            print(f"Successful validation for {user_type} user {user_id}")
            return True, ""
    
    def get_remaining_time(self, user_id: str) -> int:
        with self._lock:
            if user_id not in self._store:
                return 0
            _, timestamp, _ = self._store[user_id]
            remaining = self._expiry_time - (datetime.now() - timestamp)
            return max(0, int(remaining.total_seconds()))
    
    def _cleanup_expired(self) -> None:
        current_time = datetime.now()
        expired = [user_id for user_id, (_, timestamp, _) in self._store.items()
                  if current_time - timestamp > self._expiry_time]
        for user_id in expired:
            del self._store[user_id]

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
    return ''.join(random.sample(password, len(password)))  # Shuffle to randomize

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
        with open(template_path, 'r') as file:
            html_content = file.read()
        
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
    # Hospital ID is now provided by super admin
    return None

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
            
        # Generate credentials
        password = generate_secure_password()
        generated_id = None
        
        if account_type == 'lab':
            generated_id = generate_lab_admin_id()
            # Store credentials in memory for temporary access
            credential_store.store_credentials(generated_id, password, 'lab')
            print(f"Stored temporary credentials for lab admin {generated_id}")
            
            # Set expiration time for credentials
            expiry_time = credential_store.get_remaining_time(generated_id)
            print(f"Lab admin credentials will expire in {expiry_time} seconds")
            
        # Store credentials in memory for temporary access
        if generated_id and password:
            credential_store.store_credentials(generated_id, password, account_type)
            print(f"Stored temporary credentials for {account_type} user {generated_id}")
            
            # Set expiration time for credentials
            expiry_time = credential_store.get_remaining_time(generated_id)
            print(f"Credentials will expire in {expiry_time} seconds")
            
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
            template_path = os.path.join(os.path.dirname(__file__), 'templates/doctor_credentials.html')
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
            hospital_id = details.get('hospitalId')
            if not hospital_id:
                return jsonify({"status": "error", "message": "Hospital ID is required"}), 400
            admin_id = hospital_id
            hospital_name = details.get('hospitalName')
            street = details.get('street')
            city = details.get('city')
            state = details.get('state')
            zip_code = details.get('zipCode')
            license_number = details.get('licenseNumber')
            template_path = os.path.join(os.path.dirname(__file__), 'templates/hospital_admin.html')
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
            lab_id = generate_lab_admin_id()
            lab_name = details.get('labName', 'Main Laboratory')
            template_path = os.path.join(os.path.dirname(__file__), 'templates/lab_admin.html')
            subject = "MediOps - Your Lab Admin Account Credentials"
            placeholders = {
                '{{fullName}}': full_name,
                '{{labId}}': lab_id,
                '{{email}}': to_email,
                '{{password}}': password,
                '{{labName}}': lab_name,
                '{{phone}}': phone
            }
            generated_id = lab_id

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
            # Store credentials with normalized user type
            normalized_type = account_type.lower()
            credential_store.store_credentials(generated_id, password, normalized_type)
            
            # Log successful credential storage
            print(f"Credentials stored for {normalized_type} account: {generated_id}")
            
            return jsonify({
                "status": "success",
                "id": generated_id,
                "password": password,
                "type": normalized_type
            }), 200
        else:
            return jsonify({"status": "error", "message": "Failed to send credentials email"}), 500

    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500

@app.route('/validate-credentials', methods=['POST'])
def validate_user_credentials():
    print(f"Received credential validation request: {request.json}")
    try:
        # Validate request data and headers
        if not request.is_json:
            return jsonify({
                "status": "error",
                "message": "Content-Type must be application/json",
                "valid": False,
                "data": None
            }), 415

        data = request.json
        if not data:
            return jsonify({
                "status": "error",
                "message": "No data provided",
                "valid": False,
                "data": None
            }), 400
            
        user_id = data.get('userId')
        password = data.get('password')
        user_type = data.get('userType', 'doctor')
        
        # Validate required fields
        if not user_id or not password:
            missing_fields = []
            if not user_id: missing_fields.append('userId')
            if not password: missing_fields.append('password')
            return jsonify({
                "status": "error",
                "message": f"Missing required fields: {', '.join(missing_fields)}",
                "valid": False,
                "data": None
            }), 400
            
        # Validate user type
        valid_user_types = ['doctor', 'lab', 'hospital']
        if user_type not in valid_user_types:
            return jsonify({
                "status": "error",
                "message": f"Invalid user type. Must be one of: {', '.join(valid_user_types)}",
                "valid": False,
                "data": None
            }), 400
            
            
        # Validate ID format based on user type
        id_prefix_map = {
            'doctor': 'DOC',
            'lab': 'LAB',
            'hospital': 'HOS'
        }
        expected_prefix = id_prefix_map.get(user_type)
        if not user_id.startswith(expected_prefix):
            return jsonify({
                "status": "error",
                "message": f"Invalid {user_type} ID format. Must start with {expected_prefix}",
                "valid": False,
                "data": None
            }), 400
            
        # Rate limiting check (implement if needed)
        # TODO: Add rate limiting logic here
            
        # Validate credentials
        is_valid, error_message = credential_store.validate_credentials(user_id, password, user_type)
        
        if not is_valid:
            # Log failed attempt with timestamp and specific error
            current_time = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
            print(f"[{current_time}] Failed login attempt - Type: {user_type}, ID: {user_id}, Reason: {error_message}")
            return jsonify({
                "status": "error",
                "message": error_message,
                "valid": False,
                "data": None
            }), 401
        
        # Return successful validation response
        remaining_time = credential_store.get_remaining_time(user_id)
        current_time = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        print(f"[{current_time}] Successful login - Type: {user_type}, ID: {user_id}")
        return jsonify({
            "status": "success",
            "message": "Authentication successful",
            "valid": True,
            "data": {
                "userId": user_id,
                "userType": user_type,
                "remainingTime": remaining_time
            }
        }), 200
    except Exception as e:
        # Log the error for debugging
        print(f"Error in validate_user_credentials: {str(e)}")
        return jsonify({
            "status": "error",
            "message": "Unable to process server response",
            "valid": False,
            "data": None
        }), 500
            
    except Exception as e:
        return jsonify({"status": "error", "message": str(e), "valid": False, "data": None}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8082, debug=True)
