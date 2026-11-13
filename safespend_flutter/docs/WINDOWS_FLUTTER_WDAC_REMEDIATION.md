# Windows Flutter build policy remediation

## Evidence

On 2026-11-13, `Microsoft-Windows-CodeIntegrity/Operational` logged events
3033 and 3077 for Flutter release and test executables. The enforcing policy
is `{0283ac0f-fff1-49ae-ada1-8a933130cad6}` and requires an Enterprise signing
level. AppLocker and Microsoft Defender did not log a corresponding block.

The affected Flutter 3.47.9 engine files are unsigned, so this is expected
under a strict WDAC policy:

| File | SHA-256 |
| --- | --- |
| `bin/cache/artifacts/engine/android-arm-release/windows-x64/gen_snapshot.exe` | `5BA2DB0F9F0E13A5CA5EFA25C54CF43D971F3C660976FAFA9FF83003A93D622F` |
| `bin/cache/artifacts/engine/windows-x64/flutter_tester.exe` | `7AEF6B970463A2477A5C86E12D60577932E055A629A487271909F60600502BC4` |
| `bin/cache/dart-sdk/bin/dartvm.exe` | `CE2638B8A7B0D3ABE77709FAB521D5749182B7793D687AD969E2F8089FA808F6` |

The policy inventory command `CiTool.exe -lp` returned access denied for the
standard developer account. Only the WDAC/endpoint-security administrator can
inspect or amend this policy.

## Administrator-approved remediation

1. Validate the Flutter SDK provenance and version (`3.47.9`, framework
   revision `c197ca5199`) from the official Flutter release source. Prefer a
   managed software-distribution package placed in an administrator-controlled
   directory with developer write access removed.
2. In a pilot WDAC policy, add a **supplemental, signed hash rule** for the
   exact verified engine executables above, and for any other exact SDK binary
   the policy logs as required. Scope the supplemental policy to approved
   development devices or the managed SDK installation.
3. Do not create a broad allow rule for a user-writable path such as
   `C:\Users\*\flutter`, do not disable Code Integrity/Smart App Control, and
   do not add a blanket Defender exclusion.
4. Deploy the signed supplemental policy through the normal endpoint-management
   channel. Re-run the commands below and review Code Integrity events before
   allowing release work on the device.

```powershell
flutter test test/auth_recovery_guards_test.dart test/category_budget_migration_test.dart
flutter build appbundle --release
Get-WinEvent -FilterHashtable @{
  LogName = 'Microsoft-Windows-CodeIntegrity/Operational'
  StartTime = (Get-Date).AddMinutes(-30)
} | Where-Object { $_.Message -match 'gen_snapshot|flutter_tester' } |
  Select-Object TimeCreated, Id, Message
```

Every Flutter SDK upgrade changes these artifact hashes and must go through the
same review. If local approval is not appropriate, use the protected GitHub
Actions release workflow instead; it avoids weakening the workstation policy.
