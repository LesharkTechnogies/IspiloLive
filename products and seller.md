reduce screens to this # Seller Setup, Verification, and Product Upload Flow

This document summarizes how seller accounts are created, what parameters are required, how sellers are verified, and how product uploads work in the current system.

## 1. Seller Profile Creation
**Endpoint:** `POST /api/v1/sellers`

### Required Parameters (`CreateSellerRequest`)
```json
{
  "businessName": "Leshar Technologies",
  "businessDescription": "ISP services and networking solutions.",
  "businessAddress": "Nairobi, Kenya"
}  and products md # Product API Endpoints

This document outlines the API endpoints for managing products in the application.

## Base URL

The base URL for all product endpoints is `/api/v1/products`. The API is versioned, and also accessible via `/api/products` and `/api/v2/products`.

---

## Get All Products

-   **Endpoint:** `GET /`
-   **Description:** Retrieves a paginated list of all products.
-   **Query Parameters:**
    -   `page` (optional, default: 0): The page number to retrieve.
    -   `size` (optional, default: 20): The number of products per page.
    -   `category` (optional): Filters products by category.
    -   `sortBy` (optional, e.g., "asc" or "desc" for creation date): Sorts products.
-   **Success Response (200 OK):** `PageResponse<ProductResponse>`

---

## Search Products

-   **Endpoint:** `GET /search`
-   **Description:** Searches for products by a keyword.
-   **Query Parameters:**
    -   `keyword`: The search term.
    -   `page` (optional, default: 0): The page number.
    -   `size` (optional, default: 20): The number of products per page.
-   **Success Response (200 OK):** `PageResponse<ProductResponse>`

---

## Get Product by ID

-   **Endpoint:** `GET /{productId}`
-   **Description:** Retrieves details of a specific product.
-   **Path Parameters:**
    -   `productId`: The ID of the product.
-   **Success Response (200 OK):** `ProductResponse`

---

## Get Products by Seller

-   **Endpoint:** `GET /seller/{sellerId}`
-   **Description:** Retrieves all products listed by a specific seller.
-   **Path Parameters:**
    -   `sellerId`: The ID of the seller.
-   **Query Parameters:**
    -   `page` (optional, default: 0): The page number.
    -   `size` (optional, default: 20): The number of products per page.
-   **Success Response (200 OK):** `PageResponse<ProductResponse>`

---

## Get Products by Category

-   **Endpoint:** `GET /category/{category}`
-   **Description:** Retrieves products belonging to a specific category.
-   **Path Parameters:**
    -   `category`: The name of the category.
-   **Query Parameters:**
    -   `page` (optional, default: 0): The page number.
    -   `size` (optional, default: 20): The number of products per page.
-   **Success Response (200 OK):** `PageResponse<ProductResponse>`

---

## Get Featured Products

-   **Endpoint:** `GET /featured`
-   **Description:** Retrieves a list of featured products.
-   **Query Parameters:**
    -   `page` (optional, default: 0): The page number.
    -   `size` (optional, default: 10): The number of products per page.
-   **Success Response (200 OK):** `PageResponse<ProductResponse>`

---

## Get Trending Products

-   **Endpoint:** `GET /trending`
-   **Description:** Retrieves a list of trending products, sorted by rating.
-   **Query Parameters:**
    -   `page` (optional, default: 0): The page number.
    -   `size` (optional, default: 10): The number of products per page.
-   **Success Response (200 OK):** `PageResponse<ProductResponse>`

---

## Create Product

-   **Endpoint:** `POST /`
-   **Description:** Creates a new product.
-   **Authentication:** `SELLER` role required.
-   **Request Body:** `CreateProductRequest`
-   **Notes:** Upload product images on the frontend and pass **URLs only**.
-   **Success Response (201 Created):** `ProductResponse`

---

## Update Product

-   **Endpoint:** `PUT /{productId}`
-   **Description:** Updates an existing product.
-   **Authentication:** `SELLER` role required (and must be the owner of the product).
-   **Path Parameters:**
    -   `productId`: The ID of the product to update.
-   **Request Body:** `CreateProductRequest`
-   **Notes:** Upload product images on the frontend and pass **URLs only**.
-   **Success Response (200 OK):** `ProductResponse`

---

## Delete Product

-   **Endpoint:** `DELETE /{productId}`
-   **Description:** Deletes a product.
-   **Authentication:** `SELLER` role required (and must be the owner of the product).
-   **Path Parameters:**
    -   `productId`: The ID of the product to delete.
-   **Success Response (204 No Content):**

---

## Add to Favorites

-   **Endpoint:** `POST /{productId}/favorite`
-   **Description:** Adds a product to the user's favorites.
-   **Authentication:** `USER` role required.
-   **Path Parameters:**
    -   `productId`: The ID of the product.
-   **Success Response (200 OK):** `MessageResponse`

---

## Remove from Favorites

-   **Endpoint:** `DELETE /{productId}/favorite`
-   **Description:** Removes a product from the user's favorites.
-   **Authentication:** `USER` role required.
-   **Path Parameters:**
    -   `productId`: The ID of the product.
-   **Success Response (200 OK):** `MessageResponse`

---

## Get All Categories

-   **Endpoint:** `GET /categories`
-   **Description:** Retrieves a list of all product categories.
-   **Success Response (200 OK):** A list of category strings.

---

## Get Complete Product Details

-   **Endpoint:** `GET /{productId}/complete`
-   **Description:** Retrieves product details along with seller information and reviews.
-   **Path Parameters:**
    -   `productId`: The ID of the product.
-   **Success Response (200 OK):** A response object containing the product, seller, and reviews.

---

## Get Product with Seller

-   **Endpoint:** `GET /{productId}/with-seller`
-   **Description:** Retrieves product details along with seller information.
-   **Path Parameters:**
    -   `productId`: The ID of the product.
-   **Success Response (200 OK):** A response object containing the product and seller.

---

## Get Product Reviews

-   **Endpoint:** `GET /{productId}/reviews`
-   **Description:** Retrieves paginated reviews for a product.
-   **Path Parameters:**
    -   `productId`: The ID of the product.
-   **Query Parameters:**
    -   `page` (optional, default: 0): The page number.
    -   `size` (optional, default: 20): The number of reviews per page.
-   **Success Response (200 OK):** `PageResponse<ReviewResponse>`

---

## Add Product Review

-   **Endpoint:** `POST /{productId}/reviews`
-   **Description:** Adds a review to a product.
-   **Authentication:** `USER` role required.
-   **Path Parameters:**
    -   `productId`: The ID of the product.
-   **Request Body:** `AddReviewRequest`
-   **Success Response (201 Created):** `ReviewResponse`

---

```

