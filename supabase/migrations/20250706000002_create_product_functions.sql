-- ==================================================================================
-- PRODUCT MANAGEMENT FUNCTIONS - POS MINI MODULAR 3
-- ==================================================================================
-- Description: Database functions for product and category management
-- Version: 1.0.0
-- Date: 2025-07-06
-- ==================================================================================

-- ==================================================================================
-- CATEGORY MANAGEMENT FUNCTIONS
-- ==================================================================================

-- Function: Create a new product category
CREATE OR REPLACE FUNCTION pos_mini_modular3_create_category(
  p_name TEXT,
  p_description TEXT DEFAULT NULL,
  p_parent_id UUID DEFAULT NULL,
  p_color_code TEXT DEFAULT NULL,
  p_icon_name TEXT DEFAULT NULL,
  p_image_url TEXT DEFAULT NULL,
  p_is_featured BOOLEAN DEFAULT false,
  p_display_order INTEGER DEFAULT 0
) RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
  current_user_id UUID;
  current_business_id UUID;
  new_category_id UUID;
  category_slug TEXT;
  result jsonb;
BEGIN
  -- Get current user and business
  current_user_id := auth.uid();
  current_business_id := pos_mini_modular3_current_user_business_id();
  
  -- Validate user permission
  IF NOT pos_mini_modular3_can_access_user_profile(current_user_id) THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'Không có quyền truy cập'
    );
  END IF;
  
  -- Validate required fields
  IF p_name IS NULL OR trim(p_name) = '' THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'Tên danh mục không được để trống'
    );
  END IF;
  
  -- Generate slug from name
  category_slug := lower(regexp_replace(trim(p_name), '[^a-zA-Z0-9\s]', '', 'g'));
  category_slug := regexp_replace(category_slug, '\s+', '-', 'g');
  
  -- Validate parent category exists if provided
  IF p_parent_id IS NOT NULL THEN
    IF NOT EXISTS (
      SELECT 1 FROM pos_mini_modular3_product_categories 
      WHERE id = p_parent_id AND business_id = current_business_id
    ) THEN
      RETURN jsonb_build_object(
        'success', false,
        'error', 'Danh mục cha không tồn tại'
      );
    END IF;
  END IF;
  
  -- Check if category name already exists in business
  IF EXISTS (
    SELECT 1 FROM pos_mini_modular3_product_categories 
    WHERE business_id = current_business_id AND name = trim(p_name)
  ) THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'Tên danh mục đã tồn tại'
    );
  END IF;
  
  -- Insert new category
  INSERT INTO pos_mini_modular3_product_categories (
    business_id,
    parent_id,
    name,
    description,
    slug,
    color_code,
    icon_name,
    image_url,
    is_featured,
    display_order,
    created_by,
    updated_by
  ) VALUES (
    current_business_id,
    p_parent_id,
    trim(p_name),
    p_description,
    category_slug,
    p_color_code,
    p_icon_name,
    p_image_url,
    p_is_featured,
    p_display_order,
    current_user_id,
    current_user_id
  ) RETURNING id INTO new_category_id;
  
  -- Return success result
  result := jsonb_build_object(
    'success', true,
    'message', 'Danh mục đã được tạo thành công',
    'category_id', new_category_id,
    'slug', category_slug
  );
  
  RETURN result;

EXCEPTION WHEN OTHERS THEN
  RETURN jsonb_build_object(
    'success', false,
    'error', 'Lỗi hệ thống: ' || SQLERRM
  );
END;
$$;

-- Function: Update product category
CREATE OR REPLACE FUNCTION pos_mini_modular3_update_category(
  p_category_id UUID,
  p_name TEXT DEFAULT NULL,
  p_description TEXT DEFAULT NULL,
  p_parent_id UUID DEFAULT NULL,
  p_color_code TEXT DEFAULT NULL,
  p_icon_name TEXT DEFAULT NULL,
  p_image_url TEXT DEFAULT NULL,
  p_is_featured BOOLEAN DEFAULT NULL,
  p_is_active BOOLEAN DEFAULT NULL,
  p_display_order INTEGER DEFAULT NULL
) RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
  current_user_id UUID;
  current_business_id UUID;
  category_record RECORD;
  new_slug TEXT;
  result jsonb;
