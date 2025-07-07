-- ==================================================================================
-- MIGRATION 006: Product Management System
-- ==================================================================================
-- Purpose: Comprehensive product and category management system
-- Date: 2025-07-07
-- Dependencies: 001-005 migrations
-- ==================================================================================

-- ==================================================================================
-- TABLES CREATION
-- ==================================================================================

-- Table: pos_mini_modular3_product_categories
CREATE TABLE IF NOT EXISTS pos_mini_modular3_product_categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id UUID NOT NULL REFERENCES pos_mini_modular3_businesses(id) ON DELETE CASCADE,
  parent_id UUID REFERENCES pos_mini_modular3_product_categories(id) ON DELETE SET NULL,
  
  -- Basic Information
  name TEXT NOT NULL CHECK (LENGTH(name) >= 1 AND LENGTH(name) <= 100),
  description TEXT CHECK (LENGTH(description) <= 500),
  display_order INTEGER DEFAULT 0,
  
  -- Visual & UI
  color_code TEXT CHECK (color_code ~ '^#[0-9A-Fa-f]{6}$' OR color_code IS NULL),
  icon_name TEXT CHECK (LENGTH(icon_name) <= 50),
  image_url TEXT,
  
  -- Status & Features
  is_active BOOLEAN DEFAULT true,
  is_featured BOOLEAN DEFAULT false,
  
  -- SEO & Marketing
  slug TEXT,
  meta_title TEXT CHECK (LENGTH(meta_title) <= 160),
  meta_description TEXT CHECK (LENGTH(meta_description) <= 320),
  
  -- Settings
  settings JSONB DEFAULT '{}',
  
  -- Audit Fields
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  created_by UUID REFERENCES pos_mini_modular3_user_profiles(id),
  updated_by UUID REFERENCES pos_mini_modular3_user_profiles(id),
  
  -- Constraints
  CONSTRAINT valid_parent_hierarchy CHECK (parent_id != id),
  UNIQUE(business_id, name),
  UNIQUE(business_id, slug) DEFERRABLE
);

-- Table: pos_mini_modular3_products
CREATE TABLE IF NOT EXISTS pos_mini_modular3_products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id UUID NOT NULL REFERENCES pos_mini_modular3_businesses(id) ON DELETE CASCADE,
  category_id UUID REFERENCES pos_mini_modular3_product_categories(id) ON DELETE SET NULL,
  
  -- Basic Product Information
  name TEXT NOT NULL CHECK (LENGTH(name) >= 1 AND LENGTH(name) <= 200),
  description TEXT CHECK (LENGTH(description) <= 2000),
  short_description TEXT CHECK (LENGTH(short_description) <= 500),
  
  -- Product Codes & Identifiers
  sku TEXT CHECK (LENGTH(sku) <= 50),
  barcode TEXT CHECK (LENGTH(barcode) <= 100),
  internal_code TEXT CHECK (LENGTH(internal_code) <= 50),
  
  -- Pricing
  unit_price DECIMAL(15,2) DEFAULT 0 CHECK (unit_price >= 0),
  cost_price DECIMAL(15,2) DEFAULT 0 CHECK (cost_price >= 0),
  sale_price DECIMAL(15,2) CHECK (sale_price >= 0),
  min_price DECIMAL(15,2) DEFAULT 0 CHECK (min_price >= 0),
  max_discount_percent DECIMAL(5,2) DEFAULT 0 CHECK (max_discount_percent >= 0 AND max_discount_percent <= 100),
  
  -- Stock Management
  current_stock INTEGER DEFAULT 0 CHECK (current_stock >= 0),
  min_stock_level INTEGER DEFAULT 0 CHECK (min_stock_level >= 0),
  max_stock_level INTEGER CHECK (max_stock_level >= min_stock_level),
  reorder_point INTEGER DEFAULT 0 CHECK (reorder_point >= 0),
  
  -- Units & Measurements
  unit_of_measure TEXT DEFAULT 'piece' CHECK (LENGTH(unit_of_measure) <= 20),
  weight DECIMAL(10,3) CHECK (weight >= 0),
  weight_unit TEXT DEFAULT 'kg' CHECK (weight_unit IN ('g', 'kg', 'lb', 'oz')),
  dimensions JSONB, -- {length, width, height, unit}
  
  -- Product Attributes
  brand TEXT CHECK (LENGTH(brand) <= 100),
  manufacturer TEXT CHECK (LENGTH(manufacturer) <= 100),
  origin_country TEXT CHECK (LENGTH(origin_country) <= 50),
  
  -- Tax & Legal
  tax_rate DECIMAL(5,2) DEFAULT 0 CHECK (tax_rate >= 0 AND tax_rate <= 100),
  tax_category TEXT DEFAULT 'standard',
  
  -- Status & Features
  is_active BOOLEAN DEFAULT true,
  is_featured BOOLEAN DEFAULT false,
  is_digital BOOLEAN DEFAULT false,
  has_variants BOOLEAN DEFAULT false,
  track_stock BOOLEAN DEFAULT true,
  allow_backorder BOOLEAN DEFAULT false,
  
  -- Sales & Marketing
  tags TEXT[], -- Array of tags for filtering
  display_order INTEGER DEFAULT 0,
  
  -- SEO & Web
  slug TEXT,
  meta_title TEXT CHECK (LENGTH(meta_title) <= 160),
  meta_description TEXT CHECK (LENGTH(meta_description) <= 320),
  
  -- Media
  images JSONB DEFAULT '[]', -- Array of image URLs
  primary_image TEXT,
  
  -- Additional Data
  specifications JSONB DEFAULT '{}', -- Product specifications
  attributes JSONB DEFAULT '{}', -- Custom attributes
  settings JSONB DEFAULT '{}', -- Product-specific settings
  
  -- Analytics
  view_count INTEGER DEFAULT 0,
  sale_count INTEGER DEFAULT 0,
  last_sold_at TIMESTAMPTZ,
  
  -- Audit Fields
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  created_by UUID REFERENCES pos_mini_modular3_user_profiles(id),
  updated_by UUID REFERENCES pos_mini_modular3_user_profiles(id),
  
  -- Constraints
  UNIQUE(business_id, sku) DEFERRABLE,
  UNIQUE(business_id, barcode) DEFERRABLE,
  UNIQUE(business_id, slug) DEFERRABLE
);

