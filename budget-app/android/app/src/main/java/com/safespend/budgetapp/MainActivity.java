package com.safespend.budgetapp;

import android.os.Bundle;
import android.view.View;
import android.view.WindowManager;
import androidx.core.view.WindowCompat;
import com.getcapacitor.BridgeActivity;

public class MainActivity extends BridgeActivity {
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        // Solid Deep Navy status bar and navigation bar
        getWindow().setStatusBarColor(android.graphics.Color.parseColor("#0F172A"));
        getWindow().setNavigationBarColor(android.graphics.Color.parseColor("#0F172A"));
    }
}
