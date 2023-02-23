import 'package:dotenv/dotenv.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:palspace_backend/enums/email_template.dart';
import 'package:palspace_backend/models/user/user.dart';
import 'package:palspace_backend/services/api_service.dart';
import 'package:palspace_backend/utilities/string_extension.dart';

class MailService {
  // TODO: Maybe make a scheduler to send mails?

  Future<SendReport?> sendTemplateMail(User user, EmailTemplate template,
      {Map<String, String?> replacements = const {}}) async {
    final finalReplacements = {
      "email": user.email,
      "firstName": user.facts?.firstName,
      "lastName": user.facts?.lastName,
    };

    finalReplacements.addAll(replacements);

    // Load template from file
    final html = await template.loadAndReplace(finalReplacements);
    return _sendMail(user.email!, template.name.convertCamelCaseToReadable, html);
  }

  Future<SendReport?> _sendMail(
      String recipient, String title, String html) async {
    final env = serviceCollection.get<DotEnv>();
    SmtpServer options;
    if (env["DEBUG"] == "TRUE") {
      options = SmtpServer(env["SMTP_HOST"]!,
          allowInsecure: env["SMTP_SSL"]!.toUpperCase() != "TRUE",
          ignoreBadCertificate:
              env["SMTP_IGNORE_CERT"]!.toUpperCase() == "TRUE",
          port: int.parse(env["SMTP_PORT"]!),
          ssl: env["SMTP_SSL"]!.toUpperCase() == "TRUE");
    } else {
      options = SmtpServer(env["SMTP_HOST"]!,
          allowInsecure: env["SMTP_SSL"]!.toUpperCase() != "TRUE",
          ignoreBadCertificate:
              env["SMTP_IGNORE_CERT"]!.toUpperCase() == "TRUE",
          username: env["SMTP_EMAIL"]!,
          password: env["SMTP_PASSWORD"]!,
          port: int.parse(env["SMTP_PORT"]!),
          ssl: env["SMTP_SSL"]!.toUpperCase() == "TRUE");
    }

    final message = Message()
      ..from = Address(env["SMTP_EMAIL"]!, env["SMTP_NAME"]!)
      ..recipients.add(recipient)
      ..subject = "${env["SMTP_NAME"]!} - $title"
      ..html = html;

    try {
      final sendReport = await send(message, options);
      print('Message sent: $sendReport');
      return sendReport;
    } on MailerException catch (e) {
      print('Message not sent. (${e.message})');
      for (var p in e.problems) {
        print('Problem: ${p.code}: ${p.msg}');
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
