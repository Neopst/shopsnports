@{
  "audit_info" = "Mobile App Audit Script"
  "date" = "January 30, 2026"
  "purpose" = "Analyze shopsnports mobile app structure to identify ecommerce features for deletion"
}

# Run this in PowerShell:
# cd c:\projects\shopsnports
# Get-ChildItem -Path lib\features -Directory | ForEach-Object { Write-Host $_.Name }
# Get-ChildItem -Path lib\features -Recurse -File | Measure-Object | Select-Object Count
# Get-ChildItem -Path . -Recurse -File | Measure-Object -Property Length -Sum | Select-Object Count, @{Name="SizeMB";Expression={[math]::Round($_.Sum/1MB,2)}}

# Key commands to understand structure:
# 1. List all features: Get-ChildItem -Path lib\features -Directory
# 2. Count files: (Get-ChildItem -Path lib\features -Recurse -File).Count
# 3. Total size: (Get-ChildItem -Path . -Recurse -File | Measure-Object -Sum -Property Length).Sum / 1MB

# Features to identify and DELETE:
# - Cart system
# - Product browsing
# - Categories
# - Search (if ecommerce-focused)
# - All shopping-related screens
# - Payment/checkout features
# - Product detail screens
# - Wishlist
# - Reviews/ratings (if shopping)
# - Order history (if shopping)

# Features to KEEP:
# - Splash screens (reorder)
# - Shipping requests
# - Guest shipping
# - Affiliates
# - Auth
# - Profile
# - Navigation

