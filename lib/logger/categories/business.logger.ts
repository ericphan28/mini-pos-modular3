import type { LoggerService } from '../core/logger.service';
import { LOG_CATEGORIES, VIETNAMESE_BUSINESS_EVENTS } from '../core/constants';

export class BusinessLogger {
  constructor(private logger: LoggerService) {}

  public async productCreated(
    productData: {
      readonly id: string;
      readonly name: string;
      readonly price: number;
      readonly category?: string;
      readonly sku?: string;
    },
    userContext: {
      readonly user_id: string;
      readonly business_id: string;
    }
  ): Promise<void> {
    this.logger.setContext(userContext);
    
    await this.logger.info(
      LOG_CATEGORIES.BUSINESS.name,
      'PRODUCT_CREATED',
      VIETNAMESE_BUSINESS_EVENTS.PRODUCT_CREATED,
      {
        product_id: productData.id,
        product_name: productData.name,
        price_vnd: productData.price,
        category: productData.category,
        sku: productData.sku,
      }
    );
  }

  public async productUpdated(
    productData: {
      readonly id: string;
      readonly name?: string;
      readonly price?: number;
      readonly changes: Record<string, { from: unknown; to: unknown }>;
    },
    userContext: {
      readonly user_id: string;
      readonly business_id: string;
    }
  ): Promise<void> {
    this.logger.setContext(userContext);
    
    await this.logger.info(
      LOG_CATEGORIES.BUSINESS.name,
      'PRODUCT_UPDATED',
      VIETNAMESE_BUSINESS_EVENTS.PRODUCT_UPDATED,
      {
        product_id: productData.id,
        product_name: productData.name,
        updated_price: productData.price,
        changes: productData.changes,
        change_count: Object.keys(productData.changes).length,
      }
    );
  }

  public async orderCreated(
    orderData: {
      readonly id: string;
      readonly total: number;
      readonly items_count: number;
      readonly customer_id?: string;
      readonly payment_method?: string;
    },
    userContext: {
      readonly user_id: string;
      readonly business_id: string;
    }
  ): Promise<void> {
    this.logger.setContext(userContext);
    
    await this.logger.info(
      LOG_CATEGORIES.BUSINESS.name,
      'ORDER_CREATED',
      VIETNAMESE_BUSINESS_EVENTS.ORDER_CREATED,
      {
        order_id: orderData.id,
        total_amount_vnd: orderData.total,
        items_count: orderData.items_count,
        customer_id: orderData.customer_id,
        payment_method: orderData.payment_method,
      }
    );
  }

  public async orderCompleted(
    orderData: {
      readonly id: string;
      readonly total: number;
      readonly items_count: number;
      readonly payment_method: string;
      readonly customer_id?: string;
      readonly discount_amount?: number;
      readonly tax_amount?: number;
    },
    userContext: {
      readonly user_id: string;
      readonly business_id: string;
    }
  ): Promise<void> {
    this.logger.setContext(userContext);
    
    await this.logger.info(
      LOG_CATEGORIES.BUSINESS.name,
      'ORDER_COMPLETED',
      VIETNAMESE_BUSINESS_EVENTS.ORDER_COMPLETED,
      {
        order_id: orderData.id,
        total_amount_vnd: orderData.total,
        items_count: orderData.items_count,
        payment_method: orderData.payment_method,
        customer_id: orderData.customer_id,
        discount_amount_vnd: orderData.discount_amount,
        tax_amount_vnd: orderData.tax_amount,
        net_amount_vnd: orderData.total - (orderData.discount_amount || 0),
      }
    );
  }

  public async paymentProcessed(
    paymentData: {
      readonly payment_id: string;
      readonly order_id: string;
      readonly amount: number;
      readonly method: string;
      readonly status: 'success' | 'failed' | 'pending';
      readonly transaction_id?: string;
    },
    userContext: {
      readonly user_id: string;
      readonly business_id: string;
    }
  ): Promise<void> {
    this.logger.setContext(userContext);
    
    const event = paymentData.status === 'success' ? 'PAYMENT_PROCESSED' : 'PAYMENT_FAILED';
    const message = paymentData.status === 'success' ? 
      VIETNAMESE_BUSINESS_EVENTS.PAYMENT_PROCESSED : 
      VIETNAMESE_BUSINESS_EVENTS.PAYMENT_FAILED;

    await this.logger.info(
      LOG_CATEGORIES.BUSINESS.name,
      event,
      message,
      {
        payment_id: paymentData.payment_id,
        order_id: paymentData.order_id,
        amount_vnd: paymentData.amount,
        payment_method: paymentData.method,
        payment_status: paymentData.status,
        transaction_id: paymentData.transaction_id,
      }
    );
  }

