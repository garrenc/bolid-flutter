package com.vr.radiobolid

import android.content.Intent
import android.os.Bundle
import android.util.Log
import androidx.media.MediaBrowserServiceCompat
import androidx.media.MediaBrowserServiceCompat.BrowserRoot
import android.support.v4.media.MediaBrowserCompat
import android.support.v4.media.MediaMetadataCompat
import android.support.v4.media.session.MediaSessionCompat
import android.support.v4.media.session.PlaybackStateCompat
import android.support.v4.media.MediaDescriptionCompat
import android.net.Uri
import android.content.res.AssetFileDescriptor
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.plugin.common.MethodChannel

class RadioMediaService : MediaBrowserServiceCompat() {
    private val TAG = "RadioMediaService"
    private lateinit var mediaSession: MediaSessionCompat
    private lateinit var methodChannel: MethodChannel
    private var currentState = PlaybackStateCompat.STATE_NONE
    private var isInitialConnection = true
    private var hasDelayedActionsBeenSet = false

    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "onCreate: Initializing RadioMediaService")
        
        // Initialize method channel
        val engine = FlutterEngineCache.getInstance().get("my_engine_id")
        if (engine == null) {
            Log.e(TAG, "onCreate: FlutterEngine not found in cache!")
            return
        }
        methodChannel = MethodChannel(engine.dartExecutor.binaryMessenger, "com.vr.radiobolid/android_auto")

        // Force stop any existing playback
        methodChannel.invokeMethod("pause", null, null)

        // Initialize media session
        mediaSession = MediaSessionCompat(baseContext, "RadioMediaService").apply {
            setCallback(object : MediaSessionCompat.Callback() {
                override fun onPlay() {
                    Log.d(TAG, "onPlay called")
                    if (!hasDelayedActionsBeenSet) {
                        Log.d(TAG, "Ignoring play request - actions not ready yet")
                        return
                    }
                    if (isInitialConnection) {
                        Log.d(TAG, "Ignoring initial play request")
                        isInitialConnection = false
                        return
                    }
                    if (currentState == PlaybackStateCompat.STATE_PLAYING) {
                        Log.d(TAG, "Already playing, ignoring play request")
                        return
                    }
                    Log.d(TAG, "Processing play request")
                    methodChannel.invokeMethod("play", null, null)
                    updatePlaybackState(PlaybackStateCompat.STATE_PLAYING)
                }

                override fun onPause() {
                    Log.d(TAG, "onPause called")
                    methodChannel.invokeMethod("pause", null, null)
                    updatePlaybackState(PlaybackStateCompat.STATE_PAUSED)
                }

                override fun onStop() {
                    Log.d(TAG, "onStop called")
                    methodChannel.invokeMethod("pause", null, null)
                    updatePlaybackState(PlaybackStateCompat.STATE_STOPPED)
                }
            })
            setFlags(MediaSessionCompat.FLAG_HANDLES_MEDIA_BUTTONS or MediaSessionCompat.FLAG_HANDLES_TRANSPORT_CONTROLS)
            setSessionToken(sessionToken)
        }

        // Get the app icon as a bitmap
        val iconBitmap = try {
            val drawable = packageManager.getApplicationIcon(packageName)
            Bitmap.createBitmap(drawable.intrinsicWidth, drawable.intrinsicHeight, Bitmap.Config.ARGB_8888).apply {
                val canvas = android.graphics.Canvas(this)
                drawable.setBounds(0, 0, canvas.width, canvas.height)
                drawable.draw(canvas)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to load app icon", e)
            null
        }

        // Set initial metadata with album art
        val metadata = MediaMetadataCompat.Builder()
            .putString(MediaMetadataCompat.METADATA_KEY_MEDIA_ID, "radio_bolid")
            .putString(MediaMetadataCompat.METADATA_KEY_TITLE, "Радио Болид")
            .putString(MediaMetadataCompat.METADATA_KEY_DISPLAY_TITLE, "Радио Болид")
            .putString(MediaMetadataCompat.METADATA_KEY_DISPLAY_SUBTITLE, "Live Radio")
            .apply {
                iconBitmap?.let {
                    putBitmap(MediaMetadataCompat.METADATA_KEY_ALBUM_ART, it)
                    putBitmap(MediaMetadataCompat.METADATA_KEY_DISPLAY_ICON, it)
                    putBitmap(MediaMetadataCompat.METADATA_KEY_ART, it)
                }
            }
            .build()
        mediaSession.setMetadata(metadata)

        // Set initial state to none with no actions
        val stateBuilder = PlaybackStateCompat.Builder()
            .setState(PlaybackStateCompat.STATE_NONE, 0L, 0f)
            .setActions(0) // No actions initially
        mediaSession.setPlaybackState(stateBuilder.build())

        // Delay adding actions to prevent auto-play
        android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({
            Log.d(TAG, "Setting delayed actions")
            hasDelayedActionsBeenSet = true
            updatePlaybackState(PlaybackStateCompat.STATE_STOPPED)
            mediaSession.isActive = true
        }, 1500) // Increased delay to 1.5 seconds
    }

    private fun updatePlaybackState(state: Int) {
        Log.d(TAG, "Updating playback state to: $state")
        currentState = state
        val stateBuilder = PlaybackStateCompat.Builder()
            .setActions(
                PlaybackStateCompat.ACTION_PLAY or
                PlaybackStateCompat.ACTION_PAUSE or
                PlaybackStateCompat.ACTION_PLAY_PAUSE or
                PlaybackStateCompat.ACTION_STOP
            )
            .setState(state, 0L, if (state == PlaybackStateCompat.STATE_PLAYING) 1.0f else 0f)
        mediaSession.setPlaybackState(stateBuilder.build())
    }

    override fun onGetRoot(
        clientPackageName: String,
        clientUid: Int,
        rootHints: Bundle?
    ): BrowserRoot? {
        Log.d(TAG, "onGetRoot called by $clientPackageName")
        // Return a root with extras that indicate no autoplay
        val extras = Bundle().apply {
            putBoolean("android.media.browse.CONTENT_STYLE_SUPPORTED", true)
            putBoolean("android.media.browse.PREFER_RECENT", false)
            putBoolean("android.media.browse.SUGGEST_RECENT", false)
            putBoolean("android.media.browse.CONTENT_STYLE_BROWSABLE_HINT", false)
            putBoolean("android.media.browse.CONTENT_STYLE_PLAYABLE_HINT", false)
            putBoolean("android.auto.media.SHOULD_HANDLE_QUEUE_COMMANDS", false)
        }
        return BrowserRoot("root", extras)
    }

    override fun onLoadChildren(
        parentId: String,
        result: Result<MutableList<MediaBrowserCompat.MediaItem>>
    ) {
        Log.d(TAG, "onLoadChildren called for parentId: $parentId")
        val items = mutableListOf<MediaBrowserCompat.MediaItem>()
        isInitialConnection = true
        
        if (parentId == "root") {
            // Get the app icon as a bitmap for the media item
            val iconBitmap = try {
                val drawable = packageManager.getApplicationIcon(packageName)
                Bitmap.createBitmap(drawable.intrinsicWidth, drawable.intrinsicHeight, Bitmap.Config.ARGB_8888).apply {
                    val canvas = android.graphics.Canvas(this)
                    drawable.setBounds(0, 0, canvas.width, canvas.height)
                    drawable.draw(canvas)
                }
            } catch (e: Exception) {
                Log.e(TAG, "Failed to load app icon", e)
                null
            }

            val desc = MediaDescriptionCompat.Builder()
                .setMediaId("radio_bolid")
                .setTitle("Радио Болид")
                .setIconBitmap(iconBitmap)
                .build()

            items.add(MediaBrowserCompat.MediaItem(
                desc,
                MediaBrowserCompat.MediaItem.FLAG_PLAYABLE
            ))
        }
        
        result.sendResult(items)
    }

    override fun onDestroy() {
        Log.d(TAG, "onDestroy called")
        methodChannel.invokeMethod("pause", null, null)
        mediaSession.release()
        super.onDestroy()
    }
} 