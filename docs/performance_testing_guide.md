# Performance Testing Guide

## Overview
This guide covers performance testing for the ShopsNSports mobile app and backend.

## Mobile App Performance

### 1. Startup Performance
Test app cold start time:

```bash
# Run performance test
flutter run --profile --trace-startup

# Analyze results
flutter analyze --trace-startup
```

**Target:** < 3 seconds from tap to interactive

### 2. Frame Rendering
Monitor frame rates during scrolling:

```bash
# Run with performance overlay
flutter run --profile

# Toggle performance overlay in app
# Press 'P' in terminal
```

**Target:** Consistent 60fps, no jank

### 3. Memory Usage
Monitor memory consumption:

```bash
# Run with memory profiling
flutter run --profile

# Use DevTools memory profiler
flutter pub global activate devtools
flutter pub global run devtools
```

**Targets:**
- Initial memory: < 100MB
- Peak memory: < 250MB
- No memory leaks

### 4. Network Performance
Test API response times:

```bash
# Run integration tests with timeline
flutter drive \
  --target=integration_test/performance_test.dart \
  --profile \
  --trace-startup
```

**Targets:**
- Product list load: < 2s
- Checkout API: < 1s
- Image load: < 1s

### 5. Build Size
Analyze app bundle size:

```bash
# Android
flutter build appbundle --release --analyze-size

# iOS
flutter build ipa --release --analyze-size
```

**Target:** < 50MB total download size

## Backend Performance

### 1. Load Testing
Use artillery for load testing:

```bash
cd server
npm install -g artillery

# Run load test
artillery run load-test.yml
```

Example `load-test.yml`:
```yaml
config:
  target: "https://your-api.com"
  phases:
    - duration: 60
      arrivalRate: 10
      name: "Warm up"
    - duration: 120
      arrivalRate: 50
      name: "Sustained load"
    - duration: 60
      arrivalRate: 100
      name: "Peak load"

scenarios:
  - name: "Product browsing"
    flow:
      - get:
          url: "/api/v1/products"
      - get:
          url: "/api/v1/products/{{ $randomString() }}"
      
  - name: "Checkout flow"
    flow:
      - post:
          url: "/api/v1/checkout"
          json:
            amount: 100
            currency: "USD"
```

**Targets:**
- 95th percentile response time: < 500ms
- Error rate: < 1%
- Concurrent users: 100+

### 2. Database Performance
Monitor Firestore read/write operations:

```javascript
// Add to server code
const { performance } = require('perf_hooks');

async function measureQuery() {
  const start = performance.now();
  const result = await db.collection('products').get();
  const duration = performance.now() - start;
  console.log(`Query took ${duration}ms`);
  return result;
}
```

**Targets:**
- Simple queries: < 100ms
- Complex queries: < 300ms
- Writes: < 200ms

### 3. API Endpoint Benchmarks

Run benchmark tests:
```bash
# Install autocannon
npm install -g autocannon

# Test product listing
autocannon -c 100 -d 30 https://your-api.com/api/v1/products

# Test checkout endpoint
autocannon -c 50 -d 30 -m POST \
  -H "Content-Type: application/json" \
  -b '{"amount":100}' \
  https://your-api.com/api/v1/checkout
```

## Integration Test Performance

Run performance integration test:

```bash
flutter drive \
  --target=integration_test/admin_performance_test.dart \
  --profile
```

This will measure:
- Screen transition times
- Widget build times
- Network request durations
- User interaction responsiveness

## Profiling Tools

### Flutter DevTools
```bash
flutter pub global activate devtools
flutter pub global run devtools

# In another terminal
flutter run --profile
```

Features:
- CPU profiler
- Memory profiler
- Network inspector
- Timeline view

### Chrome DevTools (for Web Admin)
1. Build admin dashboard: `flutter build web --profile`
2. Serve: `python -m http.server -d build/web`
3. Open Chrome DevTools
4. Use Performance tab

## Performance Optimization Tips

### Mobile App
1. **Images**
   - Use `cached_network_image` with proper sizing
   - Compress images before upload
   - Use WebP format where possible

2. **Lists**
   - Use `ListView.builder` for long lists
   - Implement pagination
   - Cache list data

3. **State Management**
   - Minimize rebuilds with proper provider scoping
   - Use `const` constructors where possible
   - Avoid expensive operations in build methods

4. **Network**
   - Implement request caching
   - Use connection pooling
   - Compress API responses

### Backend
1. **Database**
   - Create composite indexes for common queries
   - Use batch operations
   - Implement query result caching

2. **API**
   - Enable gzip compression
   - Use CDN for static assets
   - Implement rate limiting

3. **Caching**
   - Cache frequently accessed data
   - Use Redis for session storage
   - Implement HTTP caching headers

## Continuous Performance Monitoring

### Firebase Performance Monitoring
```dart
// Already integrated - monitors:
// - App startup time
// - Screen rendering time
// - Network requests
```

### Backend Monitoring
```javascript
// CloudWatch metrics
// - API response times
// - Error rates
// - Resource utilization
```

## Performance Testing Schedule

- **Before each release:** Full performance test suite
- **Weekly:** Automated performance regression tests
- **Monthly:** Load testing and capacity planning
- **Quarterly:** Full system performance audit

## Performance Regression Detection

Set up automated alerts for:
- App startup time > 3s
- API response time > 500ms
- Frame rate < 55fps
- Memory usage > 300MB
- Error rate > 1%

## Reporting

Generate performance reports:
```bash
# Mobile app report
flutter test --reporter=json > test_results.json
python scripts/generate_perf_report.py test_results.json

# Backend report
artillery report load-test-results.json
```

## Troubleshooting Performance Issues

### Slow App Startup
1. Check for synchronous initialization
2. Defer non-critical initialization
3. Use lazy loading for plugins
4. Profile with `--trace-startup`

### Janky Scrolling
1. Enable performance overlay (`P` key)
2. Check for expensive build methods
3. Use `const` constructors
4. Optimize images

### High Memory Usage
1. Use DevTools memory profiler
2. Check for leaked streams
3. Verify images are disposed
4. Monitor provider lifecycles

### Slow API Responses
1. Check database query performance
2. Enable query logging
3. Add appropriate indexes
4. Implement caching
5. Use connection pooling
