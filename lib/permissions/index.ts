// ==================================================================================
// CENTRALIZED PERMISSION SYSTEM - INDEX FILE
// ==================================================================================
// Entry point for the centralized permission system

export * from './permission-types';
export * from './permission-config';
export * from './permission-engine';
export * from './route-permission-guard';

// Initialize permission system
import { permissionEngine } from './permission-engine';
import { PERMISSION_CONFIG } from './permission-config';

// Auto-initialize the permission engine
permissionEngine.initialize(PERMISSION_CONFIG);

export { permissionEngine, PERMISSION_CONFIG };
