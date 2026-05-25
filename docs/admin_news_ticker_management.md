# Admin Dashboard - News Ticker Management

## Overview
The news ticker is now managed through Firestore, allowing administrators to add, update, and remove news items in real-time through the admin dashboard.

## Firestore Collection Structure

### Collection: `news_ticker`

Each document in the `news_ticker` collection has the following structure:

```json
{
  "text": "Welcome to ShopsNports! New products available now!",
  "link": "https://shopsnports.com/new-products", // Optional
  "priority": 10,
  "isActive": true,
  "createdAt": "2025-12-23T10:00:00Z",
  "expiresAt": "2025-12-31T23:59:59Z" // Optional
}
```

### Field Descriptions

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `text` | string | Yes | The news message to display |
| `link` | string | No | Optional URL to open when clicked |
| `priority` | number | Yes | Higher numbers appear first (default: 0) |
| `isActive` | boolean | Yes | Show/hide the news item |
| `createdAt` | timestamp | Yes | When the news was created |
| `expiresAt` | timestamp | No | Auto-hide after this date |

## Admin Dashboard Integration

### Required UI Components

1. **News List View**
   - Display all news items (active and inactive)
   - Show status, priority, and expiration
   - Sort by priority (descending) and creation date

2. **Add News Form**
   ```
   [ Text Input: News Message ]
   [ URL Input: Link (optional) ]
   [ Number Input: Priority (0-100) ]
   [ Date Picker: Expiration Date (optional) ]
   [ Checkbox: Active ]
   [ Submit Button ]
   ```

3. **Edit News Form**
   - Same as Add Form, pre-filled with existing data
   - Update button instead of Submit

4. **Actions**
   - ✏️ Edit - Opens edit form
   - 🗑️ Delete - Confirms and deletes
   - 👁️ Toggle Active - Quick activate/deactivate
   - 📊 View Analytics (future)

### Firestore Security Rules

Add to `firestore.rules`:

```javascript
match /news_ticker/{tickerId} {
  // Public read for mobile app
  allow read: if true;
  
  // Only admins can write
  allow create, update, delete: if request.auth != null 
    && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
}
```

## API Methods (Already Implemented)

The `NewsTickerService` provides these methods:

### For Mobile App (Read-Only)

```dart
// Stream of active news items
Stream<List<NewsTickerItem>> getActiveNewsItems()

// One-time fetch
Future<List<NewsTickerItem>> fetchActiveNewsItems()
```

### For Admin Dashboard

```dart
// Add news
Future<bool> addNewsItem({
  required String text,
  String? link,
  int priority = 0,
  DateTime? expiresAt,
})

// Update news
Future<bool> updateNewsItem({
  required String id,
  String? text,
  String? link,
  int? priority,
  bool? isActive,
  DateTime? expiresAt,
})

// Delete news
Future<bool> deleteNewsItem(String id)

// Soft delete (deactivate)
Future<bool> deactivateNewsItem(String id)

// Get all items (for admin management)
Stream<List<NewsTickerItem>> getAllNewsItems()
```

## Admin Dashboard Implementation (React/Web)

### 1. Service File (TypeScript)

```typescript
// src/services/newsTickerService.ts
import { 
  collection, 
  addDoc, 
  updateDoc, 
  deleteDoc, 
  doc, 
  query, 
  orderBy, 
  onSnapshot,
  Timestamp 
} from 'firebase/firestore';
import { db } from './firebase';

export interface NewsTickerItem {
  id?: string;
  text: string;
  link?: string;
  priority: number;
  isActive: boolean;
  createdAt: Date;
  expiresAt?: Date;
}

const COLLECTION = 'news_ticker';

export const newsTickerService = {
  // Subscribe to all news items
  subscribeToNews(callback: (items: NewsTickerItem[]) => void) {
    const q = query(
      collection(db, COLLECTION),
      orderBy('priority', 'desc'),
      orderBy('createdAt', 'desc')
    );
    
    return onSnapshot(q, (snapshot) => {
      const items = snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data(),
        createdAt: doc.data().createdAt.toDate(),
        expiresAt: doc.data().expiresAt?.toDate(),
      })) as NewsTickerItem[];
      callback(items);
    });
  },

  // Add news item
  async addNews(item: Omit<NewsTickerItem, 'id' | 'createdAt'>) {
    return await addDoc(collection(db, COLLECTION), {
      ...item,
      createdAt: Timestamp.now(),
      expiresAt: item.expiresAt ? Timestamp.fromDate(item.expiresAt) : null,
    });
  },

  // Update news item
  async updateNews(id: string, updates: Partial<NewsTickerItem>) {
    const docRef = doc(db, COLLECTION, id);
    const updateData: any = { ...updates };
    
    if (updates.expiresAt) {
      updateData.expiresAt = Timestamp.fromDate(updates.expiresAt);
    }
    
    return await updateDoc(docRef, updateData);
  },

  // Delete news item
  async deleteNews(id: string) {
    return await deleteDoc(doc(db, COLLECTION, id));
  },

  // Toggle active status
  async toggleActive(id: string, isActive: boolean) {
    return await updateDoc(doc(db, COLLECTION, id), { isActive });
  },
};
```

