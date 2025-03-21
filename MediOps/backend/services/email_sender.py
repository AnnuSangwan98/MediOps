import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart

class EmailSender:
    def __init__(self):
        self.smtp_server = "smtp.gmail.com"
        self.smtp_port = 587
        self.sender_email = "your-email@gmail.com"  # Update with your email
        self.password = "your-app-password"  # Update with your app password
    
    def send_otp(self, to_email: str, otp: str, role: str) -> bool:
        try:
            message = MIMEMultipart()
            message["From"] = self.sender_email
            message["To"] = to_email
            message["Subject"] = f"MediOps {role.capitalize()} Verification OTP"
            
            body = f"""
            Hello,
            
            Your OTP for MediOps {role.capitalize()} verification is: {otp}
            
            This OTP will expire in 10 minutes.
            
            Best regards,
            MediOps Team
            """
            
            message.attach(MIMEText(body, "plain"))
            
            with smtplib.SMTP(self.smtp_server, self.smtp_port) as server:
                server.starttls()
                server.login(self.sender_email, self.password)
                server.send_message(message)
            
            return True
            
        except Exception as e:
            print(f"Error sending email: {str(e)}")
            return False

# Singleton instance
email_sender = EmailSender() 