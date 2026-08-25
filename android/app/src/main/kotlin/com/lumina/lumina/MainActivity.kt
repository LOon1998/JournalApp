package com.lumina.lumina

import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/// Bridges Android's own "this Activity was just screenshotted" signal
/// (Activity.registerScreenCaptureCallback, API 34+ only) over to Dart's
/// ExternalActivityGuard, via a MethodChannel — see
/// lib/services/screenshot_guard.dart for the receiving end.
///
/// Timing alone (main.dart's own debounce before re-locking on a
/// backgrounding) turned out not to be reliable for screenshots on their
/// own: Samsung's Smart Capture toolbar, which pops up immediately after
/// a screenshot, can hold focus away from the app for longer than any
/// debounce short enough to still feel instant on a genuine app switch.
/// A real signal straight from the OS — rather than guessing from how
/// long focus was away — is what actually fixes this on Android 14+
/// (which is what a Galaxy S23 Ultra on a current One UI build is
/// running). There's no equivalent pre-14 API to fall back on, so on
/// older Android this channel simply never fires and the app relies on
/// main.dart's debounce alone, same as before this existed.
class MainActivity : FlutterActivity() {
    private val channelName = "com.lumina.lumina/screenshot"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            // This is a nice-to-have, not essential — main.dart's own
            // timing debounce is still there either way — so a device
            // that reports API 34+ but doesn't actually behave the way
            // the public API is documented to (an OEM framework quirk,
            // say) degrades silently instead of taking the whole app
            // down with it on every single launch. That's exactly what
            // happened without this guard: registering here, this early
            // in the Activity's lifecycle, threw and the app couldn't
            // open at all.
            try {
                registerScreenCaptureCallback(mainExecutor) {
                    try {
                        channel.invokeMethod("screenshotTaken", null)
                    } catch (e: Exception) {
                        // Same reasoning — a failed notification here just
                        // means this one screenshot falls back to the
                        // timing debounce, not a crash.
                    }
                }
            } catch (e: Throwable) {
                // Throwable, not just Exception — this runs during Activity
                // setup, before Flutter's own crash reporting is anywhere
                // near ready to catch something like a LinkageError from an
                // OEM framework shipping a mismatched version of this API.
            }
        }
    }
}