BEGIN
  -- Get current user and business
  current_user_id := auth.uid();
  current_business_id := pos_mini_modular3_current_user_business_id();
  
  -- Validate user permission
  IF NOT pos_mini_modular3_can_access_user_profile(current_user_id) THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'Không có quyền truy cập'
    );
  END IF;
  
  -- Check if category exists and belongs to current business
  SELECT * INTO category_record
  FROM pos_mini_modular3_product_categories
  WHERE id = p_category_id AND business_id = current_business_id;
  
  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'Danh mục không tồn tại'
    );
  END IF;
  
  -- Validate parent category if provided
  IF p_parent_id IS NOT NULL AND p_parent_id != category_record.parent_id THEN
    -- Prevent circular reference
    IF p_parent_id = p_category_id THEN
      RETURN jsonb_build_object(
        'success', false,
        'error', 'Không thể chọn chính danh mục này làm danh mục cha'
      );
    END IF;
    
    -- Check if parent exists
    IF NOT EXISTS (
      SELECT 1 FROM pos_mini_modular3_product_categories 
      WHERE id = p_parent_id AND business_id = current_business_id
    ) THEN
      RETURN jsonb_build_object(
        'success', false,
        'error', 'Danh mục cha không tồn tại'
      );
    END IF;
  END IF;
  
  -- Generate new slug if name is updated
  IF p_name IS NOT NULL AND trim(p_name) != category_record.name THEN
    new_slug := lower(regexp_replace(trim(p_name), '[^a-zA-Z0-9\s]', '', 'g'));
    new_slug := regexp_replace(new_slug, '\s+', '-', 'g');
    
    -- Check if new name already exists
    IF EXISTS (
      SELECT 1 FROM pos_mini_modular3_product_categories 
      WHERE business_id = current_business_id 
        AND name = trim(p_name) 
        AND id != p_category_id
    ) THEN
      RETURN jsonb_build_object(
        'success', false,
        'error', 'Tên danh mục đã tồn tại'
      );
    END IF;
  ELSE
    new_slug := category_record.slug;
  END IF;
  
  -- Update category
  UPDATE pos_mini_modular3_product_categories SET
    name = COALESCE(trim(p_name), name),
    description = COALESCE(p_description, description),
    parent_id = COALESCE(p_parent_id, parent_id),
    slug = new_slug,
    color_code = COALESCE(p_color_code, color_code),
    icon_name = COALESCE(p_icon_name, icon_name),
    image_url = COALESCE(p_image_url, image_url),
    is_featured = COALESCE(p_is_featured, is_featured),
    is_active = COALESCE(p_is_active, is_active),
    display_order = COALESCE(p_display_order, display_order),
    updated_by = current_user_id
  WHERE id = p_category_id;
  
  -- Return success result
  result := jsonb_build_object(
    'success', true,
    'message', 'Danh mục đã được cập nhật thành công',
    'category_id', p_category_id
  );
  
  RETURN result;

EXCEPTION WHEN OTHERS THEN
  RETURN jsonb_build_object(
    'success', false,
    'error', 'Lỗi hệ thống: ' || SQLERRM
  );
END;
$$;

-- Function: Get category hierarchy
CREATE OR REPLACE FUNCTION pos_mini_modular3_get_category_tree(
  p_parent_id UUID DEFAULT NULL
) RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
  current_business_id UUID;
  result jsonb;
