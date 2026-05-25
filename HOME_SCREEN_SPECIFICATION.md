# Home Screen Specification - ShopsNports

## Overview
An **action-oriented, reassuring, transparent** home screen that serves as the control center for shipment tracking, booking, and account management. The tokenised tracking system ensures users can track shipments without creating an account, building trust and accessibility.

---

## Screen Structure (Top to Bottom)

### 1. **Welcome Bar** (Personalized Greeting)
**Component**: Sticky header at the top
- **For Registered Users**: "Welcome back, [Company/User Name]! 👋" with time-aware greeting ("Good Morning/Afternoon")
- **For Guest/Token Users**: Hide name, show generic "Track Your Shipment" or "Hello! 👋"
- **Visual**: Subtle icon next to text, light background for brand visibility

---

### 2. **Primary Action - Tokenised Tracking Hero Section**
**Component**: Prominent search/input card (impossible to miss)
- **Label**: "Track Shipment by Token or AWB"
- **Input Field Features**:
  - Accepts: Tracking token, AWB number, BL number, or PO number
  - **QR/Barcode scan icon** (right side of input)
  - **Micro-animation**: Pulsing cursor or subtle moving-dots background to draw attention
- **Current State Indicator**: Show "Last tracked: [Time]" below for returning users
- **Suggestion**: This is your #1 feature. Use brand accent color (e.g., your primary blue) with slight shadow/elevation to make it "pop"

---

### 3. **Quick-Action Buttons Toolbar** (Grid of 3-5 Large Icon Buttons)
**Component**: Below tracking bar
- **Button 1 - Book a Shipment**: 📦+ icon → Leads to booking form
- **Button 2 - Get a Quote**: 💰 icon → Quick shipping rate calculator
- **Button 3 - Schedule Pickup**: 🚚⏰ icon → Direct pickup request
- **Button 4 - Enter Tracking Code** *(Optional)*: 🔍 icon → Shortcut to paste token
- **Button 5 - View Documents** *(Optional)*: 📄 icon → Invoices, BLs, PODs

**Styling**: 
- Filled icons with labels
- Most-used action (Book/Track) slightly larger or accent-colored
- Use rounded rectangle containers for modern look

---

### 4. **Active Shipments & Status Overview** (The Heart)
**Component**: Card-based list titled "Your Active Shipments" or "In Transit"
- **Default Display**: 3-5 visible cards with "View All" button
- **Each Shipment Card Must Show**:
  - **Tracking Token/Number**: Prominent (e.g., "TOKEN: ABC-123-XYZ" or "AWB 123-456789")
  - **Route**: Visual arrow (e.g., "🛫 LAX ➔ 🛬 JFK" or "Shanghai Port ➔ Chicago")
  - **Status Badge**: Color-coded
    - 🟢 **Green**: On time / Moving
    - 🟡 **Yellow**: Warning / Approaching deadline
    - 🔴 **Red**: Delayed / Hold / Exception
  - **Last Checkpoint**: "Arrived at Sorting Facility, Downtown LA - 2:15 PM"
  - **ETA**: "Estimated Delivery: Feb 15, 2026" (or "Delivery in 2 days")
  - **Progress Bar**: Visual step indicator (Booked → Picked Up → In Transit → Arrived → Delivered) with current step highlighted in accent color

**Interactivity**:
- Tap card → Full detail view with live tracking
- Long-press → Pin/favorite critical shipments
- Swipe right → Quick actions (e.g., "Share Tracking Link", "Contact Support")

**Empty State**: 
- Friendly illustration (animated truck) + "No active shipments. Ready to ship something?" + CTA button to Book

---

