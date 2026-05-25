"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.setTemplateAsDefault = exports.deleteNotificationTemplate = exports.updateNotificationTemplate = exports.createNotificationTemplate = exports.NotificationTemplateService = void 0;
exports.createNotificationTemplateService = createNotificationTemplateService;
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
class NotificationTemplateService {
    constructor(db) {
        this.db = db;
    }
    /**
     * Create a new notification template
     */
    async createTemplate(template, createdBy) {
        const templateRef = await this.db.collection('notification_templates').add({
            ...template,
            isActive: true,
            isDefault: false,
            createdBy,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        console.log(`Notification template created: ${templateRef.id}`);
        return templateRef.id;
    }
    /**
     * Update an existing template
     */
    async updateTemplate(templateId, updates) {
        await this.db.collection('notification_templates').doc(templateId).update({
            ...updates,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        console.log(`Notification template updated: ${templateId}`);
    }
    /**
     * Delete a template
     */
    async deleteTemplate(templateId) {
        await this.db.collection('notification_templates').doc(templateId).delete();
        console.log(`Notification template deleted: ${templateId}`);
    }
    /**
     * Get template by ID
     */
    async getTemplateById(templateId) {
        const doc = await this.db.collection('notification_templates').doc(templateId).get();
        if (!doc.exists) {
            return null;
        }
        return doc.data();
    }
    /**
     * Get templates by category
     */
    async getTemplatesByCategory(category, includeInactive = false) {
        let query = this.db
            .collection('notification_templates')
            .where('category', '==', category)
            .orderBy('name');
        if (!includeInactive) {
            query = query.where('isActive', '==', true);
        }
        const snapshot = await query.get();
        return snapshot.docs.map((doc) => doc.data());
    }
    /**
     * Get templates by type
     */
    async getTemplatesByType(type, includeInactive = false) {
        let query = this.db
            .collection('notification_templates')
            .where('type', '==', type)
            .orderBy('name');
        if (!includeInactive) {
            query = query.where('isActive', '==', true);
        }
        const snapshot = await query.get();
        return snapshot.docs.map((doc) => doc.data());
    }
    /**
     * Get all templates
     */
    async getAllTemplates(includeInactive = false) {
        let query = this.db
            .collection('notification_templates')
            .orderBy('category')
            .orderBy('name');
        if (!includeInactive) {
            query = query.where('isActive', '==', true);
        }
        const snapshot = await query.get();
        return snapshot.docs.map((doc) => doc.data());
    }
    /**
     * Get default template for category and type
     */
    async getDefaultTemplate(category, type) {
        const snapshot = await this.db
            .collection('notification_templates')
            .where('category', '==', category)
            .where('type', '==', type)
            .where('isDefault', '==', true)
            .limit(1)
            .get();
        if (snapshot.empty) {
            return null;
        }
        return snapshot.docs[0].data();
    }
    /**
     * Set template as default for category
     */
    async setAsDefault(templateId) {
        const template = await this.getTemplateById(templateId);
        if (!template) {
            throw new Error('Template not found');
        }
        // Remove default flag from other templates in same category/type
        const batch = this.db.batch();
        const otherTemplates = await this.db
            .collection('notification_templates')
            .where('category', '==', template.category)
            .where('type', '==', template.type)
            .where('isDefault', '==', true)
            .get();
        otherTemplates.docs.forEach((doc) => {
            if (doc.id !== templateId) {
                batch.update(doc.ref, { isDefault: false });
            }
        });
        // Set this template as default
        batch.update(this.db.collection('notification_templates').doc(templateId), {
            isDefault: true,
        });
        await batch.commit();
        console.log(`Template set as default: ${templateId}`);
    }
    /**
     * Render template with variables
     */
    renderTemplate(template, variables) {
        let title = template.title;
        let body = template.body;
        // Replace variables in title and body
        for (const variable of template.variables) {
            const value = variables[variable.name] ?? variable.defaultValue;
            if (value === undefined && variable.required) {
                console.warn(`Missing required variable: ${variable.name}`);
            }
            const placeholder = `{{${variable.name}}}`;
            const formattedValue = this.formatVariableValue(value, variable.type);
            title = title.split(placeholder).join(formattedValue);
            body = body.split(placeholder).join(formattedValue);
        }
        return { title, body };
    }
    /**
     * Format variable value based on type
     */
    formatVariableValue(value, type) {
        if (value === null || value === undefined) {
            return '';
        }
        switch (type) {
            case 'string':
                return String(value);
            case 'number':
                return Number(value).toLocaleString();
            case 'date':
                return new Date(value).toLocaleDateString();
            case 'currency':
                return `$${Number(value).toFixed(2)}`;
            case 'boolean':
                return value ? 'Yes' : 'No';
            default:
                return String(value);
        }
    }
    /**
     * Validate template variables
     */
    validateTemplate(template) {
        const errors = [];
        if (!template.name || template.name.trim().length === 0) {
            errors.push('Template name is required');
        }
        if (!template.title || template.title.trim().length === 0) {
            errors.push('Template title is required');
        }
        if (!template.body || template.body.trim().length === 0) {
            errors.push('Template body is required');
        }
        // Check for required variables in template
        for (const variable of template.variables) {
            if (variable.required) {
                const placeholder = `{{${variable.name}}}`;
                if (!template.title.includes(placeholder) && !template.body.includes(placeholder)) {
                    errors.push(`Required variable '${variable.name}' not used in template`);
                }
            }
        }
        // Check for undefined variables in template
        const usedVariables = this.extractVariablesFromTemplate(template.title + template.body);
        for (const usedVar of usedVariables) {
            const defined = template.variables.find((v) => v.name === usedVar);
            if (!defined) {
                errors.push(`Undefined variable in template: '${usedVar}'`);
            }
        }
        return {
            valid: errors.length === 0,
            errors,
        };
    }
    /**
     * Extract variable names from template
     */
    extractVariablesFromTemplate(template) {
        const regex = /\{\{(\w+)\}\}/g;
        const variables = [];
        let match;
        while ((match = regex.exec(template)) !== null) {
            variables.push(match[1]);
        }
        return [...new Set(variables)]; // Remove duplicates
    }
    /**
     * Activate/deactivate template
     */
    async toggleTemplateStatus(templateId, isActive) {
        await this.db.collection('notification_templates').doc(templateId).update({
            isActive,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        console.log(`Template ${isActive ? 'activated' : 'deactivated'}: ${templateId}`);
    }
    /**
     * Duplicate template
     */
    async duplicateTemplate(templateId, newName) {
        const original = await this.getTemplateById(templateId);
        if (!original) {
            throw new Error('Template not found');
        }
        const newTemplate = {
            ...original,
            name: newName,
            isDefault: false,
        };
        delete newTemplate.id;
        delete newTemplate.createdAt;
        delete newTemplate.updatedAt;
        return this.createTemplate(newTemplate, original.createdBy || 'system');
    }
    /**
     * Get template usage statistics
     */
    async getTemplateUsageStats(templateId) {
        // Count how many times this template was used
        const historySnapshot = await this.db
            .collection('notification_history')
            .where('templateId', '==', templateId)
            .get();
        const totalUsage = historySnapshot.size;
        // Get recent usage
        const recentSnapshot = await this.db
            .collection('notification_history')
            .where('templateId', '==', templateId)
            .orderBy('createdAt', 'desc')
            .limit(10)
            .get();
        return {
            totalUsage,
            recentUsage: recentSnapshot.size,
            lastUsed: recentSnapshot.size > 0
                ? recentSnapshot.docs[0].data()?.createdAt
                : null,
        };
    }
}
exports.NotificationTemplateService = NotificationTemplateService;
/**
 * Create notification template service instance
 */
function createNotificationTemplateService(db) {
    return new NotificationTemplateService(db);
}
/**
 * Cloud Function: Create Notification Template
 */
const createNotificationTemplate = async (data, context) => {
    try {
        if (!context.auth?.token.admin) {
            throw new functions.https.HttpsError('permission-denied', 'Only admins can create notification templates');
        }
        const db = admin.firestore();
        const templateService = createNotificationTemplateService(db);
        const template = {
            name: data.name,
            description: data.description,
            category: data.category,
            type: data.type,
            title: data.title,
            body: data.body,
            variables: data.variables,
            isActive: true,
            isDefault: false,
        };
        // Validate template
        const validation = templateService.validateTemplate(template);
        if (!validation.valid) {
            throw new functions.https.HttpsError('invalid-argument', `Template validation failed: ${validation.errors.join(', ')}`);
        }
        const templateId = await templateService.createTemplate(template, context.auth.uid);
        return {
            success: true,
            templateId,
            message: 'Notification template created successfully',
        };
    }
    catch (error) {
        console.error('Error creating notification template:', error);
        if (error instanceof functions.https.HttpsError) {
            throw error;
        }
        throw new functions.https.HttpsError('internal', 'Failed to create notification template');
    }
};
exports.createNotificationTemplate = createNotificationTemplate;
/**
 * Cloud Function: Update Notification Template
 */
const updateNotificationTemplate = async (data, context) => {
    try {
        if (!context.auth?.token.admin) {
            throw new functions.https.HttpsError('permission-denied', 'Only admins can update notification templates');
        }
        const db = admin.firestore();
        const templateService = createNotificationTemplateService(db);
        await templateService.updateTemplate(data.templateId, data.updates);
        return {
            success: true,
            message: 'Notification template updated successfully',
        };
    }
    catch (error) {
        console.error('Error updating notification template:', error);
        if (error instanceof functions.https.HttpsError) {
            throw error;
        }
        throw new functions.https.HttpsError('internal', 'Failed to update notification template');
    }
};
exports.updateNotificationTemplate = updateNotificationTemplate;
/**
 * Cloud Function: Delete Notification Template
 */
const deleteNotificationTemplate = async (data, context) => {
    try {
        if (!context.auth?.token.admin) {
            throw new functions.https.HttpsError('permission-denied', 'Only admins can delete notification templates');
        }
        const db = admin.firestore();
        const templateService = createNotificationTemplateService(db);
        await templateService.deleteTemplate(data.templateId);
        return {
            success: true,
            message: 'Notification template deleted successfully',
        };
    }
    catch (error) {
        console.error('Error deleting notification template:', error);
        if (error instanceof functions.https.HttpsError) {
            throw error;
        }
        throw new functions.https.HttpsError('internal', 'Failed to delete notification template');
    }
};
exports.deleteNotificationTemplate = deleteNotificationTemplate;
/**
 * Cloud Function: Set Template as Default
 */
const setTemplateAsDefault = async (data, context) => {
    try {
        if (!context.auth?.token.admin) {
            throw new functions.https.HttpsError('permission-denied', 'Only admins can set default templates');
        }
        const db = admin.firestore();
        const templateService = createNotificationTemplateService(db);
        await templateService.setAsDefault(data.templateId);
        return {
            success: true,
            message: 'Template set as default successfully',
        };
    }
    catch (error) {
        console.error('Error setting template as default:', error);
        if (error instanceof functions.https.HttpsError) {
            throw error;
        }
        throw new functions.https.HttpsError('internal', 'Failed to set template as default');
    }
};
exports.setTemplateAsDefault = setTemplateAsDefault;
