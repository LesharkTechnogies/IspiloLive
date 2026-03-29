# API Integration Guide

Purpose

This document is the canonical API contract for frontend (Flutter/Dart) integration. It lists endpoint names, expected request/response shapes, authentication, common headers, pagination, error handling and concrete Dart examples to make calls and handle errors in a consistent way.

Audience

- Frontend engineers (Flutter/Dart)
- Mobile/SDK integrators
- QA engineers writing API tests
- Backend engineers maintaining compatibility

Base URL and Versioning

- Base URL: https://ispilo-backend-32613e7af752.herokuapp.com
- Versioning: All production endpoints are versioned under `/v1/` (e.g. `/v1/products/:id`). Breaking changes require incrementing major version (v2).

Authentication

- Scheme: Bearer token in `Authorization` header.
- Example: `Authorization: Bearer <access_token>`
- Token refresh: Use POST `/v1/auth/refresh` with `refreshToken` to obtain a new access token.

Common Headers

- `Content-Type: application/json`
- `Accept: application/json`
- `X-App-ID: <app-id>` (optional, for telemetry)
- `X-Device-ID: <device-id>` (optional)
# API Integration Guide

This document is the canonical API contract for frontend (Flutter/Dart) integration with the Ispilo backend. It lists every commonly used endpoint, HTTP method, request and response shapes, authentication rules, and concrete Dart examples for integration. Use this as the single source of truth for the mobile/web clients.

Base URL & version

