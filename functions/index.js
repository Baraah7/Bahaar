const admin = require("firebase-admin");
const sgMail = require("@sendgrid/mail");

admin.initializeApp();

// 🔐 set your SendGrid API key (we’ll mention where below)
sgMail.setApiKey(process.env.SENDGRID_API_KEY);

// ✅ Your API endpoint
exports.forgotPassword = onRequest(async (req, res) => {
  try {
    const { email } = req.body;

    if (!email) {
      return res.status(400).send("Email is required");
    }

    // Generate reset link
    const link = await admin.auth().generatePasswordResetLink(email, {
      url: "https://your-app.web.app/reset-password",
      handleCodeInApp: true,
    });

    // Email HTML (your template)
    const template = `
      <p>Hello,</p>
      <p>Click below to reset your password:</p>
      <a href="${link}">Reset Password</a>

      <hr>

      <div dir="rtl">
        <p>مرحبًا،</p>
        <p>اضغط أدناه لإعادة تعيين كلمة المرور:</p>
        <a href="${link}">إعادة تعيين كلمة المرور</a>
      </div>
    `;

    // 📍 SUBJECT IS HERE
    const msg = {
      to: email,
      from: "yourname@gmail.com", // must be verified in SendGrid
      subject: "Reset Password | إعادة تعيين كلمة المرور",
      html: template,
    };

    await sgMail.send(msg);

    res.send({ success: true });

  } catch (error) {
    console.error(error);
    res.status(500).send(error.message);
  }
});