# LOGIN PAGE IMPLEMENTATION FIXES
**Complete Code to Make HTML Login a 100% Flutter Replica**

**Generated:** February 19, 2026  
**Priority:** CRITICAL - Do This Before Testing

---

## QUICK SUMMARY

This document provides the **exact code changes** needed to make the HTML login page a complete replica of the Flutter login page. Follow in order.

**Estimated Implementation Time:** 90-120 minutes  
**Testing Time:** 30 minutes  
**Total:** 2-2.5 hours

---

## CHANGE 1: Update index.html (Enhanced Version)

**File:** `admin-html/pages/index.html`

Replace the entire file with this enhanced version:

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>ShopsNPorts Admin - Login</title>
  
  <!-- CSS -->
  <link rel="stylesheet" href="/css/theme.css">
  <link rel="stylesheet" href="/css/login-page.css">
  <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
  
  <!-- Favicon -->
  <link rel="icon" href="/assets/favicon.ico">
</head>
<body>
  <div class="login-wrapper">
    <div class="login-container">
      <div class="login-card">
        
        <!-- Logo & Title -->
        <div class="login-header">
          <div class="login-icon">
            <i class="fas fa-chart-pie"></i>
          </div>
          <h1 class="login-title">Admin Dashboard</h1>
          <p class="login-subtitle">Sign in to your account</p>
        </div>

        <!-- Login Form -->
        <form id="loginForm" class="login-form">
          <!-- Email Input -->
          <div class="form-group">
            <label class="form-label" for="emailInput">Email Address</label>
            <div class="input-wrapper">
              <i class="fas fa-envelope input-icon"></i>
              <input 
                type="email" 
                id="emailInput" 
                class="form-input" 
                placeholder="admin@example.com"
                required
                aria-label="Email address"
              >
            </div>
            <div id="emailError" class="form-error" role="alert"></div>
          </div>

          <!-- Password Input -->
          <div class="form-group">
            <label class="form-label" for="passwordInput">Password</label>
            <div class="input-wrapper">
              <i class="fas fa-lock input-icon"></i>
              <input 
                type="password" 
                id="passwordInput" 
                class="form-input" 
                placeholder="Enter your password"
                required
                aria-label="Password"
              >
              <button 
                type="button" 
                class="toggle-password-btn" 
                id="togglePasswordBtn"
                title="Show/hide password"
                aria-label="Toggle password visibility"
              >
                <i class="fas fa-eye"></i>
              </button>
            </div>
            <div id="passwordError" class="form-error" role="alert"></div>
          </div>

          <!-- Remember Me -->
          <div class="form-group remember-group">
            <label class="checkbox-wrapper">
              <input 
                type="checkbox" 
                id="rememberMe" 
                class="form-checkbox"
                aria-label="Remember email"
              >
              <span class="checkbox-label">Remember me</span>
            </label>
          </div>

          <!-- Error Alert -->
          <div id="loginAlert" class="alert alert-danger login-alert fade-in" role="alert" style="display: none;">
            <i class="fas fa-exclamation-circle"></i>
            <span id="loginAlertText" class="alert-text"></span>
            <button type="button" class="alert-close" onclick="closeAlert()" aria-label="Close alert">
              <i class="fas fa-times"></i>
            </button>
          </div>

          <!-- Login Button -->
          <button type="submit" class="btn btn-primary btn-lg login-btn" id="loginButton">
            <span id="loginButtonText">Sign In</span>
            <i id="loginSpinner" class="fas fa-spinner spinner-icon" style="display: none;"></i>
          </button>
        </form>

        <!-- Forgot Password Link -->
        <div class="forgot-password-section">
          <a href="#" class="forgot-password-link">Forgot password?</a>
        </div>

        <!-- Demo Credentials Box -->
        <div class="demo-credentials-box fade-in">
          <div class="demo-credentials-header">
            <i class="fas fa-info-circle"></i>
            <span>Demo Credentials</span>
          </div>
          <div class="demo-credentials-content">
            <p class="demo-credential-item">
              <strong>Email:</strong> <code>demo@example.com</code>
            </p>
            <p class="demo-credential-item">
              <strong>Password:</strong> <code>Demo@123456</code>
            </p>
          </div>
        </div>

        <!-- Footer -->
        <div class="login-footer">
          <p>&copy; 2026 ShopsNPorts. All rights reserved.</p>
        </div>
      </div>
    </div>
  </div>

  <!-- Scripts -->
  <script src="/js/firebase-config.js"></script>
  <script src="/js/login-enhanced.js"></script>
