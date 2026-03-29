/// Marketplace product data with relationships
/// Contains all products with their related products and metadata
class MarketplaceData {
  // All available products in the marketplace
  static final List<Map<String, dynamic>> allProducts = [
    {
      "id": "PRD-001",
      "title": "TP-Link TL-SF1005D 5-Port Switch",
      "price": "KSh 800",
      "image":
          "https://media.istockphoto.com/id/2193068003/photo/man-with-smartphone-and-laptop-connecting-to-internet-via-wi-fi-router-at-wooden-table-closeup.jpg?s=1024x1024&w=is&k=20&c=prqBMs1sGUEDuiz1BafuN_owlMwvFhYnQaN_wxO6JHg=",
      "category": "Hardware",
      "rating": 4.8,
      "location": "Nairobi, Kenya",
      "seller": "TechNet Solutions",
      "condition": "New",
      "description":
          "Basic unmanaged 5-port 10/100 switch. Perfect for small home or office networks.",
      "relatedProducts": ["PRD-002", "PRD-003", "PRD-008"],
    },
    {
      "id": "PRD-002",
      "title": "D-Link DGS-108 8-Port Gigabit Switch",
      "price": "KSh 3,500",
      "image":
          "https://images.unsplash.com/photo-1606904825846-647eb07f5be2?fm=jpg&q=60&w=3000&ixlib=rb-4.0.3",
      "category": "Hardware",
      "rating": 4.6,
      "location": "Mombasa, Kenya",
      "seller": "Network Pro",
      "condition": "New",
      "description": "8-port Gigabit unmanaged switch with energy-efficient design",
      "relatedProducts": ["PRD-001", "PRD-003", "PRD-008"],
    },
    {
      "id": "PRD-003",
      "title": "TP-Link TL-SF1024D 24-Port Switch",
      "price": "KSh 4,500",
      "image":
          "https://images.unsplash.com/photo-1558618666-fcd25c85cd64?fm=jpg&q=60&w=3000&ixlib=rb-4.0.3",
      "category": "Hardware",
      "rating": 4.4,
      "location": "Kisumu, Kenya",
      "seller": "ISP Tools Inc",
      "condition": "New",
      "description": "24-port Fast Ethernet switch for medium-sized networks",
      "relatedProducts": ["PRD-002", "PRD-008", "PRD-001"],
    },
    {
      "id": "PRD-004",
      "title": "TP-Link TL-WA850RE WiFi Extender",
      "price": "KSh 3,500",
      "image":
          "https://images.unsplash.com/photo-1606904825846-647eb07f5be2?fm=jpg&q=60&w=3000&ixlib=rb-4.0.3",
      "category": "Hardware",
      "rating": 4.9,
      "location": "Nakuru, Kenya",
      "seller": "WiFi Solutions",
      "condition": "New",
      "description": "Wireless range extender to boost WiFi coverage in your home or office",
      "relatedProducts": ["PRD-005", "PRD-006", "PRD-009"],
    },
    {
      "id": "PRD-005",
      "title": "Pix-link WiFi Extender Booster",
      "price": "KSh 2,999",
      "image":
          "https://images.unsplash.com/photo-1606904825846-647eb07f5be2?fm=jpg&q=60&w=3000&ixlib=rb-4.0.3",
      "category": "Hardware",
      "rating": 4.7,
      "location": "Eldoret, Kenya",
      "seller": "Wireless Pro",
      "condition": "New",
      "description": "Simple wireless repeater for extending WiFi coverage",
      "relatedProducts": ["PRD-004", "PRD-006", "PRD-007"],
    },
    {
      "id": "PRD-006",
      "title": "MikroTik wAP Weatherproof Access Point",
      "price": "KSh 4,500",
      "image":
          "https://images.unsplash.com/photo-1606904825846-647eb07f5be2?fm=jpg&q=60&w=3000&ixlib=rb-4.0.3",
      "category": "Hardware",
      "rating": 4.5,
      "location": "Thika, Kenya",
      "seller": "MikroTik Kenya",
      "condition": "New",
      "description": "Outdoor/garden weatherproof access point for harsh environments",
      "relatedProducts": ["PRD-007", "PRD-012", "PRD-013"],
    },
    {
      "id": "PRD-007",
      "title": "Mikrotik hAP Access Point",
      "price": "KSh 5,000",
      "image":
          "https://images.unsplash.com/photo-1606904825846-647eb07f5be2?fm=jpg&q=60&w=3000&ixlib=rb-4.0.3",
      "category": "Hardware",
      "rating": 4.3,
      "location": "Kiambu, Kenya",
      "seller": "RouterBoard Kenya",
      "condition": "New",
      "description": "Small home AP with 5 Ethernet ports and built-in wireless",
      "relatedProducts": ["PRD-006", "PRD-011", "PRD-012"],
    },
    {
      "id": "PRD-008",
      "title": "Mikrotik RB260GSP PoE Smart Switch",
      "price": "KSh 6,500",
      "image":
          "https://images.unsplash.com/photo-1558618666-fcd25c85cd64?fm=jpg&q=60&w=3000&ixlib=rb-4.0.3",
      "category": "Hardware",
      "rating": 4.8,
      "location": "Nairobi, Kenya",
      "seller": "PoE Solutions Kenya",
      "condition": "New",
      "description": "Smart switch with PoE output on ports for powering access points and cameras",
      "relatedProducts": ["PRD-002", "PRD-003", "PRD-006"],
    },
    {
      "id": "PRD-009",
      "title": "TP-Link Archer AX23 WiFi 6 Router",
      "price": "KSh 6,500",
      "image":
          "https://images.unsplash.com/photo-1606904825846-647eb07f5be2?fm=jpg&q=60&w=3000&ixlib=rb-4.0.3",
      "category": "Hardware",
      "rating": 4.4,
      "location": "Mombasa, Kenya",
      "seller": "Next-Gen Networks",
      "condition": "New",
      "description": "Dual-band WiFi 6 router with faster speeds and better capacity",
      "relatedProducts": ["PRD-010", "PRD-011", "PRD-004"],
    },
    {
      "id": "PRD-010",
      "title": "Tenda N301 Wireless N Router",
      "price": "KSh 1,100",
      "image":
          "https://media.istockphoto.com/id/2193068003/photo/man-with-smartphone-and-laptop-connecting-to-internet-via-wi-fi-router-at-wooden-table-closeup.jpg?s=1024x1024&w=is&k=20&c=prqBMs1sGUEDuiz1BafuN_owlMwvFhYnQaN_wxO6JHg=",
      "category": "Hardware",
      "rating": 4.7,
      "location": "Kisumu, Kenya",
      "seller": "Budget Networks",
      "condition": "New",
      "description": "Entry-level wireless N router for basic home internet needs",
      "relatedProducts": ["PRD-009", "PRD-011", "PRD-004"],
    },
    {
      "id": "PRD-011",
      "title": "Mikrotik RB750GR3 hEX Router",
      "price": "KSh 7,000",
      "image":
          "https://images.unsplash.com/photo-1558618666-fcd25c85cd64?fm=jpg&q=60&w=3000&ixlib=rb-4.0.3",
      "category": "Hardware",
      "rating": 4.2,
      "location": "Nakuru, Kenya",
      "seller": "MikroTik Distributors",
      "condition": "New",
      "description": "Wired Gigabit router (no WiFi) with advanced routing features",
      "relatedProducts": ["PRD-007", "PRD-009", "PRD-012"],
    },
    {
      "id": "PRD-012",
      "title": "Ubiquiti airMAX LiteBeam M5",
      "price": "KSh 6,500",
      "image":
          "https://images.unsplash.com/photo-1563986768609-322da13575f3?fm=jpg&q=60&w=3000&ixlib=rb-4.0.3",
      "category": "Hardware",
      "rating": 4.6,
      "location": "Eldoret, Kenya",
      "seller": "Ubiquiti Kenya",
      "condition": "New",
      "description": "Outdoor directional CPE for point-to-point wireless links",
      "relatedProducts": ["PRD-013", "PRD-006", "PRD-007"],
    },
    {
      "id": "PRD-013",
      "title": "Ubiquiti NanoStation M2",
      "price": "KSh 10,500",
      "image":
          "https://images.unsplash.com/photo-1563986768609-322da13575f3?fm=jpg&q=60&w=3000&ixlib=rb-4.0.3",
      "category": "Hardware",
      "rating": 4.5,
      "location": "Thika, Kenya",
      "seller": "Wireless Links Kenya",
      "condition": "New",
      "description": "Outdoor CPE for 2.4 GHz long-distance wireless connections",
      "relatedProducts": ["PRD-012", "PRD-006", "PRD-018"],
    },
    {
      "id": "PRD-014",
      "title": "4G LTE USB Modem Dongle",
      "price": "KSh 2,500",
      "image":
          "https://images.unsplash.com/photo-1581092160562-40aa08e78837?fm=jpg&q=60&w=3000&ixlib=rb-4.0.3",
      "category": "Hardware",
      "rating": 4.8,
      "location": "Nairobi, Kenya",
      "seller": "Mobile Broadband Co",
      "condition": "New",
      "description": "USB dongle for mobile 4G LTE broadband connectivity",
      "relatedProducts": ["PRD-015", "PRD-016", "PRD-009"],
    },
    {
      "id": "PRD-015",
      "title": "Network Cable Installation Service",
      "price": "KSh 500/point",
      "image":
          "https://images.unsplash.com/photo-1558618666-fcd25c85cd64?fm=jpg&q=60&w=3000&ixlib=rb-4.0.3",
      "category": "Services",
      "rating": 4.6,
      "location": "Nairobi, Kenya",
      "seller": "Cable Masters",
      "condition": "Service",
      "description": "Professional network cabling and infrastructure installation",
      "relatedProducts": ["PRD-016", "PRD-017", "PRD-003"],
    },
    {
      "id": "PRD-016",
      "title": "WiFi Site Survey & Planning",
      "price": "KSh 15,000",
      "image":
          "https://images.unsplash.com/photo-1563986768609-322da13575f3?fm=jpg&q=60&w=3000&ixlib=rb-4.0.3",
      "category": "Services",
      "rating": 4.9,
      "location": "Nairobi, Kenya",
      "seller": "WiFi Consultants",
      "condition": "Service",
      "description": "Professional WiFi site survey and network planning service",
      "relatedProducts": ["PRD-015", "PRD-017", "PRD-006"],
    },
    {
      "id": "PRD-017",
      "title": "ISP Network Setup & Configuration",
      "price": "KSh 25,000",
      "image":
          "https://images.unsplash.com/photo-1551288049-bebda4e38f71?fm=jpg&q=60&w=3000&ixlib=rb-4.0.3",
      "category": "Services",
      "rating": 4.4,
      "location": "Mombasa, Kenya",
      "seller": "ISP Solutions Kenya",
      "condition": "Service",
      "description": "Complete ISP network setup and configuration service",
      "relatedProducts": ["PRD-015", "PRD-016", "PRD-020"],
    },
    {
      "id": "PRD-018",
      "title": "Outdoor Antenna Installation",
      "price": "KSh 8,000",
      "image":
          "https://images.unsplash.com/photo-1563986768609-322da13575f3?fm=jpg&q=60&w=3000&ixlib=rb-4.0.3",
      "category": "Services",
      "rating": 4.9,
      "location": "Kisumu, Kenya",
      "seller": "Antenna Experts",
      "condition": "Service",
      "description": "Professional outdoor antenna and CPE installation service",
      "relatedProducts": ["PRD-012", "PRD-013", "PRD-016"],
    },
    {
      "id": "PRD-019",
      "title": "Cat6 UTP Cable (305m Box)",
      "price": "KSh 12,500",
      "image":
          "https://images.unsplash.com/photo-1558618666-fcd25c85cd64?fm=jpg&q=60&w=3000&ixlib=rb-4.0.3",
      "category": "Tools",
      "rating": 4.7,
      "location": "Nairobi, Kenya",
      "seller": "Cable Supplies Kenya",
      "condition": "New",
      "description": "305-meter box of Cat6 UTP network cable for structured cabling",
      "relatedProducts": ["PRD-020", "PRD-015", "PRD-003"],
    },
    {
      "id": "PRD-020",
      "title": "Cisco Nexus C93180YC-EX Switch",
      "price": "KSh 380,000",
      "image":
          "https://images.unsplash.com/photo-1558618666-fcd25c85cd64?fm=jpg&q=60&w=3000&ixlib=rb-4.0.3",
      "category": "Hardware",
      "rating": 4.9,
      "location": "Nairobi, Kenya",
      "seller": "Enterprise Networks",
      "condition": "New",
      "description": "High-end data center class switch with advanced features for enterprise deployments",
      "relatedProducts": ["PRD-008", "PRD-003", "PRD-011"],
    },
  ];

