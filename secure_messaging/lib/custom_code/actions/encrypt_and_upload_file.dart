// Automatic FlutterFlow imports
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

// --- ALL CRYPTO IMPORTS ---
import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';
import 'package:pointycastle/api.dart' as crypto;
import 'package:pointycastle/asymmetric/api.dart';
import 'package:pointycastle/asymmetric/rsa.dart';
import 'package:pointycastle/block/aes.dart';
import 'package:pointycastle/block/modes/gcm.dart';
import 'package:pointycastle/asymmetric/oaep.dart';
import 'package:pointycastle/digests/sha256.dart';
import 'package:pointycastle/random/fortuna_random.dart';
import 'package:asn1lib/asn1lib.dart' as asn1;
// --- END OF IMPORTS ---

// Import your custom API call
import '/backend/api_requests/api_calls.dart';

// --- Helper: Secure Random Generator ---
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

// --- Helper: Parse Public Key ---
RSAPublicKey _parsePublicKeyFromPem(String pem) {
  final lines = pem
      .replaceAll('-----BEGIN PUBLIC KEY-----', '')
      .replaceAll('-----END PUBLIC KEY-----', '')
      .replaceAll('\n', '');
  final bytes = base64.decode(lines);
  final asn1Parser = asn1.ASN1Parser(bytes as Uint8List);
  final topLevelSeq = asn1Parser.nextObject() as asn1.ASN1Sequence;
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

// --- MAIN ACTION ---
Future<bool> encryptAndUploadFile(
  String authToken,
  String recipientName,
  String recipientPublicKeyPem,
  FFUploadedFile? file,
) async {
  if (file == null || file.bytes == null) {
    print('File is null or empty.');
    return false;
  }

  try {
    // --- 1. Generate a one-time AES key and nonce ---
    final secureRandom = _getSecureRandom();
    final aesKey = secureRandom.nextBytes(32); // 256-bit AES key
    final nonce = secureRandom.nextBytes(12); // 96-bit GCM nonce

    // --- 2. Encrypt the FILE with AES-GCM ---
    final fileBytes = file.bytes!;
    final aesGcm = GCMBlockCipher(AESEngine())
      ..init(true, crypto.ParametersWithIV(crypto.KeyParameter(aesKey), nonce));
    final encryptedFileBytes = aesGcm.process(fileBytes);

    // --- 3. Parse the Recipient's Public Key ---
    final rsaPublicKey = _parsePublicKeyFromPem(recipientPublicKeyPem);

    // --- 4. Encrypt the AES key with RSA-OAEP ---
    final rsaEngine = OAEPEncoding(RSAEngine())
      ..init(true, crypto.PublicKeyParameter<RSAPublicKey>(rsaPublicKey));
    final wrappedAesKey = rsaEngine.process(aesKey);

    // --- 5. Convert bytes to Base64 strings for JSON ---
    String wrappedKeyB64 = base64.encode(wrappedAesKey);
    String encryptedFileB64 = base64.encode(encryptedFileBytes);
    // We also need to send the nonce! We'll add it to the wrapped_key.
    // This is a simple way to bundle them.
    String nonceB64 = base64.encode(nonce);
    String finalKeyPayload = '$nonceB64:$wrappedKeyB64';

    // --- 6. Call the API to Upload ---
    final apiResult = await SendFileAPICall.call(
      authToken: authToken,
      recipient: recipientName,
      wrappedKey: finalKeyPayload,
      encryptedFile: encryptedFileB64,
    );

    if (apiResult.succeeded) {
      print('Encrypted file upload successful!');
      return true;
    } else {
      print('API call failed: ${apiResult.statusCode}');
      return false;
    }
  } catch (e) {
    print('Error during file encryption/upload: $e');
    return false;
  }
}
// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the green button on the right!
