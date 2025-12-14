// Automatic FlutterFlow imports
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

// --- ALL THE IMPORTS (Keep these) ---
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
import 'package:asn1lib/asn1lib.dart' as asn1;
// --- END OF IMPORTS ---

// --- Helper Functions (Keep these) ---
RSAPrivateKey _parsePrivateKeyFromPem(String pem) {
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

String? _decryptPayload(String privateKeyPem, String encryptedPayload) {
  try {
    final decodedJsonPayload = utf8.decode(base64.decode(encryptedPayload));
    final payload = json.decode(decodedJsonPayload);
    final wrappedAesKey = base64.decode(payload['key']);
    final nonce = base64.decode(payload['nonce']);
    final encryptedMessage = base64.decode(payload['ciphertext']);
    final rsaPrivateKey = _parsePrivateKeyFromPem(privateKeyPem);
    final rsaEngine = OAEPEncoding(RSAEngine())
      ..init(false, crypto.PrivateKeyParameter<RSAPrivateKey>(rsaPrivateKey));
    final aesKey = rsaEngine.process(wrappedAesKey);
    final aesGcm = GCMBlockCipher(AESEngine())
      ..init(
          false, crypto.ParametersWithIV(crypto.KeyParameter(aesKey), nonce));
    final decryptedMessageBytes = aesGcm.process(encryptedMessage);
    return utf8.decode(decryptedMessageBytes);
  } catch (e) {
    print('DECRYPTION FAILED: $e');
    return '[Unable to decrypt message]';
  }
}

// --- MAIN ACTION (NEW LOGIC) ---
Future<List<dynamic>> processMessageList(
  List<dynamic>? messages, // The list of JSON objects
  String? privateKey,
  String? currentUser,
) async {
  List<Map<String, String>> processedList = []; // Renamed for clarity

  if (messages == null) {
    return [];
  }

  for (var message in messages) {
    // message is a Map<String, dynamic>
    final sender = message['sender'];
    final type = message['type']; // Get the new 'type' field
    String content = '';
    String messageType = 'text'; // Default to text

    if (type == 'text') {
      // --- THIS IS A TEXT MESSAGE ---
      messageType = 'text';
      final payload = message['payload'];

      if (sender == currentUser) {
        content = '[Message Sent (Encrypted)]';
      } else {
        if (privateKey != null && payload != null) {
          content =
              _decryptPayload(privateKey, payload) ?? '[Decryption Failed]';
        } else {
          content = '[Error: Missing key or payload]';
        }
      }
    } else if (type == 'file') {
      // --- THIS IS A FILE MESSAGE ---
      messageType = 'file';

      if (sender == currentUser) {
        content = 'You sent a file';
      } else {
        content = 'You received a file';
        // We'll add the download/decrypt logic here later
      }
    }

    // Add a *new* JSON object to our list
    processedList.add({
      'sender': sender,
      'type': messageType,
      'content': content,
      // We also pass the *original* payload for the download button
      'original_payload': json.encode(message),
    });
  }

  return processedList;
}
