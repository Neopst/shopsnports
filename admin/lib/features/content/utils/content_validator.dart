import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as html_dom;

/// Utility class for content validation and sanitization
class ContentValidator {
  /// Allowed HTML tags for content (safe subset)
  static const allowedTags = {
    'p', 'br', 'strong', 'b', 'em', 'i', 'u', 'a', 'ul', 'ol', 'li',
    'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'blockquote', 'code', 'pre',
    'div', 'span', 'table', 'thead', 'tbody', 'tr', 'td', 'th'
  };

  /// Allowed HTML attributes
  static const allowedAttributes = {
    'href', 'title', 'alt', 'src', 'class', 'id', 'style'
  };

  /// Maximum content length
  static const maxContentLength = 100000;

  /// Maximum title length
  static const maxTitleLength = 200;

  /// Maximum description length
  static const maxDescriptionLength = 500;

  /// Sanitize HTML content to prevent XSS attacks
  static String sanitizeHtml(String html) {
    if (html.isEmpty) return html;

    try {
      final document = html_parser.parse(html);
      _sanitizeNode(document.body!);
      return document.body!.innerHtml;
    } catch (e) {
      // If parsing fails, return empty string to be safe
      return '';
    }
  }

  /// Recursively sanitize HTML nodes
  static void _sanitizeNode(html_dom.Node node) {
    if (node is html_dom.Element) {
      // Remove disallowed tags
      if (!allowedTags.contains(node.localName)) {
        node.replaceWith(html_dom.Text(node.text));
        return;
      }

      // Remove disallowed attributes
      final attributesToRemove = <String>[];
      for (final attr in node.attributes.keys) {
        final attrStr = attr.toString();
        if (!allowedAttributes.contains(attrStr)) {
          attributesToRemove.add(attrStr);
        } else if (attrStr == 'href' || attrStr == 'src') {
          // Sanitize URLs to prevent javascript: and data: protocols
          final value = node.attributes[attr]!;
          if (value.startsWith('javascript:') ||
              value.startsWith('data:') ||
              value.startsWith('vbscript:')) {
            attributesToRemove.add(attrStr);
          }
        }
      }
      for (final attr in attributesToRemove) {
        node.attributes.remove(attr);
      }

      // Recursively sanitize children
      final children = node.nodes.toList();
      for (final child in children) {
        _sanitizeNode(child);
      }
    }
  }

  /// Validate slug format (URL-friendly)
  static bool isValidSlug(String slug) {
    if (slug.isEmpty) return false;
    // Only lowercase letters, numbers, and hyphens
    final regex = RegExp(r'^[a-z0-9-]+$');
    return regex.hasMatch(slug) && !slug.startsWith('-') && !slug.endsWith('-');
  }

  /// Generate slug from title
  static String generateSlug(String title) {
    return title
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
  }

  /// Validate content length
  static bool isValidContentLength(String content) {
    return content.length <= maxContentLength;
  }

  /// Validate title length
  static bool isValidTitleLength(String title) {
    return title.isNotEmpty && title.length <= maxTitleLength;
  }

  /// Validate description length
  static bool isValidDescriptionLength(String description) {
    return description.length <= maxDescriptionLength;
  }

  /// Validate image URL
  static bool isValidImageUrl(String? url) {
    if (url == null || url.isEmpty) return true; // Empty is allowed (optional)
    try {
      final uri = Uri.parse(url);
      // Only allow http, https, and Firebase Storage paths
      if (uri.hasScheme) {
        return uri.scheme == 'http' || uri.scheme == 'https';
      }
      // Allow Firebase Storage paths (no scheme)
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Validate date range (start before end)
  static bool isValidDateRange(DateTime start, DateTime end) {
    return start.isBefore(end);
  }

  /// Validate display order (non-negative)
  static bool isValidDisplayOrder(int order) {
    return order >= 0;
  }

  /// Comprehensive validation result
  static Map<String, String?> validateContentPage({
    required String title,
    required String slug,
    required String content,
    String? description,
  }) {
    final errors = <String, String?>{};

    if (!isValidTitleLength(title)) {
      errors['title'] = 'Title must be between 1 and $maxTitleLength characters';
    }

    if (!isValidSlug(slug)) {
      errors['slug'] = 'Slug must contain only lowercase letters, numbers, and hyphens';
    }

    if (!isValidContentLength(content)) {
      errors['content'] = 'Content must not exceed $maxContentLength characters';
    }

    if (description != null && !isValidDescriptionLength(description)) {
      errors['description'] = 'Description must not exceed $maxDescriptionLength characters';
    }

    return errors;
  }

  /// Comprehensive validation for banner
  static Map<String, String?> validateBanner({
    required String title,
    required DateTime startDate,
    required DateTime endDate,
    String? imageUrl,
    int? displayOrder,
  }) {
    final errors = <String, String?>{};

    if (!isValidTitleLength(title)) {
      errors['title'] = 'Title must be between 1 and $maxTitleLength characters';
    }

    if (!isValidDateRange(startDate, endDate)) {
      errors['dateRange'] = 'Start date must be before end date';
    }

    if (imageUrl != null && !isValidImageUrl(imageUrl)) {
      errors['imageUrl'] = 'Invalid image URL format';
    }

    if (displayOrder != null && !isValidDisplayOrder(displayOrder)) {
      errors['displayOrder'] = 'Display order must be non-negative';
    }

    return errors;
  }

  /// Comprehensive validation for email template
  static Map<String, String?> validateEmailTemplate({
    required String name,
    required String subject,
    required String htmlBody,
    required String plainTextBody,
  }) {
    final errors = <String, String?>{};

    if (name.isEmpty) {
      errors['name'] = 'Template name is required';
    }

    if (subject.isEmpty) {
      errors['subject'] = 'Email subject is required';
    }

    if (htmlBody.isEmpty) {
      errors['htmlBody'] = 'HTML body is required';
    }

    if (plainTextBody.isEmpty) {
      errors['plainTextBody'] = 'Plain text body is required';
    }

    if (!isValidContentLength(htmlBody)) {
      errors['htmlBody'] = 'HTML body must not exceed $maxContentLength characters';
    }

    return errors;
  }
}