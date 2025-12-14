from flask import Flask, request, jsonify
import pyotp 
from cryptography.hazmat.primitives.ciphers.aead import AESGCM
from cryptography.hazmat.primitives.asymmetric import rsa, ec, padding, utils
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.kdf.hkdf import HKDF
import os
import bcrypt
import jwt
import uuid
import base64
from datetime import datetime, timedelta, timezone

# --- 1. Create the Flask application ---
app = Flask(__name__)

# SECURITY NOTE: In production, this key should come from an environment variable.
app.config['SECRET_KEY'] = 'YOUR_SECRET_KEY_HERE' 

# --- 2. Database Simulation ---
# In a real app, you'd fetch this from a secure database (e.g., PostgreSQL).
# We simulate a database here with Python dictionaries.

# Passwords should be hashed. These are placeholder hashes for the demo.
hashed_rugemah = b'$2b$12$HZYu5vrKq7wrjNAmBaC6Cefw9itRpu27yIY.glAaLT9L7Js08cbcK'
hashed_carmela = b'$2b$12$eLlBlUY6BRTlZjvN83tRtebCgoHNSIlySh2YtLI1YWgoWWyXvN/Ca'

USER_DATABASE = {
    "rugemah": {
        "password_hash": hashed_rugemah, 
        "mfa_secret": "JBSWY3DPEHPK3PXP", # Secret for Google Authenticator (Demo only)
        "public_key": None 
    },
    "carmela":{
        "password_hash": hashed_carmela, 
        "mfa_secret": "K3NSSERZ6P4J2V5M", 
        "public_key": None 
    },
    "david":{
        "password_hash": hashed_rugemah, 
        "mfa_secret": "JBSWY3DPEHPK3PXP", 
        "public_key": None 
    }
}

MESSAGES_DATABASE = []

# --- 3. Cryptographic Setup ---

# Curve P-256 for ECDHE Handshake
CURVE = ec.SECP256R1()
EPHEMERAL_KEYS_STORE = {} # Stores temporary server keys for handshakes

# --- 4. Define API Endpoints ---

@app.route("/")
def hello_world():
    return "The Secure Messaging API is running!"

@app.route("/login", methods=['POST'])
def handle_login():
    data = request.json
    print(f"RECEIVED DATA: {data}")
    username = data.get('username')
    password = data.get('password')
    totp_code = data.get('totp_code')

    user_record = USER_DATABASE.get(username)

    # --- Part A: Verify Username and Password Hash ---
    if not user_record:
        return jsonify({"message": "Invalid credentials"}), 401

    if not bcrypt.checkpw(password.encode('utf-8'), user_record['password_hash']):
        return jsonify({"message": "Invalid credentials"}), 401

    # --- Part B: Verify the MFA (TOTP) Code ---
    totp = pyotp.TOTP(user_record["mfa_secret"])
    if not totp.verify(totp_code):
        return jsonify({"message": "Invalid MFA code"}), 401

    # --- Part C: Create and Return a JWT ---
    token = jwt.encode({
        'sub': username, 
        'iat': datetime.now(timezone.utc), 
        'exp': datetime.now(timezone.utc) + timedelta(hours=24) 
    }, app.config['SECRET_KEY'], algorithm="HS256")

    print(f"✅ SUCCESS: User '{username}' logged in. Token issued.")
    
    return jsonify({
        "message": f"Welcome, {username}!",
        "token": token 
    })

@app.route("/get_users", methods=['GET'])
def handle_get_users():
    """
    Fetches a list of all users *except* the user making the request.
    """
    token = None
    if 'Authorization' in request.headers:
        token = request.headers['Authorization'].split(" ")[1]

    if not token:
        return jsonify({"message": "Token is missing!"}), 401

    try:
        data = jwt.decode(token, app.config['SECRET_KEY'], algorithms=["HS256"])
        current_user = data['sub']
    except:
        return jsonify({"message": "Token is invalid!"}), 401

    user_list = []
    for username in USER_DATABASE:
        if username != current_user:
            user_list.append({ "username": username })

    print(f"✅ User '{current_user}' requested user list.")
    return jsonify({"users": user_list})

@app.route("/upload_public_key", methods=['POST'])
def handle_upload_public_key():
    token = None
    if 'Authorization' in request.headers:
        token = request.headers['Authorization'].split(" ")[1]

    if not token:
        return jsonify({"message": "Token is missing!"}), 401

    try:
        data = jwt.decode(token, app.config['SECRET_KEY'], algorithms=["HS256"])
        current_user = data['sub']
    except:
        return jsonify({"message": "Token is invalid!"}), 401

    request_data = request.json
    public_key_pem = request_data.get('public_key')

    if not public_key_pem:
        return jsonify({"message": "No public_key provided"}), 400

    if current_user in USER_DATABASE:
        USER_DATABASE[current_user]['public_key'] = public_key_pem
        print(f"✅ Public key updated for user: {current_user}")
        return jsonify({
            "status": "success",
            "message": f"Public key for {current_user} stored."
        })
    else:
        return jsonify({"message": "User not found"}), 404

@app.route("/get_public_key", methods=['GET'])
def handle_get_public_key():
    token = None
    if 'Authorization' in request.headers:
        token = request.headers['Authorization'].split(" ")[1]

    if not token:
        return jsonify({"message": "Token is missing!"}), 401

    try:
        data = jwt.decode(token, app.config['SECRET_KEY'], algorithms=["HS256"])
    except:
        return jsonify({"message": "Token is invalid!"}), 401

    target_user = request.args.get('user')
    if not target_user:
        return jsonify({"message": "No user specified in query parameter"}), 400

    user_record = USER_DATABASE.get(target_user)
    
    if not user_record:
        return jsonify({"message": "User not found"}), 404

    public_key_pem = user_record.get('public_key')

    if not public_key_pem:
        return jsonify({"message": "This user has not uploaded a public key yet"}), 404

    print(f"✅ Public key for '{target_user}' was requested and sent.")
    return jsonify({
        "username": target_user,
        "public_key": public_key_pem
    })

