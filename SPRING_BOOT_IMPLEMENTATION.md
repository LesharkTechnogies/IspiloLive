# Spring Boot Implementation Guide - ISPILO Backend

## Quick Start

### Prerequisites
- Java 17+
- Maven 3.8+
- MySQL 8.0+ / PostgreSQL 14+
- Redis (for caching)
- AWS S3 account (for media storage)

### Project Structure
```
ispilo-backend/
├── src/
│   ├── main/
│   │   ├── java/
│   │   │   └── com/ispilo/
│   │   │       ├── IspiloApplication.java
│   │   │       ├── config/
│   │   │       │   ├── SecurityConfig.java
│   │   │       │   ├── WebSocketConfig.java
│   │   │       │   ├── CacheConfig.java
│   │   │       │   └── S3Config.java
│   │   │       ├── controller/
│   │   │       │   ├── AuthController.java
│   │   │       │   ├── UserController.java
│   │   │       │   ├── SellerController.java
│   │   │       │   ├── ConversationController.java
│   │   │       │   ├── MessageController.java
│   │   │       │   ├── PostController.java
│   │   │       │   └── MediaController.java
│   │   │       ├── dto/
│   │   │       │   ├── request/
│   │   │       │   │   ├── LoginRequest.java
│   │   │       │   │   ├── RegisterRequest.java
│   │   │       │   │   ├── CreateMessageRequest.java
│   │   │       │   │   └── CreatePostRequest.java
│   │   │       │   └── response/
│   │   │       │       ├── AuthResponse.java
│   │   │       │       ├── MessageResponse.java
│   │   │       │       └── ErrorResponse.java
│   │   │       ├── entity/
│   │   │       │   ├── User.java
│   │   │       │   ├── Seller.java
│   │   │       │   ├── Conversation.java
│   │   │       │   ├── Message.java
│   │   │       │   ├── Post.java
│   │   │       │   └── Comment.java
│   │   │       ├── repository/
│   │   │       │   ├── UserRepository.java
│   │   │       │   ├── SellerRepository.java
│   │   │       │   ├── ConversationRepository.java
│   │   │       │   ├── MessageRepository.java
│   │   │       │   └── PostRepository.java
│   │   │       ├── service/
│   │   │       │   ├── AuthService.java
│   │   │       │   ├── UserService.java
│   │   │       │   ├── SellerService.java
│   │   │       │   ├── ConversationService.java
│   │   │       │   ├── MessageService.java
│   │   │       │   ├── PostService.java
│   │   │       │   └── S3Service.java
│   │   │       ├── security/
│   │   │       │   ├── JwtTokenProvider.java
│   │   │       │   ├── JwtAuthenticationFilter.java
│   │   │       │   └── UserPrincipal.java
│   │   │       ├── websocket/
│   │   │       │   ├── ChatWebSocketHandler.java
│   │   │       │   └── WebSocketEventListener.java
│   │   │       └── exception/
│   │   │           ├── GlobalExceptionHandler.java
│   │   │           ├── ResourceNotFoundException.java
│   │   │           └── UnauthorizedException.java
│   │   └── resources/
│   │       ├── application.yml
│   │       ├── application-dev.yml
│   │       ├── application-prod.yml
│   │       └── db/
│   │           └── migration/
│   │               ├── V1__create_users_table.sql
│   │               ├── V2__create_sellers_table.sql
│   │               ├── V3__create_conversations_table.sql
│   │               └── V4__create_messages_table.sql
│   └── test/
│       └── java/
│           └── com/ispilo/
│               ├── controller/
│               └── service/
├── pom.xml
└── README.md
```

---

