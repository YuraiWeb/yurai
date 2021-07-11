module yurai.services.imailservice;

public interface IMailService
{
  void setDefaultContentType(string contentType);
  void setTimeZone(string timeZone);
  void setDefaultSender(string senderEmail, string senderName);
  
  void send(string subject, string message, string senderEmail, string senderName, string fromEmail, string fromName, string toEmail, string toName);
  void send(string subject, string message, string senderEmail, string senderName, string fromEmail, string fromName, string toEmail, string toName, string contentType);
  void send(string subject, string message, string fromEmail, string fromName, string toEmail, string toName);
  void send(string subject, string message, string fromEmail, string fromName, string toEmail, string toName, string contentType);
}
