# Camera & Voice Note Permissions Setup

## Overview
The chat feature now supports:
- 📷 **Camera capture** - Take photos and send as messages
- 🎤 **Voice notes** - Record and send audio messages (AAC/M4A format)
- 📂 **Offline storage** - Messages queued in SharedPreferences when offline
- 🔄 **Auto-retry** - Pending messages sent automatically when back online

## Platform-Specific Configuration

### iOS (Info.plist)

Add these keys to `ios/Runner/Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>We need camera access to let you capture and send photos in chat</string>

<key>NSMicrophoneUsageDescription</key>
<string>We need microphone access to let you record and send voice notes</string>

<key>NSPhotoLibraryAddUsageDescription</key>
<string>We need photo library access to save images you download</string>

<key>NSPhotoLibraryUsageDescription</key>
<string>We need photo library access to view and share images</string>
```

### Android (AndroidManifest.xml)

Add these permissions to `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- Camera & Microphone -->
    <uses-permission android:name="android.permission.CAMERA" />
    <uses-permission android:name="android.permission.RECORD_AUDIO" />
    
    <!-- Storage (for saving media) -->
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"
        android:maxSdkVersion="32" />
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"
        android:maxSdkVersion="32" />
    
    <!-- For Android 13+ (API 33+) -->
    <uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
    <uses-permission android:name="android.permission.READ_MEDIA_AUDIO" />
    
    <!-- Internet for connectivity monitoring -->
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />

    <application ...>
        ...
    </application>
</manifest>
```

## Features Implemented

### 1. Camera Capture
- **Trigger**: Tap camera icon in chat input
- **Permission**: Camera + Microphone (for video capability)
- **Format**: JPEG at 85% quality
- **Storage**: Persisted to app documents directory
- **UI**: Image preview in message bubble

### 2. Voice Notes
- **Trigger**: Long-press send button (mic icon appears when text is empty)
- **Permission**: Microphone
- **Encoding**: **AAC (M4A)** — cross-platform standard
  - Bitrate: 128 kbps
  - Sample rate: 44.1 kHz
- **UI**: 
  - Red recording indicator while recording
  - Duration counter updates every second
  - Stop recording on release
- **Storage**: Saved to app documents as `voice_<timestamp>.m4a`

### 3. Offline Queue & Auto-Retry
- **Offline detection**: Uses `connectivity_plus` package
- **Storage**: Pending messages stored in `SharedPreferences` as JSON
- **Key format**: `pending_messages_<conversationId>`
- **Retry trigger**: Automatic when connectivity restored
- **Status indicators**:
  - ⏱️ `pending` - waiting for connection
  - ❌ `failed` - send error
  - ✅ `sent` - delivered successfully

### 4. Message Types Supported
```dart
{
  'type': 'text',      // Plain text message
  'type': 'image',     // Photo from camera
  'type': 'audio',     // Voice note (M4A)
  'type': 'document',  // File attachments (future)
}
```

## Backend Integration Notes

### Updated `ConversationService.sendMessage`
Now accepts:
```dart
Future<Map<String, dynamic>> sendMessage({
  required String conversationId,
  required String senderId,
  String? text,             // Optional for media messages
  String? mediaPath,        // Local file path
  String? mediaType,        // 'image', 'audio', 'document', etc.
  String? documentName,     // For file attachments
  int? durationMs,          // For audio messages
})
```

### Spring Boot Integration
When you connect your backend:

1. **Upload media files** in `_sendAttachmentMessage`:
   - Read file from `mediaPath`
   - POST to `/api/messages/upload` with multipart/form-data
   - Receive server URL for the media

2. **Replace mock `ConversationService`**:
   - Use `http` or `dio` to call REST endpoints
   - Store server-returned media URLs instead of local paths

3. **Message schema** should include:
   ```json
   {
     "id": "msg_123",
     "conversationId": "conv_456",
     "senderId": "user_789",
     "text": "Hello",
     "mediaUrl": "https://cdn.example.com/voice_123.m4a",
     "mediaType": "audio",
     "durationMs": 15000,
     "timestamp": "2025-10-01T12:00:00Z"
   }
   ```

## Testing Checklist

### iOS
- [ ] Add Info.plist keys
- [ ] Run on physical device (simulator camera won't work)
- [ ] Test camera permission prompt
- [ ] Test microphone permission prompt
- [ ] Record and play voice note
- [ ] Test offline → online queue flush

### Android
- [ ] Add AndroidManifest permissions
- [ ] Run on physical device or emulator with camera
- [ ] Test runtime permissions (Android 6+)
- [ ] Test scoped storage (Android 11+)
- [ ] Record and send voice note
- [ ] Test offline queue persistence

## Dependencies Added
```yaml
record: ^5.0.5              # Audio recording (AAC encoding)
file_picker: ^8.0.6         # Future: document attachments
just_audio: ^0.9.40         # Future: voice note playback
connectivity_plus: ^6.1.4   # Network status monitoring (already present)
```

## UI/UX Flow

### Camera
1. User taps 📷 icon
2. Permission check → request if needed
3. Native camera opens
4. Photo captured → saved to app storage
5. Message sent with image preview

### Voice Note
1. User long-presses 🎤 button
2. Permission check → request if needed
3. Recording starts (red indicator + timer)
4. User releases → recording stops
5. Audio file saved and sent
6. Message shows 🎤 icon + duration

### Offline
1. User sends message while offline
2. Message shows ⏱️ pending status
3. Stored in SharedPreferences
4. When online → auto-retry all pending
5. Status updates to ✅ sent

## Security Notes
- Media files stored in **app-sandboxed documents directory**
- Not accessible by other apps
- Cleared when app uninstalled
- For production: upload to CDN and delete local copies after successful upload

---

**Status**: ✅ Implementation complete  
**Next steps**: Add platform manifest entries → test on device → integrate backend upload