## pom.xml Dependencies

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0
         https://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>
    
    <parent>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-parent</artifactId>
        <version>3.2.0</version>
        <relativePath/>
    </parent>
    
    <groupId>com.ispilo</groupId>
    <artifactId>ispilo-backend</artifactId>
    <version>1.0.0</version>
    <name>ISPILO Backend</name>
    
    <properties>
        <java.version>17</java.version>
    </properties>
    
    <dependencies>
        <!-- Spring Boot Starters -->
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-web</artifactId>
        </dependency>
        
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-data-jpa</artifactId>
        </dependency>
        
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-security</artifactId>
        </dependency>
        
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-websocket</artifactId>
        </dependency>
        
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-validation</artifactId>
        </dependency>
        
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-cache</artifactId>
        </dependency>
        
        <!-- Database -->
        <dependency>
            <groupId>mysql</groupId>
            <artifactId>mysql-connector-java</artifactId>
            <version>8.0.33</version>
        </dependency>
        
        <!-- Flyway for migrations -->
        <dependency>
            <groupId>org.flywaydb</groupId>
            <artifactId>flyway-core</artifactId>
        </dependency>
        
        <dependency>
            <groupId>org.flywaydb</groupId>
            <artifactId>flyway-mysql</artifactId>
        </dependency>
        
        <!-- Redis -->
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-data-redis</artifactId>
        </dependency>
        
        <!-- JWT -->
        <dependency>
            <groupId>io.jsonwebtoken</groupId>
            <artifactId>jjwt-api</artifactId>
            <version>0.12.3</version>
        </dependency>
        <dependency>
            <groupId>io.jsonwebtoken</groupId>
            <artifactId>jjwt-impl</artifactId>
            <version>0.12.3</version>
            <scope>runtime</scope>
        </dependency>
        <dependency>
            <groupId>io.jsonwebtoken</groupId>
            <artifactId>jjwt-jackson</artifactId>
            <version>0.12.3</version>
            <scope>runtime</scope>
        </dependency>
        
        <!-- AWS S3 -->
        <dependency>
            <groupId>software.amazon.awssdk</groupId>
            <artifactId>s3</artifactId>
            <version>2.21.0</version>
        </dependency>
        
        <!-- Lombok -->
        <dependency>
            <groupId>org.projectlombok</groupId>
            <artifactId>lombok</artifactId>
            <optional>true</optional>
        </dependency>
        
        <!-- OpenAPI/Swagger -->
        <dependency>
            <groupId>org.springdoc</groupId>
            <artifactId>springdoc-openapi-starter-webmvc-ui</artifactId>
            <version>2.2.0</version>
        </dependency>
        
        <!-- Testing -->
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-test</artifactId>
            <scope>test</scope>
        </dependency>
        
        <dependency>
            <groupId>org.springframework.security</groupId>
            <artifactId>spring-security-test</artifactId>
            <scope>test</scope>
        </dependency>
    </dependencies>
    
    <build>
        <plugins>
            <plugin>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-maven-plugin</artifactId>
            </plugin>
        </plugins>
    </build>
</project>
```

---

## Configuration Files

### application.yml
```yaml
spring:
  application:
    name: ispilo-backend
    
  profiles:
    active: dev
    
  datasource:
    url: jdbc:mysql://localhost:3306/ispilo_db?useSSL=false&serverTimezone=UTC
    username: ${DB_USERNAME:root}
    password: ${DB_PASSWORD:password}
    driver-class-name: com.mysql.cj.jdbc.Driver
    
  jpa:
    hibernate:
      ddl-auto: validate
    show-sql: false
    properties:
      hibernate:
        dialect: org.hibernate.dialect.MySQLDialect
        format_sql: true
        
  flyway:
    enabled: true
    baseline-on-migrate: true
    locations: classpath:db/migration
    
  redis:
    host: ${REDIS_HOST:localhost}
    port: ${REDIS_PORT:6379}
    password: ${REDIS_PASSWORD:}
    
  cache:
    type: redis
    redis:
      time-to-live: 600000 # 10 minutes
      
  servlet:
    multipart:
      max-file-size: 50MB
      max-request-size: 50MB

# JWT Configuration
jwt:
  secret: ${JWT_SECRET:your-256-bit-secret-key-change-in-production}
  expiration: 86400000 # 24 hours
  refresh-expiration: 604800000 # 7 days

# AWS S3 Configuration
aws:
  s3:
    bucket-name: ${AWS_S3_BUCKET:ispilo-media}
    region: ${AWS_REGION:us-east-1}
    access-key: ${AWS_ACCESS_KEY}
    secret-key: ${AWS_SECRET_KEY}

# API Configuration
api:
  version: v1
  base-path: /api

# Logging
logging:
  level:
    root: INFO
    com.ispilo: DEBUG
    org.springframework.web: DEBUG
    org.hibernate.SQL: DEBUG

# Server
server:
  port: 8080
  compression:
    enabled: true
```

---

## Core Entity Examples

### User Entity
```java
package com.ispilo.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDateTime;

