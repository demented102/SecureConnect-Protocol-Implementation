// Automatic FlutterFlow imports
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the green button on the right!
import 'dart:async';
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
import 'package:pointycastle/random/fortuna_random.dart';

// ASN1 (key parsing) import
import 'package:asn1lib/asn1lib.dart' as asn1;

// This helper function is used to get a secure random number generator
crypto.SecureRandom _getSecureRandom() {
  final secureRandom = FortunaRandom();
  final random = Random.secure();
  final seeds = <int>[];
  for (var i = 0; i < 32; i++) {
    seeds.add(random.nextInt(256));
  }
  secureRandom.seed(crypto.KeyParameter(Uint8List.fromList(seeds)));
  return secureRandom;
}

Future<String> encryptMessage(
  String recipientPublicKeyPem,
  String message,
) async {
  // --- 1. Generate a one-time AES key and nonce ---
  final secureRandom = _getSecureRandom();
  final aesKey = secureRandom.nextBytes(32); // 256-bit AES key
  final nonce = secureRandom.nextBytes(12); // 96-bit GCM nonce

  // --- 2. Encrypt the message with AES-GCM ---
  final messageBytes = utf8.encode(message);
  final aesGcm = GCMBlockCipher(AESEngine())
    ..init(true, crypto.ParametersWithIV(crypto.KeyParameter(aesKey), nonce));
  final encryptedMessage = aesGcm.process(messageBytes);

  // --- 3. Parse the Recipient's Public Key ---
  final rsaPublicKey = parsePublicKeyFromPem(recipientPublicKeyPem);

  // --- 4. Encrypt (wrap) the one-time AES key with RSA ---
  // We use OAEP padding, which is the modern standard
  final rsaEngine = OAEPEncoding(RSAEngine())
    ..init(true, PublicKeyParameter<RSAPublicKey>(rsaPublicKey));
  final wrappedAesKey = rsaEngine.process(aesKey);

  // --- 5. Create the final payload ---
  // We bundle everything together in a JSON object, then Base64-encode it
  // so it can be sent as a single string.
  final payload = {
    'key': base64.encode(wrappedAesKey),
    'nonce': base64.encode(nonce),
    'ciphertext': base64.encode(encryptedMessage),
  };

  final jsonPayload = json.encode(payload);
  return base64.encode(utf8.encode(jsonPayload));
}

// --- Helper Function to parse the PEM string for a PUBLIC key ---
RSAPublicKey parsePublicKeyFromPem(String pem) {
  final lines = pem
      .replaceAll('-----BEGIN PUBLIC KEY-----', '')
      .replaceAll('-----END PUBLIC KEY-----', '')
      .replaceAll('\n', '');
  final bytes = base64.decode(lines);
  final asn1Parser = asn1.ASN1Parser(bytes as Uint8List);
  final topLevelSeq = asn1Parser.nextObject() as asn1.ASN1Sequence;

  // The public key is in a "bit string" which is nested
  final bitString = topLevelSeq.elements[1] as asn1.ASN1BitString;
  final publicKeyParser = asn1.ASN1Parser(bitString.contentBytes()!);
  final publicKeySeq = publicKeyParser.nextObject() as asn1.ASN1Sequence;

  final modulus = publicKeySeq.elements[0] as asn1.ASN1Integer;
  final exponent = publicKeySeq.elements[1] as asn1.ASN1Integer;

  return RSAPublicKey(
    modulus.valueAsBigInteger!,
    exponent.valueAsBigInteger!,
  );
}