@app.route("/send_message", methods=['POST'])
def handle_send_message():
    """
    Receives an end-to-end encrypted payload and stores it.
    The server CANNOT read the content of the message.
    """
    token = None
    if 'Authorization' in request.headers:
        token = request.headers['Authorization'].split(" ")[1]

    if not token:
        return jsonify({"message": "Token is missing!"}), 401

    try:
        data = jwt.decode(token, app.config['SECRET_KEY'], algorithms=["HS256"])
        current_user = data['sub']
    except:
        return jsonify({"message": "Token is invalid!"}), 401

    request_data = request.json
    encrypted_payload = request_data.get('encrypted_payload')

    if not encrypted_payload:
        return jsonify({"message": "Missing encrypted_payload"}), 400
    
    print(f"✅ Received encrypted payload from '{current_user}'. Storing.")
    MESSAGES_DATABASE.append({
        "type": "text",
        "sender": current_user,
        "recipient": "carmela", # Demo Limitation: Recipient hardcoded for prototype flow
        "payload": encrypted_payload
    })
    
    return jsonify({
        "status": "success", 
        "message": "Encrypted message stored."
    })

@app.route("/send_file", methods=['POST'])
def handle_send_file():
    token = None
    if 'Authorization' in request.headers:
        token = request.headers['Authorization'].split(" ")[1]
    if not token:
        return jsonify({"message": "Token is missing!"}), 401
    try:
        data = jwt.decode(token, app.config['SECRET_KEY'], algorithms=["HS256"])
        current_user = data['sub']
    except:
        return jsonify({"message": "Token is invalid!"}), 401

    request_data = request.json
    recipient = request_data.get('recipient')
    wrapped_key = request_data.get('wrapped_key')
    encrypted_file = request_data.get('encrypted_file')

    if not recipient or not wrapped_key or not encrypted_file:
        return jsonify({"message": "Missing recipient, key, or file data"}), 400
    
    MESSAGES_DATABASE.append({
        "type": "file",
        "sender": current_user,
        "recipient": recipient,
        "file_payload": { 
            "wrapped_key": wrapped_key,
            "encrypted_file": encrypted_file
        }
    })
    
    print(f"✅ Received E2EE file from '{current_user}' for '{recipient}'. Storing as message.")
    
    return jsonify({
        "status": "success", 
        "message": "Encrypted file stored."
    })

@app.route("/get_messages", methods=['GET'])
def handle_get_messages():
    token = None
    if 'Authorization' in request.headers:
        token = request.headers['Authorization'].split(" ")[1]

    if not token:
        return jsonify({"message": "Token is missing!"}), 401

    try:
        data = jwt.decode(token, app.config['SECRET_KEY'], algorithms=["HS256"])
        current_user = data['sub']
    except:
        return jsonify({"message": "Token is invalid!"}), 401

    print(f"Token validated. User '{current_user}' is fetching messages.")
    return jsonify({"messages": MESSAGES_DATABASE})

# --- ECDHE Handshake Endpoints (Perfect Forward Secrecy Demo) ---

@app.route("/start-handshake", methods=['GET'])
def start_handshake():
    """
    Starts the ECDHE handshake.
    Generates server's ephemeral keys and sends public key to client.
    """
    print("Received request to start handshake...")
    session_id = str(uuid.uuid4())
    server_eph_private_key = ec.generate_private_key(CURVE)
    EPHEMERAL_KEYS_STORE[session_id] = server_eph_private_key
    
    server_eph_public_key = server_eph_private_key.public_key()
    public_key_pem = server_eph_public_key.public_bytes(
        encoding=serialization.Encoding.PEM,
        format=serialization.PublicFormat.SubjectPublicKeyInfo
    ).decode('utf-8')
    
    print(f"✅ Handshake started. Session: {session_id}. Sending public key.")
    
    return jsonify({
        "session_id": session_id,
        "server_public_key": public_key_pem
    })

@app.route("/complete-handshake", methods=['POST'])
def complete_handshake():
    """
    Completes the ECDHE handshake.
    Receives client's public key, derives the shared secret.
    """
    data = request.json
    session_id = data.get('session_id')
    client_public_key_pem = data.get('client_public_key')
    
    if not session_id or not client_public_key_pem:
        return jsonify({"status": "error", "message": "Missing session_id or client_public_key"}), 400
        
    server_eph_private_key = EPHEMERAL_KEYS_STORE.pop(session_id, None)
    
    if not server_eph_private_key:
        return jsonify({"status": "error", "message": "Invalid or expired session_id"}), 400
        
    print(f"Completing handshake for session: {session_id}")
    
    client_public_key = serialization.load_pem_public_key(
        client_public_key_pem.encode('utf-8')
    )
    
    # Derive shared secret
    shared_secret = server_eph_private_key.exchange(ec.ECDH(), client_public_key)
    
    hkdf = HKDF(
        algorithm=hashes.SHA256(),
        length=32,
        salt=None,
        info=b'session-encryption-key'
    )
    session_key = hkdf.derive(shared_secret)
    
    print("✅ Shared secret derived! Key is ready for this session.")
    
    return jsonify({
        "status": "success",
        "message": "Secure session key established.",
        "derived_key_for_demo": session_key.hex() 
    })

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)