BEGIN
  current_business_id := pos_mini_modular3_current_user_business_id();
  
  WITH RECURSIVE category_tree AS (
    -- Base case: categories with specified parent_id (or root categories if NULL)
    SELECT 
      id, name, description, parent_id, slug, color_code, icon_name, 
      image_url, is_active, is_featured, display_order, created_at,
      ARRAY[display_order, id::text] as sort_path,
      0 as level
    FROM pos_mini_modular3_product_categories
    WHERE business_id = current_business_id 
      AND parent_id IS NOT DISTINCT FROM p_parent_id
      AND is_active = true
    
    UNION ALL
    
    -- Recursive case: child categories
    SELECT 
      c.id, c.name, c.description, c.parent_id, c.slug, c.color_code, c.icon_name,
      c.image_url, c.is_active, c.is_featured, c.display_order, c.created_at,
      ct.sort_path || ARRAY[c.display_order, c.id::text],
      ct.level + 1
    FROM pos_mini_modular3_product_categories c
    INNER JOIN category_tree ct ON c.parent_id = ct.id
    WHERE c.business_id = current_business_id 
      AND c.is_active = true
      AND ct.level < 5 -- Prevent infinite recursion
  )
  SELECT jsonb_agg(
    jsonb_build_object(
      'id', id,
      'name', name,
      'description', description,
      'parent_id', parent_id,
      'slug', slug,
      'color_code', color_code,
      'icon_name', icon_name,
      'image_url', image_url,
      'is_featured', is_featured,
      'display_order', display_order,
      'level', level,
      'created_at', created_at
    ) ORDER BY sort_path
  ) INTO result
  FROM category_tree;
  
  RETURN COALESCE(result, '[]'::jsonb);

EXCEPTION WHEN OTHERS THEN
  RETURN jsonb_build_object(
    'success', false,
    'error', 'Lỗi hệ thống: ' || SQLERRM
  );
END;
$$;

-- ==================================================================================
-- PRODUCT MANAGEMENT FUNCTIONS
-- ==================================================================================

-- Function: Create a new product
CREATE OR REPLACE FUNCTION pos_mini_modular3_create_product(
  p_name TEXT,
  p_description TEXT DEFAULT NULL,
  p_category_id UUID DEFAULT NULL,
  p_sku TEXT DEFAULT NULL,
  p_barcode TEXT DEFAULT NULL,
  p_unit_price DECIMAL DEFAULT 0,
  p_cost_price DECIMAL DEFAULT 0,
  p_current_stock INTEGER DEFAULT 0,
  p_min_stock_level INTEGER DEFAULT 0,
  p_unit_of_measure TEXT DEFAULT 'piece',
  p_track_stock BOOLEAN DEFAULT true,
  p_is_featured BOOLEAN DEFAULT false,
  p_tags TEXT[] DEFAULT NULL
) RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
  current_user_id UUID;
  current_business_id UUID;
  new_product_id UUID;
  product_slug TEXT;
  result jsonb;