-- Table: pos_mini_modular3_product_variants
CREATE TABLE IF NOT EXISTS pos_mini_modular3_product_variants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id UUID NOT NULL REFERENCES pos_mini_modular3_products(id) ON DELETE CASCADE,
  business_id UUID NOT NULL REFERENCES pos_mini_modular3_businesses(id) ON DELETE CASCADE,
  
  -- Variant Information
  name TEXT NOT NULL CHECK (LENGTH(name) >= 1 AND LENGTH(name) <= 200),
  sku TEXT CHECK (LENGTH(sku) <= 50),
  barcode TEXT CHECK (LENGTH(barcode) <= 100),
  
  -- Variant Attributes
  attributes JSONB NOT NULL DEFAULT '{}', -- e.g., {"size": "M", "color": "Red"}
  
  -- Pricing (overrides product pricing if set)
  unit_price DECIMAL(15,2) CHECK (unit_price >= 0),
  cost_price DECIMAL(15,2) CHECK (cost_price >= 0),
  sale_price DECIMAL(15,2) CHECK (sale_price >= 0),
  
  -- Stock
  current_stock INTEGER DEFAULT 0 CHECK (current_stock >= 0),
  min_stock_level INTEGER DEFAULT 0 CHECK (min_stock_level >= 0),
  reorder_point INTEGER DEFAULT 0 CHECK (reorder_point >= 0),
  
  -- Physical Properties
  weight DECIMAL(10,3) CHECK (weight >= 0),
  dimensions JSONB,
  
  -- Media
  image_url TEXT,
  
  -- Status
  is_active BOOLEAN DEFAULT true,
  display_order INTEGER DEFAULT 0,
  
  -- Audit Fields
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- Constraints
  UNIQUE(business_id, sku) DEFERRABLE,
  UNIQUE(business_id, barcode) DEFERRABLE,
  UNIQUE(product_id, attributes) -- Prevent duplicate attribute combinations
);

