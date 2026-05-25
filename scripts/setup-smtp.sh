#!/bin/bash

###############################################################################
# SMTP Configuration Setup Script for ShopsNPorts
#
# This script securely configures SMTP credentials for Firebase Cloud Functions
# by storing them in Firebase Functions config (encrypted, not in git).
#
# Usage: bash scripts/setup-smtp.sh
###############################################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print header
echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}        📧 SMTP Configuration Setup - ShopsNPorts${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo ""
echo "This will configure SMTP credentials for email sending."
echo "Credentials will be stored securely in Firebase Functions config."
echo ""

# Check if firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo -e "${RED}❌ Error: Firebase CLI not found${NC}"
    echo "Please install it first: npm install -g firebase-tools"
    exit 1
fi

# Check if logged in to Firebase
echo -e "${YELLOW}🔍 Checking Firebase login status...${NC}"
if firebase login:list 2>/dev/null | grep -q "No active"; then
    echo -e "${YELLOW}⚠️  Not logged in to Firebase${NC}"
    echo "Please run: firebase login"
    echo ""
    read -p "Press Enter to continue after logging in, or Ctrl+C to cancel..."
    firebase login
fi

echo -e "${GREEN}✅ Firebase CLI ready${NC}"
echo ""

# Prompt for SMTP configuration
echo -e "${BLUE}📝 SMTP Configuration (ShopsNPorts):${NC}"
echo ""
echo "Using ShopsNPorts SMTP settings:"
echo "  SMTP Host:     mail.shopsnports.com"
echo "  SMTP Port:     465"
echo "  SMTP User:     noreply@shopsnports.com"
echo "  SSL/TLS:       Enabled"
echo ""

# Set ShopsNPorts SMTP defaults
SMTP_HOST="mail.shopsnports.com"
SMTP_PORT="465"
SMTP_USER="noreply@shopsnports.com"
SMTP_SECURE="true"

# SMTP Password (hidden input) - ONLY prompt for password
echo ""
read -s -p "Enter the email account's password: " SMTP_PASS
echo ""
if [ -z "$SMTP_PASS" ]; then
    echo -e "${RED}❌ Error: SMTP Password is required${NC}"
    exit 1
fi

# Display confirmation
echo ""
echo -e "${BLUE}───────────────────────────────────────────────────────────────${NC}"
echo -e "${BLUE}📋 Configuration Summary:${NC}"
echo -e "${BLUE}───────────────────────────────────────────────────────────────${NC}"
echo "  SMTP Host:     $SMTP_HOST"
echo "  SMTP Port:     $SMTP_PORT"
echo "  SMTP User:     $SMTP_USER"
echo "  SMTP Password: $(echo '********')"  # Hidden
echo "  Secure SSL:    $SMTP_SECURE"
echo ""

# Confirm before proceeding
read -p "Proceed with this configuration? (yes/no): " CONFIRM
if [[ ! "$CONFIRM" =~ ^[Yy][Ee][Ss]$ ]]; then
    echo -e "${YELLOW}⚠️  Setup cancelled${NC}"
    exit 0
fi

echo ""
echo -e "${BLUE}🔧 Configuring Firebase Functions...${NC}"
echo ""

# Apply configuration
firebase functions:config:set \
    smtp.host="$SMTP_HOST" \
    smtp.port="$SMTP_PORT" \
    smtp.user="$SMTP_USER" \
    smtp.pass="$SMTP_PASS" \
    smtp.secure="$SMTP_SECURE" || {
    echo -e "${RED}❌ Failed to configure Firebase Functions${NC}"
    exit 1
}

echo ""
echo -e "${GREEN}✅ SMTP configuration saved successfully!${NC}"
echo ""
echo -e "${BLUE}───────────────────────────────────────────────────────────────${NC}"
echo -e "${BLUE}📌 Next Steps:${NC}"
echo -e "${BLUE}───────────────────────────────────────────────────────────────${NC}"
echo ""
echo "1. Deploy functions to apply changes:"
echo "   ${YELLOW}firebase deploy --only functions${NC}"
echo ""
echo "2. Test email sending with:"
echo "   ${YELLOW}node test-email-notification.js${NC}"
echo ""
echo "3. To view current configuration:"
echo "   ${YELLOW}firebase functions:config:get${NC}"
echo ""
echo "4. To update configuration later, run this script again:"
echo "   ${YELLOW}bash scripts/setup-smtp.sh${NC}"
echo ""
echo -e "${GREEN}🎉 Setup complete!${NC}"
echo ""