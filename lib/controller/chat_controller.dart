import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vchat/controller/user_controller.dart';
import '../models/message.dart';
import '../models/user_model.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path_lib;
import '../services/notification_service.dart';

class ChatController extends GetxController {
  final SupabaseClient _supabase = Supabase.instance.client;
  final RxList<UserModel> users = <UserModel>[].obs;
  final TextEditingController messageController = TextEditingController();
  final RxBool isSending = false.obs;
  final RxString receiverName = 'Loading...'.obs;
  final RxString senderId = ''.obs;
  final RxString receiverId = ''.obs;
  final ImagePicker _imagePicker = ImagePicker();
  late final NotificationService _notificationService;

  @override
  void onInit() {
    super.onInit();
    _notificationService = NotificationService(); // No parameters needed
    _initialize();
  }
  Future<void> _initialize() async {
    await _verifyStorageBucket();
    await fetchUsers();
    final currentUser = _supabase.auth.currentUser;
    if (currentUser != null) {
      senderId.value = currentUser.id;
      await _notificationService.init();

      // Delay to ensure OneSignal is ready
      await Future.delayed(const Duration(seconds: 2));

      // Store player ID
      await _notificationService.storePlayerId(currentUser.id);
    }
  }

  Future<void> _verifyStorageBucket() async {
    try {
      await _supabase.storage.from('chat-images').list();
      debugPrint('Storage bucket verified');
    } catch (e) {
      debugPrint('Storage bucket error: $e');
      _showSafeSnackbar('Chat storage not ready. Please contact support.');
    }
  }

  Future<void> fetchUsers() async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null || currentUserId.isEmpty) return;

      final response = await _supabase
          .from('users')
          .select()
          .neq('id', currentUserId);

      users.value = (response as List)
          .map((user) => UserModel.fromJson(user))
          .toList();
    } catch (e) {
      _showSafeSnackbar('Failed to load users');
    }
  }

  Future<void> sendMessage(String content, String type, {String? imageUrl}) async {
    try {
      if (content.isEmpty && type == 'text' && imageUrl == null) return;
      if (senderId.value.isEmpty || receiverId.value.isEmpty) {
        _showSafeSnackbar('Please select a recipient first');
        return;
      }

      isSending.value = true;
      await _supabase.from('messages').insert({
        'sender_id': senderId.value,
        'receiver_id': receiverId.value,
        'type': type,
        'content': content,
        'photo_url': imageUrl,
        'created_at': DateTime.now().toIso8601String(),
      });

      // Get user controller instance
      final userController = Get.find<UserController>();

      await _notificationService.sendChatNotification(
        receiverId: receiverId.value,
        receiverName: receiverName.value,
        senderName: userController.currentUser.value.name,
        message: content,
        imageUrl: imageUrl,
      );

      messageController.clear();
    } catch (e) {
      debugPrint('Error sending message: $e');
      _showSafeSnackbar('Failed to send message');
    } finally {
      isSending.value = false;
    }
  }
  Future<void> onMessageSend() async {
    final text = messageController.text.trim();
    if (text.isNotEmpty) {
      await sendMessage(text, 'text');
    }
  }

  Future<void> pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 70,
      );

      if (image == null) return;

      isSending.value = true;

      final fileExtension = path_lib.extension(image.path);
      final fileName = '${DateTime.now().millisecondsSinceEpoch}$fileExtension';
      final file = File(image.path);

      debugPrint('Uploading image: $fileName');

      await _supabase.storage
          .from('chat-images')
          .upload(fileName, file);

      final imageUrl = _supabase.storage
          .from('chat-images')
          .getPublicUrl(fileName);

      debugPrint('Image uploaded successfully. URL: $imageUrl');

      await sendMessage('Image', 'image', imageUrl: imageUrl);
    } catch (e) {
      debugPrint('Image upload error: $e');
      _showSafeSnackbar('Failed to upload image. Please try again.');
    } finally {
      isSending.value = false;
    }
  }

  Stream<List<Message>> getMessages() {
    if (senderId.value.isEmpty || receiverId.value.isEmpty) {
      return Stream.value([]);
    }

    return _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: true)
        .map((events) => events
        .map((e) => Message.fromJson(e))
        .where((m) =>
    (m.senderId == senderId.value && m.receiverId == receiverId.value) ||
        (m.senderId == receiverId.value && m.receiverId == senderId.value))
        .toList());
  }

  Future<void> fetchReceiverName() async {
    try {
      if (receiverId.value.isEmpty) {
        receiverName.value = 'Unknown';
        return;
      }

      final response = await _supabase
          .from('users')
          .select('name')
          .eq('id', receiverId.value)
          .single();

      receiverName.value = response['name'] ?? 'Unknown';
    } catch (e) {
      receiverName.value = 'Unknown';
    }
  }

  void _showSafeSnackbar(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.isSnackbarOpen) return;

      Get.showSnackbar(
        GetSnackBar(
          message: message,
          duration: const Duration(seconds: 3),
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          margin: const EdgeInsets.all(10),
          borderRadius: 8,
        ),
      );
    });
  }
}