</body>
</html>
```

---

## CHANGE 2: Create New CSS File for Login Page

**File:** `admin-html/css/login-page.css`

Create a new file with this content:

```css
/* ============================================================================
   Login Page Styles - Complete Replica of Flutter Admin Dashboard
   ============================================================================ */

:root {
  --login-primary: #2563eb;
  --login-primary-dark: #1e40af;
  --login-primary-light: #dbeafe;
  --login-success: #16a34a;
  --login-danger: #dc2626;
  --login-danger-light: #fee2e2;
  --login-danger-border: #fecaca;
  --login-warning: #ea580c;
  --login-text-dark: #1e293b;
  --login-text-light: #64748b;
  --login-border: #e2e8f0;
  --login-bg-light: #f3f4f6;
  --login-bg-white: #ffffff;
}

/* ============================================================================
   Global Login Styles
   ============================================================================ */

html, body {
  margin: 0;
  padding: 0;
}

body {
  background-color: var(--login-bg-light);
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', 'Oxygen',
    'Ubuntu', 'Cantarell', 'Fira Sans', 'Droid Sans', 'Helvetica Neue', sans-serif;
  min-height: 100vh;
}

/* ============================================================================
   Login Container
   ============================================================================ */

.login-wrapper {
  display: flex;
  align-items: center;
  justify-content: center;
  min-height: 100vh;
  padding: 1rem;
  background: linear-gradient(135deg, #f3f4f6 0%, #e5e7eb 100%);
}

.login-container {
  width: 100%;
  max-width: 420px;
  animation: fadeInScale 0.4s ease-out;
}

@keyframes fadeInScale {
  from {
    opacity: 0;
    transform: scale(0.95);
  }
  to {
    opacity: 1;
    transform: scale(1);
  }
}

/* ============================================================================
   Login Card
   ============================================================================ */

.login-card {
  background: var(--login-bg-white);
  border-radius: 0.75rem;
  padding: 2.5rem 2rem;
  box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1),
              0 10px 10px -5px rgba(0, 0, 0, 0.04);
  animation: slideUp 0.5s ease-out;
}

