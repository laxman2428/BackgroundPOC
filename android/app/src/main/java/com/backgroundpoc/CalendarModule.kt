package com.backgroundpoc
import com.facebook.react.bridge.NativeModule
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContext
import com.facebook.react.bridge.ReactContextBaseJavaModule
import com.facebook.react.bridge.ReactMethod
import android.util.Log
import android.content.Intent
import android.os.Build

class CalendarModule(reactContext: ReactApplicationContext) : ReactContextBaseJavaModule(reactContext) {
  init {
    // store reactContext globally so WebSocketService can use it
    ReactContextHolder.reactContext = reactContext
  }
  
  override fun getName() = "CalendarModule";

  @ReactMethod
  fun createCalendarEvent(url: String) {
    Log.d("CalendarModule", "Create event called with $url")
    val intent = Intent(reactApplicationContext, WebSocketService::class.java)
    intent.putExtra("url", url)
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
      Log.d("CalendarModule", "coming in if")
            reactApplicationContext.startForegroundService(intent)
        } else {
          Log.d("CalendarModule", "coming in else")
            reactApplicationContext.startService(intent)
        }
  }
}