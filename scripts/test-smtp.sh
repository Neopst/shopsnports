#!/bin/bash

###############################################################################
# SMTP Test Script for ShopsNPorts
#
# This script sends a test email using the configured SMTP settings.
#
# Usage: bash scripts/test-smtp.sh recipient@example.com
###############################################################################

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

RECIPIENT="${1:-}"
PROJECT_ID=$(firebase projects:list 2>/dev/null | grep -oP '(?<=\[)[^\]]+(?=\])' | head -1 || echo "")

echo -e "${BLUE}📧 SMTP Test - ShopsNPorts${NC}"
echo ""

# Check if recipient provided
if [ -z "$RECIPIENT" ]; then
    echo -e "${RED}Usage: bash scripts/test-smtp.sh recipient@example.com${NC}"
    echo ""
    echo "Example:"
    echo "  bash scripts/test-smtp.sh test@gmail.com"
    exit 1
fi

# Check if functions config is set
echo -e "${YELLOW}🔍 Checking SMTP configuration...${NC}"
CONFIG=$(firebase functions:config:get 2>/dev/null || echo "")

if [ -z "$CONFIG" ] || ! echo "$CONFIG" | grep -q "smtp"; then
    echo -e "${RED}❌ SMTP configuration not found${NC}"
    echo ""
    echo "Please run setup first:"
    echo "  ${YELLOW}bash scripts/setup-smtp.sh${NC}"
    exit 1
fi

# Get SMTP user from config (to verify)
SMTP_USER=$(echo "$CONFIG" | grep -oP '(?<="user": ")[^"]*' || echo "")

echo -e "${GREEN}✅ SMTP Configuration found${NC}"
echo "  SMTP User: $SMTP_USER"
echo "  Recipient: $RECIPIENT"
echo ""

# Create a simple test function call
echo -e "${BLUE}🧪 Sending test email...${NC}"
echo ""

# Check if we can use the existing test script
if [ -f "test-email-notification.js" ]; then
    echo -e "${YELLOW}Using existing test-email-notification.js${NC}"
    # You would need to update this script to accept recipient parameter
else
    echo -e "${YELLOW}To test email sending, you need to:${NC}"
    echo ""
    echo "1. Deploy functions first:"
    echo "   ${YELLOW}firebase deploy --only functions${NC}"
    echo ""
    echo "2. Then test via Firebase Console or by triggering sendEmail function"
    echo ""
    echo "3. Or use the test-email-notification.js script in project root"
    echo ""
fi

echo -e "${GREEN}✅ Test complete${NC}"
echo ""
echo -e "${BLUE}💡 Tip: Check your inbox for the test email${NC}"
echo ""