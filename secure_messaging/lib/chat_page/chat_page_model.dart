import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/upload_data.dart';
import 'dart:ui';
import '/custom_code/actions/index.dart' as actions;
import '/index.dart';
import 'chat_page_widget.dart' show ChatPageWidget;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class ChatPageModel extends FlutterFlowModel<ChatPageWidget> {
  ///  Local state fields for this page.

  List<dynamic> decryptedMessages = [];
  void addToDecryptedMessages(dynamic item) => decryptedMessages.add(item);
  void removeFromDecryptedMessages(dynamic item) =>
      decryptedMessages.remove(item);
  void removeAtIndexFromDecryptedMessages(int index) =>
      decryptedMessages.removeAt(index);
  void insertAtIndexInDecryptedMessages(int index, dynamic item) =>
      decryptedMessages.insert(index, item);
  void updateDecryptedMessagesAtIndex(int index, Function(dynamic) updateFn) =>
      decryptedMessages[index] = updateFn(decryptedMessages[index]);

  String text = 'text';

  String file = 'file';

  ///  State fields for stateful widgets in this page.

  // Stores action output result for [Backend Call - API (getMessagesAPI)] action in chatPage widget.
  ApiCallResponse? apiMessagesResult2;
  // Stores action output result for [Custom Action - processMessageList] action in chatPage widget.
  List<dynamic>? finalMessageList;
  // Stores action output result for [Custom Action - decryptAndSaveFile] action in recipientChat widget.
  bool? decryptSuccess;
  bool isDataUploading_uploadedFile = false;
  FFUploadedFile uploadedLocalFile_uploadedFile =
      FFUploadedFile(bytes: Uint8List.fromList([]), originalFilename: '');

  // Stores action output result for [Backend Call - API (getPublicKeyAPI)] action in IconButton widget.
  ApiCallResponse? getPublicKeyResult1;
  // Stores action output result for [Custom Action - encryptAndUploadFile] action in IconButton widget.
  bool? uploadSuccess;
  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode;
  TextEditingController? textController;
  String? Function(BuildContext, String?)? textControllerValidator;
  // Stores action output result for [Backend Call - API (getPublicKeyAPI)] action in IconButton widget.
  ApiCallResponse? getPublicKeyResult;
  // Stores action output result for [Custom Action - encryptMessage] action in IconButton widget.
  String? encryptedPayload;
  // Stores action output result for [Backend Call - API (sendMessageAPI)] action in IconButton widget.
  ApiCallResponse? apiResult20u;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    textFieldFocusNode?.dispose();
    textController?.dispose();
  }

  /// Action blocks.
  Future rerunOnPageLoadActions(BuildContext context) async {
    ApiCallResponse? apiMessagesResult2;
    List<dynamic>? finalMessageListCopy;

    apiMessagesResult2 = await GetMessagesAPICall.call(
      authToken: FFAppState().jwtToken,
    );

    if ((apiMessagesResult2?.succeeded ?? true)) {
      finalMessageListCopy = await actions.processMessageList(
        getJsonField(
          (apiMessagesResult2?.jsonBody ?? ''),
          r'''$.messages''',
          true,
        ),
        FFAppState().privateKey,
        FFAppState().username,
      );
      decryptedMessages = finalMessageListCopy!.toList().cast<dynamic>();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Couldnt get messages',
            style: TextStyle(
              color: FlutterFlowTheme.of(context).primaryText,
            ),
          ),
          duration: Duration(milliseconds: 4000),
          backgroundColor: FlutterFlowTheme.of(context).secondary,
        ),
      );
    }
  }
}
