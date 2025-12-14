// Automatic FlutterFlow imports
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

// --- ADD ALL THESE IMPORTS ---
import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';

// PointyCastle imports
import 'package:pointycastle/pointycastle.dart';
import 'package:pointycastle/api.dart' as crypto;
import 'package:pointycastle/asymmetric/api.dart';
import 'package:pointycastle/asymmetric/rsa.dart';
import 'package:pointycastle/block/aes.dart';
import 'package:pointycastle/block/modes/gcm.dart';
import 'package:pointycastle/asymmetric/oaep.dart';
import 'package:pointycastle/digests/sha256.dart';

// ASN1 (key parsing) import
import 'package:asn1lib/asn1lib.dart' as asn1;
// --- END OF IMPORTS ---

Future<String?> decryptMessage(
  String? privateKeyPem,
  String? encryptedPayload,
) async {
  // This is the new action.
  // We need to define the helper function *inside* it.

  // --- Helper Function ---
  RSAPrivateKey parsePrivateKeyFromPem(String pem) {
    final lines = pem
        .replaceAll('-----BEGIN RSA PRIVATE KEY-----', '')
        .replaceAll('-----END RSA PRIVATE KEY-----', '')
        .replaceAll('\n', '');
    final bytes = base64.decode(lines);
    final asn1Parser = asn1.ASN1Parser(bytes as Uint8List);
    final topLevelSeq = asn1Parser.nextObject() as asn1.ASN1Sequence;

    final modulus = topLevelSeq.elements[1] as asn1.ASN1Integer;
    final privateExponent = topLevelSeq.elements[3] as asn1.ASN1Integer;
    final p = topLevelSeq.elements[4] as asn1.ASN1Integer;
    final q = topLevelSeq.elements[5] as asn1.ASN1Integer;

    return RSAPrivateKey(
      modulus.valueAsBigInteger!,
      privateExponent.valueAsBigInteger!,
      p.valueAsBigInteger,
      q.valueAsBigInteger,
    );
  }
  // --- End of Helper Function ---

  if (privateKeyPem == null || encryptedPayload == null) {
    return '[Invalid Data]';
  }

  try {
    // --- 1. Decode the outer payload ---
    final decodedJsonPayload = utf8.decode(base64.decode(encryptedPayload));
    final payload = json.decode(decodedJsonPayload);

    final wrappedAesKey = base64.decode(payload['key']);
    final nonce = base64.decode(payload['nonce']);
    final encryptedMessage = base64.decode(payload['ciphertext']);

    // --- 2. Parse the User's Private Key ---
    final rsaPrivateKey = parsePrivateKeyFromPem(privateKeyPem);

    // --- 3. Decrypt (unwrap) the AES key with RSA ---
    final rsaEngine = OAEPEncoding(RSAEngine())
      ..init(false, PrivateKeyParameter<RSAPrivateKey>(rsaPrivateKey));
    final aesKey = rsaEngine.process(wrappedAesKey);

    // --- 4. Decrypt the message with AES-GCM ---
    final aesGcm = GCMBlockCipher(AESEngine())
      ..init(
          false, crypto.ParametersWithIV(crypto.KeyParameter(aesKey), nonce));
    final decryptedMessageBytes = aesGcm.process(encryptedMessage);

    // --- 5. Return the plaintext message ---
    return utf8.decode(decryptedMessageBytes);
  } catch (e) {
    print('DECRYPTION FAILED: $e');
    // If decryption fails (e.g., wrong key), return an error message.
    return '[Unable to decrypt message]';
  }
}
