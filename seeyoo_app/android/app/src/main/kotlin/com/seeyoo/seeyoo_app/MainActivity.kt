package com.seeyoo.seeyoo_app

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // Setze das Theme auf NormalTheme vor dem super.onCreate() Aufruf,
        // um den nativen Splash-Screen zu überspringen
        setTheme(R.style.NormalTheme)
        super.onCreate(savedInstanceState)
    }
}
