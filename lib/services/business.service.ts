import { businessLogger, setLoggerContext } from '@/lib/logger';
import { createClient } from '@/lib/supabase/client';

type SupabaseClient = ReturnType<typeof createClient>;

interface ProductData {
  readonly name: string;
  readonly price: number;
  readonly category: string;
  readonly sku?: string;
  readonly description?: string;
}

interface UserContext {
  readonly user_id: string;
  readonly business_id: string;
}

export class BusinessService {
  private supabase: SupabaseClient = createClient();

  public async createProduct(
    productData: ProductData,
    userContext: UserContext
  ): Promise<{ success: boolean; product?: unknown; error?: string }> {
    try {
      // Set logger context
      setLoggerContext({
        user_id: userContext.user_id,
        business_id: userContext.business_id,
      });

      const result = await businessLogger.performanceTrack(
        'CREATE_PRODUCT',
        { business_id: userContext.business_id, user_id: userContext.user_id },
        async () => {
          // Validate product data
          if (!productData.name || productData.name.trim().length === 0) {
            throw new Error('Tên sản phẩm không được để trống');
          }

          if (productData.price <= 0) {
            throw new Error('Giá sản phẩm phải lớn hơn 0');
          }

          // Insert product to database
          const { data, error } = await this.supabase
            .from('pos_mini_modular3_products')
            .insert({
              name: productData.name.trim(),
              price: productData.price,
              category: productData.category,
              sku: productData.sku,
              description: productData.description,
              business_id: userContext.business_id,
              created_by: userContext.user_id,
              created_at: new Date().toISOString(),
              updated_at: new Date().toISOString(),
              status: 'active',
            })
            .select()
            .single();

          if (error) throw error;
          return data;
        },
        {
          product_name: productData.name,
          product_price: productData.price,
          product_category: productData.category,
        }
      );

      // Log successful product creation
      await businessLogger.productCreated({
        id: result.id,
        name: result.name,
        price: result.price,
        category: result.category,
        sku: result.sku,
      }, userContext);

      return { success: true, product: result };
    } catch (error: unknown) {
      const errorMessage = error instanceof Error ? error.message : 'Unknown error';
      return { success: false, error: errorMessage };
    }
  }

  public async updateProduct(
    productId: string,
    updates: Partial<ProductData>,
    userContext: UserContext
  ): Promise<{ success: boolean; product?: unknown; error?: string }> {
    try {
      setLoggerContext({
        user_id: userContext.user_id,
        business_id: userContext.business_id,
      });

      const result = await businessLogger.performanceTrack(
        'UPDATE_PRODUCT',
        { business_id: userContext.business_id, user_id: userContext.user_id },
        async () => {
          // Get current product for change tracking
          const { data: currentProduct, error: fetchError } = await this.supabase
            .from('pos_mini_modular3_products')
            .select('*')
            .eq('id', productId)
            .eq('business_id', userContext.business_id)
            .single();

          if (fetchError) throw fetchError;
          if (!currentProduct) throw new Error('Sản phẩm không tồn tại');

          // Update product
          const { data, error } = await this.supabase
            .from('pos_mini_modular3_products')
            .update({
              ...updates,
              updated_at: new Date().toISOString(),
              updated_by: userContext.user_id,
            })
            .eq('id', productId)
            .eq('business_id', userContext.business_id)
            .select()
            .single();

          if (error) throw error;

          // Track changes for logging
          const changes: Record<string, { from: unknown; to: unknown }> = {};
          for (const [key, newValue] of Object.entries(updates)) {
            const oldValue = currentProduct[key];
            if (oldValue !== newValue) {
              changes[key] = { from: oldValue, to: newValue };
            }
          }

          return { product: data, changes };
        },
        {
          product_id: productId,
          update_fields: Object.keys(updates),
        }
      );

      // Log product update
      await businessLogger.productUpdated({
        id: productId,
        name: result.product.name,
        price: result.product.price,
        changes: result.changes,
      }, userContext);

      return { success: true, product: result.product };
    } catch (error: unknown) {
      const errorMessage = error instanceof Error ? error.message : 'Unknown error';
      return { success: false, error: errorMessage };
    }
  }

