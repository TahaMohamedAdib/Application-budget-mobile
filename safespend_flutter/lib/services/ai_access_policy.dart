bool hasAiAccess({
  required bool hasSession,
  required bool openToAll,
  required String? email,
  required Iterable<String> allowedEmails,
}) {
  if (!hasSession) return false;
  if (openToAll) return true;

  final normalizedEmail = email?.trim().toLowerCase();
  if (normalizedEmail == null || normalizedEmail.isEmpty) return false;

  return allowedEmails.any(
    (allowedEmail) => allowedEmail.trim().toLowerCase() == normalizedEmail,
  );
}
