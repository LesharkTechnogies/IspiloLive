import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../core/services/conversation_service.dart';

class ChatPage extends StatefulWidget {
  final Map<String, dynamic> conversation;
  /// Optional initial message list provided by the caller (useful for local
  /// mock data so the page can display messages without calling the service).
  final List<Map<String, dynamic>>? initialMessages;

  const ChatPage({
    super.key,
    required this.conversation,
    this.initialMessages,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Current user id (placeholder). Replace with real auth id in future.
  final String _currentUserId = 'current_user';

  // Messages in local UI shape: {id, text, isSentByMe, timestamp (DateTime), isRead}
  final List<Map<String, dynamic>> _messages = [];

  late final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  bool _isOnline = true;

  final ImagePicker _imagePicker = ImagePicker();
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  Duration _recordDuration = Duration.zero;
  Timer? _recordTimer;

  SharedPreferences? _prefs;

  static const String _pendingStorageKeyPrefix = 'pending_messages_';

  String get _conversationId {
    final idVal = widget.conversation['id'];
    if (idVal is String) return idVal;
    if (idVal is int) return idVal.toString();
    return 'conv_${widget.conversation['sellerId'] ?? ''}';
  }

  @override
  void initState() {
    super.initState();
    _connectivity = Connectivity();
    _messageController.addListener(_handleComposerChanged);
    _loadConversationMessages();
    _initializeAsyncResources();
  }

  Future<void> _loadConversationMessages() async {
    final convId = _conversationId;

    // If the caller provided initialMessages (from our mock), use them and
    // avoid calling the ConversationService. Otherwise fetch from the service.
    final msgs = widget.initialMessages;
    if (msgs != null) {
      setState(() {
        _messages.clear();
        for (final m in msgs) {
          final tsRaw = m['timestamp'] as String?;
          DateTime ts;
          try {
            ts = tsRaw != null ? DateTime.parse(tsRaw).toLocal() : DateTime.now();
          } catch (_) {
            ts = DateTime.now();
          }

          final type = (m['type'] as String?) ?? 'text';

          // senderId can be numeric (0 means current user) or a string id.
          final sender = m['senderId'];
          final bool isSentByMe = (sender == 0) || (sender == _currentUserId) || (sender is String && sender == _currentUserId);

          _messages.add({
            'id': m['id'],
            'type': type,
            'text': m['text'] ?? '',
            'mediaPath': m['mediaPath'],
            'documentName': m['documentName'],
            'durationMs': m['durationMs'],
            'isSentByMe': isSentByMe,
            'timestamp': ts,
            'isRead': m['isRead'] as bool? ?? true,
            'status': 'sent',
          });
        }
      });

      // If using mock messages, we don't need to call the service to mark read
      return;
    }

    // Fetch messages from the service
    final fetched = await ConversationService.instance.fetchMessages(convId);

    setState(() {
      _messages.clear();
      for (final m in fetched.reversed) {
        final senderId = m['senderId'] as String? ?? '';
        final tsRaw = m['timestamp'] as String?;
        DateTime ts;
        try {
          ts = tsRaw != null ? DateTime.parse(tsRaw).toLocal() : DateTime.now();
        } catch (_) {
          ts = DateTime.now();
        }

        final type = (m['mediaType'] as String?) ??
            ((m['text'] as String?)?.isNotEmpty == true ? 'text' : 'unknown');

        _messages.add({
          'id': m['id'],
          'type': type,
          'text': m['text'] ?? '',
          'mediaPath': m['mediaPath'],
          'documentName': m['documentName'],
          'durationMs': m['durationMs'],
          'isSentByMe': senderId == _currentUserId,
          'timestamp': ts,
          'isRead': true,
          'status': 'sent',
        });
      }
    });

    // Mark conversation read to clear unread counters
    await ConversationService.instance
        .markConversationRead(convId, _currentUserId);
  }

  void _handleComposerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _initializeAsyncResources() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _setupConnectivityMonitoring();
    await _restorePendingMessages();
  }

  Future<void> _setupConnectivityMonitoring() async {
    final status = await _connectivity.checkConnectivity();
    final online = status.any((result) => result != ConnectivityResult.none);
    if (mounted) {
      setState(() {
        _isOnline = online;
      });
    }

    await _connectivitySub?.cancel();
    _connectivitySub = _connectivity.onConnectivityChanged.listen((statusList) {
      final nowOnline =
          statusList.any((status) => status != ConnectivityResult.none);
      final wasOffline = !_isOnline && nowOnline;
      if (mounted) {
        setState(() {
          _isOnline = nowOnline;
        });
      }
      if (wasOffline) {
        _flushPendingMessages();
      }
    });
  }

  Future<void> _restorePendingMessages() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    _prefs = prefs;

    final key = '$_pendingStorageKeyPrefix$_conversationId';
    final pendingList = prefs.getStringList(key) ?? [];

    if (pendingList.isEmpty) return;

    for (final encoded in pendingList) {
      try {
        final decoded = jsonDecode(encoded) as Map<String, dynamic>;
        final timestamp = DateTime.parse(decoded['timestamp'] as String);

        setState(() {
          _messages.add({
            'id': decoded['id'],
            'type': decoded['type'],
            'text': decoded['text'],
            'mediaPath': decoded['mediaPath'],
            'documentName': decoded['documentName'],
            'durationMs': decoded['durationMs'],
            'isSentByMe': true,
            'timestamp': timestamp,
            'isRead': false,
            'status': 'pending',
          });
        });
      } catch (_) {
        // Skip invalid entries
      }
    }
  }

