package com.android.m3e_haptics

import android.content.Context
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class M3eHapticsPlugin: FlutterPlugin, MethodCallHandler {
    private lateinit var channel : MethodChannel
    private var context: Context? = null

    // Cache capability support values
    private var supportsLowTick: Boolean? = null
    private var supportsTick: Boolean? = null
    private var supportsClick: Boolean? = null

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "m3e_haptics/haptics")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        if (call.method == "vibrate") {
            val type = call.argument<String>("type") ?: ""
            val amplitudeDouble = call.argument<Double>("amplitude") ?: 0.5
            val amplitude = amplitudeDouble.toFloat().coerceIn(0f, 1f)

            val vibrator = getVibrator()
            if (vibrator != null && vibrator.hasVibrator()) {
                vibrateWithComposition(vibrator, type, amplitude)
            }
            result.success(null)
        } else {
            result.notImplemented()
        }
    }

    private fun getVibrator(): Vibrator? {
        val ctx = context ?: return null
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val vibratorManager = ctx.getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as? VibratorManager
            vibratorManager?.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            ctx.getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
        }
    }

    private fun vibrateWithComposition(vib: Vibrator, type: String, amplitude: Float) {
        cacheCompositionSupport(vib)

        try {
            val effect: VibrationEffect = when (type) {
                "dragTexture" -> {
                    if (supportsLowTick == true) {
                        val composition = VibrationEffect.startComposition()
                        repeat(4) {
                            composition.addPrimitive(
                                VibrationEffect.Composition.PRIMITIVE_LOW_TICK,
                                amplitude,
                            )
                        }
                        composition.compose()
                    } else {
                        VibrationEffect.createPredefined(VibrationEffect.EFFECT_TICK)
                    }
                }

                "bookendLower", "bookendUpper" -> {
                    if (supportsClick == true) {
                        VibrationEffect.startComposition()
                            .addPrimitive(
                                VibrationEffect.Composition.PRIMITIVE_CLICK,
                                amplitude,
                            )
                            .compose()
                    } else {
                        VibrationEffect.createPredefined(VibrationEffect.EFFECT_CLICK)
                    }
                }

                "tickCrossing" -> {
                    if (supportsTick == true) {
                        VibrationEffect.startComposition()
                            .addPrimitive(
                                VibrationEffect.Composition.PRIMITIVE_TICK,
                                amplitude,
                            )
                            .compose()
                    } else {
                        VibrationEffect.createPredefined(VibrationEffect.EFFECT_CLICK)
                    }
                }

                else -> VibrationEffect.createPredefined(VibrationEffect.EFFECT_CLICK)
            }
            vib.vibrate(effect)
        } catch (e: Exception) {
            vibrateWithPredefined(vib, type)
        }
    }

    private fun vibrateWithPredefined(vib: Vibrator, type: String) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val effectId = when (type) {
                "dragTexture" -> VibrationEffect.EFFECT_TICK
                "bookendLower", "bookendUpper", "tickCrossing" -> VibrationEffect.EFFECT_CLICK
                else -> VibrationEffect.EFFECT_CLICK
            }
            try {
                vib.vibrate(VibrationEffect.createPredefined(effectId))
            } catch (e: Exception) {
                @Suppress("DEPRECATION")
                vib.vibrate(10)
            }
        } else {
            val durationMs: Long = when (type) {
                "dragTexture" -> 8L
                "bookendLower", "bookendUpper", "tickCrossing" -> 15L
                else -> 10L
            }
            @Suppress("DEPRECATION")
            vib.vibrate(durationMs)
        }
    }

    private fun cacheCompositionSupport(vib: Vibrator) {
        if (supportsLowTick != null) return
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            supportsLowTick = vib.areAllPrimitivesSupported(VibrationEffect.Composition.PRIMITIVE_LOW_TICK)
            supportsTick = vib.areAllPrimitivesSupported(VibrationEffect.Composition.PRIMITIVE_TICK)
            supportsClick = vib.areAllPrimitivesSupported(VibrationEffect.Composition.PRIMITIVE_CLICK)
        } else {
            supportsLowTick = false
            supportsTick = false
            supportsClick = false
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        context = null
    }
}