-- Table: pos_mini_modular3_product_images
CREATE TABLE IF NOT EXISTS pos_mini_modular3_product_images (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id UUID REFERENCES pos_mini_modular3_products(id) ON DELETE CASCADE,
  variant_id UUID REFERENCES pos_mini_modular3_product_variants(id) ON DELETE CASCADE,
  business_id UUID NOT NULL REFERENCES pos_mini_modular3_businesses(id) ON DELETE CASCADE,
  
  -- Image Information
  url TEXT NOT NULL,
  filename TEXT,
  original_filename TEXT,
  alt_text TEXT CHECK (LENGTH(alt_text) <= 200),
  
  -- Image Properties
  size_bytes INTEGER CHECK (size_bytes > 0),
  width INTEGER CHECK (width > 0),
  height INTEGER CHECK (height > 0),
  format TEXT CHECK (format IN ('jpg', 'jpeg', 'png', 'webp', 'gif')),
  
  -- Status & Order
  is_primary BOOLEAN DEFAULT false,
  display_order INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  
  -- Audit Fields
  created_at TIMESTAMPTZ DEFAULT NOW(),
  uploaded_by UUID REFERENCES pos_mini_modular3_user_profiles(id),
  
  -- Constraints
  CHECK ((product_id IS NOT NULL AND variant_id IS NULL) OR (product_id IS NULL AND variant_id IS NOT NULL))
);

-- ==================================================================================
-- INDEXES FOR PERFORMANCE
-- ==================================================================================

-- Categories Indexes
CREATE INDEX IF NOT EXISTS idx_categories_business_id ON pos_mini_modular3_product_categories(business_id);
CREATE INDEX IF NOT EXISTS idx_categories_parent_id ON pos_mini_modular3_product_categories(parent_id);
CREATE INDEX IF NOT EXISTS idx_categories_active ON pos_mini_modular3_product_categories(business_id, is_active);
CREATE INDEX IF NOT EXISTS idx_categories_featured ON pos_mini_modular3_product_categories(business_id, is_featured);
CREATE INDEX IF NOT EXISTS idx_categories_display_order ON pos_mini_modular3_product_categories(business_id, display_order);

-- Products Indexes
CREATE INDEX IF NOT EXISTS idx_products_business_id ON pos_mini_modular3_products(business_id);
CREATE INDEX IF NOT EXISTS idx_products_category_id ON pos_mini_modular3_products(category_id);
CREATE INDEX IF NOT EXISTS idx_products_active ON pos_mini_modular3_products(business_id, is_active);
CREATE INDEX IF NOT EXISTS idx_products_featured ON pos_mini_modular3_products(business_id, is_featured);
CREATE INDEX IF NOT EXISTS idx_products_stock_low ON pos_mini_modular3_products(business_id, current_stock, min_stock_level) WHERE track_stock = true;
CREATE INDEX IF NOT EXISTS idx_products_price_range ON pos_mini_modular3_products(business_id, unit_price) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_products_sku ON pos_mini_modular3_products(business_id, sku) WHERE sku IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_products_barcode ON pos_mini_modular3_products(business_id, barcode) WHERE barcode IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_products_name_search ON pos_mini_modular3_products USING gin(to_tsvector('english', name));
CREATE INDEX IF NOT EXISTS idx_products_tags ON pos_mini_modular3_products USING gin(tags);

-- Variants Indexes
CREATE INDEX IF NOT EXISTS idx_variants_product_id ON pos_mini_modular3_product_variants(product_id);
CREATE INDEX IF NOT EXISTS idx_variants_business_id ON pos_mini_modular3_product_variants(business_id);
CREATE INDEX IF NOT EXISTS idx_variants_active ON pos_mini_modular3_product_variants(product_id, is_active);
CREATE INDEX IF NOT EXISTS idx_variants_sku ON pos_mini_modular3_product_variants(business_id, sku) WHERE sku IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_variants_attributes ON pos_mini_modular3_product_variants USING gin(attributes);

-- Images Indexes
CREATE INDEX IF NOT EXISTS idx_images_product_id ON pos_mini_modular3_product_images(product_id);
CREATE INDEX IF NOT EXISTS idx_images_variant_id ON pos_mini_modular3_product_images(variant_id);
CREATE INDEX IF NOT EXISTS idx_images_business_id ON pos_mini_modular3_product_images(business_id);
CREATE INDEX IF NOT EXISTS idx_images_primary ON pos_mini_modular3_product_images(product_id, is_primary) WHERE is_primary = true;

-- ==================================================================================
-- TRIGGERS FOR AUTO-UPDATE
-- ==================================================================================

-- Auto-update timestamps for categories
CREATE OR REPLACE FUNCTION pos_mini_modular3_update_category_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_category_timestamp
  BEFORE UPDATE ON pos_mini_modular3_product_categories
  FOR EACH ROW
  EXECUTE FUNCTION pos_mini_modular3_update_category_timestamp();

-- Auto-update timestamps for products
CREATE OR REPLACE FUNCTION pos_mini_modular3_update_product_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_product_timestamp
  BEFORE UPDATE ON pos_mini_modular3_products
  FOR EACH ROW
  EXECUTE FUNCTION pos_mini_modular3_update_product_timestamp();

