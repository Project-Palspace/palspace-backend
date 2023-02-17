import 'package:dotenv/dotenv.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class MailService {
  final DotEnv env;

  MailService(this.env) {
    print(
        "Mail service initialized: ${env["SMTP_HOST"]!}:${env["SMTP_PORT"]!} SSL: ${env["SMTP_SSL"]!.toUpperCase()}");
  }

  // TODO: Maybe make a scheduler to send mails?
  // TODO: Templates?

  Future<SendReport?> sendMail(
      String recipient, String title, String html) async {
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
