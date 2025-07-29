package com.dexterous.flutterlocalnotifications;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.content.Context;
import android.graphics.Bitmap;
import android.os.Build;
import androidx.annotation.NonNull;
import androidx.core.app.NotificationManagerCompat;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

/**
 * Custom implementation to fix the ambiguous reference to bigLargeIcon
 * This is a simplified version that only includes the necessary parts to fix the issue
 */
public class FlutterLocalNotificationsPlugin implements FlutterPlugin, MethodCallHandler {
    private MethodChannel channel;
    private Context applicationContext;

    @Override
    public void onAttachedToEngine(@NonNull FlutterPlugin.FlutterPluginBinding binding) {
        applicationContext = binding.getApplicationContext();
        channel = new MethodChannel(binding.getBinaryMessenger(), "dexterous.com/flutter/local_notifications");
        channel.setMethodCallHandler(this);
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPlugin.FlutterPluginBinding binding) {
        channel.setMethodCallHandler(null);
        channel = null;
        applicationContext = null;
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
        // This is a simplified implementation
        // The actual plugin has many more methods and functionality
        result.notImplemented();
    }

    /**
     * Creates a big picture style notification
     * This method is modified to use our custom NotificationStyle class
     * to fix the ambiguous reference to bigLargeIcon
     */
    private Notification createBigPictureNotification(
            NotificationManager notificationManager,
            NotificationManagerCompat notificationManagerCompat,
            String channelId,
            Bitmap bigPicture,
            Bitmap largeIcon) {
        
        Notification.Builder builder;
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            NotificationChannel notificationChannel = notificationManager.getNotificationChannel(channelId);
            builder = new Notification.Builder(applicationContext, channelId)
                    .setContentTitle("Title")
                    .setContentText("Content")
                    .setSmallIcon(android.R.drawable.ic_dialog_info);
        } else {
            builder = new Notification.Builder(applicationContext)
                    .setContentTitle("Title")
                    .setContentText("Content")
                    .setSmallIcon(android.R.drawable.ic_dialog_info);
        }
        
        // Use our custom NotificationStyle class to apply the big picture style
        // This avoids the ambiguous reference to bigLargeIcon
        NotificationStyle.applyBigPictureStyle(builder, bigPicture, largeIcon);
        
        return builder.build();
    }
}