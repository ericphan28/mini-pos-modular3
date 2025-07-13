import type { LoggerService } from '../core/logger.service';
import { LOG_CATEGORIES, VIETNAMESE_BUSINESS_EVENTS } from '../core/constants';

export class AuthLogger {
  constructor(private logger: LoggerService) {}

  public async loginAttempt(
    loginData: {
      readonly email?: string;
      readonly phone?: string;
      readonly method: 'email' | 'phone' | 'social' | 'sso';
      readonly ip_address: string;
      readonly user_agent: string;
      readonly provider?: string;
    }
  ): Promise<void> {
    this.logger.setContext({
      ip_address: loginData.ip_address,
      user_agent: loginData.user_agent,
    });

    await this.logger.info(
      LOG_CATEGORIES.AUTH.name,
      'LOGIN_ATTEMPT',
      'Thử đăng nhập hệ thống',
      {
        login_method: loginData.method,
        identifier: loginData.email || loginData.phone,
        masked_identifier: this.maskIdentifier(loginData.email || loginData.phone || ''),
        provider: loginData.provider,
        has_identifier: !!(loginData.email || loginData.phone),
      }
    );
  }

  public async loginSuccess(
    userData: {
      readonly user_id: string;
      readonly email?: string;
      readonly phone?: string;
      readonly business_id?: string;
      readonly role: string;
      readonly is_first_login?: boolean;
      readonly login_method: string;
    },
    sessionData: {
      readonly session_id: string;
      readonly ip_address: string;
      readonly user_agent?: string;
      readonly expires_at?: string;
    }
  ): Promise<void> {
    this.logger.setContext({
      user_id: userData.user_id,
      business_id: userData.business_id,
      session_id: sessionData.session_id,
      ip_address: sessionData.ip_address,
    });

    await this.logger.info(
      LOG_CATEGORIES.AUTH.name,
      'LOGIN_SUCCESS',
      VIETNAMESE_BUSINESS_EVENTS.USER_LOGIN,
      {
        user_role: userData.role,
        login_method: userData.login_method,
        has_business: !!userData.business_id,
        is_first_login: userData.is_first_login,
        session_expires_at: sessionData.expires_at,
        masked_email: userData.email ? this.maskEmail(userData.email) : undefined,
        masked_phone: userData.phone ? this.maskPhone(userData.phone) : undefined,
      }
    );
  }

  public async loginFailed(
    failureData: {
      readonly reason: string;
      readonly email?: string;
      readonly phone?: string;
      readonly ip_address: string;
      readonly user_agent?: string;
      readonly attempts_count?: number;
      readonly is_blocked?: boolean;
      readonly error_code?: string;
    }
  ): Promise<void> {
    this.logger.setContext({
      ip_address: failureData.ip_address,
      user_agent: failureData.user_agent,
    });

    const logLevel = failureData.is_blocked ? 'warn' : 'info';
    
    await this.logger[logLevel](
      LOG_CATEGORIES.AUTH.name,
      'LOGIN_FAILED',
      'Đăng nhập thất bại',
      {
        failure_reason: failureData.reason,
        error_code: failureData.error_code,
        identifier: failureData.email || failureData.phone,
        masked_identifier: this.maskIdentifier(failureData.email || failureData.phone || ''),
        attempts_count: failureData.attempts_count,
        is_blocked: failureData.is_blocked,
        requires_attention: (failureData.attempts_count || 0) > 3,
      }
    );
  }

  public async logout(
    userData: {
      readonly user_id: string;
      readonly session_id: string;
      readonly business_id?: string;
    },
    logoutContext: {
      readonly reason: 'user_initiated' | 'session_expired' | 'force_logout' | 'security';
      readonly ip_address?: string;
    }
  ): Promise<void> {
    this.logger.setContext({
      user_id: userData.user_id,
      business_id: userData.business_id,
      session_id: userData.session_id,
      ip_address: logoutContext.ip_address,
    });

    await this.logger.info(
      LOG_CATEGORIES.AUTH.name,
      'USER_LOGOUT',
      VIETNAMESE_BUSINESS_EVENTS.USER_LOGOUT,
      {
        logout_reason: logoutContext.reason,
        is_forced: logoutContext.reason === 'force_logout',
        is_security_related: logoutContext.reason === 'security',
      }
    );
  }

  public async passwordChanged(
    userData: {
      readonly user_id: string;
      readonly business_id?: string;
    },
    changeContext: {
      readonly initiated_by: 'user' | 'admin' | 'system';
      readonly reason?: string;
      readonly ip_address: string;
    }
  ): Promise<void> {
    this.logger.setContext({
      user_id: userData.user_id,
      business_id: userData.business_id,
      ip_address: changeContext.ip_address,
    });

    await this.logger.info(
      LOG_CATEGORIES.AUTH.name,
      'PASSWORD_CHANGED',
      'Thay đổi mật khẩu',
      {
        initiated_by: changeContext.initiated_by,
        reason: changeContext.reason,
        is_admin_reset: changeContext.initiated_by === 'admin',
        is_forced: changeContext.initiated_by === 'system',
      }
    );
  }