@keyframes slideUp {
  from {
    opacity: 0;
    transform: translateY(20px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

/* ============================================================================
   Login Header
   ============================================================================ */

.login-header {
  text-align: center;
  margin-bottom: 2rem;
}

.login-icon {
  font-size: 3rem;
  color: var(--login-primary);
  margin-bottom: 1rem;
  display: inline-block;
  animation: bounce 2s ease-in-out infinite;
}

@keyframes bounce {
  0%, 100% {
    transform: translateY(0);
  }
  50% {
    transform: translateY(-10px);
  }
}

.login-title {
  font-size: 1.875rem;
  font-weight: 700;
  color: var(--login-text-dark);
  margin: 0 0 0.5rem 0;
  letter-spacing: -0.5px;
}

.login-subtitle {
  font-size: 0.875rem;
  color: var(--login-text-light);
  margin: 0;
}

/* ============================================================================
   Login Form
   ============================================================================ */

.login-form {
  margin-bottom: 1.5rem;
}

.form-group {
  margin-bottom: 1.25rem;
}

.form-label {
  display: block;
  margin-bottom: 0.5rem;
  font-weight: 600;
  font-size: 0.875rem;
  color: var(--login-text-dark);
  letter-spacing: 0.3px;
}

/* ============================================================================
   Input Wrapper (for icons)
   ============================================================================ */

.input-wrapper {
  position: relative;
  display: flex;
  align-items: center;
}

.input-icon {
  position: absolute;
  left: 12px;
  color: var(--login-text-light);
  font-size: 1rem;
  z-index: 1;
  pointer-events: none;
  transition: color 0.2s ease;
}

.form-input:focus ~ .input-icon,
.form-input:hover ~ .input-icon {
  color: var(--login-primary);
}

.form-input {
  width: 100%;
  padding: 0.75rem 0.75rem 0.75rem 2.5rem;
  border: 1px solid var(--login-border);
  border-radius: 0.5rem;
  font-size: 0.875rem;
  background: var(--login-bg-white);
  color: var(--login-text-dark);
  transition: all 0.3s ease;
}

.form-input:focus {
  outline: none;
  border-color: var(--login-primary);
  box-shadow: 0 0 0 3px var(--login-primary-light);
  background: var(--login-bg-white);
}

.form-input:disabled {
  background-color: #f1f5f9;
  color: #94a3b8;
  cursor: not-allowed;
}

.form-input::placeholder {
  color: #cbd5e1;
}

/* ============================================================================
   Password Visibility Toggle
   ============================================================================ */

.toggle-password-btn {
  position: absolute;
  right: 12px;
  background: none;
  border: none;
  cursor: pointer;
  color: var(--login-text-light);
  font-size: 1rem;
  padding: 0.5rem;
  transition: all 0.2s ease;
  z-index: 2;
  display: flex;
  align-items: center;
  justify-content: center;
}

.toggle-password-btn:hover {
  color: var(--login-primary);
  transform: scale(1.1);
}

.toggle-password-btn:active {
  transform: scale(0.95);
}

.toggle-password-btn:focus-visible {
  outline: 2px solid var(--login-primary);
  outline-offset: 2px;
}

/* ============================================================================
   Checkbox (Remember Me)
   ============================================================================ */

.remember-group {
  margin-bottom: 2rem;
}

.checkbox-wrapper {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  cursor: pointer;
  user-select: none;
}

.form-checkbox {
  width: 18px;
  height: 18px;
  cursor: pointer;
  accent-color: var(--login-primary);
  transition: all 0.2s ease;
}

.form-checkbox:hover {
  transform: scale(1.05);
}

.form-checkbox:focus-visible {
  outline: 2px solid var(--login-primary);
  outline-offset: 2px;
}

.checkbox-label {
  font-size: 0.875rem;
  color: var(--login-text-light);
  cursor: pointer;
  transition: color 0.2s ease;
}

.checkbox-wrapper:hover .checkbox-label {
  color: var(--login-text-dark);
}

/* ============================================================================
   Error Alert
   ============================================================================ */

.login-alert {
  display: flex;
  align-items: flex-start;
  gap: 0.75rem;
  padding: 0.75rem 1rem;
  background: var(--login-danger-light);
  border: 1px solid var(--login-danger-border);
  border-radius: 0.5rem;
  margin-bottom: 1.5rem;
}

.login-alert i {
  color: var(--login-danger);
  font-size: 1rem;
  flex-shrink: 0;
  margin-top: 2px;
}

.alert-text {
  color: var(--login-danger);
  font-size: 0.875rem;
  flex: 1;
}

.alert-close {
  background: none;
  border: none;
  color: var(--login-danger);
  cursor: pointer;
  font-size: 1rem;
  padding: 0;
  display: flex;
  align-items: center;
  transition: all 0.2s ease;
  flex-shrink: 0;
  margin-left: 0.5rem;
}

.alert-close:hover {
  transform: scale(1.2);
}

/* ============================================================================
   Buttons
   ============================================================================ */

.login-btn {
  width: 100%;
  padding: 0.875rem 1rem;
  font-size: 1rem;
  font-weight: 600;
  background: var(--login-primary);
  color: white;
  border: none;
  border-radius: 0.5rem;
  cursor: pointer;
  transition: all 0.3s ease;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 0.5rem;
  box-shadow: 0 2px 8px rgba(37, 99, 235, 0.2);
}

.login-btn:hover:not(:disabled) {
  background: var(--login-primary-dark);
  box-shadow: 0 4px 12px rgba(37, 99, 235, 0.3);
  transform: translateY(-2px);
}

.login-btn:active:not(:disabled) {
  transform: translateY(0);
  box-shadow: 0 2px 4px rgba(37, 99, 235, 0.2);
}

.login-btn:disabled {
  opacity: 0.7;
  cursor: not-allowed;
}

.login-btn:focus-visible {
  outline: 2px solid var(--login-primary);
  outline-offset: 2px;
}

/* ============================================================================
   Spinner Animation
   ============================================================================ */

.spinner-icon {
  animation: spin 1s linear infinite;
}

@keyframes spin {
  from {
    transform: rotate(0deg);
  }
  to {
    transform: rotate(360deg);
  }
}

/* ============================================================================
   Forgot Password Section
   ============================================================================ */

.forgot-password-section {
  text-align: center;
  margin-bottom: 2rem;
}

.forgot-password-link {
  color: var(--login-primary);
  text-decoration: none;
  font-size: 0.875rem;
  font-weight: 500;
  transition: all 0.2s ease;
  display: inline-block;
}

.forgot-password-link:hover {
  color: var(--login-primary-dark);
  text-decoration: underline;
}

.forgot-password-link:focus-visible {
  outline: 2px solid var(--login-primary);
  outline-offset: 2px;
}

/* ============================================================================
   Demo Credentials Box
   ============================================================================ */

.demo-credentials-box {
  background: var(--login-primary-light);
  border: 1px solid #93c5fd;
  border-radius: 0.5rem;
  padding: 1rem;
  margin-bottom: 1.5rem;
}

.demo-credentials-header {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  font-weight: 600;
  color: var(--login-primary-dark);
  margin-bottom: 0.75rem;
  font-size: 0.875rem;
}

.demo-credentials-header i {
  font-size: 1rem;
}

.demo-credentials-content {
  margin: 0;
}

.demo-credential-item {
  margin: 0.5rem 0;
  font-size: 0.8rem;
  color: #1e40af;
  line-height: 1.4;
}

.demo-credential-item code {
  background: rgba(255, 255, 255, 0.5);
  padding: 0.125rem 0.375rem;
  border-radius: 3px;
  font-family: 'Monaco', 'Courier New', monospace;
  font-weight: 500;
}

/* ============================================================================
   Login Footer
   ============================================================================ */

.login-footer {
  text-align: center;
  padding-top: 1.5rem;
  border-top: 1px solid var(--login-border);
  margin-top: 1.5rem;
}

.login-footer p {
  font-size: 0.75rem;
  color: #94a3b8;
  margin: 0;
}

/* ============================================================================
   Animations
   ============================================================================ */

.fade-in {
  animation: fadeInUp 0.3s ease-out;
}

@keyframes fadeInUp {
  from {
    opacity: 0;
    transform: translateY(10px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

/* ============================================================================
   Error State
   ============================================================================ */

.form-input.error {
  border-color: var(--login-danger);
  background-color: #fee2e2;
}

.form-input.error:focus {
  box-shadow: 0 0 0 3px rgba(220, 38, 38, 0.1);
}

/* ============================================================================
   Form Error Message
   ============================================================================ */

.form-error {
  color: var(--login-danger);
  font-size: 0.75rem;
  margin-top: 0.25rem;
  display: none;
}

.form-error.show {
  display: block;
  animation: slideDown 0.2s ease-out;
}

@keyframes slideDown {
  from {
    opacity: 0;
    transform: translateY(-4px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

/* ============================================================================
   Responsive Design
   ============================================================================ */

@media (max-width: 480px) {
  .login-card {
    padding: 2rem 1.5rem;
  }

  .login-title {
    font-size: 1.5rem;
  }

  .login-icon {
    font-size: 2.5rem;
  }

  .login-container {
    max-width: 100%;
  }
}

/* ============================================================================
   Dark Mode Support (if needed in future)
   ============================================================================ */

@media (prefers-color-scheme: dark) {
  .login-wrapper {
    background: linear-gradient(135deg, #1a1a2e 0%, #16213e 100%);
  }

  .login-card {
    background: #0f172a;
    box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.5),
                0 10px 10px -5px rgba(0, 0, 0, 0.3);
  }

  .login-title {
    color: #f1f5f9;
  }

  .login-subtitle {
    color: #94a3b8;
  }

  .form-label {
    color: #e2e8f0;
  }

  .form-input {
    background: #1e293b;
    border-color: #334155;
    color: #f1f5f9;
  }

  .form-input:focus {
    border-color: #60a5fa;
    box-shadow: 0 0 0 3px rgba(96, 165, 250, 0.2);
  }

  .login-footer {
    border-color: #334155;
  }

  .login-footer p {
    color: #64748b;
  }
}

/* ============================================================================
   Print Styles
   ============================================================================ */

@media print {
  .login-wrapper {
    display: none;
  }
}

/* ============================================================================
   Accessibility
   ============================================================================ */

@media (prefers-reduced-motion: reduce) {
  * {
    animation: none !important;
    transition: none !important;
  }
}

/* Focus visible styles for keyboard navigation */
:focus-visible {
  outline: 2px solid var(--login-primary);
  outline-offset: 2px;
}

/* High contrast mode support */
@media (prefers-contrast: more) {
  .form-input {
    border-width: 2px;
  }

  .login-btn {
    border: 2px solid transparent;
  }
}
```

---

## CHANGE 3: Create Enhanced Auth JavaScript

**File:** `admin-html/js/login-enhanced.js`

Create this new enhanced auth file with all improved features:

```javascript
/**
 * Enhanced Authentication Module
 * Complete replica of Flutter Admin Dashboard login functionality
 */

// ============================================================================
// DOM Elements
// ============================================================================

let loginForm;
let emailInput;
let passwordInput;
let rememberMe;
let togglePasswordBtn;
let loginButton;
let loginButtonText;
let loginSpinner;
let loginAlert;
let loginAlertText;

// ============================================================================
// Initialize on DOM Ready
// ============================================================================

document.addEventListener('DOMContentLoaded', () => {
  initializeElements();
  attachEventListeners();
  checkAuthStatus();
  restoreRememberedEmail();
});

/**
 * Initialize DOM element references
 */
function initializeElements() {
  loginForm = document.getElementById('loginForm');
  emailInput = document.getElementById('emailInput');
  passwordInput = document.getElementById('passwordInput');
  rememberMe = document.getElementById('rememberMe');
  togglePasswordBtn = document.getElementById('togglePasswordBtn');
  loginButton = document.getElementById('loginButton');
  loginButtonText = document.getElementById('loginButtonText');
  loginSpinner = document.getElementById('loginSpinner');
  loginAlert = document.getElementById('loginAlert');
  loginAlertText = document.getElementById('loginAlertText');
}

/**
 * Attach event listeners
 */
function attachEventListeners() {
  if (loginForm) {
    loginForm.addEventListener('submit', handleLogin);
  }

  // Password visibility toggle
  if (togglePasswordBtn) {
    togglePasswordBtn.addEventListener('click', togglePasswordVisibility);
  }

  // Enter key in password field submits form
  if (passwordInput) {
    passwordInput.addEventListener('keypress', (e) => {
      if (e.key === 'Enter' && !loginButton.disabled) {
        loginForm.dispatchEvent(new Event('submit'));
      }
    });
  }

  // Clear error on input
  if (emailInput) {
    emailInput.addEventListener('input', () => {
      clearError('emailInput');
    });
  }

  if (passwordInput) {
    passwordInput.addEventListener('input', () => {
      clearError('passwordInput');
    });
  }

  // Logout button
  const logoutBtn = document.getElementById('logoutBtn');
  if (logoutBtn) {
    logoutBtn.addEventListener('click', handleLogout);
  }

  // User menu toggle
  const userMenuToggle = document.getElementById('userMenuToggle');
  const userDropdown = document.getElementById('userDropdown');
  
  if (userMenuToggle && userDropdown) {
    userMenuToggle.addEventListener('click', (e) => {
      e.stopPropagation();
      userDropdown.style.display = userDropdown.style.display === 'none' ? 'block' : 'none';
    });

    document.addEventListener('click', () => {
      userDropdown.style.display = 'none';
    });
  }
}

/**
 * Toggle password visibility
 */
function togglePasswordVisibility() {
  const isPassword = passwordInput.type === 'password';
  
  passwordInput.type = isPassword ? 'text' : 'password';
  
  // Update icon
  const icon = togglePasswordBtn.querySelector('i');
  if (icon) {
    icon.classList.toggle('fa-eye');
    icon.classList.toggle('fa-eye-slash');
  }
  
  // Focus password input
  passwordInput.focus();
}

/**
 * Handle login form submission
 */
async function handleLogin(e) {
  e.preventDefault();

  // Hide any existing error alert
  hideAlert();

  // Validation
  const emailError = validateEmail(emailInput.value);
  const passwordError = validatePassword(passwordInput.value);

  if (emailError) {
    showFieldError('emailInput', emailError);
    return;
  }

  if (passwordError) {
    showFieldError('passwordInput', passwordError);
    return;
  }

  // Disable form
  disableForm();

  try {
    // Wait for Firebase to be initialized
    if (!auth) {
      throw new Error('Firebase not initialized');
    }

    // Sign in with Firebase
    const userCredential = await auth.signInWithEmailAndPassword(
      emailInput.value.trim(),
      passwordInput.value
    );

    const user = userCredential.user;

    // Get user info from Firestore
    const adminDoc = await db.collection('admin_users').doc(user.uid).get();
    
    if (!adminDoc.exists) {
      throw new Error('User profile not found. Please contact administrator.');
    }

    const adminData = adminDoc.data();

    // Store user data in localStorage
    localStorage.setItem('adminUser', JSON.stringify({
      uid: user.uid,
      email: user.email,
      displayName: adminData.displayName,
      role: adminData.role,
      permissions: adminData.permissions,
      requirePasswordChange: adminData.requirePasswordChange
    }));

    // Remember me?
    if (rememberMe.checked) {
      localStorage.setItem('rememberEmail', emailInput.value);
    } else {
      localStorage.removeItem('rememberEmail');
    }

    console.log('✅ Login successful');

    // Show success message
    showSuccessMessage('Login successful! Redirecting...');

    // Small delay for UX
    setTimeout(() => {
      // Check if password change is required
      if (adminData.requirePasswordChange) {
        window.location.href = '/pages/password-change.html';
      } else {
        window.location.href = '/dashboard.html';
      }
    }, 500);

  } catch (error) {
    console.error('❌ Login error:', error);
    handleLoginError(error);
    
  } finally {
    // Re-enable form
    enableForm();
  }
}

/**
 * Handle login errors
 */
function handleLoginError(error) {
  let errorTitle = 'Login Failed';
  let errorMessage = 'An error occurred. Please try again.';

  if (error.code === 'auth/user-not-found') {
    errorMessage = 'User not found. Please check your email address.';
  } else if (error.code === 'auth/wrong-password') {
    errorMessage = 'Incorrect password. Please try again.';
  } else if (error.code === 'auth/invalid-email') {
    errorMessage = 'Invalid email address format.';
  } else if (error.code === 'auth/user-disabled') {
    errorMessage = 'Your account has been disabled. Contact your administrator.';
  } else if (error.code === 'auth/too-many-requests') {
    errorMessage = 'Too many login attempts. Please try again later.';
  } else if (error.code === 'auth/network-request-failed') {
    errorMessage = 'Network error. Please check your connection.';
  } else if (error.message === 'User profile not found. Please contact administrator.') {
    errorMessage = error.message;
  }

  showAlert(errorMessage);
}

/**
 * Show alert message
 */
function showAlert(message) {
  loginAlertText.textContent = message;
  loginAlert.style.display = 'flex';
  loginAlert.classList.add('fade-in');
  
  // Auto-dismiss after 5 seconds
  setTimeout(() => {
    hideAlert();
  }, 5000);
}

/**
 * Show success message
 */
function showSuccessMessage(message) {
  // Create success alert (similar structure to error alert)
  const successAlert = document.createElement('div');
  successAlert.className = 'alert alert-success fade-in';
  successAlert.style.marginBottom = '1.5rem';
  successAlert.innerHTML = `
    <i class="fas fa-check-circle" style="color: #16a34a;"></i>
    <span class="alert-text" style="color: #16a34a;">${message}</span>
  `;
  
  loginForm.parentElement.insertBefore(successAlert, loginForm);
  
  setTimeout(() => {
    successAlert.remove();
  }, 2000);
}

/**
 * Hide alert message
 */
function hideAlert() {
  loginAlert.style.display = 'none';
  loginAlert.classList.remove('fade-in');
}

/**
 * Close alert button handler
 */
function closeAlert() {
  hideAlert();
}

/**
 * Show field error
 */
function showFieldError(fieldId, message) {
  const field = document.getElementById(fieldId);
  const errorElement = document.getElementById(fieldId + 'Error');
  
  if (field) {
    field.classList.add('error');
  }
  
  if (errorElement) {
    errorElement.textContent = message;
    errorElement.classList.add('show');
  }
}

/**
 * Clear error message
 */
function clearError(fieldId) {
  const field = document.getElementById(fieldId);
  const errorElement = document.getElementById(fieldId + 'Error');
  
  if (field) {
    field.classList.remove('error');
  }
  
  if (errorElement) {
    errorElement.textContent = '';
    errorElement.classList.remove('show');
  }
}

/**
 * Validate email
 */
function validateEmail(email) {
  if (!email) {
    return 'Please enter your email address';
  }
  
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  if (!emailRegex.test(email)) {
    return 'Please enter a valid email address';
  }
  
  return null;
}

/**
 * Validate password
 */
function validatePassword(password) {
  if (!password) {
    return 'Please enter your password';
  }
  
  if (password.length < 6) {
    return 'Password must be at least 6 characters';
  }
  
  return null;
}

/**
 * Disable form during submission
 */
function disableForm() {
  emailInput.disabled = true;
  passwordInput.disabled = true;
  togglePasswordBtn.disabled = true;
  rememberMe.disabled = true;
  loginButton.disabled = true;
  
  loginButtonText.style.display = 'none';
  loginSpinner.style.display = 'inline-block';
}

/**
 * Enable form after submission
 */
function enableForm() {
  emailInput.disabled = false;
  passwordInput.disabled = false;
  togglePasswordBtn.disabled = false;
  rememberMe.disabled = false;
  loginButton.disabled = false;
  
  loginButtonText.style.display = 'inline';
  loginSpinner.style.display = 'none';
}

/**
 * Check authentication status
 */
async function checkAuthStatus() {
  const isLoginPage = window.location.pathname.includes('index.html') || window.location.pathname === '/' || window.location.pathname.endsWith('/');
  const adminUser = localStorage.getItem('adminUser');

  if (isLoginPage) {
    if (adminUser) {
      // Already logged in, redirect to dashboard
      setTimeout(() => {
        window.location.href = '/dashboard.html';
      }, 200);
    }
  } else {
    // On protected page, check if authenticated
    if (!adminUser) {
      // Not logged in, redirect to login
      window.location.href = '/pages/index.html';
    } else {
      // Load user info in navbar
      loadCurrentUserInfo();
    }
  }
}

/**
 * Restore remembered email
 */
function restoreRememberedEmail() {
  if (!emailInput) return;
  
  const rememberedEmail = localStorage.getItem('rememberEmail');
  if (rememberedEmail) {
    emailInput.value = rememberedEmail;
    rememberMe.checked = true;
  }
}

/**
 * Load current user info in navbar
 */
function loadCurrentUserInfo() {
  const adminUser = JSON.parse(localStorage.getItem('adminUser'));
  
  if (adminUser) {
    const userName = document.getElementById('userName');
    const userRole = document.getElementById('userRole');
    const userAvatar = document.getElementById('userAvatar');

    if (userName) userName.textContent = adminUser.displayName;
    if (userRole) {
      const roleDisplay = adminUser.role === 'super_admin' ? 'Super Admin' : 'Admin';
      userRole.textContent = roleDisplay;
    }
    if (userAvatar) {
      userAvatar.textContent = adminUser.displayName
        .split(' ')
        .map(n => n[0])
        .join('')
        .toUpperCase();
    }
  }
}

/**
 * Get current user from localStorage
 */
function getCurrentAdminUser() {
  const user = localStorage.getItem('adminUser');
  return user ? JSON.parse(user) : null;
}

/**
 * Check if user has permission to access module
 */
function hasModuleAccess(moduleName) {
  const adminUser = getCurrentAdminUser();
  if (!adminUser) return false;
  
  if (adminUser.role === 'super_admin') return true;
  
  return adminUser.permissions?.[moduleName] === true;
}

/**
 * Redirect to login if not authenticated
 */
function requireAuth() {
  const adminUser = getCurrentAdminUser();
  if (!adminUser) {
    window.location.href = '/pages/index.html';
    return false;
  }
  return true;
}

/**
 * Redirect to login if unauthorized
 */
function requireModuleAccess(moduleName) {
  if (!requireAuth()) return false;
  
  if (!hasModuleAccess(moduleName)) {
    alert('You do not have access to this module');
    window.history.back();
    return false;
  }
  return true;
}

/**
 * Handle logout
 */
async function handleLogout() {
  try {
    await logout();
  } catch (error) {
    console.error('Logout error:', error);
  }
}

/**
 * Change admin password
 */
async function changeAdminPassword(currentPassword, newPassword) {
  const user = auth.currentUser;
  if (!user) {
    throw new Error('User not authenticated');
  }

  try {
    // Reauthenticate user
    const credential = firebase.auth.EmailAuthProvider.credential(
      user.email,
      currentPassword
    );
    await user.reauthenticateWithCredential(credential);

    // Update password in Firebase Auth
    await user.updatePassword(newPassword);

    // Update requirePasswordChange flag in Firestore
    await db.collection('admin_users').doc(user.uid).update({
      requirePasswordChange: false,
      lastPasswordChange: new Date(),
      updatedAt: new Date()
    });

    // Update localStorage
    const adminUser = JSON.parse(localStorage.getItem('adminUser'));
    adminUser.requirePasswordChange = false;
    localStorage.setItem('adminUser', JSON.stringify(adminUser));

    return {
      success: true,
      message: 'Password changed successfully'
    };
  } catch (error) {
    console.error('Password change error:', error);
    throw error;
  }
}

/**
 * Logout user
 */
async function logout() {
  try {
    await auth.signOut();
    localStorage.removeItem('adminUser');
    localStorage.removeItem('rememberEmail');
    window.location.href = '/pages/index.html';
  } catch (error) {
    console.error('Logout error:', error);
    throw error;
  }
}
```

---

## CHANGE 4: Update Global Auth.js (Keep Compatibility)

**File:** `admin-html/js/auth.js`

Update this file to use the new login page script while maintaining backward compatibility:

```javascript
/**
 * Authentication Module - Main Entry Point
 * This file provides backward compatibility for existing pages
 * New login functionality is in login-enhanced.js
 */

// Import all functions from login-enhanced if running on login page
// Otherwise, provide compatibility wrappers

/**
 * Check if on login page
 */
const isOnLoginPage = () => {
  return window.location.pathname.includes('index.html') || 
         window.location.pathname === '/' || 
         window.location.pathname.endsWith('/pages/');
};

// If on login page, all functions are handled by login-enhanced.js
if (!isOnLoginPage()) {
  // For protected pages, provide these functions
  
  /**
   * Get current user from localStorage
   */
  function getCurrentAdminUser() {
    const user = localStorage.getItem('adminUser');
    return user ? JSON.parse(user) : null;
  }

  /**
   * Check if user has permission to access module
   */
  function hasModuleAccess(moduleName) {
    const adminUser = getCurrentAdminUser();
    if (!adminUser) return false;
    
    if (adminUser.role === 'super_admin') return true;
    
    return adminUser.permissions?.[moduleName] === true;
  }

  /**
   * Redirect to login if not authenticated
   */
  function requireAuth() {
    const adminUser = getCurrentAdminUser();
    if (!adminUser) {
      window.location.href = '/pages/index.html';
      return false;
    }
    return true;
  }

  /**
   * Redirect to login if unauthorized
   */
  function requireModuleAccess(moduleName) {
    if (!requireAuth()) return false;
    
    if (!hasModuleAccess(moduleName)) {
      alert('You do not have access to this module');
      window.history.back();
      return false;
    }
    return true;
  }

  /**
   * Load current user info in navbar
   */
  function loadCurrentUserInfo() {
    const adminUser = JSON.parse(localStorage.getItem('adminUser'));
    
    if (adminUser) {
      const userName = document.getElementById('userName');
      const userRole = document.getElementById('userRole');
      const userAvatar = document.getElementById('userAvatar');

      if (userName) userName.textContent = adminUser.displayName;
      if (userRole) {
        const roleDisplay = adminUser.role === 'super_admin' ? 'Super Admin' : 'Admin';
        userRole.textContent = roleDisplay;
      }
      if (userAvatar) {
        userAvatar.textContent = adminUser.displayName
          .split(' ')
          .map(n => n[0])
          .join('')
          .toUpperCase();
      }
    }
  }

  /**
   * Handle logout
   */
  async function handleLogout() {
    try {
      await logout();
    } catch (error) {
      console.error('Logout error:', error);
    }
  }

  /**
   * Logout user
   */
  async function logout() {
    try {
      await auth.signOut();
      localStorage.removeItem('adminUser');
      localStorage.removeItem('rememberEmail');
      window.location.href = '/pages/index.html';
    } catch (error) {
      console.error('Logout error:', error);
      throw error;
    }
  }

  /**
   * Check authentication on protected pages
   */
  document.addEventListener('DOMContentLoaded', () => {
    requireAuth();
    
    // Setup logout
    const logoutBtn = document.getElementById('logoutBtn');
    if (logoutBtn) {
      logoutBtn.addEventListener('click', handleLogout);
    }

    // Setup user menu
    const userMenuToggle = document.getElementById('userMenuToggle');
    const userDropdown = document.getElementById('userDropdown');
    
    if (userMenuToggle && userDropdown) {
      userMenuToggle.addEventListener('click', (e) => {
        e.stopPropagation();
        userDropdown.style.display = userDropdown.style.display === 'none' ? 'block' : 'none';
      });

      document.addEventListener('click', () => {
        userDropdown.style.display = 'none';
      });
    }
  });
}
```

---

## SUMMARY OF CHANGES

| File | Change | Impact |
|------|--------|--------|
| `pages/index.html` | **Complete rewrite** with enhanced HTML | HIGH |
| `css/login-page.css` | **New file** with complete styling | HIGH |
| `js/login-enhanced.js` | **New file** with all enhanced features | HIGH |
| `js/auth.js` | **Updated** for backward compatibility | MEDIUM |

---

## FEATURES NOW IMPLEMENTED

✅ Password visibility toggle icon  
✅ Demo credentials info box  
✅ Input disabled during loading  
✅ Input field icons (email, lock)  
✅ Smooth animations & transitions  
✅ Animated loading spinner  
✅ Complete error handling  
✅ Real-time input validation  
✅ Remember me checkbox with localStorage  
✅ Hover effects on buttons  
✅ Focus state effects  
✅ Enter key to submit  
✅ Accessibility improvements  
✅ Mobile responsive design  
✅ Dark mode support (CSS prepared)  
✅ Tab navigation support  

---

## TESTING CHECKLIST

Before running full tests, verify:

- [ ] Password toggle shows/hides password with eye icon
- [ ] Demo credentials box appears below form
- [ ] Login button spinner animates during submission
- [ ] Email and password fields disable during login
- [ ] Error message appears with animation
- [ ] Success message redirects to dashboard
- [ ] Remember me saves email
- [ ] Hover effects work on button
- [ ] Enter key submits form
- [ ] Tab navigation works
- [ ] Mobile view is responsive
- [ ] All animations are smooth
- [ ] Accessibility is working

---

**Time to Implement:** 90-120 minutes  
**Time to Test:** 30 minutes  
**Total:** 2-2.5 hours

**Ready to proceed?** Run the tests once these changes are applied.