**Required fields:**
- `businessName`
- `businessDescription`
- `businessAddress`

**Optional fields (not in request; system-managed):**
- `businessLogo` (not set during creation)
- `isVerified` (system-set)
- `rating` (defaults to 4.5)
- `totalSales` (defaults to 0)

### Validation Rules
- `businessName` → required
- `businessDescription` → required, **10–1000 characters**
- `businessAddress` → required

### Logic Flow (Backend)
1. Resolve authenticated user from email/phone.
2. Check if the user already has a seller profile (`existsByUserId`).
3. If already a seller → **409 Conflict**.
4. Create `Seller` with:
  - `businessName`, `businessDescription`, `businessAddress`
  - `isVerified = true` (temporary for presentation)
5. Save seller and return `SellerResponse`.

### Seller Response Fields (`SellerResponse`)
- `id`
- `userId`
- `businessName`
- `businessDescription`
- `businessLogo`
- `businessAddress`
- `isVerified`
- `rating`
- `totalSales`
- `createdAt`
- `updatedAt`

---

## 2. Seller Verification
Seller verification is stored on `Seller.isVerified`. **For the current presentation, new sellers are marked as verified (`true`) at creation.** There is **no API** in the current codebase to verify sellers. This must be set manually in the database or via a future admin endpoint.

**Verification criteria (current implementation):**
- Only the `isVerified` flag controls verification status.
- No documents are uploaded in seller creation.

---

## 3. Product Upload & Seller Linking

### Upload Product Image (Frontend)
Product images are uploaded on the **frontend** to your preferred storage/CDN. The backend only receives image URLs.

### Create Product
**Endpoint:** `POST /api/v1/products`

**Request Body (`CreateProductRequest`)**
```json
{
  "title": "WiFi Router",
  "description": "Dual band 5GHz router",
  "price": 5999.99,
  "stockQuantity": 10,
  "mainImage": "https://...",
  "imageUrl1": "https://...",
  "imageUrl2": "https://...",
  "imageUrl3": "https://...",
  "imageUrl4": "https://...",
  "images": ["https://..."],
  "category": "Networking",
  "condition": "New",
  "location": "Nairobi",
  "sellerId": "optional-for-admin"
}
```

### Product Creation Logic (Backend)
1. Resolve authenticated user from email/phone.
2. If user **is admin** and `sellerId` provided → use that seller.
3. Otherwise, the user **must already be a seller**:
   - Uses `sellerRepository.findByUserId(userId)`
   - If not found → **400 BadRequest** (“User is not a seller. Please register as seller first.”)
4. Validate required product fields (`title`, `price`).
5. Build product images from `mainImage` + up to 4 optional image URLs (and optional `images[]`).
6. If `mainImage` missing → default image URL is used.
7. Save product and return `ProductResponse`.

---

## 4. What Defines a Seller (Current System)
A user becomes a seller **only** when they successfully create a seller profile. There is no role stored yet.

**Current seller criteria:**
- A `Seller` row exists linked to `User.id`
- `sellerRepository.existsByUserId(userId)` returns true
- `isVerified` is purely informational and does not gate product creation

---

## 5. Gaps / Future Enhancements (Not Implemented)
- Assigning `ROLE_SELLER` in user roles is **not implemented**.
- No endpoint to verify sellers or upload verification documents.
- No check to restrict product creation for `isVerified = false` sellers.

If you want, I can add:
- Admin API to verify sellers
- Verification document upload endpoint
- Seller role assignment and enforcement