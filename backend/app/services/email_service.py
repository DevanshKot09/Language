import smtplib
import logging
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from typing import Optional

from app.core.config import settings

logger = logging.getLogger("lingua_ai.email")


class EmailService:
    """
    Reusable transactional email service using Gmail SMTP with STARTTLS.
    Strictly prevents secret logging and follows secure email delivery standards.
    """

    @classmethod
    def is_configured(cls) -> bool:
        """Checks if SMTP credentials and host are configured."""
        return bool(settings.SMTP_HOST and settings.SMTP_USER and settings.SMTP_PASSWORD)

    @classmethod
    def send_email(
        cls,
        to_email: str,
        subject: str,
        html_content: str,
        text_content: Optional[str] = None,
    ) -> bool:
        """
        Sends a transactional email via SMTP.
        Returns True if successful, False otherwise.
        Never logs credentials or secret tokens.
        """
        if not cls.is_configured():
            logger.warning("SMTP is not configured. Email to recipient suppressed.")
            return False

        from_email = settings.SMTP_FROM_EMAIL or settings.SMTP_USER
        from_header = f"{settings.SMTP_FROM_NAME} <{from_email}>"

        msg = MIMEMultipart("alternative")
        msg["Subject"] = subject
        msg["From"] = from_header
        msg["To"] = to_email

        # Attach plain-text fallback
        plain_text = text_content or "Please open this email in an HTML-compatible email client."
        msg.attach(MIMEText(plain_text, "plain", "utf-8"))

        # Attach rich HTML version
        msg.attach(MIMEText(html_content, "html", "utf-8"))

        try:
            # Connect via SMTP with STARTTLS on port 587
            with smtplib.SMTP(settings.SMTP_HOST, settings.SMTP_PORT, timeout=15) as server:
                server.ehlo()
                server.starttls()
                server.ehlo()
                server.login(settings.SMTP_USER, settings.SMTP_PASSWORD)
                server.sendmail(from_email, [to_email], msg.as_string())

            domain = to_email.split("@")[-1] if "@" in to_email else "unknown"
            logger.info(f"Transactional email sent successfully to @{domain} (subject: {subject})")
            return True
        except Exception as e:
            logger.error(f"Failed to send email: {type(e).__name__}")
            return False

    @classmethod
    def send_password_reset_email(cls, to_email: str, reset_link: str) -> bool:
        """
        Sends the official LINGUA AI password recovery email.
        Uses responsive, accessible, branded HTML styling.
        """
        subject = "Reset your LINGUA AI password"

        text_content = (
            f"Hello,\n\n"
            f"We received a request to reset your password for your LINGUA AI account.\n\n"
            f"To reset your password, please open the following link in your browser:\n"
            f"{reset_link}\n\n"
            f"This link will expire in 15 minutes for your security.\n\n"
            f"If you did not request a password reset, you can safely ignore this email. "
            f"Your account remains protected.\n\n"
            f"— The LINGUA AI Team"
        )

        html_content = f"""<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Reset your LINGUA AI password</title>
</head>
<body style="margin: 0; padding: 0; background-color: #FAF9FD; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; color: #1B1738;">
  <table role="presentation" border="0" cellpadding="0" cellspacing="0" width="100%" style="background-color: #FAF9FD; padding: 32px 16px;">
    <tr>
      <td align="center">
        <table role="presentation" border="0" cellpadding="0" cellspacing="0" width="100%" style="max-width: 520px; background-color: #FFFFFF; border-radius: 24px; border: 1px solid #ECE7F7; box-shadow: 0 4px 20px rgba(56, 20, 142, 0.04); overflow: hidden;">
          <!-- Header Branding -->
          <tr>
            <td style="padding: 32px 32px 20px 32px; text-align: center; border-bottom: 1px solid #F0ECF8;">
              <table role="presentation" border="0" cellpadding="0" cellspacing="0" style="margin: 0 auto;">
                <tr>
                  <td style="width: 36px; height: 36px; background-color: #4F22E5; border-radius: 10px; text-align: center; vertical-align: middle;">
                    <span style="color: #FFFFFF; font-size: 20px; font-weight: bold; line-height: 36px;">L</span>
                  </td>
                  <td style="padding-left: 10px; font-size: 22px; font-weight: 800; color: #1B1738; letter-spacing: -0.3px;">
                    LINGUA <span style="color: #4F22E5;">AI</span>
                  </td>
                </tr>
              </table>
            </td>
          </tr>

          <!-- Body Content -->
          <tr>
            <td style="padding: 32px 32px 24px 32px; text-align: left;">
              <h1 style="margin: 0 0 12px 0; font-size: 22px; font-weight: 800; color: #1B1738; line-height: 1.3;">
                Reset your password
              </h1>
              <p style="margin: 0 0 20px 0; font-size: 15px; line-height: 1.6; color: #4C4964;">
                Hello, we received a request to reset your password for your <strong>LINGUA AI</strong> account. Click the button below to choose a new password.
              </p>

              <!-- CTA Button -->
              <table role="presentation" border="0" cellpadding="0" cellspacing="0" style="margin: 28px 0;">
                <tr>
                  <td align="center" style="border-radius: 14px; background-color: #4F22E5; box-shadow: 0 4px 0 #38148E;">
                    <a href="{reset_link}" target="_blank" style="display: inline-block; padding: 14px 28px; font-size: 15px; font-weight: 700; color: #FFFFFF; text-decoration: none; border-radius: 14px; background-color: #4F22E5;">
                      Reset Password &rarr;
                    </a>
                  </td>
                </tr>
              </table>

              <p style="margin: 0 0 16px 0; font-size: 13.5px; line-height: 1.5; color: #7E7B95;">
                This reset link is valid for <strong>15 minutes</strong>. If you did not request a password reset, you can safely ignore this email — your account remains secure.
              </p>

              <hr style="border: none; border-top: 1px solid #F0ECF8; margin: 24px 0;" />

              <p style="margin: 0; font-size: 12px; line-height: 1.5; color: #9A97B0;">
                If the button above doesn't work, copy and paste this link into your browser:<br>
                <a href="{reset_link}" style="color: #4F22E5; word-break: break-all; text-decoration: underline;">{reset_link}</a>
              </p>
            </td>
          </tr>

          <!-- Security Footer -->
          <tr>
            <td style="padding: 20px 32px; background-color: #FAF9FD; text-align: center; border-top: 1px solid #F0ECF8;">
              <p style="margin: 0; font-size: 12px; color: #7E7B95; line-height: 1.5;">
                Protected by Lingua Child-Safe AI Security &bull; 256-bit Encryption<br>
                Non-diagnostic language & literacy educational platform
              </p>
            </td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
</body>
</html>"""

        return cls.send_email(
            to_email=to_email,
            subject=subject,
            html_content=html_content,
            text_content=text_content,
        )
