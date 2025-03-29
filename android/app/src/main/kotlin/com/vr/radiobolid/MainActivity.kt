package com.vr.radiobolid

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.plugin.common.MethodChannel
import android.content.ComponentName
import android.support.v4.media.MediaBrowserCompat
import android.support.v4.media.session.PlaybackStateCompat
import android.support.v4.media.MediaMetadataCompat
import android.os.Bundle

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.vr.radiobolid/android_auto"
    private var mediaBrowser: MediaBrowserCompat? = null
    private lateinit var methodChannel: MethodChannel

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Cache the FlutterEngine for use in the MediaService
        FlutterEngineCache
            .getInstance()
            .put("my_engine_id", flutterEngine)

        // Set up the method channel
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "setupAndroidAuto" -> {
                    setupAndroidAuto()
                    result.success(null)
                }
                "updatePlaybackState" -> {
                    val isPlaying = call.argument<Boolean>("isPlaying") ?: false
                    val title = call.argument<String>("title") ?: ""
                    val artist = call.argument<String>("artist") ?: ""
                    val albumArt = call.argument<String>("albumArt") ?: ""
                    updatePlaybackState(isPlaying, title, artist, albumArt)
                    result.success(null)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun setupAndroidAuto() {
        // Initialize MediaBrowser
        mediaBrowser = MediaBrowserCompat(
            this,
            ComponentName(this, RadioMediaService::class.java),
            object : MediaBrowserCompat.ConnectionCallback() {
                override fun onConnected() {
                    // MediaBrowser is connected to the service
                    methodChannel.invokeMethod("onAndroidAutoConnected", null)
                }

                override fun onConnectionSuspended() {
                    // Connection to the service was lost
                    methodChannel.invokeMethod("onAndroidAutoConnectionSuspended", null)
                }

                override fun onConnectionFailed() {
                    // Connection to the service failed
                    methodChannel.invokeMethod("onAndroidAutoConnectionFailed", null)
                }
            },
            null
        )
        
        // Connect to the MediaBrowserService
        mediaBrowser?.connect()
    }

    private fun updatePlaybackState(isPlaying: Boolean, title: String, artist: String, albumArt: String) {
        val metadata = MediaMetadataCompat.Builder()
            .putString(MediaMetadataCompat.METADATA_KEY_TITLE, title)
            .putString(MediaMetadataCompat.METADATA_KEY_ARTIST, artist)
            .putString(MediaMetadataCompat.METADATA_KEY_ALBUM_ART_URI, albumArt)
            .build()

        val playbackState = PlaybackStateCompat.Builder()
            .setActions(PlaybackStateCompat.ACTION_PLAY or
                    PlaybackStateCompat.ACTION_PAUSE or
                    PlaybackStateCompat.ACTION_STOP)
            .setState(if (isPlaying) PlaybackStateCompat.STATE_PLAYING else PlaybackStateCompat.STATE_PAUSED, 0, 1f)
            .build()

        // Send the update through the method channel to the service
        methodChannel.invokeMethod("updateMediaSession", mapOf(
            "isPlaying" to isPlaying,
            "title" to title,
            "artist" to artist,
            "albumArt" to albumArt
        ), null)
    }

    override fun onDestroy() {
        super.onDestroy()
        mediaBrowser?.disconnect()
    }
} 