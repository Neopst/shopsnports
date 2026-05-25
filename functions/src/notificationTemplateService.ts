import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { validateString, ValidationError } from './validation';

/**
 * Notification Template Service
 *
 * Manages notification templates with variable substitution
 * Supports multiple notification types and categories
 */

export interface NotificationTemplate {
  id?: string;
  name: string;
  description: string;
  category: 'payout' | 'shipping' | 'invoice' | 'affiliate' | 'admin' | 'system';
  type: 'push' | 'email' | 'sms';
  title: string;
  body: string;
  variables: TemplateVariable[];
  isActive: boolean;
  isDefault: boolean;
  createdBy?: string;
  createdAt?: admin.firestore.FieldValue;
  updatedAt?: admin.firestore.FieldValue;
}

export interface TemplateVariable {
  name: string;
  type: 'string' | 'number' | 'date' | 'currency' | 'boolean';
  description: string;
  required: boolean;
  defaultValue?: any;
}

export class NotificationTemplateService {
  private db: admin.firestore.Firestore;

  constructor(db: admin.firestore.Firestore) {
    this.db = db;
  }

  /**
   * Create a new notification template
   */
  async createTemplate(
    template: NotificationTemplate,
    createdBy: string
  ): Promise<string> {
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
  async updateTemplate(
    templateId: string,
    updates: Partial<NotificationTemplate>
  ): Promise<void> {
    await this.db.collection('notification_templates').doc(templateId).update({
      ...updates,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log(`Notification template updated: ${templateId}`);
  }

  /**
   * Delete a template
   */
  async deleteTemplate(templateId: string): Promise<void> {
    await this.db.collection('notification_templates').doc(templateId).delete();

    console.log(`Notification template deleted: ${templateId}`);
  }

  /**
   * Get template by ID
   */
  async getTemplateById(templateId: string): Promise<NotificationTemplate | null> {
    const doc = await this.db.collection('notification_templates').doc(templateId).get();

    if (!doc.exists) {
      return null;
    }

    return doc.data() as NotificationTemplate;
  }

  /**
   * Get templates by category
   */
  async getTemplatesByCategory(
    category: string,
    includeInactive: boolean = false
  ): Promise<NotificationTemplate[]> {
    let query = this.db
      .collection('notification_templates')
      .where('category', '==', category)
      .orderBy('name');

    if (!includeInactive) {
      query = query.where('isActive', '==', true) as any;
    }

    const snapshot = await query.get();

    return snapshot.docs.map((doc) => doc.data() as NotificationTemplate);
  }

  /**
   * Get templates by type
   */
  async getTemplatesByType(
    type: string,
    includeInactive: boolean = false
  ): Promise<NotificationTemplate[]> {
    let query = this.db
      .collection('notification_templates')
      .where('type', '==', type)
      .orderBy('name');

    if (!includeInactive) {
      query = query.where('isActive', '==', true) as any;
    }

    const snapshot = await query.get();

    return snapshot.docs.map((doc) => doc.data() as NotificationTemplate);
  }

  /**
   * Get all templates
   */
  async getAllTemplates(includeInactive: boolean = false): Promise<NotificationTemplate[]> {
    let query = this.db
      .collection('notification_templates')
      .orderBy('category')
      .orderBy('name');

    if (!includeInactive) {
      query = query.where('isActive', '==', true) as any;
    }

    const snapshot = await query.get();

    return snapshot.docs.map((doc) => doc.data() as NotificationTemplate);
  }

  /**
   * Get default template for category and type
   */
  async getDefaultTemplate(
    category: string,
    type: string
  ): Promise<NotificationTemplate | null> {
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

    return snapshot.docs[0].data() as NotificationTemplate;
  }

  /**
   * Set template as default for category
   */
  async setAsDefault(templateId: string): Promise<void> {
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
  renderTemplate(
    template: NotificationTemplate,
    variables: Record<string, any>
  ): { title: string; body: string } {
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
  private formatVariableValue(value: any, type: string): string {
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
  validateTemplate(template: NotificationTemplate): { valid: boolean; errors: string[] } {
    const errors: string[] = [];

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
  private extractVariablesFromTemplate(template: string): string[] {
    const regex = /\{\{(\w+)\}\}/g;
    const variables: string[] = [];
    let match;

    while ((match = regex.exec(template)) !== null) {
      variables.push(match[1]);
    }

    return [...new Set(variables)]; // Remove duplicates
  }

  /**
   * Activate/deactivate template
   */
  async toggleTemplateStatus(templateId: string, isActive: boolean): Promise<void> {
    await this.db.collection('notification_templates').doc(templateId).update({
      isActive,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log(`Template ${isActive ? 'activated' : 'deactivated'}: ${templateId}`);
  }

  /**
   * Duplicate template
   */
  async duplicateTemplate(templateId: string, newName: string): Promise<string> {
    const original = await this.getTemplateById(templateId);

    if (!original) {
      throw new Error('Template not found');
    }

    const newTemplate: NotificationTemplate = {
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
  async getTemplateUsageStats(templateId: string): Promise<Record<string, any>> {
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

/**
 * Create notification template service instance
 */
export function createNotificationTemplateService(db: admin.firestore.Firestore): NotificationTemplateService {
  return new NotificationTemplateService(db);
}

/**
 * Cloud Function: Create Notification Template
 */
export const createNotificationTemplate = async (
  data: {
    name: string;
    description: string;
    category: string;
    type: string;
    title: string;
    body: string;
    variables: TemplateVariable[];
  },
  context: functions.https.CallableContext
) => {
  try {
    if (!context.auth?.token.admin) {
      throw new functions.https.HttpsError(
        'permission-denied',
        'Only admins can create notification templates'
      );
    }

    const db = admin.firestore();
    const templateService = createNotificationTemplateService(db);

    const template: NotificationTemplate = {
      name: data.name,
      description: data.description,
      category: data.category as any,
      type: data.type as any,
      title: data.title,
      body: data.body,
      variables: data.variables,
      isActive: true,
      isDefault: false,
    };

    // Validate template
    const validation = templateService.validateTemplate(template);
    if (!validation.valid) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        `Template validation failed: ${validation.errors.join(', ')}`
      );
    }

    const templateId = await templateService.createTemplate(template, context.auth.uid);

    return {
      success: true,
      templateId,
      message: 'Notification template created successfully',
    };
  } catch (error) {
    console.error('Error creating notification template:', error);
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    throw new functions.https.HttpsError('internal', 'Failed to create notification template');
  }
};

/**
 * Cloud Function: Update Notification Template
 */
export const updateNotificationTemplate = async (
  data: {
    templateId: string;
    updates: Partial<NotificationTemplate>;
  },
  context: functions.https.CallableContext
) => {
  try {
    if (!context.auth?.token.admin) {
      throw new functions.https.HttpsError(
        'permission-denied',
        'Only admins can update notification templates'
      );
    }

    const db = admin.firestore();
    const templateService = createNotificationTemplateService(db);

    await templateService.updateTemplate(data.templateId, data.updates);

    return {
      success: true,
      message: 'Notification template updated successfully',
    };
  } catch (error) {
    console.error('Error updating notification template:', error);
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    throw new functions.https.HttpsError('internal', 'Failed to update notification template');
  }
};

/**
 * Cloud Function: Delete Notification Template
 */
export const deleteNotificationTemplate = async (
  data: {
    templateId: string;
  },
  context: functions.https.CallableContext
) => {
  try {
    if (!context.auth?.token.admin) {
      throw new functions.https.HttpsError(
        'permission-denied',
        'Only admins can delete notification templates'
      );
    }

    const db = admin.firestore();
    const templateService = createNotificationTemplateService(db);

    await templateService.deleteTemplate(data.templateId);

    return {
      success: true,
      message: 'Notification template deleted successfully',
    };
  } catch (error) {
    console.error('Error deleting notification template:', error);
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    throw new functions.https.HttpsError('internal', 'Failed to delete notification template');
  }
};

/**
 * Cloud Function: Set Template as Default
 */
export const setTemplateAsDefault = async (
  data: {
    templateId: string;
  },
  context: functions.https.CallableContext
) => {
  try {
    if (!context.auth?.token.admin) {
      throw new functions.https.HttpsError(
        'permission-denied',
        'Only admins can set default templates'
      );
    }

    const db = admin.firestore();
    const templateService = createNotificationTemplateService(db);

    await templateService.setAsDefault(data.templateId);

    return {
      success: true,
      message: 'Template set as default successfully',
    };
  } catch (error) {
    console.error('Error setting template as default:', error);
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    throw new functions.https.HttpsError('internal', 'Failed to set template as default');
  }
};