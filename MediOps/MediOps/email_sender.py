import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
import sys

def send_email(recipient, subject, body):
    # Email credentials
    sender_email = "aryanshukla0024@gmail.com"
    sender_password = "jqlj tdhn rmjs vyha"

    # Create message
    message = MIMEMultipart()
    message["From"] = sender_email
    message["To"] = recipient
    message["Subject"] = subject

    # Add body to email
    message.attach(MIMEText(body, "plain"))

    try:
        # Create SMTP session
        server = smtplib.SMTP("smtp.gmail.com", 587)
        server.starttls()
        
        # Login
        server.login(sender_email, sender_password)
        
        # Send email
        server.send_message(message)
        server.quit()
        print("SUCCESS")  # Success indicator for Swift
    except Exception as e:
        print(f"ERROR: {str(e)}")  # Error message for Swift
        sys.exit(1)

if __name__ == "__main__":
    if len(sys.argv) != 4:
        print("ERROR: Invalid arguments")
        sys.exit(1)
    
    send_email(sys.argv[1], sys.argv[2], sys.argv[3])