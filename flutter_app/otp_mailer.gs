function doGet() {
  return ContentService.createTextOutput('Pockify OTP mailer is live');
}

function doPost(e) {
  const data = JSON.parse(e.postData.contents);
  const to = String(data.toEmail || '')
    .trim()
    .toLowerCase();
  const code = String(data.code || '').trim();
  const name = String(data.toName || 'there').trim() || 'there';
  const minutes = Number(data.expiresInMinutes) || 10;

  if (!to || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(to) || !/^\d{6}$/.test(code)) {
    return ContentService.createTextOutput(
      JSON.stringify({ ok: false, error: 'invalid' }),
    ).setMimeType(ContentService.MimeType.JSON);
  }

  MailApp.sendEmail({
    to: to,
    subject: 'Your Pockify code: ' + code,
    htmlBody:
      '<p>Hi ' +
      name +
      ',</p>' +
      '<p>Your Pockify verification code is:</p>' +
      '<p style="font-size:28px;font-weight:bold;letter-spacing:6px">' +
      code +
      '</p>' +
      '<p>Type this 6-digit code in the app to finish signing up. ' +
      'It expires in ' +
      minutes +
      ' minutes.</p>' +
      '<p>If you did not create a Pockify account, ignore this email.</p>',
  });

  return ContentService.createTextOutput(JSON.stringify({ ok: true })).setMimeType(
    ContentService.MimeType.JSON,
  );
}