BEGIN
  -- Get current user and business
  current_user_id := auth.uid();
  current_business_id := pos_mini_modular3_current_user_business_id();
  
  -- Validate user permission
  IF NOT pos_mini_modular3_can_access_user_profile(current_user_id) THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'Không có quyền truy cập'
    );
  END IF;
  
  -- Validate required fields
  IF p_name IS NULL OR trim(p_name) = '' THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'Tên sản phẩm không được để trống'
    );
  END IF;
  
  -- Generate slug from name
  product_slug := lower(regexp_replace(trim(p_name), '[^a-zA-Z0-9\s]', '', 'g'));
  product_slug := regexp_replace(product_slug, '\s+', '-', 'g');
  
  -- Validate category exists if provided
  IF p_category_id IS NOT NULL THEN
    IF NOT EXISTS (
      SELECT 1 FROM pos_mini_modular3_product_categories 
      WHERE id = p_category_id AND business_id = current_business_id
    ) THEN
      RETURN jsonb_build_object(
        'success', false,
        'error', 'Danh mục không tồn tại'
      );
    END IF;
  END IF;
  
  -- Check SKU uniqueness if provided
  IF p_sku IS NOT NULL AND trim(p_sku) != '' THEN
    IF EXISTS (
      SELECT 1 FROM pos_mini_modular3_products 
      WHERE business_id = current_business_id AND sku = trim(p_sku)
    ) THEN
      RETURN jsonb_build_object(
        'success', false,
        'error', 'Mã SKU đã tồn tại'
      );
    END IF;
  END IF;
  
  -- Check barcode uniqueness if provided
  IF p_barcode IS NOT NULL AND trim(p_barcode) != '' THEN
    IF EXISTS (
      SELECT 1 FROM pos_mini_modular3_products 
      WHERE business_id = current_business_id AND barcode = trim(p_barcode)
    ) THEN
      RETURN jsonb_build_object(
        'success', false,
        'error', 'Mã vạch đã tồn tại'
      );
    END IF;
  END IF;
  
  -- Insert new product
  INSERT INTO pos_mini_modular3_products (
    business_id,
    category_id,
    name,
    description,
    sku,
    barcode,
    slug,
    unit_price,
    cost_price,
    current_stock,
    min_stock_level,
    unit_of_measure,
    track_stock,
    is_featured,
    tags,
    created_by,
    updated_by
  ) VALUES (
    current_business_id,
    p_category_id,
    trim(p_name),
    p_description,
    NULLIF(trim(p_sku), ''),
    NULLIF(trim(p_barcode), ''),
    product_slug,
    p_unit_price,
    p_cost_price,
    p_current_stock,
    p_min_stock_level,
    p_unit_of_measure,
    p_track_stock,
    p_is_featured,
    p_tags,
    current_user_id,
    current_user_id
  ) RETURNING id INTO new_product_id;
  
  -- Return success result
  result := jsonb_build_object(
    'success', true,
    'message', 'Sản phẩm đã được tạo thành công',
    'product_id', new_product_id,
    'slug', product_slug
  );
  
  RETURN result;

EXCEPTION WHEN OTHERS THEN
  RETURN jsonb_build_object(
    'success', false,
    'error', 'Lỗi hệ thống: ' || SQLERRM
  );
END;
$$;

-- Function: Update product
CREATE OR REPLACE FUNCTION pos_mini_modular3_update_product(
  p_product_id UUID,
  p_name TEXT DEFAULT NULL,
  p_description TEXT DEFAULT NULL,
  p_category_id UUID DEFAULT NULL,
  p_sku TEXT DEFAULT NULL,
  p_barcode TEXT DEFAULT NULL,
  p_unit_price DECIMAL DEFAULT NULL,
  p_cost_price DECIMAL DEFAULT NULL,
  p_sale_price DECIMAL DEFAULT NULL,
  p_current_stock INTEGER DEFAULT NULL,
  p_min_stock_level INTEGER DEFAULT NULL,
  p_unit_of_measure TEXT DEFAULT NULL,
  p_track_stock BOOLEAN DEFAULT NULL,
  p_is_active BOOLEAN DEFAULT NULL,
  p_is_featured BOOLEAN DEFAULT NULL,
  p_tags TEXT[] DEFAULT NULL
) RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
  current_user_id UUID;
  current_business_id UUID;
  product_record RECORD;
  new_slug TEXT;
  result jsonb;
