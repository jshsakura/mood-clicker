package com.example.mood_clicker

import android.content.Context
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
  private val channelName = "mood_clicker/haptics"

  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
      .setMethodCallHandler { call, result ->
        if (call.method != "play") {
          result.notImplemented()
          return@setMethodCallHandler
        }
        val args = call.arguments as? Map<*, *>
        result.success(playAndroidHaptics(args))
      }
  }

  private fun getVibrator(): Vibrator? {
    return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
      val manager = getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as? VibratorManager
      manager?.defaultVibrator
    } else {
      @Suppress("DEPRECATION")
      getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
    }
  }

  private fun playAndroidHaptics(args: Map<*, *>?): Boolean {
    val vibrator = getVibrator() ?: return false
    if (!vibrator.hasVibrator()) return false
    val androidMap = args?.get("android") as? Map<*, *> ?: return false

    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
      val primitives = androidMap["primitives"] as? List<*>
      if (!primitives.isNullOrEmpty()) {
        val composition = VibrationEffect.startComposition()
        var supported = true
        for (raw in primitives) {
          val step = raw as? Map<*, *> ?: continue
          val code = primitiveCode(step["type"] as? String)
          if (code == null || !vibrator.areAllPrimitivesSupported(code)) {
            supported = false
            break
          }
          val scale = ((step["scale"] as? Number)?.toFloat() ?: 0.5f).coerceIn(0f, 1f)
          val delayMs = (step["delayMs"] as? Number)?.toInt() ?: 0
          composition.addPrimitive(code, scale, delayMs)
        }
        if (supported) {
          vibrator.vibrate(composition.compose())
          return true
        }
      }
    }

    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && vibrator.hasAmplitudeControl()) {
      val timingsRaw = androidMap["timings"] as? List<*> ?: return false
      val ampsRaw = androidMap["amplitudes"] as? List<*> ?: return false
      if (timingsRaw.isEmpty() || timingsRaw.size != ampsRaw.size) return false
      val timings = LongArray(timingsRaw.size) { i -> (timingsRaw[i] as Number).toLong() }
      val amps = IntArray(ampsRaw.size) { i -> (ampsRaw[i] as Number).toInt().coerceIn(0, 255) }
      vibrator.vibrate(VibrationEffect.createWaveform(timings, amps, -1))
      return true
    }

    return false
  }

  private fun primitiveCode(name: String?): Int? {
    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.R) return null
    return when (name) {
      "tick" -> VibrationEffect.Composition.PRIMITIVE_TICK
      "click" -> VibrationEffect.Composition.PRIMITIVE_CLICK
      "thud" -> VibrationEffect.Composition.PRIMITIVE_THUD
      "lowTick" ->
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
          VibrationEffect.Composition.PRIMITIVE_LOW_TICK
        } else {
          VibrationEffect.Composition.PRIMITIVE_TICK
        }
      else -> null
    }
  }
}
