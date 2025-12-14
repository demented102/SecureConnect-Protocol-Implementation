// Automatic FlutterFlow imports
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'dart:async';
import 'dart:convert'; // FIX 1: Corrected 'dart.convert' typo
import 'dart:typed_data';

import 'package:pointycastle/pointycastle.dart';
import 'package:pointycastle/asymmetric/api.dart';
import 'package:pointycastle/asymmetric/rsa.dart';
import 'package:pointycastle/signers/rsa_signer.dart';
import 'package:pointycastle/digests/sha256.dart'; // FIX 2: Added missing import

import 'package:asn1lib/asn1lib.dart' as asn1;

Future<String> signMessage(
  String privateKeyPem,
  String message,
) async {
  // --- 1. Parse the Private Key ---
  final rsaPrivateKey = parsePrivateKeyFromPem(privateKeyPem);

  // --- 2. Create the Signer ---
  // We tell it to use SHA-256 for hashing and PKCS1 v1.5 for padding
  final signer = RSASigner(SHA256Digest(), '0609608648016503040201');
  signer.init(true, PrivateKeyParameter<RSAPrivateKey>(rsaPrivateKey));

  // --- 3. Create the Signature ---
  final messageBytes = Uint8List.fromList(utf8.encode(message));
  final signature = signer.generateSignature(messageBytes);

  // --- 4. Return as Base64 ---
  // We must convert the signature bytes to a string to send via JSON.
  return base64.encode(signature.bytes);
}

// --- Helper Function to parse the PEM string ---
RSAPrivateKey parsePrivateKeyFromPem(String pem) {
  final lines = pem
      .replaceAll('-----BEGIN RSA PRIVATE KEY-----', '')
      .replaceAll('-----END RSA PRIVATE KEY-----', '')
      .replaceAll('\n', '');
  final bytes = base64.decode(lines);
  final asn1Parser = asn1.ASN1Parser(bytes as Uint8List);
  final topLevelSeq = asn1Parser.nextObject() as asn1.ASN1Sequence;

  final modulus = topLevelSeq.elements[1] as asn1.ASN1Integer;
  final exponent = topLevelSeq.elements[3] as asn1.ASN1Integer;
  final p = topLevelSeq.elements[4] as asn1.ASN1Integer;
  final q = topLevelSeq.elements[5] as asn1.ASN1Integer;

  return RSAPrivateKey(
    modulus.valueAsBigInteger!,
    exponent.valueAsBigInteger!,
    p.valueAsBigInteger,
    q.valueAsBigInteger,
  );
}
// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the green button on the right!
