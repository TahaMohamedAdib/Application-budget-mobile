const translationsTesterFeedback = <String, Map<String, String>>{
  'en': {
    'continueWithGoogle': 'Continue with Google',
    'sendRecoveryEmail': 'Send recovery email',
    'recoveryEmailSent':
        'If an account exists, recovery instructions have been sent.',
    'resetPassword': 'Reset password',
    'passwordPolicy':
        'Use 8+ characters with an uppercase letter, number, and special character.',
    'passwordResetSuccess': 'Password updated successfully.',
    'recoverySessionInvalid': 'This recovery link is invalid or has expired.',
    'includeInMonthlyBudget': 'Include in monthly budget'
  },
  'fr': {
    'continueWithGoogle': 'Continuer avec Google',
    'sendRecoveryEmail': 'Envoyer l’e-mail de récupération',
    'recoveryEmailSent':
        'Si un compte existe, les instructions de récupération ont été envoyées.',
    'resetPassword': 'Réinitialiser le mot de passe',
    'passwordPolicy':
        'Utilisez au moins 8 caractères avec une majuscule, un chiffre et un caractère spécial.',
    'passwordResetSuccess': 'Mot de passe mis à jour avec succès.',
    'recoverySessionInvalid':
        'Ce lien de récupération est invalide ou a expiré.',
    'includeInMonthlyBudget': 'Inclure dans le budget mensuel'
  },
  'ar': {
    'continueWithGoogle': 'المتابعة باستخدام Google',
    'sendRecoveryEmail': 'إرسال بريد الاسترداد',
    'recoveryEmailSent':
        'إذا كان الحساب موجودًا، فقد تم إرسال تعليمات الاسترداد.',
    'resetPassword': 'إعادة تعيين كلمة المرور',
    'passwordPolicy': 'استخدم 8 أحرف على الأقل مع حرف كبير ورقم ورمز خاص.',
    'passwordResetSuccess': 'تم تحديث كلمة المرور بنجاح.',
    'recoverySessionInvalid': 'رابط الاسترداد غير صالح أو انتهت صلاحيته.',
    'includeInMonthlyBudget': 'تضمين في الميزانية الشهرية'
  },
  'es': {
    'continueWithGoogle': 'Continuar con Google',
    'sendRecoveryEmail': 'Enviar correo de recuperación',
    'recoveryEmailSent':
        'Si existe una cuenta, se enviaron las instrucciones de recuperación.',
    'resetPassword': 'Restablecer contraseña',
    'passwordPolicy':
        'Usa 8+ caracteres con mayúscula, número y carácter especial.',
    'passwordResetSuccess': 'Contraseña actualizada correctamente.',
    'recoverySessionInvalid':
        'Este enlace de recuperación no es válido o ha caducado.',
    'includeInMonthlyBudget': 'Incluir en el presupuesto mensual'
  },
  'de': {
    'continueWithGoogle': 'Mit Google fortfahren',
    'sendRecoveryEmail': 'Wiederherstellungs-E-Mail senden',
    'recoveryEmailSent':
        'Falls ein Konto existiert, wurden Wiederherstellungsanweisungen gesendet.',
    'resetPassword': 'Passwort zurücksetzen',
    'passwordPolicy':
        'Nutze mindestens 8 Zeichen mit Großbuchstabe, Zahl und Sonderzeichen.',
    'passwordResetSuccess': 'Passwort erfolgreich aktualisiert.',
    'recoverySessionInvalid':
        'Dieser Wiederherstellungslink ist ungültig oder abgelaufen.',
    'includeInMonthlyBudget': 'In Monatsbudget einbeziehen'
  },
  'pt': {
    'continueWithGoogle': 'Continuar com Google',
    'sendRecoveryEmail': 'Enviar e-mail de recuperação',
    'recoveryEmailSent':
        'Se existir uma conta, as instruções de recuperação foram enviadas.',
    'resetPassword': 'Redefinir palavra-passe',
    'passwordPolicy':
        'Use 8+ caracteres com maiúscula, número e carácter especial.',
    'passwordResetSuccess': 'Palavra-passe atualizada com sucesso.',
    'recoverySessionInvalid':
        'Esta ligação de recuperação é inválida ou expirou.',
    'includeInMonthlyBudget': 'Incluir no orçamento mensal'
  },
  'it': {
    'continueWithGoogle': 'Continua con Google',
    'sendRecoveryEmail': 'Invia email di recupero',
    'recoveryEmailSent':
        'Se esiste un account, sono state inviate le istruzioni di recupero.',
    'resetPassword': 'Reimposta password',
    'passwordPolicy':
        'Usa almeno 8 caratteri con maiuscola, numero e carattere speciale.',
    'passwordResetSuccess': 'Password aggiornata correttamente.',
    'recoverySessionInvalid':
        'Questo link di recupero non è valido o è scaduto.',
    'includeInMonthlyBudget': 'Includi nel budget mensile'
  },
  'tr': {
    'continueWithGoogle': 'Google ile devam et',
    'sendRecoveryEmail': 'Kurtarma e-postası gönder',
    'recoveryEmailSent': 'Hesap varsa kurtarma talimatları gönderildi.',
    'resetPassword': 'Şifreyi sıfırla',
    'passwordPolicy':
        'Büyük harf, sayı ve özel karakter içeren en az 8 karakter kullanın.',
    'passwordResetSuccess': 'Şifre başarıyla güncellendi.',
    'recoverySessionInvalid':
        'Bu kurtarma bağlantısı geçersiz veya süresi dolmuş.',
    'includeInMonthlyBudget': 'Aylık bütçeye dahil et'
  },
  'nl': {
    'continueWithGoogle': 'Doorgaan met Google',
    'sendRecoveryEmail': 'Herstel-e-mail verzenden',
    'recoveryEmailSent':
        'Als er een account bestaat, zijn herstelinstructies verzonden.',
    'resetPassword': 'Wachtwoord opnieuw instellen',
    'passwordPolicy':
        'Gebruik 8+ tekens met hoofdletter, cijfer en speciaal teken.',
    'passwordResetSuccess': 'Wachtwoord succesvol bijgewerkt.',
    'recoverySessionInvalid': 'Deze herstellink is ongeldig of verlopen.',
    'includeInMonthlyBudget': 'Opnemen in maandbudget'
  },
  'ru': {
    'continueWithGoogle': 'Продолжить с Google',
    'sendRecoveryEmail': 'Отправить письмо для восстановления',
    'recoveryEmailSent':
        'Если аккаунт существует, инструкции по восстановлению отправлены.',
    'resetPassword': 'Сбросить пароль',
    'passwordPolicy':
        'Используйте не менее 8 символов с заглавной буквой, цифрой и спецсимволом.',
    'passwordResetSuccess': 'Пароль успешно обновлён.',
    'recoverySessionInvalid':
        'Ссылка восстановления недействительна или истекла.',
    'includeInMonthlyBudget': 'Включить в месячный бюджет'
  },
  'zh': {
    'continueWithGoogle': '使用 Google 继续',
    'sendRecoveryEmail': '发送恢复邮件',
    'recoveryEmailSent': '如果账户存在，恢复说明已发送。',
    'resetPassword': '重置密码',
    'passwordPolicy': '请使用至少 8 个字符，包含大写字母、数字和特殊字符。',
    'passwordResetSuccess': '密码已成功更新。',
    'recoverySessionInvalid': '此恢复链接无效或已过期。',
    'includeInMonthlyBudget': '计入月度预算'
  },
  'ja': {
    'continueWithGoogle': 'Google で続行',
    'sendRecoveryEmail': '復旧メールを送信',
    'recoveryEmailSent': 'アカウントが存在する場合、復旧手順を送信しました。',
    'resetPassword': 'パスワードをリセット',
    'passwordPolicy': '大文字、数字、記号を含む8文字以上を使用してください。',
    'passwordResetSuccess': 'パスワードを更新しました。',
    'recoverySessionInvalid': 'この復旧リンクは無効か期限切れです。',
    'includeInMonthlyBudget': '月間予算に含める'
  },
  'ko': {
    'continueWithGoogle': 'Google로 계속하기',
    'sendRecoveryEmail': '복구 이메일 보내기',
    'recoveryEmailSent': '계정이 있으면 복구 안내를 보냈습니다.',
    'resetPassword': '비밀번호 재설정',
    'passwordPolicy': '대문자, 숫자, 특수 문자를 포함해 8자 이상 사용하세요.',
    'passwordResetSuccess': '비밀번호가 업데이트되었습니다.',
    'recoverySessionInvalid': '이 복구 링크는 유효하지 않거나 만료되었습니다.',
    'includeInMonthlyBudget': '월 예산에 포함'
  },
  'hi': {
    'continueWithGoogle': 'Google के साथ जारी रखें',
    'sendRecoveryEmail': 'पुनर्प्राप्ति ईमेल भेजें',
    'recoveryEmailSent':
        'यदि खाता मौजूद है, तो पुनर्प्राप्ति निर्देश भेज दिए गए हैं।',
    'resetPassword': 'पासवर्ड रीसेट करें',
    'passwordPolicy':
        'बड़े अक्षर, संख्या और विशेष चिह्न के साथ 8+ वर्ण प्रयोग करें।',
    'passwordResetSuccess': 'पासवर्ड सफलतापूर्वक अपडेट हो गया।',
    'recoverySessionInvalid':
        'यह पुनर्प्राप्ति लिंक अमान्य या समाप्त हो चुका है।',
    'includeInMonthlyBudget': 'मासिक बजट में शामिल करें'
  },
  'id': {
    'continueWithGoogle': 'Lanjutkan dengan Google',
    'sendRecoveryEmail': 'Kirim email pemulihan',
    'recoveryEmailSent': 'Jika akun ada, petunjuk pemulihan telah dikirim.',
    'resetPassword': 'Atur ulang kata sandi',
    'passwordPolicy':
        'Gunakan 8+ karakter dengan huruf besar, angka, dan karakter khusus.',
    'passwordResetSuccess': 'Kata sandi berhasil diperbarui.',
    'recoverySessionInvalid':
        'Tautan pemulihan ini tidak valid atau kedaluwarsa.',
    'includeInMonthlyBudget': 'Sertakan dalam anggaran bulanan'
  },
  'pl': {
    'continueWithGoogle': 'Kontynuuj z Google',
    'sendRecoveryEmail': 'Wyślij e-mail odzyskiwania',
    'recoveryEmailSent':
        'Jeśli konto istnieje, wysłano instrukcje odzyskiwania.',
    'resetPassword': 'Zresetuj hasło',
    'passwordPolicy':
        'Użyj co najmniej 8 znaków z wielką literą, cyfrą i znakiem specjalnym.',
    'passwordResetSuccess': 'Hasło zostało zaktualizowane.',
    'recoverySessionInvalid':
        'Ten link odzyskiwania jest nieprawidłowy lub wygasł.',
    'includeInMonthlyBudget': 'Uwzględnij w budżecie miesięcznym'
  },
};
