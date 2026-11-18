import CoreHaptics
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var hapticEngine: CHHapticEngine?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let channel = FlutterMethodChannel(
      name: "mood_clicker/haptics",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    channel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "play", let args = call.arguments as? [String: Any] else {
        result(FlutterMethodNotImplemented)
        return
      }
      result(self?.playCoreHaptics(args) ?? false)
    }
  }

  private func playCoreHaptics(_ args: [String: Any]) -> Bool {
    guard CHHapticEngine.capabilitiesForHardware().supportsHaptics,
      let rawEvents = args["ios"] as? [[String: Any]], !rawEvents.isEmpty
    else {
      return false
    }
    do {
      if hapticEngine == nil {
        let engine = try CHHapticEngine()
        engine.resetHandler = { [weak self] in
          try? self?.hapticEngine?.start()
        }
        try engine.start()
        hapticEngine = engine
      }
      var events: [CHHapticEvent] = []
      for item in rawEvents {
        let typeName = item["type"] as? String ?? "transient"
        let intensity = Float((item["intensity"] as? Double) ?? 0.5)
        let sharpness = Float((item["sharpness"] as? Double) ?? 0.5)
        let startSec = Double((item["startMs"] as? Int) ?? 0) / 1000.0
        let durationSec = Double((item["durationMs"] as? Int) ?? 0) / 1000.0
        let eventType: CHHapticEvent.EventType =
          typeName == "continuous" ? .hapticContinuous : .hapticTransient
        let params = [
          CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
          CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness),
        ]
        events.append(
          CHHapticEvent(
            eventType: eventType,
            parameters: params,
            relativeTime: startSec,
            duration: eventType == .hapticContinuous ? max(0.02, durationSec) : 0
          )
        )
      }
      let pattern = try CHHapticPattern(events: events, parameters: [])
      let player = try hapticEngine?.makePlayer(with: pattern)
      try player?.start(atTime: CHHapticTimeImmediate)
      return true
    } catch {
      return false
    }
  }
}
