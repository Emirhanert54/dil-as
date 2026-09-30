import 'package:cloud_firestore/cloud_firestore.dart';

class PushRequestService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> sendHomeworkNotificationToClass({
    required String className,
    required String homeworkTitle,
  }) async {
    await _firestore.collection('pushRequests').add({
      'type': 'homework',
      'targetType': 'class',
      'className': className.trim(),
      'title': 'Yeni ödevin var! 📚',
      'body': '$homeworkTitle ödevi eklendi. Hadi başlayalım!',
      'rewardOnOpen': false,
      'createdAt': FieldValue.serverTimestamp(),
      'sent': false,
    });
  }

  static Future<void> sendMessageNotificationToChild({
    required String childId,
    required String messageTitle,
    required String messageBody,
    bool rewardOnOpen = false,
    String? rewardId,
  }) async {
    final doc = _firestore.collection('pushRequests').doc();

    await doc.set({
      'type': 'message',
      'targetType': 'child',
      'childId': childId.trim(),
      'title': messageTitle.trim().isEmpty
          ? 'Yeni mesajın var! 💬'
          : messageTitle.trim(),
      'body': messageBody.trim().isEmpty
          ? 'Mesajını okumak için dokun.'
          : messageBody.trim(),
      'rewardOnOpen': rewardOnOpen,
      if (rewardOnOpen && rewardId != null && rewardId.trim().isNotEmpty)
        'rewardId': rewardId.trim(),
      'createdAt': FieldValue.serverTimestamp(),
      'sent': false,
    });
  }

  static Future<void> sendAdminBroadcast({
    required String title,
    required String body,
  }) async {
    await _firestore.collection('pushRequests').add({
      'type': 'admin',
      'targetType': 'all',
      'title': title.trim(),
      'body': body.trim(),
      'rewardOnOpen': false,
      'createdAt': FieldValue.serverTimestamp(),
      'sent': false,
    });
  }
}

