/// Elasticsearch configuration for search functionality
/// Note: This is a placeholder - actual implementation depends on your search infrastructure
class ElasticsearchConfig {
  final String? host;
  final int? port;
  final String? index;
  final bool? enableSSL;
  final Duration connectionTimeout;
  final Duration searchTimeout;

  ElasticsearchConfig({
    this.host,
    this.port,
    this.index,
    this.enableSSL,
    required this.connectionTimeout,
    required this.searchTimeout,
  });

  factory ElasticsearchConfig.development() {
    return ElasticsearchConfig(
      host: 'localhost',
      port: 9200,
      index: 'dev_shipments',
      enableSSL: false,
      connectionTimeout: const Duration(seconds: 10),
      searchTimeout: const Duration(seconds: 30),
    );
  }

  factory ElasticsearchConfig.staging() {
    return ElasticsearchConfig(
      host: 'staging-search.example.com',
      port: 9200,
      index: 'staging_shipments',
      enableSSL: true,
      connectionTimeout: const Duration(seconds: 10),
      searchTimeout: const Duration(seconds: 30),
    );
  }

  factory ElasticsearchConfig.production() {
    return ElasticsearchConfig(
      host: 'prod-search.example.com',
      port: 9200,
      index: 'prod_shipments',
      enableSSL: true,
      connectionTimeout: const Duration(seconds: 5),
      searchTimeout: const Duration(seconds: 10),
    );
  }
}