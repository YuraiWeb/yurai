module yurai.external.services.vibemailservice;

import yurai.core.settings;

static if (Yurai_UseVibed_Mail)
{
  import std.string : format;

  version (Windows)
  {
    import std.datetime : Clock, WindowsTimeZone;
  }
  else
  {
    import std.datetime : Clock, PosixTimeZone;
  }

  import vibe.d : SMTPClientSettings,
                  TLSContext, TLSPeerValidationMode, TLSVersion,
                  Mail, sendMail, toRFC822DateTimeString;

  import yurai.services.imailservice;

  public final class VibeMailService : IMailService
  {
    private:
    string _host;
    ushort _port;
    string _username;
    string _password;
    string _contentType;
    string _timeZone;
    string _senderName;
    string _senderEmail;
    SMTPClientSettings _settings;

    public:
    final:
    this(string host, ushort port, string username = null, string password = null)
    {
      _settings = new SMTPClientSettings(host, port);
    }

    /// Sets the tls context setup.
    void setTlsContextSetup(void delegate(scope TLSContext) @safe newContextSetup)
    {
      _settings.tlsContextSetup = newContextSetup;
    }

    /// Sets the tls validation mode.
    void setTlsValidationMode(TLSPeerValidationMode newValidationMode)
    {
      _settings.tlsValidationMode = newValidationMode;
    }

    /// Sets the tls version.
    void setTlsVersion(TLSVersion newVersion)
    {
      _settings.tlsVersion = newVersion;
    }

    void setDefaultContentType(string contentType)
    {
      _contentType = contentType;
    }

    void setTimeZone(string timeZone)
    {
      _timeZone = timeZone;
    }

    void setDefaultSender(string senderEmail, string senderName)
    {
      _senderEmail = senderEmail;
      _senderName = senderName;
    }

    void send(string subject, string message, string senderEmail, string senderName, string fromEmail, string fromName, string toEmail, string toName)
    {
      send(subject, message, senderEmail, senderName, fromEmail, fromName, toEmail, toName, _contentType);
    }
    void send(string subject, string message, string fromEmail, string fromName, string toEmail, string toName)
    {
      send(subject, message, _senderEmail, _senderName, fromEmail, fromName, toEmail, toName, _contentType);
    }
    void send(string subject, string message, string fromEmail, string fromName, string toEmail, string toName, string contentType)
    {
      send(subject, message, _senderEmail, _senderName, fromEmail, fromName, toEmail, toName, contentType);
    }

    void send(string subject, string message, string senderEmail, string senderName, string fromEmail, string fromName, string toEmail, string toName, string contentType)
    {
      auto mail = new Mail;

      version (Windows)
      {
        auto timeZone = WindowsTimeZone.getTimeZone(_timeZone);
      }
      else
      {
        auto timeZone = PosixTimeZone.getTimeZone(_timeZone);
      }

      mail.headers["Date"] = Clock.currTime(timeZone).toRFC822DateTimeString();
      mail.headers["Sender"] = "%s <%s>".format(senderName, senderEmail);
      mail.headers["From"] = "%s <%s>".format(fromName, fromEmail);
      mail.headers["To"] = toName ? "".format(toName, toEmail) : toEmail;
      mail.headers["Subject"] = subject;
      mail.headers["Content-Type"] = contentType;
      mail.bodyText = message;

      sendMail(_settings, mail);
    }
  }
}