@Entity
@Table(name = "users")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class User {
    
    @Id
    @Column(length = 255)
    private String id;
    
    @Column(unique = true, nullable = false)
    private String email;
    
    @Column(name = "password_hash", nullable = false)
    private String passwordHash;
    
    @Column(nullable = false)
    private String name;
    
    @Column(length = 500)
    private String avatar;
    
    @Column(length = 50)
    private String phone;
    
    @Column(name = "phone_privacy_public")
    private Boolean phonePrivacyPublic = false;
    
    @Column(name = "country_code", length = 10)
    private String countryCode;
    
    @Column(name = "is_verified")
    private Boolean isVerified = false;
    
    @Column(columnDefinition = "TEXT")
    private String bio;
    
    private String location;
    
    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;
    
    @UpdateTimestamp
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
    
    @PrePersist
    public void prePersist() {
        if (id == null) {
            id = "user_" + System.currentTimeMillis();
        }
    }
}
```

### Message Entity
```java
package com.ispilo.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

@Entity
@Table(name = "messages", indexes = {
    @Index(name = "idx_conversation", columnList = "conversation_id,timestamp"),
    @Index(name = "idx_sender", columnList = "sender_id")
})
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Message {
    
    @Id
    @Column(length = 255)
    private String id;
    
    @Column(name = "conversation_id", nullable = false, length = 255)
    private String conversationId;
    
    @Column(name = "sender_id", nullable = false, length = 255)
    private String senderId;
    
    @Column(columnDefinition = "TEXT")
    private String text;
    
    @Column(name = "media_url", length = 500)
    private String mediaUrl;
    
    @Column(name = "media_type", length = 50)
    private String mediaType;
    
    @Column(name = "document_name")
    private String documentName;
    
    @Column(name = "duration_ms")
    private Integer durationMs;
    
    @Column(name = "is_read")
    private Boolean isRead = false;
    
    @Column(nullable = false)
    private LocalDateTime timestamp;
    
    @PrePersist
    public void prePersist() {
        if (id == null) {
            id = "msg_" + System.currentTimeMillis();
        }
        if (timestamp == null) {
            timestamp = LocalDateTime.now();
        }
    }
}
```

---

## Controller Examples

### SellerController
```java
package com.ispilo.controller;

import com.ispilo.dto.request.UpsertSellerRequest;
import com.ispilo.dto.response.SellerResponse;
import com.ispilo.service.SellerService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import jakarta.validation.Valid;

@RestController
@RequestMapping("/api/sellers")
@RequiredArgsConstructor
@Tag(name = "Sellers", description = "Seller management APIs")
public class SellerController {
    
    private final SellerService sellerService;
    
    @GetMapping("/{id}")
    @Operation(summary = "Get seller by ID")
    public ResponseEntity<SellerResponse> getSellerById(@PathVariable String id) {
        SellerResponse seller = sellerService.getSellerById(id);
        return ResponseEntity.ok(seller);
    }
    
    @PostMapping
    @PreAuthorize("isAuthenticated()")
    @Operation(summary = "Create or update seller")
    public ResponseEntity<SellerResponse> upsertSeller(
            @Valid @RequestBody UpsertSellerRequest request) {
        SellerResponse seller = sellerService.upsertSeller(request);
        HttpStatus status = request.getId() == null ? HttpStatus.CREATED : HttpStatus.OK;
        return ResponseEntity.status(status).body(seller);
    }
}
```

### MessageController
```java
package com.ispilo.controller;

import com.ispilo.dto.request.CreateMessageRequest;
import com.ispilo.dto.response.MessageResponse;
import com.ispilo.security.UserPrincipal;
import com.ispilo.service.MessageService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import jakarta.validation.Valid;
import java.time.LocalDateTime;
import java.util.List;

@RestController
@RequestMapping("/api/conversations/{conversationId}/messages")
@RequiredArgsConstructor
@Tag(name = "Messages", description = "Messaging APIs")
public class MessageController {
    
    private final MessageService messageService;
    
    @GetMapping
    @Operation(summary = "Get messages in conversation")
    public ResponseEntity<List<MessageResponse>> getMessages(
            @PathVariable String conversationId,
            @RequestParam(defaultValue = "50") int limit,
            @RequestParam(required = false) LocalDateTime before) {
        List<MessageResponse> messages = messageService.getMessages(
            conversationId, limit, before);
        return ResponseEntity.ok(messages);
    }
    