  public async completeOrder(
    orderData: {
      readonly items: readonly { product_id: string; quantity: number; price: number }[];
      readonly customer_id?: string;
      readonly payment_method: string;
      readonly discount_amount?: number;
      readonly tax_amount?: number;
    },
    userContext: UserContext
  ): Promise<{ success: boolean; order?: unknown; error?: string }> {
    try {
      setLoggerContext({
        user_id: userContext.user_id,
        business_id: userContext.business_id,
      });

      const result = await businessLogger.performanceTrack(
        'COMPLETE_ORDER',
        { business_id: userContext.business_id, user_id: userContext.user_id },
        async () => {
          // Calculate totals
          const subtotal = orderData.items.reduce((sum, item) => sum + (item.price * item.quantity), 0);
          const discountAmount = orderData.discount_amount || 0;
          const taxAmount = orderData.tax_amount || 0;
          const total = subtotal - discountAmount + taxAmount;

          // Create order
          const { data: order, error: orderError } = await this.supabase
            .from('pos_mini_modular3_orders')
            .insert({
              business_id: userContext.business_id,
              customer_id: orderData.customer_id,
              subtotal_amount: subtotal,
              discount_amount: discountAmount,
              tax_amount: taxAmount,
              total_amount: total,
              payment_method: orderData.payment_method,
              status: 'completed',
              created_by: userContext.user_id,
              created_at: new Date().toISOString(),
              completed_at: new Date().toISOString(),
            })
            .select()
            .single();

          if (orderError) throw orderError;

          // Create order items
          const orderItems = orderData.items.map(item => ({
            order_id: order.id,
            product_id: item.product_id,
            quantity: item.quantity,
            unit_price: item.price,
            total_price: item.price * item.quantity,
          }));

          const { error: itemsError } = await this.supabase
            .from('pos_mini_modular3_order_items')
            .insert(orderItems);

          if (itemsError) throw itemsError;

          return {
            ...order,
            items: orderItems,
            items_count: orderData.items.length,
          };
        },
        {
          items_count: orderData.items.length,
          payment_method: orderData.payment_method,
        }
      );

      // Log order completion
      await businessLogger.orderCompleted({
        id: result.id,
        total: result.total_amount,
        items_count: result.items_count,
        payment_method: orderData.payment_method,
        customer_id: orderData.customer_id,
        discount_amount: orderData.discount_amount,
        tax_amount: orderData.tax_amount,
      }, userContext);

      return { success: true, order: result };
    } catch (error: unknown) {
      const errorMessage = error instanceof Error ? error.message : 'Unknown error';
      return { success: false, error: errorMessage };
    }
  }

  public async processPayment(
    paymentData: {
      readonly order_id: string;
      readonly amount: number;
      readonly method: string;
      readonly transaction_id?: string;
    },
    userContext: UserContext
  ): Promise<{ success: boolean; payment?: unknown; error?: string }> {
    try {
      setLoggerContext({
        user_id: userContext.user_id,
        business_id: userContext.business_id,
      });

      const result = await businessLogger.performanceTrack(
        'PROCESS_PAYMENT',
        { business_id: userContext.business_id, user_id: userContext.user_id },
        async () => {
          // Simulate payment processing logic
          const isSuccessful = Math.random() > 0.1; // 90% success rate for demo

          const payment = {
            id: `payment_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
            order_id: paymentData.order_id,
            amount: paymentData.amount,
            method: paymentData.method,
            status: isSuccessful ? 'success' : 'failed',
            transaction_id: paymentData.transaction_id || `txn_${Date.now()}`,
            processed_at: new Date().toISOString(),
          };

          if (!isSuccessful) {
            throw new Error('Thanh toán thất bại - vui lòng thử lại');
          }

          return payment;
        },
        {
          order_id: paymentData.order_id,
          amount: paymentData.amount,
          payment_method: paymentData.method,
        }
      );

      // Log payment processing
      await businessLogger.paymentProcessed({
        payment_id: result.id,
        order_id: paymentData.order_id,
        amount: paymentData.amount,
        method: paymentData.method,
        status: result.status as 'success' | 'failed' | 'pending',
        transaction_id: result.transaction_id,
      }, userContext);

      return { success: true, payment: result };
    } catch (error: unknown) {
      const errorMessage = error instanceof Error ? error.message : 'Unknown error';
      
      // Log failed payment
      await businessLogger.paymentProcessed({
        payment_id: `failed_${Date.now()}`,
        order_id: paymentData.order_id,
        amount: paymentData.amount,
        method: paymentData.method,
        status: 'failed',
        transaction_id: paymentData.transaction_id,
      }, userContext);

      return { success: false, error: errorMessage };
    }
  }
}
