# Server Management Scripts

## Quick Start

### Start the server (single run)
```powershell
.\start-server.ps1
```

### Start with auto-restart (recommended for development)
```powershell
.\monitor-server.ps1 -AutoRestart
```

### Test API endpoints
```powershell
.\test-api.ps1
```

---

## Scripts Overview

### 1. `start-server.ps1`
**Purpose:** Basic server startup script

**Features:**
- Sets Firebase credentials automatically
- Loads environment variables from .env
- Shows clear startup messages
- Single run (stops when you press Ctrl+C)

**Usage:**
```powershell
.\start-server.ps1
```

**When to use:** 
- Quick server start
- When you want full control over restarts
- Testing configuration changes

---

### 2. `monitor-server.ps1`
**Purpose:** Advanced server monitoring with auto-restart

**Features:**
- Auto-restart on crash (optional)
- Restart counter
- Timestamps for each restart
- Graceful shutdown detection

**Usage:**
```powershell
# Single run (no auto-restart)
.\monitor-server.ps1

# Auto-restart mode
.\monitor-server.ps1 -AutoRestart
```

**When to use:**
- Long development sessions
- When debugging crashes
- Production-like testing

---

### 3. `test-api.ps1`
**Purpose:** Quick API health check

**Features:**
- Tests 9 core endpoints
- Color-coded results (✓/✗)
- Summary statistics
- Fast execution (< 5 seconds)

**Usage:**
```powershell
# Test localhost
.\test-api.ps1

# Test remote server
.\test-api.ps1 -BaseUrl "https://api.shopsnports.com"
```

**When to use:**
- After server starts
- Before APK builds
- After deploying changes
- Troubleshooting issues

---

## Typical Workflow

### Development Session
```powershell
# Terminal 1: Start server with auto-restart
.\monitor-server.ps1 -AutoRestart

# Terminal 2: Run tests when needed
.\test-api.ps1
```

### Quick Testing
```powershell
# Terminal 1: Start server
.\start-server.ps1

# Terminal 2: Test endpoints
.\test-api.ps1

# Stop server with Ctrl+C when done
```

### Pre-Deployment Check
```powershell
.\start-server.ps1
# Wait for "listening at http://localhost:3000"

# In another terminal:
.\test-api.ps1

# All tests should pass ✓
```

---

## Troubleshooting

### Server won't start
```powershell
# Check if port 3000 is in use
Get-NetTCPConnection -LocalPort 3000 -ErrorAction SilentlyContinue

# Kill existing node processes
Get-Process node -ErrorAction SilentlyContinue | Stop-Process -Force

# Try starting again
.\start-server.ps1
```

### Firebase credentials error
```powershell
# Check if credentials file exists
Test-Path .\shopsnports-firebase-adminsdk-fbsvc-b0880f6249.json

# If false, copy from admin_dashboard:
Copy-Item ..\admin_dashboard\shopsnports-firebase-adminsdk-fbsvc-b0880f6249.json .
```

### API tests failing
```powershell
# Check server is running
Invoke-WebRequest http://localhost:3000 -UseBasicParsing

# View server logs in the monitor terminal
# Look for error messages

# Common fixes:
# 1. Restart server
# 2. Check .env file has required keys
# 3. Verify database connection
```

---

## Environment Variables

All scripts automatically set:
- `GOOGLE_APPLICATION_CREDENTIALS` - Firebase service account
- `NODE_ENV` - defaults to "development"

Additional variables from `.env`:
- `PORT` - Server port (default: 3000)
- `DATABASE_URL` - PostgreSQL connection string
- `RESEND_API_KEY` - Email service key
- `STRIPE_SECRET_KEY` - Payment gateway
- etc.

---

## Server Logs

### What to look for:

✅ **Good startup:**
```
Products API mounted at /api/v1/products
Categories API mounted at /api/v1/categories
Orders API mounted at /api/v1/orders
...
DB initialized
ShopsNports payment example server listening at http://localhost:3000
```

⚠️ **Warnings (non-critical):**
```
Firebase Admin SDK not initialized for news ticker
Products router failed to load: Cannot find module '../config/db'
```

❌ **Errors (critical):**
```
Error: Cannot find module 'express'
error: password authentication failed for user "app_user"
Firebase Admin initialization failed
```

---

## Advanced Usage

### Custom port
```powershell
$env:PORT = 8080
.\start-server.ps1
```

### Production mode
```powershell
$env:NODE_ENV = "production"
.\start-server.ps1
```

### Debug mode
```powershell
$env:DEBUG = "*"
.\start-server.ps1
```

---

## Integration with Audit

While running comprehensive audits:

1. **Start server in auto-restart mode:**
   ```powershell
   .\monitor-server.ps1 -AutoRestart
   ```

2. **Leave it running in a dedicated terminal**

3. **Run test script periodically:**
   ```powershell
   .\test-api.ps1
   ```

4. **Focus on development/audit work** - server manages itself

---

## Tips

- Always start server before running mobile app
- Use auto-restart during long development sessions
- Run test-api.ps1 after making changes
- Check server logs if tests fail
- Use Ctrl+C to stop gracefully
- Keep monitor terminal visible to see crashes
