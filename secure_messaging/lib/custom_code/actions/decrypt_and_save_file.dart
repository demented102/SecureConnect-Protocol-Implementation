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
import 'package:asn1lib/asn1lib.dart' as asn1;
// --- END OF IMPORTS ---
import 'package:mime_type/mime_type.dart';
// --- NEW IMPORTS FOR FILE SAVING ---
import 'package:file_saver/file_saver.dart';
// --- END OF NEW IMPORTS ---

// --- Helper: Parse Private Key ---
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
// --- End of Helper ---

Future<bool> decryptAndSaveFile(
  String? privateKeyPem,
  dynamic filePayload, // This is the JSON object
) async {
  if (privateKeyPem == null || filePayload == null) {
    print('Error: Missing private key or file payload.');
    return false;
  }

  try {
    // --- 2. Extract data from the payload ---
// filePayload is a JSON string, so we must decode it first
    final originalMessage = json.decode(filePayload);

// Now we can access its contents
    final payload = originalMessage['file_payload'];
    final String keyPayload = payload['wrapped_key'];
    final String encryptedFileB64 = payload['encrypted_file'];

    // --- 3. Un-bundle the nonce and the key ---
    // We bundled them as 'nonce:key'
    final parts = keyPayload.split(':');
    final nonce = base64.decode(parts[0]);
    final wrappedAesKey = base64.decode(parts[1]);

    // --- 4. Decode the file ---
    final encryptedFileBytes = base64.decode(encryptedFileB64);

    // --- 5. Decrypt the AES key with RSA ---
    final rsaPrivateKey = _parsePrivateKeyFromPem(privateKeyPem);
    final rsaEngine = OAEPEncoding(RSAEngine())
      ..init(false, crypto.PrivateKeyParameter<RSAPrivateKey>(rsaPrivateKey));
    final aesKey = rsaEngine.process(wrappedAesKey);

    // --- 6. Decrypt the file with AES-GCM ---
    final aesGcm = GCMBlockCipher(AESEngine())
      ..init(
          false, crypto.ParametersWithIV(crypto.KeyParameter(aesKey), nonce));
    final decryptedFileBytes = aesGcm.process(encryptedFileBytes);

    // --- 7. Save the file to the device ---
    // We'll give it a generic name for now.
    String fileName = 'decrypted_file_${DateTime.now().millisecondsSinceEpoch}';
    // You could also try to get the original filename if you send it

    String? resultPath = await FileSaver.instance.saveAs(
        name: fileName,
        bytes: decryptedFileBytes,
        ext: 'jpg',
        mimeType: MimeType.jpeg); // You can change 'jpg' or make it dynamic

    print('File saved to: $resultPath');
    return true;
  } catch (e) {
    print('Error during file decryption/saving: $e');
    return false;
  }
}
// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the green button on the right!