  Future<void> _flushPendingMessages() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    _prefs = prefs;

    final key = '$_pendingStorageKeyPrefix$_conversationId';
    final pendingList = prefs.getStringList(key) ?? [];

    if (pendingList.isEmpty) return;

    final List<String> failedMessages = [];

    for (final encoded in pendingList) {
      try {
        final decoded = jsonDecode(encoded) as Map<String, dynamic>;
        final type = decoded['type'] as String?;

        final sent = await ConversationService.instance.sendMessage(
          conversationId: _conversationId,
          senderId: _currentUserId,
          text: decoded['text'] as String?,
          mediaPath: decoded['mediaPath'] as String?,
          mediaType: type,
          documentName: decoded['documentName'] as String?,
          durationMs: decoded['durationMs'] as int?,
        );

        // Update UI to show as sent
        if (mounted) {
          setState(() {
            final idx = _messages.indexWhere((m) => m['id'] == decoded['id']);
            if (idx != -1) {
              _messages[idx] = {
                'id': sent['id'],
                'type': sent['mediaType'] ?? type ?? 'text',
                'text': sent['text'],
                'mediaPath': sent['mediaPath'],
                'documentName': sent['documentName'],
                'durationMs': sent['durationMs'],
                'isSentByMe': true,
                'timestamp': DateTime.parse(sent['timestamp']).toLocal(),
                'isRead': false,
                'status': 'sent',
              };
            }
          });
        }
      } catch (_) {
        failedMessages.add(encoded);
      }
    }