BEGIN
  -- Get current user and business
  current_user_id := auth.uid();
  current_business_id := pos_mini_modular3_current_user_business_id();
  
  -- Validate user permission
  IF NOT pos_mini_modular3_can_access_user_profile(current_user_id) THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'Không có quyền truy cập'
    );
  END IF;
  
  -- Check if product exists and belongs to current business
  SELECT * INTO product_record
  FROM pos_mini_modular3_products
  WHERE id = p_product_id AND business_id = current_business_id;
  
  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'Sản phẩm không tồn tại'
    );
  END IF;
  
  -- Validate category if provided
  IF p_category_id IS NOT NULL AND p_category_id != product_record.category_id THEN
    IF NOT EXISTS (
      SELECT 1 FROM pos_mini_modular3_product_categories 
      WHERE id = p_category_id AND business_id = current_business_id
    ) THEN
      RETURN jsonb_build_object(
        'success', false,
        'error', 'Danh mục không tồn tại'
      );
    END IF;
  END IF;
  
  -- Generate new slug if name is updated
  IF p_name IS NOT NULL AND trim(p_name) != product_record.name THEN
    new_slug := lower(regexp_replace(trim(p_name), '[^a-zA-Z0-9\s]', '', 'g'));
    new_slug := regexp_replace(new_slug, '\s+', '-', 'g');
  ELSE
    new_slug := product_record.slug;
  END IF;
  
  -- Check SKU uniqueness if updated
  IF p_sku IS NOT NULL AND trim(p_sku) != COALESCE(product_record.sku, '') THEN
    IF trim(p_sku) != '' AND EXISTS (
      SELECT 1 FROM pos_mini_modular3_products 
      WHERE business_id = current_business_id 
        AND sku = trim(p_sku) 
        AND id != p_product_id
    ) THEN
      RETURN jsonb_build_object(
        'success', false,
        'error', 'Mã SKU đã tồn tại'
      );
    END IF;
  END IF;
  
  -- Check barcode uniqueness if updated
  IF p_barcode IS NOT NULL AND trim(p_barcode) != COALESCE(product_record.barcode, '') THEN
    IF trim(p_barcode) != '' AND EXISTS (
      SELECT 1 FROM pos_mini_modular3_products 
      WHERE business_id = current_business_id 
        AND barcode = trim(p_barcode) 
        AND id != p_product_id
    ) THEN
      RETURN jsonb_build_object(
        'success', false,
        'error', 'Mã vạch đã tồn tại'
      );
    END IF;
  END IF;
  
  -- Update product
  UPDATE pos_mini_modular3_products SET
    name = COALESCE(trim(p_name), name),
    description = COALESCE(p_description, description),
    category_id = COALESCE(p_category_id, category_id),
    sku = CASE 
      WHEN p_sku IS NOT NULL THEN NULLIF(trim(p_sku), '') 
      ELSE sku 
    END,
    barcode = CASE 
      WHEN p_barcode IS NOT NULL THEN NULLIF(trim(p_barcode), '') 
      ELSE barcode 
    END,
    slug = new_slug,
    unit_price = COALESCE(p_unit_price, unit_price),
    cost_price = COALESCE(p_cost_price, cost_price),
    sale_price = COALESCE(p_sale_price, sale_price),
    current_stock = COALESCE(p_current_stock, current_stock),
    min_stock_level = COALESCE(p_min_stock_level, min_stock_level),
    unit_of_measure = COALESCE(p_unit_of_measure, unit_of_measure),
    track_stock = COALESCE(p_track_stock, track_stock),
    is_active = COALESCE(p_is_active, is_active),
    is_featured = COALESCE(p_is_featured, is_featured),
    tags = COALESCE(p_tags, tags),
    updated_by = current_user_id
  WHERE id = p_product_id;
  
  -- Return success result
  result := jsonb_build_object(
    'success', true,
    'message', 'Sản phẩm đã được cập nhật thành công',
    'product_id', p_product_id
  );
  
  RETURN result;

EXCEPTION WHEN OTHERS THEN
  RETURN jsonb_build_object(
    'success', false,
    'error', 'Lỗi hệ thống: ' || SQLERRM
  );
END;
$$;

-- Function: Get products with filters and pagination
CREATE OR REPLACE FUNCTION pos_mini_modular3_get_products(
  p_category_id UUID DEFAULT NULL,
  p_search_term TEXT DEFAULT NULL,
  p_is_active BOOLEAN DEFAULT NULL,
  p_is_featured BOOLEAN DEFAULT NULL,
  p_has_low_stock BOOLEAN DEFAULT NULL,
  p_tags TEXT[] DEFAULT NULL,
  p_page INTEGER DEFAULT 1,
  p_limit INTEGER DEFAULT 20,
  p_sort_by TEXT DEFAULT 'name',
  p_sort_order TEXT DEFAULT 'ASC'
) RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
  current_business_id UUID;
  total_count INTEGER;
  products_data jsonb;
  result jsonb;
  offset_value INTEGER;
  sort_column TEXT;