- Base URL: https://ispilo-backend-32613e7af752.herokuapp.com
- API prefix: /v1 (e.g. https://.../v1/products)

Global conventions

- Authentication: Bearer tokens in `Authorization` header. Example: `Authorization: Bearer <accessToken>`.
- Content type: `application/json` for request/response JSON payloads.
- Dates: ISO 8601 in UTC (e.g. `2026-03-11T12:00:00Z`).
- IDs: UUID strings or stable string IDs depending on endpoint; the frontend should treat IDs as opaque strings.
- Money: `price` fields are numeric (decimal); `currency` is a 3-letter ISO currency code (e.g., `USD`).
- Error envelope: all non-2xx responses use the error envelope shown below.

Standard response envelopes

- Success (single resource):

```json
{ "data": { ... resource ... } }
```

- Success (collection / paginated):

```json
{
  "data": [ ... ],
  "meta": {
    "page": 1,
    "size": 20,
    "total": 123
  }
}
```

- Error response (standardized):

```json
{
  "error": {
    "code": "INVALID_ARGUMENT",
    "message": "Human readable message",
    "details": { /* optional additional info */ }
  }
}
```

Authentication & Authorization

- Use `POST /v1/auth/login` to get `accessToken` and `refreshToken`.
- Access tokens are short-lived; call `POST /v1/auth/refresh` with `refreshToken` to obtain a new `accessToken`.
- Protect endpoints requiring authenticated user with 401 for missing/invalid token, and 403 for valid token but insufficient role.

Errors and status codes

- 200 OK — Successful GET/PUT/PATCH operations returning a body.
- 201 Created — Resource successfully created.
- 204 No Content — Successful operation with no body (e.g. DELETE).
- 400 Bad Request — Validation or malformed request.
- 401 Unauthorized — Missing or invalid token.
- 403 Forbidden — Authenticated but not allowed.
- 404 Not Found — Resource missing.
- 409 Conflict — Duplicate or conflicting resource state.
- 429 Too Many Requests — Rate limited.
- 500 Internal Server Error — Unexpected server failure.

Endpoints (detailed)

Authentication

- POST /v1/auth/login
  - Purpose: Authenticate a user and return tokens.
  - Auth: none
  - Body:

```json
{ "email": "user@example.com", "password": "hunter2" }
```

  - Success (200):

```json
{
  "data": {
    "accessToken": "ey...",
    "refreshToken": "rf...",
    "user": { "id": "...", "email": "...", "name": "..." }
  }
}
```

- POST /v1/auth/refresh
  - Purpose: Exchange refresh token for a new access token.
  - Body: `{ "refreshToken": "..." }`
  - Success (200): returns new tokens.

Users

- GET /v1/users/me
  - Purpose: Retrieve current authenticated user profile.
  - Auth: Bearer
  - Success (200): `data` contains user object.

- PUT /v1/users/me
  - Purpose: Update current user profile (partial updates supported).
  - Body example:

```json
{
  "name": "Alice Doe",
  "phone": "+254712345678",
  "company": "Leshark Technologies"
}
```

  - Success (200): returns updated user object.

Products

- GET /v1/products
  - Purpose: List products with filtering, sorting and pagination.
  - Query params: `page` (1-based), `size`, `query`, `category`, `minPrice`, `maxPrice`, `sort` (e.g. `price:asc`).
  - Success (200): returns `data` array and `meta` page info.

- GET /v1/products/:id
  - Purpose: Get full product details.
  - Success (200): `data` is product object:

```json
{
  "id": "prod_abc",
  "title": "UniFi Switch 24-Port",
  "description": "Managed Gigabit switch...",
  "price": 379.00,
  "currency": "USD",
  "condition": "New",
  "rating": 4.6,
  "reviewCount": 45,
  "images": ["https://.../img1.jpg"],
  "specifications": { "Model": "US-24-250W" },
  "shipping": { "info": "Ships in 1-2 days", "cost": "Free" },
  "seller": { "id": "seller_003", "name": "NetworkPro" },
  "createdAt": "2026-03-01T12:00:00Z"
}
```

- POST /v1/products
  - Purpose: Create a product (seller role required).
  - Auth: Bearer (seller)
  - Body (example):

```json
{
  "title": "New Device",
  "description": "...",
  "price": 1250.00,
  "currency": "USD",
  "condition": "New",
  "images": ["https://.../1.jpg"],
  "specifications": { "Model": "X" }
}
```

  - Success (201): returns created product.

Favorites

- POST /v1/favorites
  - Body: `{ "productId": "prod_abc" }`
  - Auth: Bearer
  - Success (201): favorite created.

- DELETE /v1/favorites/:productId
  - Auth: Bearer
  - Success (204): removed.

Sellers

- GET /v1/sellers/:id
  - Purpose: Retrieve seller profile.
  - Success (200): seller object includes `phonePrivacyPublic`, `rating`, `totalSales`.

- GET /v1/sellers/:id/products
  - Query param: `size` (limit number)
  - Success (200): paged products belonging to seller.

Conversations & Messages

- POST /v1/conversations
  - Purpose: Create or return an existing conversation between buyer and seller.
  - Body:

```json
{ "sellerId": "seller_003", "buyerId": "user_111", "initialMessage": "Hi, is this still available?" }
```

  - Success (200): conversation object with `id`, `participants`, `lastMessageAt`.

- POST /v1/messages
  - Purpose: Send a message within a conversation.
  - Body example:

```json
{
  "conversationId": "conv_123",
  "senderId": "user_111",
  "type": "text",
  "payload": { "text": "Yes, available" }
}
```

  - Success (201): returns message object.

Orders

- POST /v1/orders
  - Purpose: Create an order from buyer.
  - Auth: Bearer
  - Body example:

```json
{
  "buyerId": "user_111",
  "items": [ { "productId": "prod_abc", "quantity": 1, "priceSnapshot": 379.00 } ],
  "shippingAddress": { "line1": "...", "city": "..." },
  "paymentMethod": "card"
}
```

  - Success (201): order object with status `pending`.

Notifications

- GET /v1/notifications
  - Query param: `unread=true`
  - Success (200): returns list and `meta.unreadCount`.

Health & misc

- GET /v1/health
  - Purpose: quick health check (no auth).
  - Success (200): `{ "status": "ok" }`.

Expected outcome and formatting rules (frontend contract)

- Always inspect HTTP status code first. Use the `data` and `error` envelopes described above.
- For paginated endpoints: expect `data` array and `meta` object. If `meta.total` is absent treat it as unknown.
- For numeric fields (price, rating) assume the backend returns numbers — don't parse them as strings.
- For optional fields, check presence before dereferencing. Example: `product['shipping']` may be null or missing.

Dart/Flutter integration examples (extended)

1) GET product using `http` package (with base URL constant)

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;