    // Update storage: keep only failed messages
    await prefs.setStringList(key, failedMessages);
  }

  @override
  void dispose() {
    _messageController.removeListener(_handleComposerChanged);
    _messageController.dispose();
    _scrollController.dispose();
    _connectivitySub?.cancel();
    _recordTimer?.cancel();
    if (_isRecording) {
      _audioRecorder.stop();
    }
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final convId = _conversationId;
    final text = _messageController.text.trim();

    // Optimistic UI append
    final localMsg = {
      'id': 'local_${DateTime.now().millisecondsSinceEpoch}',
      'type': 'text',
      'text': text,
      'mediaPath': null,
      'documentName': null,
      'durationMs': null,
      'isSentByMe': true,
      'timestamp': DateTime.now(),
      'isRead': false,
      'status': _isOnline ? 'sending' : 'pending',
    };

    setState(() {
      _messages.add(localMsg);
    });

    _messageController.clear();
    HapticFeedback.lightImpact();

    // Send to service
    if (!_isOnline) {
      await _queuePendingMessage(localMsg);
      return;
    }

    ConversationService.instance
        .sendMessage(
      conversationId: convId,
      senderId: _currentUserId,
      text: text,
    )
        .then((sent) {
      // replace optimistic message id with real id and keep isRead false
      setState(() {
        final idx = _messages.indexWhere((m) => m['id'] == localMsg['id']);
        if (idx != -1) {
          _messages[idx] = {
            'id': sent['id'],
            'type': sent['mediaType'] ?? 'text',
            'text': sent['text'] ?? '',
            'mediaPath': sent['mediaPath'],
            'documentName': sent['documentName'],
            'durationMs': sent['durationMs'],
            'isSentByMe': true,
            'timestamp': DateTime.parse(sent['timestamp']).toLocal(),
            'isRead': false,
            'status': 'sent',
          };
        }
      });
    }).catchError((_) {
      setState(() {
        final idx = _messages.indexWhere((m) => m['id'] == localMsg['id']);
        if (idx != -1) {
          _messages[idx]['status'] = 'failed';
        }
      });
    });

    // Scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 100,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else {
      return '${difference.inDays}d';
    }
  }

  Widget _buildMessageContent(
      Map<String, dynamic> message, bool isSentByMe, ColorScheme colorScheme) {
    final type = (message['type'] as String?) ?? 'text';
    switch (type) {
      case 'image':
        final path = message['mediaPath'] as String?;
        if (path != null && File(path).existsSync()) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.file(
              File(path),
              width: 60.w,
              fit: BoxFit.cover,
            ),
          );
        }
        return _buildAttachmentPlaceholder(
          icon: Icons.broken_image,
          label: 'Image unavailable',
          isSentByMe: isSentByMe,
          colorScheme: colorScheme,
        );
      case 'audio':
        final durationMs = message['durationMs'] as int?;
        final durationLabel = durationMs != null
            ? Duration(milliseconds: durationMs).toString().split('.').first
            : 'Voice note';
        return _buildAttachmentPlaceholder(
          icon: Icons.mic,
          label: durationLabel,
          isSentByMe: isSentByMe,
          colorScheme: colorScheme,
        );
      case 'document':
        final name = message['documentName'] as String? ?? 'Document';
        return _buildAttachmentPlaceholder(
          icon: Icons.insert_drive_file,
          label: name,
          isSentByMe: isSentByMe,
          colorScheme: colorScheme,
        );
      case 'text':
      default:
        final text = (message['text'] as String?) ?? '';
        return Text(
          text.isEmpty ? '[Unsupported message]' : text,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: isSentByMe ? Colors.white : colorScheme.onSurface,
          ),
        );
    }
  }

  Widget _buildAttachmentPlaceholder({
    required IconData icon,
    required String label,
    required bool isSentByMe,
    required ColorScheme colorScheme,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 20,
          color: isSentByMe ? Colors.white : colorScheme.onSurface,
        ),
        SizedBox(width: 2.w),
        Flexible(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: isSentByMe ? Colors.white : colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }

  Future<bool> _ensurePermissions(List<Permission> permissions,
      {String? rationale}) async {
    bool allGranted = true;
    for (final permission in permissions) {
      var status = await permission.status;
      if (!status.isGranted) {
        status = await permission.request();
      }
      if (!status.isGranted) {
        allGranted = false;
        break;
      }
    }

    if (!allGranted && rationale != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(rationale)),
      );
    }

    return allGranted;
  }

  Future<String> _persistLocalFile(File source, {String? preferredName}) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final ext = source.path.split('.').last;
    final sanitizedExt = ext.isEmpty ? 'bin' : ext;
    final fileName = preferredName ??
        'chat_${DateTime.now().millisecondsSinceEpoch}.$sanitizedExt';
    final targetPath = '${docsDir.path}/$fileName';
    final savedFile = await source.copy(targetPath);
    return savedFile.path;
  }

  Future<void> _handleCameraTap() async {
    final granted = await _ensurePermissions(
      [Permission.camera, Permission.microphone],
      rationale: 'Camera and microphone access are required to capture photos.',
    );
    if (!granted) return;

    final capture = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
      preferredCameraDevice: CameraDevice.rear,
    );
    if (capture == null) return;

    final savedPath = await _persistLocalFile(File(capture.path));
    await _sendAttachmentMessage(
      type: 'image',
      mediaPath: savedPath,
      text: '[Photo]',
    );
  }

  Future<void> _sendAttachmentMessage({
    required String type,
    String? text,
    String? mediaPath,
    String? documentName,
    int? durationMs,
  }) async {
    final convId = _conversationId;
    final localId = 'local_${DateTime.now().millisecondsSinceEpoch}';

    final localMessage = {
      'id': localId,
      'type': type,
      'text': text,
      'mediaPath': mediaPath,
      'documentName': documentName,
      'durationMs': durationMs,
      'isSentByMe': true,
      'timestamp': DateTime.now(),
      'isRead': false,
      'status': _isOnline ? 'sending' : 'pending',
    };

    setState(() {
      _messages.add(localMessage);
    });

    if (!_isOnline) {
      await _queuePendingMessage(localMessage);
      return;
    }

    try {
      final sent = await ConversationService.instance.sendMessage(
        conversationId: convId,
        senderId: _currentUserId,
        text: text,
        mediaPath: mediaPath,
        mediaType: type,
        documentName: documentName,
        durationMs: durationMs,
      );

      if (!mounted) return;

      setState(() {
        final idx = _messages.indexWhere((m) => m['id'] == localId);
        if (idx != -1) {
          _messages[idx] = {
            'id': sent['id'],
            'type': sent['mediaType'] ?? type,
            'text': sent['text'],
            'mediaPath': sent['mediaPath'] ?? mediaPath,
            'documentName': sent['documentName'] ?? documentName,
            'durationMs': sent['durationMs'] ?? durationMs,
            'isSentByMe': true,
            'timestamp': DateTime.parse(sent['timestamp']).toLocal(),
            'isRead': false,
            'status': 'sent',
          };
        }
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        final idx = _messages.indexWhere((m) => m['id'] == localId);
        if (idx != -1) {
          _messages[idx]['status'] = 'failed';
        }
      });
    }
  }

  Future<void> _queuePendingMessage(Map<String, dynamic> message) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    _prefs = prefs;

    final key = '$_pendingStorageKeyPrefix$_conversationId';
    final existing = prefs.getStringList(key) ?? [];
    final encoded = jsonEncode({
      'id': message['id'],
      'type': message['type'],
      'text': message['text'],
      'mediaPath': message['mediaPath'],
      'documentName': message['documentName'],
      'durationMs': message['durationMs'],
      'timestamp': (message['timestamp'] as DateTime).toIso8601String(),
    });
    existing.add(encoded);
    await prefs.setStringList(key, existing);
  }

  Future<void> _handleVoiceRecordStart() async {
    final granted = await _ensurePermissions(
      [Permission.microphone],
      rationale: 'Microphone access is required to record voice notes.',
    );
    if (!granted) return;

    if (_isRecording) return;

    final docsDir = await getApplicationDocumentsDirectory();
    final fileName = 'voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
    final path = '${docsDir.path}/$fileName';

    await _audioRecorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      ),
      path: path,
    );

    setState(() {
      _isRecording = true;
      _recordDuration = Duration.zero;
    });

    _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _recordDuration += const Duration(seconds: 1);
        });
      }
    });
  }

  Future<void> _handleVoiceRecordStop() async {
    if (!_isRecording) return;

    _recordTimer?.cancel();
    _recordTimer = null;

    final path = await _audioRecorder.stop();
    final duration = _recordDuration;

    setState(() {
      _isRecording = false;
      _recordDuration = Duration.zero;
    });

    if (path != null && File(path).existsSync()) {
      await _sendAttachmentMessage(
        type: 'audio',
        mediaPath: path,
        text: '[Voice note]',
        durationMs: duration.inMilliseconds,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1877F2), // Facebook blue
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
        ),
        title: Row(
          children: [
            Stack(
              children: [
                ClipOval(
                  child: CustomImageWidget(
                    imageUrl: widget.conversation['avatar'],
                    width: 10.w,
                    height: 10.w,
                    fit: BoxFit.cover,
                  ),
                ),
                if (widget.conversation['isOnline'])
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 2.5.w,
                      height: 2.5.w,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        widget.conversation['name'],
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      if (widget.conversation['isVerified']) ...[
                        SizedBox(width: 1.w),
                        const Icon(
                          Icons.verified,
                          color: Colors.white,
                          size: 16,
                        ),
                      ],
                    ],
                  ),
                  if (widget.conversation['isOnline'])
                    Text(
                      'Online',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.videocam,
              color: Colors.white,
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.call,
              color: Colors.white,
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.more_vert,
              color: Colors.white,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                image: DecorationImage(
                  image: const NetworkImage(
                      'https://images.unsplash.com/photo-1579546929518-9e396f3cc809?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80'),
                  fit: BoxFit.cover,
                  opacity: 0.1,
                ),
              ),
              child: ListView.builder(
                controller: _scrollController,
                padding: EdgeInsets.all(3.w),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  final isSentByMe = message['isSentByMe'];

                  return Container(
                    margin: EdgeInsets.only(bottom: 1.h),
                    child: Row(
                      mainAxisAlignment: isSentByMe
                          ? MainAxisAlignment.end
                          : MainAxisAlignment.start,
                      children: [
                        if (!isSentByMe) ...[
                          ClipOval(
                            child: CustomImageWidget(
                              imageUrl: widget.conversation['avatar'],
                              width: 8.w,
                              height: 8.w,
                              fit: BoxFit.cover,
                            ),
                          ),
                          SizedBox(width: 2.w),
                        ],
                        Flexible(
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 4.w,
                              vertical: 1.5.h,
                            ),
                            decoration: BoxDecoration(
                              color: isSentByMe
                                  ? const Color(0xFF1877F2) // Facebook blue
                                  : Colors.grey[200],
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildMessageContent(
                                    message, isSentByMe, colorScheme),
                                SizedBox(height: 0.5.h),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _formatTimestamp(message['timestamp']),
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        color: isSentByMe
                                            ? Colors.white
                                                .withValues(alpha: 0.7)
                                            : colorScheme.onSurface
                                                .withValues(alpha: 0.6),
                                      ),
                                    ),
                                    if (message['status'] == 'pending') ...[
                                      SizedBox(width: 1.w),
                                      Icon(
                                        Icons.schedule,
                                        size: 14,
                                        color: isSentByMe
                                            ? Colors.white
                                                .withValues(alpha: 0.7)
                                            : colorScheme.onSurface
                                                .withValues(alpha: 0.6),
                                      ),
                                    ] else if (message['status'] ==
                                        'failed') ...[
                                      SizedBox(width: 1.w),
                                      Icon(
                                        Icons.error,
                                        size: 14,
                                        color: Colors.orangeAccent,
                                      ),
                                    ],
                                    if (isSentByMe) ...[
                                      SizedBox(width: 1.w),
                                      Icon(
                                        message['isRead']
                                            ? Icons.done_all
                                            : Icons.done,
                                        size: 14,
                                        color: message['isRead']
                                            ? const Color(0xFF1877F2)
                                            : Colors.white
                                                .withValues(alpha: 0.7),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (isSentByMe) ...[
                          SizedBox(width: 2.w),
                          ClipOval(
                            child: Container(
                              width: 8.w,
                              height: 8.w,
                              color: Colors.grey[300],
                              child:
                                  const Icon(Icons.person, color: Colors.grey),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
          ),

          // Message Input
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: colorScheme.outline.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  // Camera Icon
                  IconButton(
                    onPressed: _handleCameraTap,
                    icon: Icon(
                      Icons.camera_alt,
                      color: const Color(0xFF1877F2),
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 1.w),
                  // Voice Note Icon (when not recording)
                  if (!_isRecording)
                    GestureDetector(
                      onLongPress: _handleVoiceRecordStart,
                      child: Container(
                        padding: EdgeInsets.all(2.w),
                        child: Icon(
                          Icons.mic,
                          color: const Color(0xFF1877F2),
                          size: 24,
                        ),
                      ),
                    ),
                  // Recording indicator (when recording)
                  if (_isRecording)
                    GestureDetector(
                      onTap: _handleVoiceRecordStop,
                      child: Container(
                        padding: EdgeInsets.all(2.w),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.stop,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  // Recording duration display
                  if (_isRecording) ...[
                    SizedBox(width: 2.w),
                    Text(
                      '${_recordDuration.inMinutes}:${(_recordDuration.inSeconds % 60).toString().padLeft(2, '0')}',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  SizedBox(width: 1.w),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle: GoogleFonts.inter(
                            fontSize: 14,
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 4.w,
                            vertical: 1.5.h,
                          ),
                        ),
                        style: GoogleFonts.inter(fontSize: 14),
                        maxLines: null,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  SizedBox(width: 2.w),
                  // Send button (only shows when there's text)
                  if (_messageController.text.trim().isNotEmpty)
                    GestureDetector(
                      onTap: _sendMessage,
                      child: Container(
                        padding: EdgeInsets.all(2.w),
                        decoration: const BoxDecoration(
                          color: Color(0xFF1877F2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.send,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
