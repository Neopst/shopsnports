Admin Dashboard Plan for ShopsNports

Recommendation
- Web-first admin dashboard (preferred)
  - Use React + Next.js or Flutter Web for a single-codebase approach.
  - React/Next.js is recommended if you want rapid access to mature admin templates and ecosystem.
  - Flutter Web is an option if you prefer a single UI stack across mobile and web; expect heavier bundle sizes and occasional web-specific styling work.

Why web-first
- Admin workflows (inventory, bulk uploads, reporting, CSV exports) fit desktop workflows better.
- Easier to secure and restrict access (network rules, role-based auth, SSO integrations).
- Faster iteration with existing web admin templates and libraries.

Suggested Tech Choices
- Frontend: React + Next.js (recommended) or Flutter Web (if you want UI parity).
- Component library: Ant Design / Material UI for React, or standard Flutter widgets + responsive layout for Flutter Web.
- Backend: Firebase (Firestore + Cloud Functions) for rapid MVP; or Node.js/Express + PostgreSQL for full control.
- Auth: Firebase Auth with role claims, or an OAuth/SSO provider; use role-based claims (admin/vendor) to gate access.

Minimal Data Model (key entities)
- Users: {id, name, email, role: [customer,vendor,admin], createdAt}
- Products: {id, vendorId, name, sku, price, inventory, images[], category, createdAt}
- Orders: {id, userId, vendorId, items[], total, status, shippingAddress, paymentInfo, createdAt}
- Payouts: {id, vendorId, amount, status, requestedAt, paidAt}
- Affiliates: {id, userId, affiliateCode, earnings, referrals[]}

MVP Admin Features (phase 1)
- Authentication & role-based access for admins and vendors
- Orders list + filtering by status/date/vendor
- Products CRUD for vendors and admin
- Inventory management and bulk CSV import
- Basic analytics (orders, revenue, top products)
- Payouts management for vendors
- Affiliate overview (registrations, earnings)

Rollout Plan
1. Build admin auth and a secure admin route (web). Protect using role claims.
2. Implement Orders list and Product CRUD (core features). Add CSV import for catalog.
3. Add analytics dashboards and vendor payouts.
4. Expand affiliate tools and reporting.
5. Harden security (audit logs, rate limiting, backups).

Integration Notes
- If using Firebase, leverage custom claims for admin/vendor roles and Cloud Functions for server-side tasks (exports, payouts processing).
- Keep admin APIs small and well-documented; prefer server-side pagination for lists.
- For multi-vendor workflows, define clear ownership rules: vendors can manage their own products/orders; admin can manage everything.

Developer ergonomics
- Use environment variables and separate dev/staging/prod Firebase projects.
- Add CI checks for deployments and a release checklist ensuring mock providers are not shipped in production builds.

Optional: Flutter Web Admin Shell
- If you prefer Flutter for both mobile and admin, scaffold a separate web target (e.g., `admin/`) using Flutter Web and share common UI components.
- Keep admin UI responsive and leverage desktop layouts for denser data displays.

Estimated effort (MVP)
- Web admin (React/Next.js) MVP: 2-4 weeks (single developer, basic features)
- Flutter Web admin MVP: 3-5 weeks (may need more polish for web UX)


