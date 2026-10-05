class Constants {

  /// ทดสอบเครื่องจริง
  // ── เปิด Command Prompt ──────────────────────
  // C:\Users\Gistda\AppData\Local\Android\Sdk\platform-tools\adb.exe devices
  // R52Y4026RHL   device
  // C:\Users\Gistda\AppData\Local\Android\Sdk\platform-tools\adb.exe -s R52Y4026RHL reverse tcp:3000 tcp:3000
  static String backendUri = "http://localhost:3000";

  /// ทดสอบด้วยเครื่องจริง >> ไร้สาย (ใช้ ngrok สร้าง public HTTPS tunnel)
  /// ── flutter build apk  ──────────────────────
  // ── terminal backend ──────────────────────
  // docker compose up
  // ngrok http 3000
  // static String backendUri = "https://d50c-1-10-131-100.ngrok-free.app";

  /// ทดสอบด้วย Android Emulator
  //static String backendUri = "http://10.0.2.2:3000";

  /// ทดสอบด้วย IP เครื่องจริง
  // static String backendUri = "http://192.168.0.54:3000";

}