  public async userRegistered(
    userData: {
      readonly user_id: string;
      readonly email?: string;
      readonly phone?: string;
      readonly role: string;
      readonly business_id?: string;
      readonly registration_method: string;
    },
    registrationContext: {
      readonly ip_address: string;
      readonly user_agent?: string;
      readonly referrer?: string;
      readonly invitation_id?: string;
    }
  ): Promise<void> {
    this.logger.setContext({
      user_id: userData.user_id,
      business_id: userData.business_id,
      ip_address: registrationContext.ip_address,
    });

    await this.logger.info(
      LOG_CATEGORIES.AUTH.name,
      'USER_REGISTERED',
      VIETNAMESE_BUSINESS_EVENTS.USER_REGISTERED,
      {
        user_role: userData.role,
        registration_method: userData.registration_method,
        has_business: !!userData.business_id,
        is_invited: !!registrationContext.invitation_id,
        invitation_id: registrationContext.invitation_id,
        referrer: registrationContext.referrer,
        masked_email: userData.email ? this.maskEmail(userData.email) : undefined,
        masked_phone: userData.phone ? this.maskPhone(userData.phone) : undefined,
      }
    );
  }

  public async permissionChanged(
    permissionData: {
      readonly user_id: string;
      readonly business_id: string;
      readonly old_role?: string;
      readonly new_role: string;
      readonly permissions_added: readonly string[];
      readonly permissions_removed: readonly string[];
    },
    changeContext: {
      readonly changed_by: string;
      readonly reason?: string;
      readonly ip_address?: string;
    }
  ): Promise<void> {
    this.logger.setContext({
      user_id: permissionData.user_id,
      business_id: permissionData.business_id,
      ip_address: changeContext.ip_address,
    });

    await this.logger.info(
      LOG_CATEGORIES.AUTH.name,
      'PERMISSION_CHANGED',
      'Thay đổi quyền người dùng',
      {
        target_user_id: permissionData.user_id,
        changed_by_user_id: changeContext.changed_by,
        role_change: permissionData.old_role ? 
          `${permissionData.old_role} → ${permissionData.new_role}` : 
          permissionData.new_role,
        old_role: permissionData.old_role,
        new_role: permissionData.new_role,
        permissions_added: permissionData.permissions_added,
        permissions_removed: permissionData.permissions_removed,
        is_promotion: this.isRolePromotion(permissionData.old_role, permissionData.new_role),
        reason: changeContext.reason,
      }
    );
  }

  public async suspiciousActivity(
    activityData: {
      readonly user_id?: string;
      readonly activity_type: string;
      readonly severity: 'low' | 'medium' | 'high' | 'critical';
      readonly description: string;
      readonly ip_address: string;
      readonly user_agent?: string;
      readonly additional_info?: Record<string, unknown>;
    }
  ): Promise<void> {
    this.logger.setContext({
      user_id: activityData.user_id,
      ip_address: activityData.ip_address,
      user_agent: activityData.user_agent,
    });

    const logLevel = activityData.severity === 'critical' ? 'error' : 'warn';

    if (logLevel === 'error') {
      await this.logger.error(
        LOG_CATEGORIES.SECURITY.name,
        'SUSPICIOUS_ACTIVITY',
        `Hoạt động đáng ngờ: ${activityData.description}`,
        undefined,
        {
          activity_type: activityData.activity_type,
          severity: activityData.severity,
          requires_investigation: activityData.severity === 'high' || activityData.severity === 'critical',
          additional_info: activityData.additional_info,
        }
      );
    } else {
      await this.logger.warn(
        LOG_CATEGORIES.SECURITY.name,
        'SUSPICIOUS_ACTIVITY',
        `Hoạt động đáng ngờ: ${activityData.description}`,
        {
          activity_type: activityData.activity_type,
          severity: activityData.severity,
          requires_investigation: activityData.severity === 'high' || activityData.severity === 'critical',
          additional_info: activityData.additional_info,
        }
      );
    }
  }

  public async sessionExpired(
    sessionData: {
      readonly user_id: string;
      readonly session_id: string;
      readonly business_id?: string;
      readonly duration_minutes: number;
    }
  ): Promise<void> {
    this.logger.setContext({
      user_id: sessionData.user_id,
      business_id: sessionData.business_id,
      session_id: sessionData.session_id,
    });

    await this.logger.info(
      LOG_CATEGORIES.AUTH.name,
      'SESSION_EXPIRED',
      'Phiên đăng nhập hết hạn',
      {
        session_duration_minutes: sessionData.duration_minutes,
        is_long_session: sessionData.duration_minutes > 480, // 8 hours
      }
    );
  }

  private maskIdentifier(identifier: string): string {
    if (!identifier) return '';
    
    if (identifier.includes('@')) {
      return this.maskEmail(identifier);
    } else if (/^\+?[\d\s\-\(\)]+$/.test(identifier)) {
      return this.maskPhone(identifier);
    }
    
    // Generic masking for other identifiers
    if (identifier.length <= 3) return '***';
    const start = identifier.substring(0, 2);
    const end = identifier.substring(identifier.length - 1);
    return `${start}***${end}`;
  }

  private maskEmail(email: string): string {
    const [username, domain] = email.split('@');
    if (!domain) return '***@invalid';
    
    const maskedUsername = username.length > 3 ? 
      username.substring(0, 3) + '***' : 
      '***';
    return `${maskedUsername}@${domain}`;
  }

  private maskPhone(phone: string): string {
    const cleaned = phone.replace(/\D/g, '');
    if (cleaned.length < 6) return '***';
    
    const start = cleaned.substring(0, 3);
    const end = cleaned.substring(cleaned.length - 3);
    return `${start}***${end}`;
  }

  private isRolePromotion(oldRole?: string, newRole?: string): boolean {
    if (!oldRole || !newRole) return false;
    
    const roleHierarchy: Record<string, number> = {
      'seller': 1,
      'accountant': 2,
      'manager': 3,
      'owner': 4,
      'admin': 5,
    };
    
    return (roleHierarchy[newRole.toLowerCase()] || 0) > (roleHierarchy[oldRole.toLowerCase()] || 0);
  }
}
