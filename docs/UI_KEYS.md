UI widget keys

This file documents test/QA keys used across the affiliate UI.

affiliate dashboard
- `affiliate_logo` - AppBar logo image
- `affiliate_notifications` - notifications icon in AppBar
- `affiliate_name_text` - the Text widget that displays the affiliate name (profile header)
- `affiliate_edit_profile` - Edit profile button in profile header
- `create_shipment_fab` - alias key wrapping the FloatingActionButton used to create a shipment request
- `affiliate_cta_create_share` - existing FAB key (label + icon)
- `no_requests_create_button` - CTA button shown when there are no requests

shipment request tile
- `affiliate_request_{id}` - tile root key (replace {id} with request id)
- `request_status_{id}` - textual status key in the tile
- `request_amount_{id}` - displayed amount when available
- `request_commission_{id}` - displayed commission when available
- `mark_complete_button_{id}` - visible 'Mark complete' button (enabled for admins, non-admins see 'Admins only' snackbar)

Notes
- Keys that contain `{id}` should be matched by constructing the string with the request id present in the mock or real data.
- The `mark_complete_button_{id}` triggers a call to the mock service when `isAdmin` is true. In production this should invoke the server-side admin action.

Testing
- Use these keys in widget tests to locate specific controls and assert behavior (e.g. verify the 'Admins only' snackbar appears when a non-admin taps `mark_complete_button_{id}`).