  public async inventoryUpdated(
    inventoryData: {
      readonly product_id: string;
      readonly product_name?: string;
      readonly old_quantity: number;
      readonly new_quantity: number;
      readonly reason: string;
      readonly reference_id?: string;
    },
    userContext: {
      readonly user_id: string;
      readonly business_id: string;
    }
  ): Promise<void> {
    this.logger.setContext(userContext);
    
    const quantityChange = inventoryData.new_quantity - inventoryData.old_quantity;
    const changeType = quantityChange > 0 ? 'INCREASE' : 'DECREASE';
    
    await this.logger.info(
      LOG_CATEGORIES.BUSINESS.name,
      'INVENTORY_UPDATED',
      VIETNAMESE_BUSINESS_EVENTS.INVENTORY_UPDATED,
      {
        product_id: inventoryData.product_id,
        product_name: inventoryData.product_name,
        quantity_change: quantityChange,
        change_type: changeType,
        old_quantity: inventoryData.old_quantity,
        new_quantity: inventoryData.new_quantity,
        update_reason: inventoryData.reason,
        reference_id: inventoryData.reference_id,
      }
    );
  }

  public async subscriptionChanged(
    subscriptionData: {
      readonly business_id: string;
      readonly old_tier: string;
      readonly new_tier: string;
      readonly effective_date: string;
      readonly reason?: string;
    },
    userContext: {
      readonly user_id: string;
      readonly business_id: string;
    }
  ): Promise<void> {
    this.logger.setContext(userContext);
    
    await this.logger.info(
      LOG_CATEGORIES.BUSINESS.name,
      'SUBSCRIPTION_CHANGED',
      VIETNAMESE_BUSINESS_EVENTS.SUBSCRIPTION_CHANGED,
      {
        business_id: subscriptionData.business_id,
        tier_change: `${subscriptionData.old_tier} → ${subscriptionData.new_tier}`,
        old_tier: subscriptionData.old_tier,
        new_tier: subscriptionData.new_tier,
        effective_date: subscriptionData.effective_date,
        reason: subscriptionData.reason,
        is_upgrade: this.isUpgrade(subscriptionData.old_tier, subscriptionData.new_tier),
      }
    );
  }

  public async performanceTrack<T>(
    operation: string,
    businessContext: { readonly business_id: string; readonly user_id?: string },
    fn: () => Promise<T>,
    additionalContext?: Record<string, unknown>
  ): Promise<T> {
    this.logger.setContext(businessContext);
    
    return await this.logger.performance(
      LOG_CATEGORIES.BUSINESS.name,
      operation,
      fn,
      additionalContext
    );
  }

  public async dataExport(
    exportData: {
      readonly export_type: string;
      readonly data_range: { from: string; to: string };
      readonly record_count: number;
      readonly file_format: string;
    },
    userContext: {
      readonly user_id: string;
      readonly business_id: string;
    }
  ): Promise<void> {
    this.logger.setContext(userContext);
    
    await this.logger.info(
      LOG_CATEGORIES.BUSINESS.name,
      'DATA_EXPORT',
      VIETNAMESE_BUSINESS_EVENTS.DATA_EXPORT,
      {
        export_type: exportData.export_type,
        date_range: exportData.data_range,
        record_count: exportData.record_count,
        file_format: exportData.file_format,
      }
    );
  }

  public async businessRegistered(
    businessData: {
      readonly business_id: string;
      readonly business_name: string;
      readonly business_type: string;
      readonly owner_id: string;
      readonly tax_id?: string;
    }
  ): Promise<void> {
    this.logger.setContext({
      user_id: businessData.owner_id,
      business_id: businessData.business_id,
    });
    
    await this.logger.info(
      LOG_CATEGORIES.BUSINESS.name,
      'BUSINESS_REGISTERED',
      VIETNAMESE_BUSINESS_EVENTS.BUSINESS_REGISTERED,
      {
        business_id: businessData.business_id,
        business_name: businessData.business_name,
        business_type: businessData.business_type,
        owner_id: businessData.owner_id,
        has_tax_id: !!businessData.tax_id,
      }
    );
  }

  private isUpgrade(oldTier: string, newTier: string): boolean {
    const tierLevels: Record<string, number> = {
      'free': 0,
      'basic': 1,
      'advanced': 2,
      'enterprise': 3,
    };
    
    return (tierLevels[newTier.toLowerCase()] || 0) > (tierLevels[oldTier.toLowerCase()] || 0);
  }
}