### 5. **Alerts & Notifications Center** (Proactive Communication)
**Component**: Collapsed/expandable card titled "⚠️ Alerts" or "Requires Attention"
- **Shows Only When Needed**: Hidden if no alerts (keeps UI clean)
- **Alert Types & Actions**:
  - 📋 **Documentation Required**: "Customs docs needed for TOKEN: ABC-123" → "Upload" button
  - ⚠️ **Delivery Exception**: "Address clarification needed for AWB 789" → "Fix Address" button
  - 💳 **Payment/Invoice**: "Payment receipt ready for Invoice #2024-001" → "Download" button
  - 🌦️ **External Factor**: "Weather delay impacting Port of XYZ. ETA +2 days" → "Learn More" button
  - 🚫 **Critical Hold**: "Customs hold on shipment ABC-123. Action required." → "View Details" button

**Styling**:
- Bold icon (bell 🔔 or flag 🚩) with color-coded dot (red = urgent, yellow = warning)
- Each alert is actionable with a clear CTA button
- Tap alert → Modal or detail screen with full context

---

### 6. **Dashboard Stats & Insights** (For Registered Users Only)
**Component**: Modular card (collapsible or hidden by default)
- **For B2B/Enterprise Users**:
  - "This Month: 12 Shipments | 3 In Transit | $4,850 Spent"
  - "Avg. Transit Time: 4.2 days | On-Time %: 97%"
  - Simple donut chart: "On-Time vs. Delayed Shipments"
  
- **For Guest/Casual Users**: Replace with "Recent Documents"
  - Quick download links to last 3-5 invoices, BLs, PODs

**Suggestion**: Make this collapsible so power users can expand but it doesn't clutter the main flow.

---

### 7. **Resources & Shortcuts** (Bottom Section)
**Component**: Row of smaller buttons/links
- 💬 **Contact Support**: Direct chat, email, or phone
- 📖 **Service Guide**: Shipping rules, prohibited items, terms
- 📍 **Locations**: Warehouse addresses, drop-off points, pickup schedules
- ⚙️ **Account & Billing**: Profile, payment methods, subscription

---

### 8. **Persistent 5-Tab Bottom Navigation Bar**
```
[Home] [Track] [Ship] [Documents] [Account]
 🏠    🔍    📦    📄        👤
```
- **Home** (Current): Overview & quick actions
- **Track**: Full-page tracking history with filters
- **Ship**: Booking flow
- **Documents**: Repository for invoices, BLs, PODs
- **Account**: Profile, settings, payment methods, support

---

## Key Features & Functionality

### Essential Features
- ✅ **Pull-to-Refresh**: Update shipment statuses and alerts
- ✅ **Search/Filter**: Filter active shipments by status (Delayed, Delivered, In Transit, etc.)
- ✅ **Token-Based Access**: Users can track without login
- ✅ **Offline Mode**: Cache last-known shipment data for basic offline viewing
- ✅ **Push Notifications**: Critical alerts send as push notifications

### Advanced (Phase 4+)
- 🔄 **Customizable Widgets**: Allow users to reorder/hide sections
- 🗺️ **Live Map View**: Show shipment location (if carrier API available)
- 📊 **Data Visualization**: Charts for performance metrics
- 📍 **Recurring Pickups**: Schedule patterns for power users

---

## Visual & UX Enhancements

### Animation & Motion
- **Status Update**: Gentle refresh animation on updated card (subtle pulse)
- **Progress Bar**: Smooth fill animation as shipment progresses
- **Tracking Bar**: Pulsing cursor or moving-dots background (draws eye naturally)
- **Empty State**: Friendly animated truck icon

### Color Coding Strategy
```
🟢 Green:  On-time, Active, Success
🟡 Yellow: Warning, Approaching deadline, Action needed
🔴 Red:    Delayed, Hold, Critical exception
⚪ Gray:   Completed/Delivered
```

### Contextual Illustrations
- Header illustration (optional): Branded truck or route illustration
- Empty state: Friendly truck with "Ready to Ship?"
- No alerts state: Clean, minimal design

### Helpful Microcopy
- **Empty section**: "Tip: You can schedule recurring pickups for faster processing"
- **Long loading**: "Fetching latest status..." with spinner
- **Error state**: "Unable to load. Check your connection or try again."

