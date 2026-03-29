# ISPILO Backend API Specification

## Overview
Complete REST API specification for the ISPILO platform backend (Spring Boot). This document provides detailed endpoints, request/response schemas, authentication, and database design for migrating from Flutter mock services to production backend.

---

## Table of Contents
1. [Authentication & Security](#authentication--security)
2. [Core Entities](#core-entities)
3. [API Endpoints](#api-endpoints)
4. [Database Schema](#database-schema)
5. [File Upload & Media](#file-upload--media)
6. [Real-time Features](#real-time-features)
7. [Error Handling](#error-handling)

---

## Authentication & Security

### JWT Authentication
```http
POST /api/auth/register
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "SecurePass123!",
  "name": "John Doe",
  "countryCode": "254"
}

Response: 201 Created
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refreshToken": "refresh_token_here",
  "user": {
    "id": "user_123",
    "email": "user@example.com",
    "name": "John Doe",
    "avatar": null,
    "isVerified": false
  }
}
```

```http
POST /api/auth/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "SecurePass123!"
}

Response: 200 OK
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refreshToken": "refresh_token_here",
  "user": { ... }
}
```

```http
POST /api/auth/refresh
Content-Type: application/json

{
  "refreshToken": "refresh_token_here"
}

Response: 200 OK
{
  "token": "new_access_token",
  "refreshToken": "new_refresh_token"
}
```

### Authenticated Requests
All authenticated endpoints require:
```http
Authorization: Bearer {token}
```

---

## Core Entities

### User Entity
```json
{
  "id": "user_123",
  "email": "user@example.com",
  "name": "John Doe",
  "avatar": "https://cdn.ispilo.com/avatars/user_123.jpg",
  "phone": "+254712345678",
  "phonePrivacyPublic": false,
  "countryCode": "254",
  "isVerified": true,
  "bio": "Tech enthusiast",
  "location": "Nairobi, Kenya",
  "createdAt": "2025-10-01T10:00:00Z",
  "updatedAt": "2025-10-01T12:30:00Z"
}
```

### Seller Entity
```json
{
  "id": "seller_001",
  "userId": "user_123",
  "name": "NetworkPro Solutions",
  "avatar": "https://cdn.ispilo.com/sellers/seller_001.jpg",
  "isVerified": true,
  "phone": "+254712345678",
  "phonePrivacyPublic": true,
  "countryCode": "254",
  "rating": 4.8,
  "totalSales": 156,
  "responseTime": "2 hours",
  "createdAt": "2025-09-01T10:00:00Z"
}
```

### Conversation Entity
```json
{
  "id": "conv_abc123",
  "participants": [
    {
      "id": "user_123",
      "name": "John Doe",
      "avatar": "https://...",
      "isOnline": true
    },
    {
      "id": "seller_001",
      "name": "NetworkPro Solutions",
      "avatar": "https://...",
      "isOnline": false
    }
  ],
  "lastMessage": {
    "id": "msg_xyz789",
    "senderId": "user_123",
    "text": "Is this still available?",
    "timestamp": "2025-10-01T12:34:56Z",
    "isRead": false
  },
  "unreadCount": 2,
  "createdAt": "2025-10-01T10:00:00Z",
  "updatedAt": "2025-10-01T12:34:56Z"
}
```

### Message Entity
```json
{
  "id": "msg_xyz789",
  "conversationId": "conv_abc123",
  "senderId": "user_123",
  "text": "Hello, is this item available?",
  "mediaUrl": "https://cdn.ispilo.com/media/img123.jpg",
  "mediaType": "image",
  "documentName": "invoice.pdf",
  "durationMs": 15000,
  "isRead": false,
  "timestamp": "2025-10-01T12:34:56Z"
}
```

### Post Entity (Social Feed)
```json
{
  "id": "post_001",
  "userId": "user_123",
  "username": "John Doe",
  "userAvatar": "https://...",
  "isVerified": true,
  "description": "Check out this amazing product!",
  "imageUrl": "https://cdn.ispilo.com/posts/post_001.jpg",
  "likes": 42,
  "comments": 12,
  "shares": 5,
  "isSponsored": false,
  "timestamp": "2025-10-01T10:00:00Z"
}
```

### Comment Entity
```json
{
  "id": "comment_001",
  "postId": "post_001",
  "userId": "user_456",
  "username": "Jane Smith",
  "userAvatar": "https://...",
  "text": "This looks great! 👍",
  "likes": 5,
  "isLiked": false,
  "timestamp": "2025-10-01T11:15:00Z"
}
```

---

## API Endpoints

### 1. User Management

#### Get Current User
```http
GET /api/users/me
Authorization: Bearer {token}

Response: 200 OK
{
  "id": "user_123",
  "email": "user@example.com",
  "name": "John Doe",
  ...
}
```

#### Update Profile
```http
PUT /api/users/me
Authorization: Bearer {token}
Content-Type: application/json

{
  "name": "John Updated",
  "bio": "New bio",
  "location": "Mombasa, Kenya",
  "phonePrivacyPublic": true
}

Response: 200 OK
{ updated user object }
```

#### Update Avatar
```http
POST /api/users/me/avatar
Authorization: Bearer {token}
Content-Type: multipart/form-data

avatar: [binary file data]

Response: 200 OK
{
  "avatarUrl": "https://cdn.ispilo.com/avatars/user_123.jpg"
}
```

---

### 2. Seller Management

#### Get Seller by ID
```http
GET /api/sellers/{sellerId}

Response: 200 OK
{
  "id": "seller_001",
  "name": "NetworkPro Solutions",
  ...
}

404 Not Found - Seller doesn't exist
```

#### Create/Update Seller (Upsert)
```http
POST /api/sellers
Authorization: Bearer {token}
Content-Type: application/json

{
  "id": "seller_001", // optional for create
  "name": "NetworkPro Solutions",
  "avatar": "https://...",
  "phone": "+254712345678",
  "phonePrivacyPublic": true,
  "countryCode": "254"
}

Response: 201 Created / 200 OK
{ created/updated seller object }
```

#### Get Seller Products
```http
GET /api/sellers/{sellerId}/products?page=0&size=20

Response: 200 OK
{
  "content": [ { product }, ... ],
  "totalElements": 45,
  "totalPages": 3,
  "page": 0,
  "size": 20
}
```

---

### 3. Conversation & Messaging

#### Get or Create Conversation
```http
GET /api/conversations?userId={userId}&sellerId={sellerId}
Authorization: Bearer {token}

Response: 200 OK
{
  "id": "conv_abc123",
  "participants": [ ... ],
  ...
}

204 No Content - No existing conversation
```

#### Create Conversation
```http
POST /api/conversations
Authorization: Bearer {token}
Content-Type: application/json

{
  "sellerId": "seller_001",
  "sellerName": "NetworkPro Solutions",
  "sellerAvatar": "https://..."
}

Response: 201 Created
{ conversation object }
```

#### Get User Conversations
```http
GET /api/conversations?userId={userId}&page=0&size=20
Authorization: Bearer {token}

Response: 200 OK
{
  "content": [ { conversation }, ... ],
  "totalElements": 12,
  "totalPages": 1,
  "page": 0
}
```

#### Get Messages in Conversation
```http
GET /api/conversations/{conversationId}/messages?limit=50&before={timestamp}
Authorization: Bearer {token}

Response: 200 OK
[
  {
    "id": "msg_123",
    "conversationId": "conv_abc123",
    "senderId": "user_123",
    "text": "Hello!",
    "timestamp": "2025-10-01T12:00:00Z",
    ...
  },
  ...
]
```

#### Send Message
```http
POST /api/conversations/{conversationId}/messages
Authorization: Bearer {token}
Content-Type: application/json

{
  "text": "Is this still available?",
  "mediaUrl": null,
  "mediaType": null,
  "documentName": null,
  "durationMs": null
}

Response: 201 Created
{ created message object }
```

#### Send Media Message
```http
POST /api/conversations/{conversationId}/messages
Authorization: Bearer {token}
Content-Type: application/json

{
  "text": "Check out this image",
  "mediaUrl": "https://cdn.ispilo.com/media/img123.jpg",
  "mediaType": "image"
}

Response: 201 Created
{ created message object }
```

#### Mark Messages as Read
```http
POST /api/conversations/{conversationId}/read
Authorization: Bearer {token}

Response: 200 OK
{
  "markedAsRead": 3
}
```

---

### 4. Unread Messages

#### Get Unread Count
```http
GET /api/users/me/unread
Authorization: Bearer {token}

Response: 200 OK
{
  "total": 5,
  "conversations": [
    {
      "conversationId": "conv_abc123",
      "count": 3,
      "lastMessage": { ... }
    },
    {
      "conversationId": "conv_def456",
      "count": 2,
      "lastMessage": { ... }
    }
  ]
}
```

---

### 5. Social Feed (Posts)

#### Get Feed Posts
```http
GET /api/posts?page=0&size=20
Authorization: Bearer {token}

Response: 200 OK
{
  "content": [ { post }, ... ],
  "totalElements": 150,
  "totalPages": 8,
  "page": 0
}
```

#### Create Post
```http
POST /api/posts
Authorization: Bearer {token}
Content-Type: application/json

{
  "description": "Check out this amazing product!",
  "imageUrl": "https://cdn.ispilo.com/posts/post_001.jpg"
}

Response: 201 Created
{ created post object }
```

#### Like/Unlike Post
```http
POST /api/posts/{postId}/like
Authorization: Bearer {token}

Response: 200 OK
{
  "isLiked": true,
  "likes": 43
}
```

#### Get Post Comments
```http
GET /api/posts/{postId}/comments?page=0&size=20
Authorization: Bearer {token}

Response: 200 OK
{
  "content": [ { comment }, ... ],
  "totalElements": 25,
  "totalPages": 2,
  "page": 0
}
```

#### Add Comment
```http
POST /api/posts/{postId}/comments
Authorization: Bearer {token}
Content-Type: application/json

{
  "text": "This looks great! 👍"
}

Response: 201 Created
{ created comment object }
```

#### Like Comment
```http
POST /api/comments/{commentId}/like
Authorization: Bearer {token}

Response: 200 OK
{
  "isLiked": true,
  "likes": 6
}
```

---

### 6. Products/Marketplace

#### Search Products
```http
GET /api/products?query={searchTerm}&category={category}&minPrice={min}&maxPrice={max}&page=0&size=20
Authorization: Bearer {token}

Response: 200 OK
{
  "content": [ { product }, ... ],
  "totalElements": 78,
  "totalPages": 4,
  "page": 0
}
```

#### Get Product Details
```http
GET /api/products/{productId}
Authorization: Bearer {token}

Response: 200 OK
{
  "id": "prod_001",
  "name": "Cisco Router",
  "description": "High-performance enterprise router",
  "price": 45000,
  "currency": "KES",
  "sellerId": "seller_001",
  "images": [ "https://..." ],
  "category": "Networking",
  "condition": "New",
  "stock": 15,
  ...
}
```

---

### 7. Media Upload

#### Upload Media (Images, Videos, Documents)
```http
POST /api/media/upload
Authorization: Bearer {token}
Content-Type: multipart/form-data

file: [binary file data]
type: "image" | "video" | "document" | "voice"

Response: 201 Created
{
  "mediaUrl": "https://cdn.ispilo.com/media/abc123.jpg",
  "mediaType": "image",
  "fileName": "photo.jpg",
  "fileSize": 245678,
  "uploadedAt": "2025-10-01T12:34:56Z"
}
```

---

## Database Schema

### Users Table
```sql
CREATE TABLE users (
    id VARCHAR(255) PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    name VARCHAR(255) NOT NULL,
    avatar VARCHAR(500),
    phone VARCHAR(50),
    phone_privacy_public BOOLEAN DEFAULT FALSE,
    country_code VARCHAR(10),
    is_verified BOOLEAN DEFAULT FALSE,
    bio TEXT,
    location VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_email (email)
);
```

### Sellers Table
```sql
CREATE TABLE sellers (
    id VARCHAR(255) PRIMARY KEY,
    user_id VARCHAR(255) NOT NULL,
    name VARCHAR(255) NOT NULL,
    avatar VARCHAR(500),
    is_verified BOOLEAN DEFAULT FALSE,
    phone VARCHAR(50),
    phone_privacy_public BOOLEAN DEFAULT TRUE,
    country_code VARCHAR(10),
    rating DECIMAL(3,2) DEFAULT 0.00,
    total_sales INT DEFAULT 0,
    response_time VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id)
);
```

### Conversations Table
```sql
CREATE TABLE conversations (
    id VARCHAR(255) PRIMARY KEY,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_updated_at (updated_at)
);
```

### Conversation Participants Table
```sql
CREATE TABLE conversation_participants (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    conversation_id VARCHAR(255) NOT NULL,
    user_id VARCHAR(255) NOT NULL,
    unread_count INT DEFAULT 0,
    joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (conversation_id) REFERENCES conversations(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE KEY unique_participant (conversation_id, user_id),
    INDEX idx_user_conversations (user_id, conversation_id)
);
```

### Messages Table
```sql
CREATE TABLE messages (
    id VARCHAR(255) PRIMARY KEY,
    conversation_id VARCHAR(255) NOT NULL,
    sender_id VARCHAR(255) NOT NULL,
    text TEXT,
    media_url VARCHAR(500),
    media_type VARCHAR(50),
    document_name VARCHAR(255),
    duration_ms INT,
    is_read BOOLEAN DEFAULT FALSE,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (conversation_id) REFERENCES conversations(id) ON DELETE CASCADE,
    FOREIGN KEY (sender_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_conversation (conversation_id, timestamp),
    INDEX idx_sender (sender_id)
);
```

### Posts Table
```sql
CREATE TABLE posts (
    id VARCHAR(255) PRIMARY KEY,
    user_id VARCHAR(255) NOT NULL,
    description TEXT,
    image_url VARCHAR(500),
    likes INT DEFAULT 0,
    comments_count INT DEFAULT 0,
    shares INT DEFAULT 0,
    is_sponsored BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_posts (user_id, created_at),
    INDEX idx_created_at (created_at)
);
```

### Comments Table
```sql
CREATE TABLE comments (
    id VARCHAR(255) PRIMARY KEY,
    post_id VARCHAR(255) NOT NULL,
    user_id VARCHAR(255) NOT NULL,
    text TEXT NOT NULL,
    likes INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_post_comments (post_id, created_at)
);
```

### Post Likes Table
```sql
CREATE TABLE post_likes (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    post_id VARCHAR(255) NOT NULL,
    user_id VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE KEY unique_like (post_id, user_id)
);
```

### Comment Likes Table
```sql
CREATE TABLE comment_likes (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    comment_id VARCHAR(255) NOT NULL,
    user_id VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (comment_id) REFERENCES comments(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE KEY unique_like (comment_id, user_id)
);
```

---

## File Upload & Media

### Storage Strategy
- **CDN**: Use AWS S3 / Cloudflare R2 for media storage
- **URL Pattern**: `https://cdn.ispilo.com/{type}/{userId}/{filename}`
- **Types**: avatars, posts, media, documents, voice

### Upload Flow
1. Client requests upload URL: `POST /api/media/upload-url`
2. Server generates pre-signed S3 URL
3. Client uploads directly to S3
4. Client confirms upload: `POST /api/media/confirm`
5. Server validates and stores media reference

### File Validation
- **Images**: Max 5MB, formats: JPG, PNG, WebP
- **Videos**: Max 50MB, formats: MP4, MOV
- **Documents**: Max 10MB, formats: PDF, DOC, DOCX
- **Voice Notes**: Max 5MB, format: M4A, AAC

---

## Real-time Features

### WebSocket Endpoints
```
ws://api.ispilo.com/ws/chat?token={jwt_token}
```

### Events

#### Incoming Message
```json
{
  "type": "NEW_MESSAGE",
  "conversationId": "conv_abc123",
  "message": {
    "id": "msg_xyz",
    "senderId": "user_456",
    "text": "Hello!",
    "timestamp": "2025-10-01T12:34:56Z"
  }
}
```

#### Message Read
```json
{
  "type": "MESSAGE_READ",
  "conversationId": "conv_abc123",
  "messageIds": ["msg_xyz", "msg_abc"]
}
```

#### User Online Status
```json
{
  "type": "USER_ONLINE",
  "userId": "user_456",
  "isOnline": true
}
```

---

## Error Handling

### Standard Error Response
```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid email format",
    "details": {
      "field": "email",
      "value": "invalid-email"
    },
    "timestamp": "2025-10-01T12:34:56Z"
  }
}
```

### HTTP Status Codes
- `200 OK` - Success
- `201 Created` - Resource created
- `204 No Content` - Success with no body
- `400 Bad Request` - Validation error
- `401 Unauthorized` - Authentication required
- `403 Forbidden` - Permission denied
- `404 Not Found` - Resource not found
- `409 Conflict` - Resource conflict
- `429 Too Many Requests` - Rate limit exceeded
- `500 Internal Server Error` - Server error

### Common Error Codes
- `VALIDATION_ERROR` - Input validation failed
- `AUTHENTICATION_REQUIRED` - No valid token
- `PERMISSION_DENIED` - Insufficient permissions
- `RESOURCE_NOT_FOUND` - Requested resource doesn't exist
- `RATE_LIMIT_EXCEEDED` - Too many requests
- `SERVER_ERROR` - Internal server error

---

## Performance Optimization

### Caching Strategy
- **User Profile**: Cache for 5 minutes
- **Seller Info**: Cache for 10 minutes
- **Conversations List**: Cache for 1 minute
- **Unread Counts**: Real-time via WebSocket

### Pagination
- Default page size: 20
- Max page size: 100
- Use cursor-based pagination for large datasets

### Database Indexes
All foreign keys and frequently queried fields should have indexes as shown in schema.

---

## Next Steps

1. Implement Spring Boot controllers for each endpoint
2. Set up MySQL/PostgreSQL database with schema
3. Configure AWS S3 for media storage
4. Implement JWT authentication with Spring Security
5. Add WebSocket support with Spring WebSocket/STOMP
6. Create OpenAPI/Swagger documentation
7. Write integration tests
8. Deploy to staging environment

---

## Flutter Migration Checklist

- [ ] Replace `SellerService.getSellerById()` with API call
- [ ] Replace `SellerService.upsertSellerFromMap()` with API call
- [ ] Replace `ConversationService.getOrCreateConversation()` with API calls
- [ ] Replace `ConversationService.sendMessage()` with API call
- [ ] Implement real-time message listener via WebSocket
- [ ] Add offline queue sync when network restored
- [ ] Implement JWT token management
- [ ] Add retry logic for failed API calls
- [ ] Cache user/seller data locally with expiry
