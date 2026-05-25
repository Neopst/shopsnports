Write-Host "Running Admin Dashboard QA Tests" -ForegroundColor Green
Write-Host "===================================" -ForegroundColor Green
Write-Host ""

Write-Host "1. Running E2E Functional Tests..." -ForegroundColor Yellow
flutter test integration_test/admin_e2e_test.dart --verbose

Write-Host ""
Write-Host "2. Running Performance Tests..." -ForegroundColor Yellow
# Use optimized CI/CD version for faster execution
flutter test integration_test/admin_performance_test_ci.dart --verbose

Write-Host ""
Write-Host "3. Running Unit Tests for Admin Services..." -ForegroundColor Yellow
flutter test test/admin_services_test.dart --verbose

Write-Host ""
Write-Host "4. Checking Code Coverage..." -ForegroundColor Yellow
flutter test --coverage test/
if (Test-Path "coverage\lcov.info") {
    Write-Host "Coverage report generated at coverage/lcov.info" -ForegroundColor Green
    Write-Host "Use 'genhtml coverage/lcov.info -o coverage/html' to generate HTML report" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "5. Running Lint Checks..." -ForegroundColor Yellow
flutter analyze lib/

Write-Host ""
Write-Host "Admin QA Tests Complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "- Review test results above" -ForegroundColor White
Write-Host "- Check ADMIN_QA_CHECKLIST.md for manual testing procedures" -ForegroundColor White
Write-Host "- Address any failing tests or lint issues" -ForegroundColor White
Write-Host "- Run manual QA checklist items" -ForegroundColor White
echo.