-- Auto-update timestamps for variants
CREATE OR REPLACE FUNCTION pos_mini_modular3_update_variant_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_variant_timestamp
  BEFORE UPDATE ON pos_mini_modular3_product_variants
  FOR EACH ROW
  EXECUTE FUNCTION pos_mini_modular3_update_variant_timestamp();

-- ==================================================================================
-- ROW LEVEL SECURITY (RLS)
-- ==================================================================================

-- Enable RLS for all tables
ALTER TABLE pos_mini_modular3_product_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE pos_mini_modular3_products ENABLE ROW LEVEL SECURITY;
ALTER TABLE pos_mini_modular3_product_variants ENABLE ROW LEVEL SECURITY;
ALTER TABLE pos_mini_modular3_product_images ENABLE ROW LEVEL SECURITY;

-- Categories RLS Policies
CREATE POLICY categories_business_isolation ON pos_mini_modular3_product_categories
  FOR ALL TO authenticated
  USING (
    business_id = pos_mini_modular3_current_user_business_id()
    OR EXISTS (
      SELECT 1 FROM pos_mini_modular3_user_profiles 
      WHERE id = auth.uid() AND role = 'super_admin'
    )
  );

-- Products RLS Policies
CREATE POLICY products_business_isolation ON pos_mini_modular3_products
  FOR ALL TO authenticated
  USING (
    business_id = pos_mini_modular3_current_user_business_id()
    OR EXISTS (
      SELECT 1 FROM pos_mini_modular3_user_profiles 
      WHERE id = auth.uid() AND role = 'super_admin'
    )
  );

-- Variants RLS Policies
CREATE POLICY variants_business_isolation ON pos_mini_modular3_product_variants
  FOR ALL TO authenticated
  USING (
    business_id = pos_mini_modular3_current_user_business_id()
    OR EXISTS (
      SELECT 1 FROM pos_mini_modular3_user_profiles 
      WHERE id = auth.uid() AND role = 'super_admin'
    )
  );

-- Images RLS Policies
CREATE POLICY images_business_isolation ON pos_mini_modular3_product_images
  FOR ALL TO authenticated
  USING (
    business_id = pos_mini_modular3_current_user_business_id()
    OR EXISTS (
      SELECT 1 FROM pos_mini_modular3_user_profiles 
      WHERE id = auth.uid() AND role = 'super_admin'
    )
  );

-- ==================================================================================
-- COMMENTS FOR DOCUMENTATION
-- ==================================================================================

COMMENT ON TABLE pos_mini_modular3_product_categories IS 'Product categories with hierarchical support and business isolation';
COMMENT ON TABLE pos_mini_modular3_products IS 'Main products table with comprehensive inventory and pricing management';
COMMENT ON TABLE pos_mini_modular3_product_variants IS 'Product variants for products with multiple options (size, color, etc.)';
COMMENT ON TABLE pos_mini_modular3_product_images IS 'Product and variant images with metadata';

-- Column Comments for Categories
COMMENT ON COLUMN pos_mini_modular3_product_categories.parent_id IS 'Self-reference for hierarchical categories';
COMMENT ON COLUMN pos_mini_modular3_product_categories.slug IS 'URL-friendly identifier for web/API';
COMMENT ON COLUMN pos_mini_modular3_product_categories.color_code IS 'Hex color code for UI theming';
COMMENT ON COLUMN pos_mini_modular3_product_categories.settings IS 'Category-specific settings in JSON format';

-- Column Comments for Products
COMMENT ON COLUMN pos_mini_modular3_products.sku IS 'Stock Keeping Unit - unique within business';
COMMENT ON COLUMN pos_mini_modular3_products.dimensions IS 'Product dimensions: {length, width, height, unit}';
COMMENT ON COLUMN pos_mini_modular3_products.tags IS 'Array of text tags for filtering and search';
COMMENT ON COLUMN pos_mini_modular3_products.specifications IS 'Technical specifications in JSON format';
COMMENT ON COLUMN pos_mini_modular3_products.attributes IS 'Custom product attributes';
COMMENT ON COLUMN pos_mini_modular3_products.track_stock IS 'Whether to track inventory for this product';

-- Column Comments for Variants
COMMENT ON COLUMN pos_mini_modular3_product_variants.attributes IS 'Variant attributes like {"size": "M", "color": "Red"}';

-- ==================================================================================
-- END OF MIGRATION
-- ==================================================================================
