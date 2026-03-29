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