---

## Tokenised Tracking System Integration

### Guest User Flow (Token-Based)
1. **Entry Point**: User arrives with tracking token (from email link, SMS, or manual entry)
2. **Token Input**: Paste token into hero tracking bar
3. **Instant View**: Token-based tracking page loads (no login required)
4. **Deep Link**: Every tracking token is shareable & bookmark-able
5. **Guest Alerts**: Users can receive SMS/email alerts for token-tracked shipments

### Registered User Flow
1. **Dashboard**: See all their shipments at a glance
2. **Token Sharing**: Generate shareable tracking links for each shipment
3. **Bulk Operations**: Track multiple shipments, set favorites, organize by project

### Security & Trust
- ✅ Tokens are unique, time-limited, and one-way-hashable
- ✅ Display token prominently (builds transparency)
- ✅ Never show full token in logs (privacy)
- ✅ Allow tokens to be revoked/expired

---

## User Experience Goals (5-Second Rule)

When a user opens the app, they should instantly know:

1. ✅ **What needs attention** → Alerts section visible at a glance
2. ✅ **Where their shipments are** → Active Shipments with clear status
3. ✅ **How to track something new** → Tracking hero bar impossible to miss
4. ✅ **What to do next** → Quick-action buttons for primary tasks
5. ✅ **Context & reassurance** → Token visible, ETA clear, last update shown

---

## Suggested Build Priority

### Phase 3b (Design & MVP)
1. Welcome bar (personalized for registered users)
2. Heroic tracking bar (with scan icon, disabled for non-auth initially)
3. Quick-action buttons (Book, Quote, Pickup)
4. Active Shipments section (static mock data first)
5. Alerts section (static mock alerts)

### Phase 3c (Backend Integration)
1. Fetch active shipments from Firestore/API (stream provider)
2. Real-time status updates via WebSocket or polling
3. Fetch alerts/notifications
4. Implement pull-to-refresh
5. Token-based tracking (guest link support)

### Phase 4 (Polish)
1. Animations (status update, progress bar)
2. Offline mode (local cache)
3. Dashboard stats (for registered users)
4. Customizable widgets
5. Live map integration

---

## Key Differentiators for ShopsNports

1. **Token Transparency**: Make it the primary feature. No login barrier = more conversions
2. **Reassuring Design**: Use color, animations, and clear language to build trust
3. **Action-Oriented**: Every section has a clear next step
4. **Mobile-First**: Design for thumb-friendly interactions (buttons at bottom, swipes intuitive)
5. **Real-Time Feel**: Live status, push alerts, and refresh-to-update pattern create sense of control

---

## Component Dependencies

```
HomeScreen (ConsumerStatefulWidget)
├── Welcome Bar (Personalized greeting)
├── Tracking Bar Hero (Search + scan icon)
├── Quick Actions Grid (4 buttons)
├── Active Shipments List
│   ├── StreamProvider (fetch from Firestore)
│   ├── ShipmentCard (individual card widget)
│   └── View All CTA link
├── Alerts Section (conditional)
│   ├── AlertCard (individual alert widget)
│   └── Actionable CTAs per alert
├── Stats Dashboard (collapsible, for registered users)
└── Bottom Navigation (from Phase 1)
```

---

## Notes for Development

- **State Management**: Use `StreamProvider` for real-time shipment updates
- **Refresh**: Implement `RefreshIndicator` wrapping the entire scrollable content
- **Error Handling**: Show friendly fallback UI when API fails
- **Performance**: Use `ListView.builder()` for active shipments list (lazy loading)
- **Theming**: Use your brand colors consistently (primary blue, accent yellow, greens for success)
- **Accessibility**: Ensure color-blind users can distinguish status (use icons + text labels, not just color)

---

**Status**: 🟡 **Ready for Phase 3b Design Build**

Next step: Create static mockups, then build the screen with mock data before integrating real API calls.