  /// Get product by ID
  static Map<String, dynamic>? getProductById(String productId) {
    try {
      return allProducts.firstWhere((product) => product['id'] == productId);
    } catch (e) {
      return null;
    }
  }

  /// Get related products for a given product ID
  static List<Map<String, dynamic>> getRelatedProducts(String productId) {
    final product = getProductById(productId);
    if (product == null) return [];

    final relatedIds = product['relatedProducts'] as List<String>? ?? [];
    return relatedIds
        .map((id) => getProductById(id))
        .where((p) => p != null)
        .cast<Map<String, dynamic>>()
        .toList();
  }

  /// Get products by category
  static List<Map<String, dynamic>> getProductsByCategory(String category) {
    if (category == 'All Categories') return allProducts;
    return allProducts
        .where((product) => product['category'] == category)
        .toList();
  }

  /// Get products by seller
  static List<Map<String, dynamic>> getProductsBySeller(String seller) {
    return allProducts
        .where((product) => product['seller'] == seller)
        .toList();
  }

  /// Search products
  static List<Map<String, dynamic>> searchProducts(String query) {
    if (query.isEmpty) return allProducts;
    final lowerQuery = query.toLowerCase();
    return allProducts.where((product) {
      return (product['title'] as String).toLowerCase().contains(lowerQuery) ||
          (product['category'] as String).toLowerCase().contains(lowerQuery) ||
          (product['description'] as String).toLowerCase().contains(lowerQuery);
    }).toList();
  }
}