BEGIN
  current_business_id := pos_mini_modular3_current_user_business_id();
  
  -- Calculate offset
  offset_value := (p_page - 1) * p_limit;
  
  -- Validate sort column
  sort_column := CASE p_sort_by
    WHEN 'name' THEN 'p.name'
    WHEN 'price' THEN 'p.unit_price'
    WHEN 'stock' THEN 'p.current_stock'
    WHEN 'created' THEN 'p.created_at'
    WHEN 'updated' THEN 'p.updated_at'
    ELSE 'p.name'
  END;
  
  -- Build dynamic query for products
  WITH filtered_products AS (
    SELECT 
      p.id,
      p.name,
      p.description,
      p.short_description,
      p.sku,
      p.barcode,
      p.unit_price,
      p.cost_price,
      p.sale_price,
      p.current_stock,
      p.min_stock_level,
      p.unit_of_measure,
      p.is_active,
      p.is_featured,
      p.track_stock,
      p.tags,
      p.primary_image,
      p.created_at,
      p.updated_at,
      c.name as category_name,
      c.id as category_id,
      -- Low stock indicator
      CASE 
        WHEN p.track_stock AND p.current_stock <= p.min_stock_level 
        THEN true 
        ELSE false 
      END as is_low_stock
    FROM pos_mini_modular3_products p
    LEFT JOIN pos_mini_modular3_product_categories c ON p.category_id = c.id
    WHERE p.business_id = current_business_id
      AND (p_category_id IS NULL OR p.category_id = p_category_id)
      AND (p_is_active IS NULL OR p.is_active = p_is_active)
      AND (p_is_featured IS NULL OR p.is_featured = p_is_featured)
      AND (p_search_term IS NULL OR p.name ILIKE '%' || p_search_term || '%')
      AND (p_has_low_stock IS NULL OR 
           (p_has_low_stock = true AND p.track_stock AND p.current_stock <= p.min_stock_level) OR
           (p_has_low_stock = false AND (NOT p.track_stock OR p.current_stock > p.min_stock_level)))
      AND (p_tags IS NULL OR p.tags && p_tags)
  )
  SELECT 
    COUNT(*) OVER() as total_count,
    jsonb_agg(
      jsonb_build_object(
        'id', id,
        'name', name,
        'description', description,
        'short_description', short_description,
        'sku', sku,
        'barcode', barcode,
        'unit_price', unit_price,
        'cost_price', cost_price,
        'sale_price', sale_price,
        'current_stock', current_stock,
        'min_stock_level', min_stock_level,
        'unit_of_measure', unit_of_measure,
        'is_active', is_active,
        'is_featured', is_featured,
        'track_stock', track_stock,
        'is_low_stock', is_low_stock,
        'tags', tags,
        'primary_image', primary_image,
        'category', jsonb_build_object(
          'id', category_id,
          'name', category_name
        ),
        'created_at', created_at,
        'updated_at', updated_at
      )
    ) as products_data
  INTO total_count, products_data
  FROM (
    SELECT * FROM filtered_products
    ORDER BY 
      CASE WHEN p_sort_order = 'ASC' THEN
        CASE p_sort_by
          WHEN 'name' THEN name
          WHEN 'created' THEN created_at::text
          WHEN 'updated' THEN updated_at::text
        END
      END ASC,
      CASE WHEN p_sort_order = 'DESC' THEN
        CASE p_sort_by
          WHEN 'name' THEN name
          WHEN 'created' THEN created_at::text
          WHEN 'updated' THEN updated_at::text
        END
      END DESC,
      CASE WHEN p_sort_order = 'ASC' THEN
        CASE p_sort_by
          WHEN 'price' THEN unit_price
          WHEN 'stock' THEN current_stock::decimal
        END
      END ASC,
      CASE WHEN p_sort_order = 'DESC' THEN
        CASE p_sort_by
          WHEN 'price' THEN unit_price
          WHEN 'stock' THEN current_stock::decimal
        END
      END DESC
    LIMIT p_limit OFFSET offset_value
  ) sorted_products;
  
  -- Build result
  result := jsonb_build_object(
    'success', true,
    'data', jsonb_build_object(
      'products', COALESCE(products_data, '[]'::jsonb),
      'pagination', jsonb_build_object(
        'current_page', p_page,
        'per_page', p_limit,
        'total_items', COALESCE(total_count, 0),
        'total_pages', CEIL(COALESCE(total_count, 0)::decimal / p_limit)
      )
    )
  );
  
  RETURN result;