    @PostMapping
    @Operation(summary = "Send message")
    public ResponseEntity<MessageResponse> sendMessage(
            @PathVariable String conversationId,
            @Valid @RequestBody CreateMessageRequest request,
            @AuthenticationPrincipal UserPrincipal currentUser) {
        MessageResponse message = messageService.sendMessage(
            conversationId, request, currentUser.getId());
        return ResponseEntity.status(HttpStatus.CREATED).body(message);
    }
    
    @PostMapping("/read")
    @Operation(summary = "Mark messages as read")
    public ResponseEntity<Void> markAsRead(
            @PathVariable String conversationId,
            @AuthenticationPrincipal UserPrincipal currentUser) {
        messageService.markAsRead(conversationId, currentUser.getId());
        return ResponseEntity.ok().build();
    }
}
```

---

## Service Examples

### MessageService
```java
package com.ispilo.service;

import com.ispilo.dto.request.CreateMessageRequest;
import com.ispilo.dto.response.MessageResponse;
import com.ispilo.entity.Message;
import com.ispilo.repository.MessageRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class MessageService {
    
    private final MessageRepository messageRepository;
    private final SimpMessagingTemplate messagingTemplate;
    
    public List<MessageResponse> getMessages(
            String conversationId, int limit, LocalDateTime before) {
        List<Message> messages;
        if (before != null) {
            messages = messageRepository.findByConversationIdAndTimestampBefore(
                conversationId, before, limit);
        } else {
            messages = messageRepository.findByConversationIdOrderByTimestampDesc(
                conversationId, limit);
        }
        return messages.stream()
            .map(this::toResponse)
            .collect(Collectors.toList());
    }
    
    @Transactional
    public MessageResponse sendMessage(
            String conversationId, CreateMessageRequest request, String senderId) {
        Message message = Message.builder()
            .conversationId(conversationId)
            .senderId(senderId)
            .text(request.getText())
            .mediaUrl(request.getMediaUrl())
            .mediaType(request.getMediaType())
            .documentName(request.getDocumentName())
            .durationMs(request.getDurationMs())
            .isRead(false)
            .timestamp(LocalDateTime.now())
            .build();
        
        message = messageRepository.save(message);
        
        // Send WebSocket notification
        MessageResponse response = toResponse(message);
        messagingTemplate.convertAndSend(
            "/topic/conversations/" + conversationId, response);
        
        return response;
    }
    
    @Transactional
    public void markAsRead(String conversationId, String userId) {
        messageRepository.markAsReadByConversationAndNotSender(
            conversationId, userId);
    }
    
    private MessageResponse toResponse(Message message) {
        return MessageResponse.builder()
            .id(message.getId())
            .conversationId(message.getConversationId())
            .senderId(message.getSenderId())
            .text(message.getText())
            .mediaUrl(message.getMediaUrl())
            .mediaType(message.getMediaType())
            .documentName(message.getDocumentName())
            .durationMs(message.getDurationMs())
            .isRead(message.getIsRead())
            .timestamp(message.getTimestamp())
            .build();
    }
}
```

---

## Security Configuration

### JwtTokenProvider
```java
package com.ispilo.security;

import io.jsonwebtoken.*;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import javax.crypto.SecretKey;
import java.util.Date;

@Component
public class JwtTokenProvider {
    
    @Value("${jwt.secret}")
    private String jwtSecret;
    
    @Value("${jwt.expiration}")
    private long jwtExpiration;
    
    private SecretKey getSigningKey() {
        return Keys.hmacShaKeyFor(jwtSecret.getBytes());
    }
    
    public String generateToken(String userId) {
        Date now = new Date();
        Date expiryDate = new Date(now.getTime() + jwtExpiration);
        
        return Jwts.builder()
            .setSubject(userId)
            .setIssuedAt(now)
            .setExpiration(expiryDate)
            .signWith(getSigningKey())
            .compact();
    }
    
    public String getUserIdFromToken(String token) {
        Claims claims = Jwts.parserBuilder()
            .setSigningKey(getSigningKey())
            .build()
            .parseClaimsJws(token)
            .getBody();
        
        return claims.getSubject();
    }
    
