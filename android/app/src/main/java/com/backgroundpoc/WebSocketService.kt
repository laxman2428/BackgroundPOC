package com.backgroundpoc

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat
import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.WritableMap
import com.facebook.react.modules.core.DeviceEventManagerModule
import okhttp3.*
import java.util.concurrent.TimeUnit

class WebSocketService : Service() {

    
    companion object {
        const val CHANNEL_ID = "WebSocketServiceChannel"
        const val TAG = "WebSocketService"
    }
    lateinit var notificationManger: NotificationManager
    

    private lateinit var client: OkHttpClient
    private var webSocket: WebSocket? = null
    private var url: String = ""

    override fun onCreate() {
      Log.d("CalendarModule", "on create function called")
        try {
        Log.d("CalendarModule", "onCreate called")
        createNotificationChannel()
        startForeground(1, createNotification("Connecting..."))

        client = OkHttpClient.Builder()
            .readTimeout(0, TimeUnit.MILLISECONDS)
            .build()
        } catch (e: Exception) {
            Log.e("CalendarModule", "Error in onCreate: ${e.message}", e)
        }
        
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        try {
        Log.d("CalendarModule", "onStartCommand called")
        url = intent?.getStringExtra("url") ?: ""
        connectWebSocket(url)
    } catch (e: Exception) {
        Log.e("CalendarModule", "Error in onStartCommand: ${e.message}", e)
    }
    return START_STICKY
    }

    private fun createNotificationChannel() {
        Log.d("CalendarModule", "on create notification function called")
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Log.d("CalendarModule", "on create notification function if called")
            val channel = NotificationChannel(
                CHANNEL_ID,
                "WebSocket Service",
                NotificationManager.IMPORTANCE_LOW
            )
            val manager = getSystemService(NotificationManager::class.java)
            Log.d("CalendarModule", "on create notification function after manager called")
            manager.createNotificationChannel(channel)
        }
    }

    private fun createNotification(content: String): Notification {
        Log.d("CalendarModule", "is create notification getting called")
        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
        .setContentTitle("WebSocket Service")
        .setContentText(content)
        .setSmallIcon(R.mipmap.ic_launcher) // or your custom icon in drawable
        .setPriority(NotificationCompat.PRIORITY_LOW)
        .build()

    Log.d("CalendarModule", "Notification created: $notification")
    return notification
    }

    private fun connectWebSocket(url: String) {
        Log.d("CalendarModule", "connect web socket function called")
        val request = Request.Builder()
            .url(url)
            .build()
            Log.d("CalendarModule", "connecting web socket")

        webSocket = client.newWebSocket(request, object : WebSocketListener() {
            override fun onOpen(ws: WebSocket, response: Response) {
                Log.d("CalendarModule", "WebSocket connected")
                startForeground(1, createNotification("Connected"))

                val params = Arguments.createMap()
                params.putString("status", "connected")
                sendEventToJS("WebSocketEvent", params)
            }

            override fun onMessage(ws: WebSocket, text: String) {
                Log.d("CalendarModule", "Received: $text")
              
                val params = Arguments.createMap()
                params.putString("message", text)
                sendEventToJS("WebSocketMessage", params)
            }

            override fun onFailure(ws: WebSocket, t: Throwable, response: Response?) {
                Log.e("CalendarModule", "WebSocket failed, reconnecting...", t)
                reconnect()
            }

            override fun onClosing(ws: WebSocket, code: Int, reason: String) {
                ws.close(1000, null)
            }
        })
    }

    private fun reconnect() {
        Thread.sleep(5000)
        connectWebSocket(url)
    }

    override fun onDestroy() {
        webSocket?.close(1000, null)
        client.dispatcher.executorService.shutdown()
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    // 🔥 Bridge method to send events from native → JS
    private fun sendEventToJS(eventName: String, params: WritableMap?) {
        val reactContext: ReactApplicationContext? = ReactContextHolder.reactContext
        if (reactContext != null && reactContext.hasActiveCatalystInstance()) {
            reactContext
                .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter::class.java)
                .emit(eventName, params)
        } else {
            Log.w(TAG, "React context not ready, dropping event: $eventName")
        }
    }
}
