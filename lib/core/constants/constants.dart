class Constants {

  /// ── ทดสอบเครื่องจริง ──────────────────────
  // เปิด Command Prompt
  // C:\Users\Gistda\AppData\Local\Android\Sdk\platform-tools\adb.exe devices
  // R52Y4026RHL   device
  // C:\Users\Gistda\AppData\Local\Android\Sdk\platform-tools\adb.exe -s R52Y4026RHL reverse tcp:3000 tcp:3000
  static const String backendUri = String.fromEnvironment(
    'BACKEND_URI',
    defaultValue: 'http://localhost:3000',
  );

  /// ── ทดสอบด้วยเครื่องจริง >> ไร้สาย (ใช้ ngrok สร้าง public HTTPS tunnel) ──────────────────────
  /// flutter build apk
  /// ── terminal backend ──────────────────────
  // docker compose up
  // ngrok http 3000
  // static String backendUri = "https://d50c-1-10-131-100.ngrok-free.app";

}