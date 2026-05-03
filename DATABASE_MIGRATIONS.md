# Database Migration Guide - ISPILO

## Overview
This guide provides Flyway migration scripts for setting up the ISPILO database schema with proper indexing, constraints, and performance optimizations.

## Migration Files Location
```
src/main/resources/db/migration/
├── V1__create_users_table.sql
├── V2__create_sellers_table.sql
├── V3__create_conversations_tables.sql
├── V4__create_messages_table.sql
├── V5__create_posts_tables.sql
├── V6__create_products_tables.sql
└── V7__add_indexes_and_optimizations.sql
```

---

## V1__create_users_table.sql

```sql
-- Users table - Core user accounts
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
    INDEX idx_email (email),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Refresh tokens for JWT authentication
CREATE TABLE refresh_tokens (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id VARCHAR(255) NOT NULL,
    token VARCHAR(500) UNIQUE NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_token (token),
    INDEX idx_user_id (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

---

## V2__create_sellers_table.sql

```sql
-- Sellers table - Marketplace sellers/vendors
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
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_rating (rating),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Seller reviews/ratings
CREATE TABLE seller_reviews (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    seller_id VARCHAR(255) NOT NULL,
    reviewer_id VARCHAR(255) NOT NULL,
    rating INT NOT NULL CHECK (rating BETWEEN 1 AND 5),
    review_text TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (seller_id) REFERENCES sellers(id) ON DELETE CASCADE,
    FOREIGN KEY (reviewer_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE KEY unique_review (seller_id, reviewer_id),
    INDEX idx_seller_rating (seller_id, rating)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

---

## V3__create_conversations_tables.sql

```sql
-- Conversations table - Chat conversations
CREATE TABLE conversations (
    id VARCHAR(255) PRIMARY KEY,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_updated_at (updated_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Conversation participants - Many-to-many relationship
CREATE TABLE conversation_participants (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    conversation_id VARCHAR(255) NOT NULL,
    user_id VARCHAR(255) NOT NULL,
    unread_count INT DEFAULT 0,
    joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_read_at TIMESTAMP NULL,
    FOREIGN KEY (conversation_id) REFERENCES conversations(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE KEY unique_participant (conversation_id, user_id),
    INDEX idx_user_conversations (user_id, conversation_id),
    INDEX idx_unread (user_id, unread_count)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

---

## V4__create_messages_table.sql

```sql
-- Messages table - Chat messages
CREATE TABLE messages (
    id VARCHAR(255) PRIMARY KEY,
    conversation_id VARCHAR(255) NOT NULL,
    sender_id VARCHAR(255) NOT NULL,
    text TEXT,
    media_url VARCHAR(500),
    media_type VARCHAR(50) COMMENT 'image, video, document, voice',
    document_name VARCHAR(255),
    duration_ms INT COMMENT 'For voice/video messages',
    is_read BOOLEAN DEFAULT FALSE,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (conversation_id) REFERENCES conversations(id) ON DELETE CASCADE,
    FOREIGN KEY (sender_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_conversation_time (conversation_id, timestamp DESC),
    INDEX idx_sender (sender_id),
    INDEX idx_unread (conversation_id, is_read)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Message read receipts (optional - for detailed tracking)
CREATE TABLE message_read_receipts (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    message_id VARCHAR(255) NOT NULL,
    user_id VARCHAR(255) NOT NULL,
    read_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (message_id) REFERENCES messages(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE KEY unique_receipt (message_id, user_id),
    INDEX idx_message_user (message_id, user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

---

## V5__create_posts_tables.sql

```sql
-- Posts table - Social feed posts
CREATE TABLE posts (
    id VARCHAR(255) PRIMARY KEY,
    user_id VARCHAR(255) NOT NULL,
    description TEXT,
    image_url VARCHAR(500),
    video_url VARCHAR(500),
    likes_count INT DEFAULT 0,
    comments_count INT DEFAULT 0,
    shares_count INT DEFAULT 0,
    is_sponsored BOOLEAN DEFAULT FALSE,
    sponsor_id VARCHAR(255) COMMENT 'For sponsored posts',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_posts (user_id, created_at DESC),
    INDEX idx_created_at (created_at DESC),
    INDEX idx_sponsored (is_sponsored, created_at DESC)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Post likes
CREATE TABLE post_likes (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    post_id VARCHAR(255) NOT NULL,
    user_id VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE KEY unique_like (post_id, user_id),
    INDEX idx_post_likes (post_id, created_at DESC),
    INDEX idx_user_likes (user_id, created_at DESC)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Comments
CREATE TABLE comments (
    id VARCHAR(255) PRIMARY KEY,
    post_id VARCHAR(255) NOT NULL,
    user_id VARCHAR(255) NOT NULL,
    parent_comment_id VARCHAR(255) COMMENT 'For nested replies',
    text TEXT NOT NULL,
    likes_count INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (parent_comment_id) REFERENCES comments(id) ON DELETE CASCADE,
    INDEX idx_post_comments (post_id, created_at DESC),
    INDEX idx_parent_replies (parent_comment_id, created_at ASC)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Comment likes
CREATE TABLE comment_likes (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    comment_id VARCHAR(255) NOT NULL,
    user_id VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (comment_id) REFERENCES comments(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE KEY unique_like (comment_id, user_id),
    INDEX idx_comment_likes (comment_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Post shares
CREATE TABLE post_shares (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    post_id VARCHAR(255) NOT NULL,
    user_id VARCHAR(255) NOT NULL,
    platform VARCHAR(50) COMMENT 'internal, facebook, twitter, whatsapp',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_post_shares (post_id, created_at DESC)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

---

## V6__create_products_tables.sql

```sql
-- Product categories
CREATE TABLE categories (
    id VARCHAR(255) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    slug VARCHAR(255) UNIQUE NOT NULL,
    parent_id VARCHAR(255),
    icon_url VARCHAR(500),
    display_order INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (parent_id) REFERENCES categories(id) ON DELETE CASCADE,
    INDEX idx_slug (slug),
    INDEX idx_parent (parent_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Products
CREATE TABLE products (
    id VARCHAR(255) PRIMARY KEY,
    seller_id VARCHAR(255) NOT NULL,
    category_id VARCHAR(255),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    price DECIMAL(10,2) NOT NULL,
    currency VARCHAR(10) DEFAULT 'KES',
    stock INT DEFAULT 0,
    condition_type VARCHAR(50) COMMENT 'new, used, refurbished',
    brand VARCHAR(255),
    model VARCHAR(255),
    is_active BOOLEAN DEFAULT TRUE,
    views_count INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (seller_id) REFERENCES sellers(id) ON DELETE CASCADE,
    FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE SET NULL,
    INDEX idx_seller_products (seller_id, is_active, created_at DESC),
    INDEX idx_category_products (category_id, is_active, created_at DESC),
    INDEX idx_price_range (price, is_active),
    INDEX idx_search (name, is_active),
    FULLTEXT idx_fulltext_search (name, description, brand, model)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Product images
CREATE TABLE product_images (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    product_id VARCHAR(255) NOT NULL,
    image_url VARCHAR(500) NOT NULL,
    display_order INT DEFAULT 0,
    is_primary BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE,
    INDEX idx_product_images (product_id, display_order)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Product specifications
CREATE TABLE product_specifications (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    product_id VARCHAR(255) NOT NULL,
    spec_key VARCHAR(255) NOT NULL,
    spec_value TEXT NOT NULL,
    display_order INT DEFAULT 0,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE,
    INDEX idx_product_specs (product_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- User favorites/saved products
CREATE TABLE product_favorites (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    product_id VARCHAR(255) NOT NULL,
    user_id VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE KEY unique_favorite (product_id, user_id),
    INDEX idx_user_favorites (user_id, created_at DESC)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

---

## V7__add_indexes_and_optimizations.sql

```sql
-- Additional performance indexes

-- User activity tracking
CREATE INDEX idx_users_activity ON users(is_verified, created_at DESC);

-- Conversation performance
CREATE INDEX idx_conversations_activity ON conversations(updated_at DESC);

-- Message pagination optimization
CREATE INDEX idx_messages_pagination ON messages(conversation_id, timestamp DESC) 
    INCLUDE (sender_id, text, media_url, is_read);

-- Post feed optimization
CREATE INDEX idx_posts_feed ON posts(created_at DESC, is_sponsored) 
    INCLUDE (user_id, description, image_url, likes_count, comments_count);

-- Product search optimization
CREATE INDEX idx_products_active_price ON products(is_active, price, created_at DESC);
CREATE INDEX idx_products_category_price ON products(category_id, is_active, price);

-- Analytics indexes
CREATE INDEX idx_post_likes_analytics ON post_likes(user_id, created_at);
CREATE INDEX idx_message_activity ON messages(sender_id, timestamp);

-- Composite indexes for common queries
CREATE INDEX idx_seller_active_products ON products(seller_id, is_active, stock);
CREATE INDEX idx_user_unread_messages ON conversation_participants(user_id, unread_count)
    WHERE unread_count > 0;
```

---

## Performance Tuning Configuration

### MySQL Configuration (my.cnf)

```ini
[mysqld]
# InnoDB settings
innodb_buffer_pool_size = 2G
innodb_log_file_size = 512M
innodb_flush_log_at_trx_commit = 2
innodb_flush_method = O_DIRECT

# Query cache (MySQL 5.7 and earlier)
query_cache_type = 1
query_cache_size = 128M

# Connection settings
max_connections = 500
thread_cache_size = 50

# Character set
character-set-server = utf8mb4
collation-server = utf8mb4_unicode_ci

# Logging
slow_query_log = 1
slow_query_log_file = /var/log/mysql/slow-query.log
long_query_time = 2

# Binary logging for replication
server-id = 1
log_bin = /var/log/mysql/mysql-bin.log
binlog_format = ROW
expire_logs_days = 7
```

---

## Sample Data Insertion

### V8__insert_sample_data.sql (Development only)

```sql
-- Sample categories
INSERT INTO categories (id, name, slug, parent_id, display_order) VALUES
('cat_electronics', 'Electronics', 'electronics', NULL, 1),
('cat_networking', 'Networking', 'networking', 'cat_electronics', 1),
('cat_computers', 'Computers', 'computers', 'cat_electronics', 2),
('cat_fashion', 'Fashion', 'fashion', NULL, 2),
('cat_home', 'Home & Garden', 'home-garden', NULL, 3);

-- Sample users (password: password123)
INSERT INTO users (id, email, password_hash, name, phone, country_code, is_verified) VALUES
('user_001', 'john@example.com', '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', 'John Doe', '+254712345678', '254', TRUE),
('user_002', 'jane@example.com', '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', 'Jane Smith', '+254723456789', '254', TRUE),
('user_003', 'bob@example.com', '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', 'Bob Wilson', '+254734567890', '254', FALSE);

-- Sample sellers
INSERT INTO sellers (id, user_id, name, is_verified, phone_privacy_public, rating, total_sales) VALUES
('seller_001', 'user_002', 'NetworkPro Solutions', TRUE, TRUE, 4.8, 156),
('seller_002', 'user_003', 'TechHub Kenya', FALSE, TRUE, 4.2, 45);

-- Sample products
INSERT INTO products (id, seller_id, category_id, name, description, price, currency, stock, condition_type, is_active) VALUES
('prod_001', 'seller_001', 'cat_networking', 'Cisco Enterprise Router', 'High-performance enterprise-grade router', 45000.00, 'KES', 5, 'new', TRUE),
('prod_002', 'seller_001', 'cat_computers', 'Dell Latitude Laptop', 'i7 16GB RAM, 512GB SSD', 75000.00, 'KES', 3, 'refurbished', TRUE),
('prod_003', 'seller_002', 'cat_networking', 'TP-Link Switch 24-Port', 'Managed Gigabit Switch', 12000.00, 'KES', 10, 'new', TRUE);

-- Sample product images
INSERT INTO product_images (product_id, image_url, display_order, is_primary) VALUES
('prod_001', 'https://cdn.ispilo.com/products/router1.jpg', 1, TRUE),
('prod_002', 'https://cdn.ispilo.com/products/laptop1.jpg', 1, TRUE),
('prod_003', 'https://cdn.ispilo.com/products/switch1.jpg', 1, TRUE);
```

---

## Migration Execution

### Local Development

```bash
# Run all migrations
mvn flyway:migrate

# Check migration status
mvn flyway:info

# Clean database (WARNING: Deletes all data)
mvn flyway:clean

# Repair failed migrations
mvn flyway:repair
```

### Production Deployment

```bash
# Backup database first!
mysqldump -u root -p ispilo_db > backup_$(date +%Y%m%d).sql

# Run migrations
mvn flyway:migrate -Dflyway.configFiles=flyway-prod.conf

# Verify migration
mvn flyway:validate
```

---

## Rollback Strategy

Flyway doesn't support automatic rollback. For critical migrations, create undo scripts:

### Example: V8_1__undo_add_column.sql

```sql
-- Undo V8__add_user_status_column.sql
ALTER TABLE users DROP COLUMN status;
```

---

## Monitoring & Maintenance

### Check Table Sizes

```sql
SELECT 
    table_name,
    ROUND(((data_length + index_length) / 1024 / 1024), 2) AS 'Size (MB)'
FROM information_schema.TABLES 
WHERE table_schema = 'ispilo_db'
ORDER BY (data_length + index_length) DESC;
```

### Check Index Usage

```sql
SELECT 
    table_name,
    index_name,
    cardinality
FROM information_schema.STATISTICS 
WHERE table_schema = 'ispilo_db'
ORDER BY table_name, index_name;
```

### Optimize Tables (Monthly)

```sql
OPTIMIZE TABLE users, sellers, products, messages, posts;
```

---

## Next Steps

1. Set up MySQL database
2. Configure Flyway in Spring Boot
3. Run migrations in order
4. Verify table creation and indexes
5. Insert sample data for testing
6. Set up database backups
7. Configure monitoring with slow query log
# Database Schema & Integration Guide

Purpose

This document describes the recommended database schema, naming conventions, example CREATE statements (Postgres), indexes, relations, and migration guidance for the `ispilo` backend. It is written for backend and frontend engineers to understand the canonical data model and queries used by the API.

Recommended engine

- PostgreSQL (preferred): offers JSONB support, strong indexing and migration tooling.
- MySQL or MariaDB acceptable, but examples use Postgres syntax.

Conventions

- Table names: plural snake_case (e.g., `users`, `products`).
- Columns: snake_case.
- Primary keys: `id` of type `uuid` (default) or `bigserial` if you prefer integers.
- Timestamps: `created_at`, `updated_at` (timezone-aware `timestamptz`).
- Soft deletes: `deleted_at` nullable timestamp if needed.
- JSON fields: `jsonb` for flexible metadata (e.g. product specs).

Core tables

1) users

```sql
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT NOT NULL UNIQUE,
  password_hash TEXT NOT NULL,
  full_name TEXT,
  role TEXT NOT NULL DEFAULT 'buyer',
  phone TEXT,
  country_code TEXT,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
```

Indexes: unique on `email`, index on `phone` if phone lookup required.

2) sellers

```sql
CREATE TABLE sellers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  avatar_url TEXT,
  is_verified BOOLEAN DEFAULT false,
  rating NUMERIC(3,2) DEFAULT 0.0,
  total_sales INTEGER DEFAULT 0,
  phone TEXT,
  phone_privacy_public BOOLEAN DEFAULT false,
  country_code TEXT,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX idx_sellers_user_id ON sellers(user_id);
```

3) products

```sql
CREATE TABLE products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  seller_id UUID NOT NULL REFERENCES sellers(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  name TEXT,
  description TEXT,
  price NUMERIC(12,2),
  currency TEXT DEFAULT 'USD',
  condition TEXT,
  rating NUMERIC(3,2) DEFAULT 0.0,
  review_count INTEGER DEFAULT 0,
  metadata JSONB, -- additional fields
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX idx_products_seller_id ON products(seller_id);
CREATE INDEX idx_products_price ON products(price);
-- Full-text index for title and description
CREATE INDEX idx_products_ft ON products USING GIN (to_tsvector('english', coalesce(title,'') || ' ' || coalesce(description,'')));
```

4) product_images

```sql
CREATE TABLE product_images (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id UUID REFERENCES products(id) ON DELETE CASCADE,
  url TEXT NOT NULL,
  position INTEGER DEFAULT 0
);
CREATE INDEX idx_product_images_product_id ON product_images(product_id);
```

5) product_specifications

```sql
CREATE TABLE product_specifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id UUID REFERENCES products(id) ON DELETE CASCADE,
  key TEXT NOT NULL,
  value TEXT
);
CREATE INDEX idx_product_specs_product_id ON product_specifications(product_id);
```

6) favorites

```sql
CREATE TABLE favorites (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  product_id UUID REFERENCES products(id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (user_id, product_id)
);
CREATE INDEX idx_favorites_user_id ON favorites(user_id);
```

7) conversations

```sql
CREATE TABLE conversations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  buyer_id UUID REFERENCES users(id) ON DELETE SET NULL,
  seller_id UUID REFERENCES sellers(id) ON DELETE SET NULL,
  last_message_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX idx_conversations_buyer_id ON conversations(buyer_id);
CREATE INDEX idx_conversations_seller_id ON conversations(seller_id);
```

8) messages

```sql
CREATE TABLE messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID REFERENCES conversations(id) ON DELETE CASCADE,
  sender_id UUID REFERENCES users(id) ON DELETE CASCADE,
  type TEXT NOT NULL, -- e.g. 'text','image','offer'
  payload JSONB, -- structured message payload
  created_at timestamptz NOT NULL DEFAULT now(),
  delivered_at timestamptz,
  read_at timestamptz
);
CREATE INDEX idx_messages_conversation_id ON messages(conversation_id);
CREATE INDEX idx_messages_created_at ON messages(created_at DESC);
```

9) orders and order_items (basic)

```sql
CREATE TABLE orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  buyer_id UUID REFERENCES users(id) ON DELETE SET NULL,
  total_amount NUMERIC(12,2),
  currency TEXT DEFAULT 'USD',
  status TEXT DEFAULT 'pending',
  shipping_address JSONB,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE order_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID REFERENCES orders(id) ON DELETE CASCADE,
  product_id UUID REFERENCES products(id) ON DELETE SET NULL,
  price_snapshot NUMERIC(12,2),
  quantity INTEGER DEFAULT 1
);
CREATE INDEX idx_order_items_order_id ON order_items(order_id);
```

Indexes & performance

- Add indexes on foreign keys for join performance (seller_id, product_id, user_id).
- Use GIN indexes for JSONB fields if you query them frequently (e.g., metadata @> '{"key":"value"}').
- Consider partial indexes for common queries (e.g., `WHERE deleted_at IS NULL`).
- For high-volume tables (messages), consider partitioning by date or conversation_id.

Migration

- Recommended: Flyway, Liquibase or use your framework's migration system (e.g., Spring Boot Flyway, Django migrations, Rails migrations).
- Migrations should be idempotent and reversible when possible.
- Keep a migration history table to track applied migrations.

Backups & retention

- Daily full backups, hourly WAL archiving for Postgres in production.
- Retention policy: at minimum 30 days for point-in-time recovery; longer for audit logs if required.

Sample queries

- Get product with images and specs (single query example):

```sql
SELECT p.*, jsonb_agg(pi.*) FILTER (WHERE pi.id IS NOT NULL) AS images,
       jsonb_object_agg(ps.key, ps.value) FILTER (WHERE ps.id IS NOT NULL) AS specifications
FROM products p
LEFT JOIN product_images pi ON pi.product_id = p.id
LEFT JOIN product_specifications ps ON ps.product_id = p.id
WHERE p.id = '...'
GROUP BY p.id;
```

- Get seller products (limit 4):

```sql
SELECT * FROM products WHERE seller_id = 'seller_uuid' ORDER BY created_at DESC LIMIT 4;
```

Security & privacy

- Store password hashes only (bcrypt, Argon2). Never store plain text.
- Protect PII: phone numbers should be masked in responses unless requester is authorized. Consider encrypting sensitive fields using application-layer encryption or DB-level encryption.
- Access control: enforce owner-based checks on products, orders, conversations.

Denormalization & snapshots

- Store price snapshots on order items to preserve historical prices.
- Consider caching frequently-read aggregates (e.g., product rating, total_sales on seller) and keep them updated via application events or DB triggers.

ER Diagram (textual shorthand)

users 1---* favorites *---1 products
sellers 1---* products 1---* product_images
conversations 1---* messages
orders 1---* order_items

Appendix: Postgres utilities

- gen_random_uuid(): provided by `pgcrypto` or `pgcrypto`/`uuid-ossp` depending on setup.
- Use `jsonb` operators for efficient JSON queries.

Migration tips

- Add new columns with defaults in two steps: add nullable column, backfill, then set NOT NULL and default if required.
- Avoid long-running blocking migrations on very large tables (use batching or create new table and swap).

If you want, I can:
- Generate a single migration file set for Postgres implementing the schema above.
- Produce a short README for running migrations locally (Flyway or equivalent).
- Add a small SQL fixtures file with sample data for frontend development.
