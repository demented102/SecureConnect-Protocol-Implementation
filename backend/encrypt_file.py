import os
from cryptography.hazmat.primitives.ciphers.aead import AESGCM

# --- 1. Key Generation ---
# In a real app, this key would be securely managed.
# For this lab, we generate a random 256-bit (32-byte) key.
key = AESGCM.generate_key(bit_length=256)
aesgcm = AESGCM(key)

# --- 2. File Encryption ---
def encrypt_file(file_path):
    # A nonce (number used once) is required for GCM mode.
    # It must be unique for each encryption with the same key.
    # We generate a random 96-bit (12-byte) nonce.
    nonce = os.urandom(12)
    
    # Read the file content
    with open(file_path, 'rb') as f:
        plaintext = f.read()
    
    # Encrypt the content
    ciphertext = aesgcm.encrypt(nonce, plaintext, None)
    
    # Write the nonce and ciphertext to a new file
    encrypted_file_path = file_path + ".enc"
    with open(encrypted_file_path, 'wb') as f:
        f.write(nonce)
        f.write(ciphertext)
    
    print(f"✅ File encrypted successfully: {encrypted_file_path}")
    return encrypted_file_path

# --- 3. File Decryption ---
def decrypt_file(encrypted_file_path):
    # Read the nonce and ciphertext from the encrypted file
    with open(encrypted_file_path, 'rb') as f:
        nonce = f.read(12) # First 12 bytes are the nonce
        ciphertext = f.read()
    
    # Decrypt the content
    try:
        plaintext = aesgcm.decrypt(nonce, ciphertext, None)
        
        # Write the decrypted content to a new file
        decrypted_file_path = encrypted_file_path.replace(".enc", ".dec")
        with open(decrypted_file_path, 'wb') as f:
            f.write(plaintext)
            
        print(f"✅ File decrypted successfully: {decrypted_file_path}")
        return decrypted_file_path
    except Exception as e:
        # This will fail if the key is wrong or the data was tampered with
        print(f"❌ Decryption failed: {e}")
        return None

# --- Main execution ---
if __name__ == "__main__":
    # Create a dummy file to test with
    with open("my_secret_data.txt", "w") as f:
        f.write("This contains sensitive humanitarian data.")
    
    # Run the encryption and decryption process
    encrypted_path = encrypt_file("my_secret_data.txt")
    if encrypted_path:
        decrypt_file(encrypted_path)