    public boolean validateToken(String token) {
        try {
            Jwts.parserBuilder()
                .setSigningKey(getSigningKey())
                .build()
                .parseClaimsJws(token);
            return true;
        } catch (JwtException | IllegalArgumentException e) {
            return false;
        }
    }
}
```

---

## WebSocket Configuration

### WebSocketConfig
```java
package com.ispilo.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.messaging.simp.config.MessageBrokerRegistry;
import org.springframework.web.socket.config.annotation.*;

@Configuration
@EnableWebSocketMessageBroker
public class WebSocketConfig implements WebSocketMessageBrokerConfigurer {
    
    @Override
    public void configureMessageBroker(MessageBrokerRegistry registry) {
        registry.enableSimpleBroker("/topic", "/queue");
        registry.setApplicationDestinationPrefixes("/app");
    }
    
    @Override
    public void registerStompEndpoints(StompEndpointRegistry registry) {
        registry.addEndpoint("/ws/chat")
            .setAllowedOriginPatterns("*")
            .withSockJS();
    }
}
```

---

## Testing Examples

### MessageControllerTest
```java
package com.ispilo.controller;

import com.ispilo.dto.request.CreateMessageRequest;
import com.ispilo.dto.response.MessageResponse;
import com.ispilo.security.JwtTokenProvider;
import com.ispilo.service.MessageService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.web.servlet.MockMvc;

import java.time.LocalDateTime;

import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@WebMvcTest(MessageController.class)
class MessageControllerTest {
    
    @Autowired
    private MockMvc mockMvc;
    
    @MockBean
    private MessageService messageService;
    
    @MockBean
    private JwtTokenProvider jwtTokenProvider;
    
    @Test
    @WithMockUser
    void sendMessage_Success() throws Exception {
        MessageResponse response = MessageResponse.builder()
            .id("msg_123")
            .conversationId("conv_abc")
            .senderId("user_123")
            .text("Hello!")
            .timestamp(LocalDateTime.now())
            .build();
        
        when(messageService.sendMessage(anyString(), any(), anyString()))
            .thenReturn(response);
        
        mockMvc.perform(post("/api/conversations/conv_abc/messages")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"text\":\"Hello!\"}"))
            .andExpect(status().isCreated())
            .andExpect(jsonPath("$.id").value("msg_123"))
            .andExpect(jsonPath("$.text").value("Hello!"));
    }
}
```

---

## Deployment

### Docker Compose (Development)
```yaml
version: '3.8'

services:
  mysql:
    image: mysql:8.0
    environment:
      MYSQL_ROOT_PASSWORD: rootpassword
      MYSQL_DATABASE: ispilo_db
    ports:
      - "3306:3306"
    volumes:
      - mysql_data:/var/lib/mysql
      
  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
      
  backend:
    build: .
    ports:
      - "8080:8080"
    environment:
      DB_USERNAME: root
      DB_PASSWORD: rootpassword
      REDIS_HOST: redis
      JWT_SECRET: your-secret-key-change-in-production
    depends_on:
      - mysql
      - redis

volumes:
  mysql_data:
```

### Dockerfile
```dockerfile
FROM eclipse-temurin:17-jdk-alpine AS build
WORKDIR /app
COPY pom.xml .
COPY src ./src
RUN ./mvnw clean package -DskipTests

FROM eclipse-temurin:17-jre-alpine
WORKDIR /app
COPY --from=build /app/target/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
```

---

## Next Steps

1. **Initialize Project**: Use Spring Initializr or copy project structure
2. **Configure Database**: Set up MySQL and run Flyway migrations
3. **Implement Controllers**: Start with Auth, User, and Seller controllers
4. **Add Security**: Implement JWT authentication
5. **WebSocket**: Set up real-time messaging
6. **Testing**: Write unit and integration tests
7. **Deploy**: Use Docker Compose for local, AWS/GCP for production

---

## Performance Tips

1. **Database Indexing**: Add indexes on foreign keys and frequently queried fields
2. **Caching**: Use Redis for user profiles, seller info
3. **Connection Pooling**: Configure HikariCP properly
4. **Pagination**: Always paginate list endpoints
5. **Async Processing**: Use @Async for non-critical operations
6. **CDN**: Serve static media from S3/CloudFront
7. **Monitoring**: Add Spring Boot Actuator + Prometheus
