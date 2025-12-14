import pyotp
import time

# --- 1. User Setup (One-Time Event) ---
# In a real app, you'd generate this once per user and
# save the 'user_secret' in your database.
user_secret = pyotp.random_base32()
print(f"Generated User Secret: {user_secret}")

# Generate the provisioning URI. This is the link you'd
# encode into a QR code for the user to scan.
# We'll pretend the user is 'user@example.com' for an app 'MySecureApp'
provisioning_uri = pyotp.totp.TOTP(user_secret).provisioning_uri(
    name='user@example.com',
    issuer_name='MySecureApp'
)
print(f"Provisioning URI (for QR code): {provisioning_uri}")
print("\n--- PLEASE SCAN THIS URI (or manually enter the secret) ---")
print("Scan the QR code this URI generates (e.g., using an online QR generator).")
print("Then, enter the 6-digit code from your authenticator app.")


# --- 2. Login Verification (Every Time User Logs In) ---
def verify_login_attempt():
    # Create the TOTP object using the user's stored secret
    totp = pyotp.TOTP(user_secret)

    # Get the code from the user
    user_code = input("Enter 6-digit MFA code: ")
    
    # Verify the code
    if totp.verify(user_code):
        print("✅ SUCCESS: Code is valid. Login approved.")
        return True
    else:
        print("❌ FAILURE: Code is invalid. Login denied.")
        return False

# --- Main execution ---
if __name__ == "__main__":
    # Wait for the user to scan the QR code and enter a code
    while not verify_login_attempt():
        # Keep asking until they get it right
        print("Please try again.")