const baseUrl = 'https://ispilo-backend-32613e7af752.herokuapp.com';

Future<Map<String, dynamic>> fetchProduct(String id, String token) async {
  final url = Uri.parse('\$baseUrl/v1/products/\$id');
  final resp = await http.get(url, headers: {
    'Authorization': 'Bearer '\$token,
    'Accept': 'application/json'
  });
  if (resp.statusCode == 200) {
    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    return body['data'] as Map<String, dynamic>;
  }
  final err = jsonDecode(resp.body) as Map<String, dynamic>?;
  throw Exception(err?['error']?['message'] ?? 'Failed (\$resp.statusCode)');
}
```

2) POST favorite using Dio (authenticated)

```dart
import 'package:dio/dio.dart';

final dio = Dio(BaseOptions(baseUrl: baseUrl));

Future<void> addFavorite(String productId, String token) async {
  final resp = await dio.post('/v1/favorites',
    data: { 'productId': productId },
    options: Options(headers: { 'Authorization': 'Bearer '\$token })
  );
  if (resp.statusCode != 201) throw Exception('Failed to add favorite');
}
```

Route argument safety

- When passing data to routes use simple maps or IDs (recommended to pass only `productId` and fetch fresh detail in the detail screen).
- Example: `Navigator.pushNamed(context, '/product-detail', arguments: { 'productId': productId });`
- In destination:

```dart
final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
final productId = args?['productId'] as String?;
if (productId == null) {
  // handle missing id (show error or pop)
}
```

Common pitfalls

- Do not `as String` cast an identifier if a variable named `String` is present in scope. That causes `The name 'String' isn't a type` errors. Always use typed variables and avoid shadowing built-in types.
- Validate all remote data before use (types and null checks).

Next steps & tooling

- I can export an OpenAPI (Swagger) fragment from these contracts for Postman or API clients.
- I can add a small `postman_collection.json` or `openapi.yaml` in the repo if you want automated mocks.

If you'd like, tell me which endpoints to expand first into OpenAPI examples (e.g., Products, Conversations), and I will generate them.

Service catalog (high level)

- Auth & App Security: registration, login, refresh, MFA, API-key management, role & permission checks.
- Users: profile read/update, settings, preferences, avatars.
- Products: CRUD for sellers, search, related products, views.
- Sellers: seller profiles, ratings, seller-specific product lists.
- Conversations & Messages: REST endpoints for conversation lifecycle + WebSocket realtime messaging.
- Posts: timeline posts, comments, likes, and realtime post events via WebSocket.
- Favorites & Watchlist: mark, unmark products.
- Orders & Payments: create orders, payment status callbacks.
- Education hub: courses, videos, enrollments, progress tracking, course content streaming links.
- Notifications: read/unread, push subscription registration.

API Key and registration -> login flow (recommended patterns)

There are two common keys/tokens used by clients:

1) API key (x-api-key): optional, used for app identification or server-to-server. Short-lived or rotateable. Not a user identity token.
2) User tokens (accessToken / refreshToken): issued after user authentication, used for authenticated operations and WebSocket auth.

Recommended flows

- Mobile-first / user flows (recommended):
  1. User registers: POST /v1/auth/register (body: name, email, password, optional device info). Server returns 201 with `data.user` and may return `data.apiKey` if the app requires a per-install key. Prefer to return API key only when needed.
  2. User logs in: POST /v1/auth/login -> returns `{ data: { accessToken, refreshToken, user } }`.
  3. Client stores `accessToken` in secure storage and `refreshToken` in secure storage (platform secure storage / Keychain / Keystore).
  4. For all protected REST requests: set header `Authorization: Bearer <accessToken>`.
  5. If the backend requires an application-level API key, include it as `x-api-key: <apiKey>` for non-user endpoints (e.g., public telemetry, anonymous product reads) or as a second header alongside Authorization.

- Machine-to-machine / server flows:
  - Use long-lived API keys with scoped permissions and IP or claim restrictions. Keep them off mobile apps when possible.

Registration example (body) — `POST /v1/auth/register`

```json
{ "name": "Alice", "email": "alice@example.com", "password": "..." }
```

Registration success (201):

