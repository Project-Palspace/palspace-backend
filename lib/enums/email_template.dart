import 'dart:io';

enum EmailTemplate { welcome, resetPassword, verifyEmail, verifyAccountDeletion, emailVerified }

extension EmailTemplateEx on EmailTemplate {
  String get name => toString().split('.').last;
  String get path => 'email_templates/$name.html';

  Future<String> load() async {
    return await File.fromUri(Uri.parse(path)).readAsString();
  }

  Future<String> loadAndReplace(Map<String, String?> replacements) async {
    var html = await load();
    replacements.forEach((key, value) {
      html = html.replaceAll("{$key}", value ?? '{missing-key=$key}');
    });
    return html;
  }
}
