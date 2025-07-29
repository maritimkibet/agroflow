package com.dexterous.flutterlocalnotifications;

import android.app.Notification;
import android.graphics.Bitmap;
import android.os.Build;

/**
 * Custom implementation to fix the ambiguous reference to bigLargeIcon
 */
public class NotificationStyle {

    /**
     * Applies the big picture style to a notification
     */
    public static void applyBigPictureStyle(Notification.Builder builder, Bitmap bigPicture, Bitmap largeIcon) {
        Notification.BigPictureStyle bigPictureStyle = new Notification.BigPictureStyle();
        bigPictureStyle.bigPicture(bigPicture);
        
        // Fix for the ambiguous reference to bigLargeIcon
        // Explicitly cast null to Bitmap to resolve the ambiguity
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            bigPictureStyle.bigLargeIcon((Bitmap) null);
        }
        
        builder.setStyle(bigPictureStyle);
    }
}