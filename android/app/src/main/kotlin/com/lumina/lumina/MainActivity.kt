package com.lumina.lumina

import io.flutter.embedding.android.FlutterFragmentActivity

// FlutterFragmentActivity, not plain FlutterActivity — local_auth's
// Fingerprint Unlock prompt is built on androidx.biometric.BiometricPrompt,
// which requires hosting inside a FragmentActivity. Using plain
// FlutterActivity here would make every biometric prompt call throw at
// runtime, even though everything compiles fine either way.
class MainActivity : FlutterFragmentActivity()
