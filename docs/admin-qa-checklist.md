# Admin QA Checklist

This checklist covers smoke-level E2E and manual QA for admin dashboard and in-app admin flows.

## Goals
- Verify admin login and session flows
- Verify permissions and role-based actions (approve, ban, promote)
- Verify transactions and webhook-events listing
- Verify audit logging for admin actions
- Verify optimistic UI updates and error handling

## Smoke E2E tests (automated)
- Login (dev credentials) and open `/admin`
- Assert Recent Transactions table loads
- Assert Recent Webhook Events table loads
- Create user (if DB available) and assert it appears in users list

## Manual QA steps
1. Roles & permissions matrix
   - Login as admin: confirm full access
   - Login as manager: confirm limited user edits but no user deletion
   - Login as support: confirm read-only access

2. Audit actions
   - Perform an action (ban user, approve payout)
   - Verify an audit entry is created in logs with timestamp, actor, and action

3. Optimistic updates
   - Edit a user; confirm UI updates immediately and server reconciles
   - Simulate server failure (return 500) and confirm UI rolls back or shows error

4. Performance
   - Load dashboard and measure time to first interactive (TFI) for transactions table (< 2s expected in staging)

5. Security
   - Verify CSRF tokens for state-changing requests
   - Verify cookies are Secure, HttpOnly and SameSite=Lax (or Strict) in production
   - Verify CSP does not allow 'unsafe-inline' after bundle migration

## Acceptance
- E2E smoke tests pass locally or in CI
- Manual QA checklist items verified and signed off in PR
