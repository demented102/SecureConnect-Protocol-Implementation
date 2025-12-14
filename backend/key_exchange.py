from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.asymmetric import ec
from cryptography.hazmat.primitives.kdf.hkdf import HKDF
from cryptography.hazmat.primitives.ciphers.aead import AESGCM

# --- 1. Both parties agree on a "curve" to use ---
# This is not secret. We'll use SECP256R1.
curve = ec.SECP256R1()

# --- 2. Client-Side Simulation ---
print("--- Client Side ---")
# Client generates a temporary (ephemeral) private/public key pair
client_private_key = ec.generate_private_key(curve)
client_public_key = client_private_key.public_key()
print("Client generated ephemeral keys.")

# --- 3. Server-Side Simulation ---
print("\n--- Server Side ---")
# Server also generates its own temporary private/public key pair
server_private_key = ec.generate_private_key(curve)
server_public_key = server_private_key.public_key()
print("Server generated ephemeral keys.")

# --- 4. The Exchange ---
# The client sends its public key to the server.
# The server sends its public key to the client.
# (This is the "exchange" part. The private keys NEVER move)
print("\n--- Key Exchange ---")
print("Client and Server exchange public keys...")

# --- 5. Deriving the Shared Secret (Client) ---
# Client uses THEIR private key and the SERVER'S public key
client_shared_secret = client_private_key.exchange(ec.ECDH(), server_public_key)
print("Client derived the shared secret.")

# --- 6. Deriving the Shared Secret (Server) ---
# Server uses THEIR private key and the CLIENT'S public key
server_shared_secret = server_private_key.exchange(ec.ECDH(), client_public_key)
print("Server derived the shared secret.")

# --- 7. Verification ---
if client_shared_secret == server_shared_secret:
    print("✅ SUCCESS: Both parties derived the exact same secret!")
    
    # --- 8. Using the Derived Key (as required by Lab 3) ---
    # The shared secret is NOT an encryption key itself.
    # We "derive" a usable key from it using a KDF (Key Derivation Function).
    hkdf = HKDF(
        algorithm=hashes.SHA256(),
        length=32, # We want a 256-bit (32-byte) key for AES
        salt=None,
        info=b'handshake data',
    )
    
    encryption_key = hkdf.derive(client_shared_secret)
    print("Derived a 256-bit AES key from the shared secret.")
    
    # Now we can use this key for AES-GCM (just like in Lab 1)
    aesgcm = AESGCM(encryption_key)
    nonce = b'123456789012' # 12-byte (96-bit) nonce
    plaintext = b"This message is protected by forward secrecy."
    
    ciphertext = aesgcm.encrypt(nonce, plaintext, None)
    print(f"Encrypted message: {ciphertext.hex()}")
    
    # The other party can derive the *same* key to decrypt
    decrypted_plaintext = aesgcm.decrypt(nonce, ciphertext, None)
    print(f"Decrypted message: {decrypted_plaintext.decode()}")

else:
    print("❌ FAILURE: Secrets do not match.")

# After this, client_private_key and server_private_key are DISCARDED.
# This is what provides the forward secrecy.