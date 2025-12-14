from cryptography.hazmat.primitives.asymmetric import rsa, padding, utils
from cryptography.hazmat.primitives import hashes

# --- 1. Key Generation ---
# In a real system, you'd generate this once and save it.
private_key = rsa.generate_private_key(
    public_exponent=65537,
    key_size=2048,
)
public_key = private_key.public_key()

# --- 2. Message Signing (Sender's Side) ---
def sign_message(message_text):
    message = message_text.encode('utf-8') # Convert string to bytes
    
    print(f"Signing message: '{message_text}'")
    
    signature = private_key.sign(
        message,
        padding.PSS(
            mgf=padding.MGF1(hashes.SHA256()),
            salt_length=padding.PSS.MAX_LENGTH
        ),
        hashes.SHA256()
    )
    
    print("✅ Message signed.")
    return signature, message

# --- 3. Signature Verification (Recipient's Side) ---
def verify_signature(public_key, signature, original_message):
    print("Verifying signature...")
    try:
        public_key.verify(
            signature,
            original_message,
            padding.PSS(
                mgf=padding.MGF1(hashes.SHA256()),
                salt_length=padding.PSS.MAX_LENGTH
            ),
            hashes.SHA256()
        )
        print("✅ Signature is valid.")
        return True
    except Exception as e:
        # This will fail if the signature is wrong, the message
        # was tampered with, or the wrong public key was used.
        print(f"❌ Signature verification failed: {e}")
        return False

# --- Main execution ---
if __name__ == "__main__":
    # Sender signs the message
    my_signature, my_message = sign_message("This is a sensitive decision.")
    
    # Recipient verifies the message
    # In your app, the recipient would have the SENDER'S public_key
    verify_signature(public_key, my_signature, my_message)
    
    # --- DEMONSTRATE FAILED VERIFICATION ---
    print("\n--- Tampering Test ---")
    tampered_message = b"This is a tampered decision."
    verify_signature(public_key, my_signature, tampered_message)