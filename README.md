# ⚠️ Security Notice & Educational Disclaimer

**This repository is a conceptual prototype created for educational purposes and academic demonstration. It is NOT intended for use in production environments or for transmitting sensitive real-world data.**

The primary goal of this project is to demonstrate the fundamental principles of End-to-End Encryption (E2EE), Zero-Knowledge server architectures, and the application of cryptographic primitives (RSA, AES-GCM, ECDHE) within a client-server messaging model.

---

## 🛡️ Production Considerations & Limitations

While the cryptographic algorithms used in this project (like AES-256-GCM and RSA-2048-OAEP) are industry standards, the *implementation architecture* of this prototype takes intentional shortcuts for the sake of demonstration. 

If this system were to be adapted for a real-world, production-grade application, the following critical security and architectural upgrades would be mandatory:

### 1. Secure Key Storage (Client-Side)
* **Current State:** Private keys are stored in standard persisted App State (shared preferences/local storage).
* **Production Requirement:** Private keys must be moved to hardware-backed secure storage, such as the **Android Keystore** or **iOS Secure Enclave**. This protects the keys from extraction even if the device is physically compromised or rooted.

### 2. Man-in-the-Middle (MITM) Mitigation
* **Current State:** The system uses "Trust on First Use" (TOFU). The server dictates public key distribution without secondary verification.
* **Production Requirement:** Implementation of **Out-of-Band Key Verification**. Users must be able to verify each other's public key fingerprints (e.g., by scanning a QR code in person) to ensure the server hasn't swapped a public key to intercept messages.

### 3. Backend Infrastructure & Scalability
* **Current State:** Uses a single-threaded Flask development server with in-memory Python dictionaries simulating a database. Large file transfers are handled entirely in memory via Base64 strings.
* **Production Requirement:** * Deployment via a production WSGI server (e.g., Gunicorn) behind a reverse proxy (e.g., Nginx).
    * Migration to a persistent, encrypted-at-rest database (e.g., PostgreSQL).
    * Implementation of **multipart chunked streaming** for file uploads to prevent server memory exhaustion.

### 4. Perfect Forward Secrecy (PFS)
* **Current State:** The ECDHE (Elliptic Curve Diffie-Hellman Ephemeral) handshake is implemented as a standalone demonstration endpoint. Standard messages rely on static RSA key encapsulation.
* **Production Requirement:** The ECDHE protocol (like the Double Ratchet Algorithm used by Signal) must be fully integrated into the core messaging loop, continuously rotating symmetric keys so that a future compromise of a private key does not expose past messages.

### 5. Threat Throttling & Rate Limiting
* **Current State:** Basic JWT and TOTP authentication.
* **Production Requirement:** Strict API rate limiting and account lockout mechanisms to defend against brute-force login attempts and denial-of-service (DoS) attacks.

In the contemporary humanitarian landscape, the digital transformation of Non-Governmental Organisations (NGOs) has become a double-edged sword. While it enhances efficiency, conventional communication platforms rely on a "centralised trust" model (using only encryption-in-transit like TLS). This creates a single point of failure where server breaches can expose sensitive humanitarian data—such as refugee biometrics, locations, and medical histories—leading to severe real-world consequences.

**SecureConnect** was built to address this ethical challenge. By adhering to strict "Privacy by Design" principles, it implements a **Zero-Knowledge Architecture**. The server functions solely as a "blind relay" and a key directory. It possesses no mathematical ability to decrypt user communications, ensuring that data sovereignty remains strictly with the end-users.

---

## ⚙️ How It Works (System Architecture & Cryptography)

The system relies on shifting all cryptographic intelligence to the client (the Flutter mobile app), while the server (Python/Flask) remains oblivious to the plaintext content.

### 1. Robust Authentication
Before any keys are exchanged, users must authenticate. The system utilizes a multi-factor approach:
* **Primary:** Passwords securely hashed via **bcrypt**.
* **Secondary (MFA):** Time-based One-Time Passwords (**TOTP**) via Google Authenticator.
* **Session:** Authenticated users are issued a stateless **JSON Web Token (JWT)** for API authorization.

### 2. Hybrid End-to-End Encryption (E2EE)
To balance speed and security, the messaging protocol uses a hybrid encryption model:
* **Key Generation:** The client locally generates an **RSA-2048** key pair. The Public Key is uploaded to the server; the Private Key never leaves the device.
* **Sending a Message:** 1. Sender requests the Recipient's Public RSA Key from the server.
  2. Sender generates a random, one-time **AES-256** key and a 12-byte nonce.
  3. The message plaintext is encrypted using **AES-256-GCM** (providing both confidentiality and integrity via an authentication tag).
  4. The one-time AES key is then "wrapped" (encrypted) using the Recipient's Public Key via **RSA-OAEP**.
  5. The bundled ciphertext and wrapped key are sent to the server.
* **Receiving a Message:** The Recipient downloads the bundle, uses their local Private RSA Key to unwrap the AES key, and then uses the AES key to decrypt the actual message.

### 3. Secure File Sharing
Files (like images or documents) are processed using the same hybrid cryptographic flow. 
* The file is read as a binary byte array (`Uint8List`).
* It is encrypted using AES-256-GCM.
* The resulting ciphertext is encoded into a Base64 string for transmission via standard JSON payloads. 
* Upon receipt, the payload is decrypted and written securely to the device's native file system.

---

## 📂 Project Structure

```text
/project-folder
│
├── /backend_python_api    # The Flask Server code (api.py, requirements.txt)
└── /secure_messaging      # The Flutter App code (lib/, pubspec.yaml, etc.)