```json
{ "data": { "user": { "id": "user_1", "email": "alice@example.com" }, "apiKey": "app_abc123" } }
```

Login example and token usage

```http
POST /v1/auth/login
Content-Type: application/json

{ "email": "alice@example.com", "password": "..." }
```

Response (200):

```json
{ "data": { "accessToken": "eyJ...", "refreshToken": "rf_...", "user": { "id": "user_1" } } }
```

Use in requests:

Headers:

- `Authorization: Bearer <accessToken>`
- `x-api-key: <apiKey>` (optional; only if backend requires app identification)

Token refresh

- When the `accessToken` expires (401 on request), call `POST /v1/auth/refresh` with `{ refreshToken }` to get a new access token. Retry the failed request once after refresh.

App security & authentication details

- Passwords: server must store passwords hashed with a strong adaptive algorithm (bcrypt/argon2). Frontend should not store raw passwords — use secure storage for tokens only.
- MFA: optional endpoints `POST /v1/auth/mfa/start` and `POST /v1/auth/mfa/verify` for phone/email/Authenticator apps.
- Roles & permissions: endpoints return `user.roles` and `user.permissions`. The mobile app should hide actions it isn't permitted to show, but enforce checks server-side always.
- Session invalidation: `POST /v1/auth/logout` invalidates refresh token; `POST /v1/auth/revoke` can revoke other sessions or API keys.

WebSocket realtime (Conversations & Posts)

- Base WebSocket URL: `wss://ispilo-backend-32613e7af752.herokuapp.com/ws` (path may be `/ws/v1` depending on deployment). Use TLS (wss) only.
- Authentication: prefer passing `accessToken` in the WebSocket `Authorization` header via the initial HTTP upgrade request (if client supports), or include as a `token` query parameter for clients that require it: `wss://.../ws?token=<accessToken>`.
- Subprotocol: `ispilo.v1` (optional) for version negotiation.

Connection example (JS-like):

```js
const ws = new WebSocket('wss://ispilo-backend-32613e7af752.herokuapp.com/ws?token=' + accessToken, 'ispilo.v1');
```

WebSocket message contract (JSON frames)

- All frames are JSON with `type` and `payload` keys.

Common message types for conversations:

1. Client -> Server: `subscribe_conversations` — subscribe to conversation stream

```json
{ "type": "subscribe_conversations", "payload": { "userId": "user_1" } }
```

2. Client -> Server: `send_message`

```json
{ "type": "send_message", "payload": { "conversationId": "conv_1", "text": "Hello" } }
```

3. Server -> Client: `message_new`

```json
{ "type": "message_new", "payload": { "message": { "id": "m_1", "conversationId": "conv_1", "senderId": "user_2", "text": "Hi", "createdAt": "..." } } }
```

4. Typing indicators, read receipts

```json
{ "type": "typing", "payload": { "conversationId": "conv_1", "userId": "user_2", "isTyping": true } }
```

Posts realtime contract (for feed updates)

- Subscribe to timeline or seller feed: `subscribe_posts` with filters.
- New post event: `post_new` with `payload.post` containing minimal fields (id, authorId, title, excerpt, createdAt, image).

Reconnection & resync

- When reconnecting, client should call `sync_state` with last-known cursors (e.g., lastMessageAt or lastPostId). Server returns missed events.

Education hub (endpoints)

- GET /v1/education/courses?page=&size=
  - Returns list of courses with `meta` pagination.

- GET /v1/education/courses/:id
  - Returns course details, modules, and metadata.

- POST /v1/education/enrollments
  - Body: `{ "courseId": "...", "userId": "..." }` — enroll a user.

- GET /v1/education/enrollments?userId=
  - Return list of user enrollments and progress.

- GET /v1/education/videos/:id/stream
  - Returns signed streaming URL or redirect to CDN. Use short-lived signed URLs for video playback.

Education realtime (optional)

- WebSocket channels can emit `course_update` events for live webinars or Q&A; same ws connection as conversations can be multiplexed with event types.

Posts, comments and moderation

- POST /v1/posts
  - Body: `{ "authorId": "...", "title": "...", "body": "...", "visibility": "public|private|followers" }`

- GET /v1/posts/:id
  - Returns post and comments metadata.