### 2. React Component

```tsx
// src/components/NewsTickerManager.tsx
import React, { useState, useEffect } from 'react';
import { newsTickerService, NewsTickerItem } from '../services/newsTickerService';

export const NewsTickerManager: React.FC = () => {
  const [items, setItems] = useState<NewsTickerItem[]>([]);
  const [formData, setFormData] = useState({
    text: '',
    link: '',
    priority: 0,
    expiresAt: '',
  });

  useEffect(() => {
    const unsubscribe = newsTickerService.subscribeToNews(setItems);
    return () => unsubscribe();
  }, []);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    await newsTickerService.addNews({
      text: formData.text,
      link: formData.link || undefined,
      priority: formData.priority,
      isActive: true,
      expiresAt: formData.expiresAt ? new Date(formData.expiresAt) : undefined,
    });
    // Reset form
    setFormData({ text: '', link: '', priority: 0, expiresAt: '' });
  };

  return (
    <div className="news-ticker-manager">
      <h2>News Ticker Management</h2>
      
      {/* Add Form */}
      <form onSubmit={handleSubmit} className="add-news-form">
        <input
          type="text"
          placeholder="News message"
          value={formData.text}
          onChange={(e) => setFormData({ ...formData, text: e.target.value })}
          required
        />
        <input
          type="url"
          placeholder="Link (optional)"
          value={formData.link}
          onChange={(e) => setFormData({ ...formData, link: e.target.value })}
        />
        <input
          type="number"
          placeholder="Priority"
          value={formData.priority}
          onChange={(e) => setFormData({ ...formData, priority: +e.target.value })}
        />
        <input
          type="datetime-local"
          placeholder="Expiration (optional)"
          value={formData.expiresAt}
          onChange={(e) => setFormData({ ...formData, expiresAt: e.target.value })}
        />
        <button type="submit">Add News</button>
      </form>

      {/* News List */}
      <table className="news-list">
        <thead>
          <tr>
            <th>Status</th>
            <th>Priority</th>
            <th>Message</th>
            <th>Expires</th>
            <th>Actions</th>
          </tr>
        </thead>
        <tbody>
          {items.map((item) => (
            <tr key={item.id}>
              <td>
                <span className={item.isActive ? 'active' : 'inactive'}>
                  {item.isActive ? '✓ Active' : '✗ Inactive'}
                </span>
              </td>
              <td>{item.priority}</td>
              <td>{item.text}</td>
              <td>{item.expiresAt?.toLocaleDateString() || 'Never'}</td>
              <td>
                <button onClick={() => newsTickerService.toggleActive(item.id!, !item.isActive)}>
                  {item.isActive ? 'Deactivate' : 'Activate'}
                </button>
                <button onClick={() => newsTickerService.deleteNews(item.id!)}>
                  Delete
                </button>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
};
```

## Testing

### 1. Add Test Data via Firestore Console

1. Go to Firebase Console → Firestore Database
2. Create collection: `news_ticker`
3. Add document with:
   ```json
   {
     "text": "🎉 Welcome to ShopsNports!",
     "priority": 10,
     "isActive": true,
     "createdAt": "current timestamp"
   }
   ```

### 2. Verify in Mobile App

1. Run the app
2. Check that news ticker shows on all screens
3. Verify scrolling animation works
4. Test with multiple news items

### 3. Test Admin Features

1. Add news from admin dashboard
2. Verify it appears in mobile app immediately
3. Update priority and check reordering
4. Toggle active/inactive
5. Test expiration dates

## Best Practices

1. **Priority Guidelines**
   - 100: Critical announcements
   - 50-99: Important news
   - 10-49: Regular updates
   - 0-9: Low priority info

2. **Message Length**
   - Keep messages under 100 characters
   - Use clear, actionable language
   - Include emojis for visual appeal (optional)

3. **Expiration**
   - Set expiration for time-sensitive news
   - Use "Never" for evergreen content
   - Review and clean up expired items monthly

4. **Performance**
   - Limit to 20 active items max
   - Archive old items instead of deleting
   - Use pagination for admin view if needed

## Future Enhancements

- [ ] Click tracking analytics
- [ ] A/B testing for messages
- [ ] Rich text formatting
- [ ] Image attachments
- [ ] Scheduled publishing
- [ ] Geolocation-based news
- [ ] Multi-language support

---

**Status:** ✅ Service Implemented  
**Mobile App:** Ready  
**Admin Dashboard:** Needs implementation  
**Next Steps:** Build admin UI components
