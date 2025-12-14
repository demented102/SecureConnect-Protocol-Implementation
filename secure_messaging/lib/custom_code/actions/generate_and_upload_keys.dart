// Automatic FlutterFlow imports
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'dart:async';
import 'dart:math';
// --- CORRECT ---
import 'dart:typed_data';
import 'package:pointycastle/random/fortuna_random.dart';
import 'package:pointycastle/src/registry/registry.dart';
import 'package:pointycastle/asymmetric/api.dart';
import 'package:pointycastle/asymmetric/rsa.dart';
import 'package:pointycastle/key_generators/rsa_key_generator.dart';
import 'package:pointycastle/pointycastle.dart';
import 'package:asn1lib/asn1lib.dart' as asn1;
import 'dart:convert';
import 'package:crypto/crypto.dart';

// Import your custom API call
import '/backend/api_requests/api_calls.dart';
// Import your App State

/// This is our main action
Future<String?> generateAndUploadKeys(String authToken) async {
  // --- 1. Generate RSA Key Pair ---
  final secureRandom = FortunaRandom();
  final random = Random.secure();
  final seeds = <int>[];
  for (var i = 0; i < 32; i++) {
    seeds.add(random.nextInt(256));
  }
  secureRandom.seed(KeyParameter(Uint8List.fromList(seeds)));

  // --- END OF FIX ---

  final keyParams = RSAKeyGeneratorParameters(BigInt.from(65537), 2048, 12);
  final paramsWithRandom = ParametersWithRandom(keyParams, secureRandom);
  final keyGenerator = RSAKeyGenerator()..init(paramsWithRandom);

  final keyPair = keyGenerator.generateKeyPair();
  final rsaPublicKey = keyPair.publicKey as RSAPublicKey;
  final rsaPrivateKey = keyPair.privateKey as RSAPrivateKey;

  // --- 2. Format the Public Key as PEM ---
  // This is what the server expects
  final pubKeyPem = encodePublicKeyToPem(rsaPublicKey);

  // --- 3. Format the Private Key as PEM ---
  // This is what we will save on the device
  final privKeyPem = encodePrivateKeyToPem(rsaPrivateKey);

  // --- 4. Call the API to Upload the Public Key ---
  try {
    final apiResult = await UploadPublicKeyAPICall.call(
      authToken: authToken, // Pass the token
      publicKeyPem: pubKeyPem, // Pass the new public key
    );

    if (apiResult.succeeded) {
      // It worked!
      print('Public key uploaded successfully.');
      // Return the PRIVATE key so we can save it
      return privKeyPem;
    } else {
      // The API call failed
      print('Failed to upload public key: ${apiResult.statusCode}');
      return null;
    }
  } catch (e) {
    print('Error in generateAndUploadKeys: $e');
    return null;
  }
}

// --- Helper Functions to create PEM formats ---

String encodePublicKeyToPem(RSAPublicKey key) {
  final algorithm = asn1.ASN1Sequence()
    ..add(asn1.ASN1ObjectIdentifier.fromComponentString(
        '1.2.840.113549.1.1.1')) // rsaEncryption
    ..add(asn1.ASN1Null());

  final publicKeySequence = asn1.ASN1Sequence()
    ..add(asn1.ASN1Integer(key.modulus!))
    ..add(asn1.ASN1Integer(key.exponent!));

  final bitString = asn1.ASN1BitString(publicKeySequence.encodedBytes);

  final topLevelSequence = asn1.ASN1Sequence()
    ..add(algorithm)
    ..add(bitString);

  final dataBase64 = base64.encode(topLevelSequence.encodedBytes);
  return '-----BEGIN PUBLIC KEY-----\n$dataBase64\n-----END PUBLIC KEY-----';
}

String encodePrivateKeyToPem(RSAPrivateKey key) {
  final privateKeySequence = asn1.ASN1Sequence()
    ..add(asn1.ASN1Integer(BigInt.zero)) // version
    ..add(asn1.ASN1Integer(key.modulus!))
    ..add(asn1.ASN1Integer(key.exponent!))
    ..add(asn1.ASN1Integer(key.privateExponent!))
    ..add(asn1.ASN1Integer(key.p!))
    ..add(asn1.ASN1Integer(key.q!))
    ..add(asn1.ASN1Integer(key.privateExponent! % (key.p! - BigInt.one))) // dP
    ..add(asn1.ASN1Integer(key.privateExponent! % (key.q! - BigInt.one))) // dQ
    ..add(asn1.ASN1Integer(key.q!.modInverse(key.p!))); // qInv

  final dataBase64 = base64.encode(privateKeySequence.encodedBytes);
  return '-----BEGIN RSA PRIVATE KEY-----\n$dataBase64\n-----END RSA PRIVATE KEY-----';
}
// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the green button on the right!