- POST /v1/posts/:id/comments
  - Add a comment.

- Moderation endpoints (admin only): `/v1/moderation/posts/:id/ban`, `/v1/moderation/comments/:id/remove`.

User profile & settings

- GET /v1/users/:id/settings
  - Returns preferences (privacy, notifications, language).

- PUT /v1/users/:id/settings
  - Update settings.

- PUT /v1/users/:id/avatar
  - Upload avatar (multipart/form-data or pre-signed URL flow). Return CDN URL.

Products & Sellers (expanded)

- Product search advanced filters: tags, sellerRatingMin, inStock=true, location radius filters (lat/lng + radius).
- Product view tracking: `POST /v1/products/:id/views` increments view count — allows backend to rate-limit rapid repeated views.
- Seller verification: `/v1/sellers/:id/verify` (admin) and `/v1/sellers/:id/verifications` (read public verification status).

Encryption, transport and signing recommendations

- Transport: require TLS 1.2+ (prefer 1.3) for all endpoints (HTTPS / WSS). Pin certificates at app-level only when you control both ends and can rotate pins safely.
- Token signing: use JWTs signed with RS256 (asymmetric) so the frontend/edge can verify tokens if needed; keep signing private key on server.
- Sensitive fields: do not send extremely sensitive PII in plain JSON unless required. For highly sensitive payloads (payment details), use dedicated PCI-compliant flows or client-side encryption with server-provided ephemeral keys.
- Payload encryption option: if you need end-to-end payload encryption for a specific feature, use hybrid encryption:
  - Server exposes ephemeral public key or uses ECDH key-exchange.
  - Client generates ephemeral key, derives symmetric AES-256-GCM key, encrypts payload, sends ciphertext + ephemeral public key.
  - Server derives symmetric key, decrypts.

- Password hashing (server): bcrypt/argon2id with a suitable work factor.

API keys, scopes, and rotation

- When issuing API keys, include metadata: `scopes`, `createdBy`, `expiresAt`, `lastUsedAt`.
- Use `x-api-key` header for API key. Reject keys in URL parameters.
- Rotation policy: provide `/v1/keys/rotate` to generate a new key and retire the old key in a single atomic operation.

Practical example: register -> login -> connect websocket (Dart)

```dart
// 1) register
final regResp = await http.post(Uri.parse('\$baseUrl/v1/auth/register'),
  body: jsonEncode({ 'name': 'Bob', 'email': 'bob@example.com', 'password': '...' }),
  headers: { 'Content-Type': 'application/json' });

// 2) login
final loginResp = await http.post(Uri.parse('\$baseUrl/v1/auth/login'),
  body: jsonEncode({ 'email': 'bob@example.com', 'password': '...' }),
  headers: { 'Content-Type': 'application/json' });
final tokens = jsonDecode(loginResp.body)['data'];
final accessToken = tokens['accessToken'];

// 3) open websocket (using web_socket_channel)
final uri = Uri.parse('wss://ispilo-backend-32613e7af752.herokuapp.com/ws?token=\$accessToken');
final channel = WebSocketChannel.connect(uri);
channel.sink.add(jsonEncode({ 'type': 'subscribe_conversations', 'payload': { 'userId': tokens['user']['id'] } }));
```

Expected outcome & verification checklist for frontend integrators

- Registration returns `user` and optional `apiKey`.
- Login returns `accessToken` (valid ~15m) and `refreshToken` (longer-lived). Confirm `Authorization` header grants access to protected endpoints.
- WebSocket connection `wss://.../ws?token=` upgrades successfully and authenticated messages produce `message_new` events when peers send messages.
- Video streaming endpoints return short-lived signed URLs; ensure your player follows redirects and uses the signed URL for playback.

Security checklist

- Use secure storage (Keychain/Keystore) for tokens on device.
- Rotate API keys regularly and limit their scopes.
- Enforce server-side role checks even when hiding UI in the client.

If you want, I can:

- Export an OpenAPI 3.0 spec for these services.
- Generate a Postman collection with example requests and sample responses.
- Create small JSON fixtures (e.g., `test/fixtures/product.json`, `conversation.json`) to speed front-end testing.