EXCEPTION WHEN OTHERS THEN
  RETURN jsonb_build_object(
    'success', false,
    'error', 'Lỗi hệ thống: ' || SQLERRM
  );
END;
$$;

-- Function: Update product stock
CREATE OR REPLACE FUNCTION pos_mini_modular3_update_product_stock(
  p_product_id UUID,
  p_quantity_change INTEGER,
  p_operation TEXT DEFAULT 'add', -- 'add', 'subtract', 'set'
  p_reason TEXT DEFAULT NULL
) RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
  current_user_id UUID;
  current_business_id UUID;
  product_record RECORD;
  new_stock INTEGER;
  result jsonb;
BEGIN
  -- Get current user and business
  current_user_id := auth.uid();
  current_business_id := pos_mini_modular3_current_user_business_id();
  
  -- Validate user permission
  IF NOT pos_mini_modular3_can_access_user_profile(current_user_id) THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'Không có quyền truy cập'
    );
  END IF;
  
  -- Get product
  SELECT * INTO product_record
  FROM pos_mini_modular3_products
  WHERE id = p_product_id AND business_id = current_business_id;
  
  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'Sản phẩm không tồn tại'
    );
  END IF;
  
  -- Check if product tracks stock
  IF NOT product_record.track_stock THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'Sản phẩm này không theo dõi tồn kho'
    );
  END IF;
  
  -- Calculate new stock based on operation
  CASE p_operation
    WHEN 'add' THEN
      new_stock := product_record.current_stock + p_quantity_change;
    WHEN 'subtract' THEN
      new_stock := product_record.current_stock - p_quantity_change;
    WHEN 'set' THEN
      new_stock := p_quantity_change;
    ELSE
      RETURN jsonb_build_object(
        'success', false,
        'error', 'Thao tác không hợp lệ'
      );
  END CASE;
  
  -- Validate new stock
  IF new_stock < 0 THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'Số lượng tồn kho không thể âm'
    );
  END IF;
  
  -- Update stock
  UPDATE pos_mini_modular3_products 
  SET 
    current_stock = new_stock,
    updated_by = current_user_id
  WHERE id = p_product_id;
  
  -- Return success result
  result := jsonb_build_object(
    'success', true,
    'message', 'Cập nhật tồn kho thành công',
    'product_id', p_product_id,
    'old_stock', product_record.current_stock,
    'new_stock', new_stock,
    'change', new_stock - product_record.current_stock
  );
  
  RETURN result;

EXCEPTION WHEN OTHERS THEN
  RETURN jsonb_build_object(
    'success', false,
    'error', 'Lỗi hệ thống: ' || SQLERRM
  );
END;
$$;

-- ==================================================================================
-- COMMENTS FOR FUNCTIONS
-- ==================================================================================

COMMENT ON FUNCTION pos_mini_modular3_create_category IS 'Create a new product category with validation and business isolation';
COMMENT ON FUNCTION pos_mini_modular3_update_category IS 'Update existing product category with validation';
COMMENT ON FUNCTION pos_mini_modular3_get_category_tree IS 'Get hierarchical category tree for the current business';
COMMENT ON FUNCTION pos_mini_modular3_create_product IS 'Create a new product with validation and business isolation';
COMMENT ON FUNCTION pos_mini_modular3_update_product IS 'Update existing product with comprehensive validation';
COMMENT ON FUNCTION pos_mini_modular3_get_products IS 'Get products with advanced filtering, search, and pagination';
COMMENT ON FUNCTION pos_mini_modular3_update_product_stock IS 'Update product stock with operation tracking';

-- ==================================================================================
-- END OF FUNCTIONS
-- ==================================================================================
