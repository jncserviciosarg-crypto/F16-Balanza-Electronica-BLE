                 android:name(0x01010003)="com.example.f16_balanza_electronica.DYNAMIC_RECEIVER_NOT_EXPORTED
                 _PERMISSION" (Raw:
                 "com.example.f16_balanza_electronica.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION")
               E: application (line=47)
                 A: android:label(0x01010001)="F16 Balanza" (Raw: "F16 Balanza")
                 A: android:icon(0x01010002)=@0x7f0c0001
                 A: android:name(0x01010003)="android.app.Application" (Raw: "android.app.Application")     
                 A: android:debuggable(0x0101000f)=(type 0x12)0xffffffff
                 A: android:extractNativeLibs(0x010104ea)=(type 0x12)0x0
                 A: android:appComponentFactory(0x0101057a)="androidx.core.app.CoreComponentFactory" (Raw:  
                 "androidx.core.app.CoreComponentFactory")
                 E: activity (line=54)
                   A: android:theme(0x01010000)=@0x7f0e00a2
                   A: android:name(0x01010003)="com.example.f16_balanza_electronica.MainActivity" (Raw:     
                   "com.example.f16_balanza_electronica.MainActivity")
                   A: android:exported(0x01010010)=(type 0x12)0xffffffff
                   A: android:taskAffinity(0x01010012)="" (Raw: "")
                   A: android:launchMode(0x0101001d)=(type 0x10)0x1
                   A: android:configChanges(0x0101001f)=(type 0x11)0x40003fb4
                   A: android:windowSoftInputMode(0x0101022b)=(type 0x11)0x10
                   A: android:hardwareAccelerated(0x010102d3)=(type 0x12)0xffffffff
                   E: meta-data (line=70)
                     A: android:name(0x01010003)="io.flutter.embedding.android.NormalTheme" (Raw:
                     "io.flutter.embedding.android.NormalTheme")
                     A: android:resource(0x01010025)=@0x7f0e00a3
                   E: intent-filter (line=74)
                     E: action (line=75)
                       A: android:name(0x01010003)="android.intent.action.MAIN" (Raw:
                       "android.intent.action.MAIN")
                     E: category (line=77)
                       A: android:name(0x01010003)="android.intent.category.LAUNCHER" (Raw:
                       "android.intent.category.LAUNCHER")
                 E: meta-data (line=84)
                   A: android:name(0x01010003)="flutterEmbedding" (Raw: "flutterEmbedding")
                   A: android:value(0x01010024)=(type 0x10)0x2
                 E: provider (line=91)
                   A: android:name(0x01010003)="dev.fluttercommunity.plus.share.ShareFileProvider" (Raw:    
                   "dev.fluttercommunity.plus.share.ShareFileProvider")
                   A: android:exported(0x01010010)=(type 0x12)0x0
                   A:
                   android:authorities(0x01010018)="com.example.f16_balanza_electronica.flutter.share_provid
                   er" (Raw: "com.example.f16_balanza_electronica.flutter.share_provider")
                   A: android:grantUriPermissions(0x0101001b)=(type 0x12)0xffffffff
                   E: meta-data (line=96)
                     A: android:name(0x01010003)="android.support.FILE_PROVIDER_PATHS" (Raw:
                     "android.support.FILE_PROVIDER_PATHS")
                     A: android:resource(0x01010025)=@0x7f100001
                 E: receiver (line=104)
                   A: android:name(0x01010003)="dev.fluttercommunity.plus.share.SharePlusPendingIntent"     
                   (Raw: "dev.fluttercommunity.plus.share.SharePlusPendingIntent")
                   A: android:exported(0x01010010)=(type 0x12)0x0
                   E: intent-filter (line=107)
                     E: action (line=108)
                       A: android:name(0x01010003)="EXTRA_CHOSEN_COMPONENT" (Raw: "EXTRA_CHOSEN_COMPONENT") 
                 E: provider (line=112)
                   A: android:name(0x01010003)="net.nfet.flutter.printing.PrintFileProvider" (Raw:
                   "net.nfet.flutter.printing.PrintFileProvider")
                   A: android:exported(0x01010010)=(type 0x12)0x0
                   A: android:authorities(0x01010018)="com.example.f16_balanza_electronica.flutter.printing"
                   (Raw: "com.example.f16_balanza_electronica.flutter.printing")
                   A: android:grantUriPermissions(0x0101001b)=(type 0x12)0xffffffff
                   E: meta-data (line=117)
                     A: android:name(0x01010003)="android.support.FILE_PROVIDER_PATHS" (Raw:
                     "android.support.FILE_PROVIDER_PATHS")
                     A: android:resource(0x01010025)=@0x7f100000
                 E: uses-library (line=122)
                   A: android:name(0x01010003)="androidx.window.extensions" (Raw:
                   "androidx.window.extensions")
                   A: android:required(0x0101028e)=(type 0x12)0x0
                 E: uses-library (line=125)
                   A: android:name(0x01010003)="androidx.window.sidecar" (Raw: "androidx.window.sidecar")   
                   A: android:required(0x0101028e)=(type 0x12)0x0
                 E: provider (line=129)
                   A: android:name(0x01010003)="androidx.startup.InitializationProvider" (Raw:
                   "androidx.startup.InitializationProvider")
                   A: android:exported(0x01010010)=(type 0x12)0x0
                   A: android:authorities(0x01010018)="com.example.f16_balanza_electronica.androidx-startup"
                   (Raw: "com.example.f16_balanza_electronica.androidx-startup")
                   E: meta-data (line=133)
                     A: android:name(0x01010003)="androidx.lifecycle.ProcessLifecycleInitializer" (Raw:     
                     "androidx.lifecycle.ProcessLifecycleInitializer")
                     A: android:value(0x01010024)="androidx.startup" (Raw: "androidx.startup")
                   E: meta-data (line=136)
                     A: android:name(0x01010003)="androidx.profileinstaller.ProfileInstallerInitializer"    
                     (Raw: "androidx.profileinstaller.ProfileInstallerInitializer")
                     A: android:value(0x01010024)="androidx.startup" (Raw: "androidx.startup")
                 E: receiver (line=141)
                   A: android:name(0x01010003)="androidx.profileinstaller.ProfileInstallReceiver" (Raw:     
                   "androidx.profileinstaller.ProfileInstallReceiver")
                   A: android:permission(0x01010006)="android.permission.DUMP" (Raw:
                   "android.permission.DUMP")
                   A: android:enabled(0x0101000e)=(type 0x12)0xffffffff
                   A: android:exported(0x01010010)=(type 0x12)0xffffffff
                   A: android:directBootAware(0x01010505)=(type 0x12)0x0
                   E: intent-filter (line=147)
                     E: action (line=148)
                       A: android:name(0x01010003)="androidx.profileinstaller.action.INSTALL_PROFILE" (Raw: 
                       "androidx.profileinstaller.action.INSTALL_PROFILE")
                   E: intent-filter (line=150)
                     E: action (line=151)
                       A: android:name(0x01010003)="androidx.profileinstaller.action.SKIP_FILE" (Raw:       
                       "androidx.profileinstaller.action.SKIP_FILE")
                   E: intent-filter (line=153)
                     E: action (line=154)
                       A: android:name(0x01010003)="androidx.profileinstaller.action.SAVE_PROFILE" (Raw:    
                       "androidx.profileinstaller.action.SAVE_PROFILE")
                   E: intent-filter (line=156)
                     E: action (line=157)
                       A: android:name(0x01010003)="androidx.profileinstaller.action.BENCHMARK_OPERATION"   
                       (Raw: "androidx.profileinstaller.action.BENCHMARK_OPERATION")
[  +18 ms] Stopping app 'app-debug.apk' on 24117RN76L.
[   +4 ms] executing: C:\Users\Lenovo\AppData\Local\Android\sdk\platform-tools\adb.exe -s oz7phec6w8ws8pqs
shell am force-stop com.example.f16_balanza_electronica
[ +177 ms] Installing APK.
[   +3 ms] Installing build\app\outputs\flutter-apk\app-debug.apk...
[        ] executing: C:\Users\Lenovo\AppData\Local\Android\sdk\platform-tools\adb.exe -s oz7phec6w8ws8pqs  
install -t -r C:\flutter_application\F16-v_1_0_1\build\app\outputs\flutter-apk\app-debug.apk
[+8654 ms] Performing Streamed Install
                    Success
[        ] Installing build\app\outputs\flutter-apk\app-debug.apk... (completed in 8.7s)
[   +1 ms] executing: C:\Users\Lenovo\AppData\Local\Android\sdk\platform-tools\adb.exe -s oz7phec6w8ws8pqs  
shell echo -n a1a725395399309af2f04138dac7b34ed2948807 >
/data/local/tmp/sky.com.example.f16_balanza_electronica.sha1
[  +87 ms] executing: C:\Users\Lenovo\AppData\Local\Android\sdk\platform-tools\adb.exe -s oz7phec6w8ws8pqs
shell -x logcat -v time -t 1
[ +130 ms] --------- beginning of system
                    01-13 20:40:53.238 I/ActivityManager( 1967): unbindService
                    com.android.server.am.ActiveServices@be8556d conn=android.os.BinderProxy@1fe5794        
                    callingPid=2882
[  +12 ms] executing: C:\Users\Lenovo\AppData\Local\Android\sdk\platform-tools\adb.exe -s oz7phec6w8ws8pqs
shell am start -a android.intent.action.MAIN -c android.intent.category.LAUNCHER -f 0x20000000 --ez
enable-dart-profiling true --ez enable-checked-mode true --ez verify-entry-points true
com.example.f16_balanza_electronica/com.example.f16_balanza_electronica.MainActivity
[ +259 ms] Starting: Intent { act=android.intent.action.MAIN cat=[android.intent.category.LAUNCHER]
flg=0x20000000 cmp=com.example.f16_balanza_electronica/.MainActivity (has extras) }
[        ] Waiting for VM Service port to be available...
[+1112 ms] D/FlutterJNI(20221): Beginning load of flutter...
[  +99 ms] D/FlutterJNI(20221): flutter (null) was loaded normally!
[+1430 ms] I/flutter (20221): [IMPORTANT:flutter/shell/platform/android/android_context_vk_impeller.cc(62)]
Using the Impeller rendering backend (Vulkan).
[ +144 ms] VM Service URL on device: http://127.0.0.1:33235/RsussQZ0LWk=/
[   +1 ms] executing: C:\Users\Lenovo\AppData\Local\Android\sdk\platform-tools\adb.exe -s oz7phec6w8ws8pqs
forward tcp:0 tcp:33235
[  +53 ms] 49725
[        ] Forwarded host port 49725 to device port 33235 for VM Service
[   +8 ms] Caching compiled dill
[  +83 ms] Connecting to service protocol: http://127.0.0.1:49725/RsussQZ0LWk=/
[ +301 ms] Launching a Dart Developer Service (DDS) instance at http://127.0.0.1:0, connecting to VM service
at http://127.0.0.1:49725/RsussQZ0LWk=/.
[ +626 ms] Successfully connected to service protocol: http://127.0.0.1:49725/RsussQZ0LWk=/
[  +92 ms] DevFS: Creating new filesystem on the device (null)
[  +47 ms] DevFS: Created new filesystem on the device
(file:///data/user/0/com.example.f16_balanza_electronica/code_cache/F16-v_1_0_1SWUQDU/F16-v_1_0_1/)
[   +4 ms] Updating assets
[   +1 ms] runHooks() with {TargetFile: C:\flutter_application\F16-v_1_0_1\lib\main.dart, BuildMode: debug} 
and TargetPlatform.android_arm64
[        ] runHooks() - will perform dart build
[   +2 ms] Initializing file store
[   +3 ms] dart_build: Starting due to {}
[  +64 ms] No packages with native assets. Skipping native assets compilation.
[   +9 ms] dart_build: Complete
[  +30 ms] Persisting file store
[   +6 ms] Done persisting file store
[  +13 ms] runHooks() - done
[ +293 ms] Syncing files to device 24117RN76L...
[   +3 ms] Compiling dart to kernel with 0 updated files
[   +1 ms] Processing bundle.
[   +1 ms] <- recompile package:f16_balanza_electronica/main.dart c247bf55-9b44-473e-bf8a-f790aa6aba9e      
[        ] <- c247bf55-9b44-473e-bf8a-f790aa6aba9e
[   +3 ms] Bundle processing done.
[ +506 ms] D/HWUI    (20221): [HWUI] Flag vulkan_enhance_pipeline_cache enabled
[        ] D/HWUI    (20221): [HWUI] EnhanceVkPipelineCache is disabled
[        ] D/HWUI    (20221): [HWUI] Flag ddre enabled
[        ] I/Choreographer(20221): Skipped 214 frames!  The application may be doing too much work on its   
main thread.
[        ] I/ComputilityLevel(20221): getComputilityLevel(): 2
[   +3 ms] I/WindowExtensionsImpl(20221): Initializing Window Extensions, vendor API level=9, activity      
embedding enabled=true
[  +49 ms] E/nza_electronica(20221): [perfctl] 20221 20221 FPSGO ver:7
[   +1 ms] E/nza_electronica(20221): [perfctl] 1 1 1 0
[   +1 ms] D/BufferQueueConsumer(20221): [](id:4efd00000000,api:0,p:-1,c:20221) connect:
controlledByApp=false
[   +1 ms] D/BLASTBufferQueue(20221): [VRI[MainActivity]#0](f:0,a:0) constructor()
[   +2 ms] D/BLASTBufferQueue(20221): [VRI[MainActivity]#0](f:0,a:0) update width=2400 height=1080 format=-3
mTransformHint=7
[   +6 ms] D/VRI[MainActivity](20221): vri.reportNextDraw 0 Rect(0, 0 - 2400, 1080)
android.view.ViewRootImpl.performTraversals:5538 android.view.ViewRootImpl.doTraversal:4091
android.view.ViewRootImpl$TraversalRunnable.run:12473 android.view.Choreographer$CallbackRecord.run:2037    
android.view.Choreographer$CallbackRecord.run:2046 
[        ] D/SurfaceView(20221): UPDATE null, mIsCastMode = false
[   +4 ms] D/ViewRootImplStubImpl(20221): onSurfaceViewAttached:
[        ] D/ViewRootImplStubImpl(20221): , vri:android.view.ViewRootImpl@c51789f,
com.example.f16_balanza_electronica/com.example.f16_balanza_electronica.MainActivity
[        ] D/ViewRootImplStubImpl(20221): , vri size:2400x1080
[   +1 ms] D/ViewRootImplStubImpl(20221): ,
surfaceView:io.flutter.embedding.android.FlutterSurfaceView{f3d323e V.E...... ......ID 0,0-2400,1080},      
SurfaceView[com.example.f16_balanza_electronica/com.example.f16_balanza_electronica.MainActivity]
[        ] D/ViewRootImplStubImpl(20221): , surfaceView size:2400x1080
[        ] D/ViewRootImplStubImpl(20221): , surfaceControl:Surface(name=f3d323e
SurfaceView[com.example.f16_balanza_electronica/com.example.f16_balanza_electronica.MainActivity](BLAST)#686
)/@0xb6afdec
[   +1 ms] D/BufferQueueConsumer(20221): [](id:4efd00000001,api:0,p:-1,c:20221) connect:
controlledByApp=false
[        ] D/BLASTBufferQueue(20221): [f3d323e
SurfaceView[com.example.f16_balanza_electronica/com.example.f16_balanza_electronica.MainActivity]#1](f:0,a:0
) constructor()
[        ] D/BLASTBufferQueue(20221): [f3d323e
SurfaceView[com.example.f16_balanza_electronica/com.example.f16_balanza_electronica.MainActivity]#1](f:0,a:0
) update width=2400 height=1080 format=4 mTransformHint=7
[  +12 ms] I/nza_electronica(20221): Compiler allocated 6307KB to compile void
android.view.ViewRootImpl.performTraversals()
[  +18 ms] Updating files.
[        ] Pending asset builds completed. Writing dirty entries.
[        ] DevFS: Sync finished
[   +1 ms] Syncing files to device 24117RN76L... (completed in 631ms)
[   +2 ms] Synced 0.0MB.
[   +3 ms] <- accept
[   +9 ms] Connected to _flutterView/0xb4000075aba0d970.
[   +5 ms] Flutter run key commands.
[   +2 ms] r Hot reload. 
[   +1 ms] R Hot restart.
[   +1 ms] h List all available interactive commands.
[   +1 ms] d Detach (terminate "flutter run" but leave application running).
[   +1 ms] c Clear the screen
[   +1 ms] q Quit (terminate the application on the device).
[   +1 ms] A Dart VM Service on 24117RN76L is available at: http://127.0.0.1:49731/x2NpKSH0uVo=/
[   +3 ms] The Flutter DevTools debugger and profiler on 24117RN76L is available at:
           http://127.0.0.1:49731/x2NpKSH0uVo=/devtools/?uri=ws://127.0.0.1:49731/x2NpKSH0uVo=/ws
[ +122 ms] D/WmSystemUiDebug(20221): set navigation bar color,Alpha=1.0, RGB:0,0,0
caller:io.flutter.plugin.platform.PlatformPlugin.setSystemChromeSystemUIOverlayStyle:503
io.flutter.plugin.platform.PlatformPlugin.access$700:36
io.flutter.plugin.platform.PlatformPlugin$1.setSystemUiOverlayStyle:123
io.flutter.embedding.engine.systemchannels.PlatformChannel$1.onMethodCall:130
io.flutter.plugin.common.MethodChannel$IncomingMethodCallHandler.onMessage:267
io.flutter.embedding.engine.dart.DartMessenger.invokeHandler:292
io.flutter.embedding.engine.dart.DartMessenger.lambda$dispatchMessageToQueue$0$io-flutter-embedding-engine-d
art-DartMessenger:319 io.flutter.embedding.engine.dart.DartMessenger$$ExternalSyntheticLambda0.run:0        
android.os.Handler.handleCallback:995 android.os.Handler.dispatchMessage:103 
[  +11 ms] D/InsetsController(20221): Setting requestedVisibleTypes to -16 (was -9)
[  +32 ms] D/VRI[MainActivity](20221): vri.reportNextDraw 0 Rect(0, 0 - 2400, 1080)
android.view.ViewRootImpl.performTraversals:5538 android.view.ViewRootImpl.doTraversal:4091
android.view.ViewRootImpl$TraversalRunnable.run:12473 android.view.Choreographer$CallbackRecord.run:2037    
android.view.Choreographer$CallbackRecord.run:2046 
[   +1 ms] D/SurfaceView(20221): UPDATE Surface(name=f3d323e
SurfaceView[com.example.f16_balanza_electronica/com.example.f16_balanza_electronica.MainActivity]#685)/@0x1d
51e84, mIsProjectionMode = false
[        ] D/InsetsController(20221): default animation onReady types: 3
controller=android.view.InsetsAnimationControlImpl@522666d
[        ] D/ViewRootImplStubImpl(20221): requestedTypes: 3
[        ] D/WindowLayoutComponentImpl(20221): Register WindowLayoutInfoListener on
Context=com.example.f16_balanza_electronica.MainActivity@9d2cdc7, of which
baseContext=android.app.ContextImpl@b8fab33
[  +13 ms] D/VRI[MainActivity](20221): vri.reportNextDraw 0 Rect(0, 0 - 2400, 1080)
android.view.ViewRootImpl.handleResized:3221 android.view.ViewRootImpl.-$$Nest$mhandleResized:0
android.view.ViewRootImpl$W.resized:13680 android.app.servertransaction.WindowStateResizeItem.execute:93    
android.app.servertransaction.WindowStateTransactionItem.execute:62 
[  +70 ms] I/GrallocExtra(20221): gralloc_extra_query:is_SW3D 0
[   +3 ms] I/nza_electronica(20221): Support mwdf product tanzanite: 
[   +1 ms] D/nza_electronica(20221): MWDF parse error: No such file or directory
[        ] I/GrallocExtra(20221): gralloc_extra_query:is_SW3D 0
[        ] D/BLASTBufferQueue(20221): [f3d323e
SurfaceView[com.example.f16_balanza_electronica/com.example.f16_balanza_electronica.MainActivity]#1](f:0,a:1
) acquireNextBufferLocked size=2400x1080 mFrameNumber=1 applyTransaction=true mTimestamp=803361683739(auto) 
mPendingTransactions.size=0 graphicBufferId=86848533692426 transform=0
[  +12 ms] D/VRI[MainActivity](20221): vri.Setup new sync=wmsSync-VRI[MainActivity]#1
[  +11 ms] I/SKIA    (20221): CreateGraphicsPipeline pipeline cache hit. elpased time: 0.23 ms.
[   +4 ms] D/BLASTBufferQueue(20221): [VRI[MainActivity]#0](f:0,a:1) acquireNextBufferLocked size=2400x1080 
mFrameNumber=1 applyTransaction=true mTimestamp=803396516662(auto) mPendingTransactions.size=0
graphicBufferId=86848533692434 transform=4
[   +5 ms] D/VRI[MainActivity](20221): vri.reportDrawFinished 0 0 Rect(0, 0 - 2400, 1080)
[        ] I/NativeTurboSchedManager(20221): Load libmiui_runtime
[ +156 ms] I/HandWritingStubImpl(20221): refreshLastKeyboardType: 1
[        ] I/HandWritingStubImpl(20221): getCurrentKeyboardType: 1
[   +9 ms] D/InsetsController(20221): hide(ime(), fromIme=false)
[   +2 ms] I/ImeTracker(20221): com.example.f16_balanza_electronica:b8a4c6ce: onCancelled at
PHASE_CLIENT_ALREADY_HIDDEN
[  +54 ms] D/InsetsController(20221): onAnimationFinish showOnFinish: false
[   +3 ms] W/InteractionJankMonitor(20221): Initializing without READ_DEVICE_CONFIG permission.
enabled=false, interval=1, missedFrameThreshold=3, frameTimeThreshold=64,
package=com.example.f16_balanza_electronica
[   +1 ms] D/InsetsAnimationCtrlImpl(20221): notifyFinished shown: false, currentAlpha: 1.000000,
currentInsets: Insets{left=0, top=0, right=0, bottom=0}
[        ] D/InsetsController(20221): cancelAnimation of types:3 animType:1
host:com.example.f16_balanza_electronica/com.example.f16_balanza_electronica.MainActivity
invokeCallback=false
[  +10 ms] D/InsetsController(20221): notifyFinished. shown: false
runner=android.view.InsetsAnimationControlImpl@522666d
[        ] D/InsetsAnimationCtrlImpl(20221): Animation finished abruptly.
[        ] I/HandWritingStubImpl(20221): getCurrentKeyboardType: 1
[ +477 ms] D/ProfileInstaller(20221): Installing profile for com.example.f16_balanza_electronica
[+1004 ms] E/LB      (20221): fail to open file: No such file or directory
[   +1 ms] W/1.raster(20221): type=1400 audit(0.0:7977): avc:  denied  { getattr } for
path="/sys/module/metis/parameters/minor_window_app" dev="sysfs" ino=79730
scontext=u:r:untrusted_app:s0:c125,c257,c512,c768 tcontext=u:object_r:sysfs_migt:s0 tclass=file permissive=0
app=com.example.f16_balanza_electronica
[+2409 ms] ══╡ EXCEPTION CAUGHT BY RENDERING LIBRARY
╞═════════════════════════════════════════════════════════
                    The following assertion was thrown during layout:
                    A RenderFlex overflowed by 17 pixels on the bottom.

                    The relevant error-causing widget was:
                      Column
Column:file:///C:/flutter_application/F16-v_1_0_1/lib/screens/f16_splash_screen.dart:208:22

                    To inspect this widget in Flutter DevTools, visit:

http://127.0.0.1:49731/x2NpKSH0uVo=/devtools//#/inspector?uri=http%3A%2F%2F127.0.0.1%3A49731%2Fx2NpKSH0uVo%3
                    D%2F&inspectorRef=inspector-0

                    The overflowing RenderFlex has an orientation of Axis.vertical.
                    The edge of the RenderFlex that is overflowing has been marked in the rendering with a  
yellow and
                    black striped pattern. This is usually caused by the contents being too big for the     
RenderFlex.
                    Consider applying a flex factor (e.g. using an Expanded widget) to force the children of
the
                    RenderFlex to fit within the available space instead of being sized to their natural    
size.
                    This is considered an error condition because it indicates that there is content that   
cannot be
                    seen. If the content is legitimately bigger than the available space, consider clipping 
it with a
                    ClipRect widget before putting it in the flex, or using a scrollable container rather   
than a Flex,
                    like a ListView.
                    The specific RenderFlex in question is: RenderFlex#09609 relayoutBoundary=up5
OVERFLOWING:
                      needs compositing
                      creator: Column ← ConstrainedBox ← LayoutBuilder ← Center ← MediaQuery ← Padding ←    
SafeArea ←
                        KeyedSubtree-[GlobalKey#ad102] ← _BodyBuilder ← MediaQuery ←
LayoutId-[<_ScaffoldSlot.body>] ←
                        CustomMultiChildLayout ← ⋯
                      parentData: <none> (can use size)
                      constraints: BoxConstraints(300.0<=w<=900.0, 0.0<=h<=480.0)
                      size: Size(900.0, 480.0)
                      direction: vertical
                      mainAxisAlignment: start
                      mainAxisSize: min
                      crossAxisAlignment: center
                      verticalDirection: down
                      spacing: 0.0

◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤        

════════════════════════════════════════════════════════════════════════════════════════════════════        
[+2022 ms] W/nza_electronica(20221): userfaultfd: MOVE ioctl seems unsupported: Connection timed out
[   +6 ms] W/FinalizerDaemon(20221): type=1400 audit(0.0:7995): avc:  denied  { getopt } for
path="/dev/socket/usap_pool_primary" scontext=u:r:untrusted_app:s0:c125,c257,c512,c768
tcontext=u:r:zygote:s0 tclass=unix_stream_socket permissive=0 app=com.example.f16_balanza_electronica       
[ +288 ms] E/nza_electronica(20221): FrameInsert open fail: No such file or directory
[  +18 ms] D/[FBP-Android](20221): [FBP] onMethodCall: flutterRestart
[        ] D/[FBP-Android](20221): [FBP] initializing BluetoothAdapter
[   +4 ms] D/[FBP-Android](20221): [FBP] disconnectAllDevices(flutterRestart)
[        ] D/[FBP-Android](20221): [FBP] connectedPeripherals: 0
[  +13 ms] D/[FBP-Android](20221): [FBP] onMethodCall: getAdapterState
[+2784 ms] I/MIUIInput(20221): [MotionEvent] ViewRootImpl windowName
'com.example.f16_balanza_electronica/com.example.f16_balanza_electronica.MainActivity', {
action=ACTION_DOWN, id[0]=0, pointerCount=1, eventTime=812666, downTime=812666, phoneEventTime=20:41:08.213 
} moveCount:0
[   +9 ms] W/MirrorManager(20221): this model don't Support
[        ] D/VRI[MainActivity](20221): getMiuiFreeformStackInfo mTmpFrames.miuiFreeFormStackInfo: null      
[ +113 ms] I/PowerHalMgrImpl(20221): perfLockAcq is supported. 
[  +32 ms] I/MIUIInput(20221): [MotionEvent] ViewRootImpl windowName
'com.example.f16_balanza_electronica/com.example.f16_balanza_electronica.MainActivity', { action=ACTION_UP, 
id[0]=0, pointerCount=1, eventTime=812748, downTime=812666, phoneEventTime=20:41:08.295 } moveCount:0       
[ +267 ms] D/VRI[MainActivity](20221): getMiuiFreeformStackInfo mTmpFrames.miuiFreeFormStackInfo: null
[  +36 ms] D/[FBP-Android](20221): [FBP] onMethodCall: startScan
[   +1 ms] D/CompatChangeReporter(20221): Compat change id reported: 386727721; UID 10381; state: ENABLED
[        ] D/BluetoothAdapter(20221): isLeEnabled(): ON
[        ] D/BluetoothLeScanner(20221): onScannerRegistered() - status=0 scannerId=6 mScannerId=0
[ +564 ms] I/PowerHalMgrImpl(20221): hdl:679, pid:20221 
[+9458 ms] D/[FBP-Android](20221): [FBP] onMethodCall: stopScan
[        ] D/BluetoothAdapter(20221): isLeEnabled(): ON
[   +7 ms] I/flutter (20221): [FBP] stopScan: already stopped
[+1774 ms] I/MIUIInput(20221): [MotionEvent] ViewRootImpl windowName
'com.example.f16_balanza_electronica/com.example.f16_balanza_electronica.MainActivity', {
action=ACTION_DOWN, id[0]=0, pointerCount=1, eventTime=824935, downTime=824935, phoneEventTime=20:41:20.482 
} moveCount:0
[   +1 ms] D/VRI[MainActivity](20221): getMiuiFreeformStackInfo mTmpFrames.miuiFreeFormStackInfo: null
[  +88 ms] I/MIUIInput(20221): [MotionEvent] ViewRootImpl windowName
'com.example.f16_balanza_electronica/com.example.f16_balanza_electronica.MainActivity', { action=ACTION_UP, 
id[0]=0, pointerCount=1, eventTime=825032, downTime=824935, phoneEventTime=20:41:20.579 } moveCount:0       
[  +41 ms] D/[FBP-Android](20221): [FBP] onMethodCall: connect
[   +1 ms] D/BluetoothGatt(20221): connect() - device: XX:XX:XX:XX:E6:1A, auto: false
[        ] D/BluetoothGatt(20221): registerApp()
[        ] D/BluetoothGatt(20221): registerApp() - UUID=d1fcda0f-b543-41fc-af8e-c17d08a703cb
[   +1 ms] D/BluetoothGatt(20221): onClientRegistered() - status=0 clientIf=50
[ +271 ms] D/BluetoothGatt(20221): onClientConnectionState() - status=0 clientIf=50 connected=true
device=XX:XX:XX:XX:E6:1A
[   +1 ms] D/[FBP-Android](20221): [FBP] onConnectionStateChange:connected
[        ] D/[FBP-Android](20221): [FBP]   status: SUCCESS
[ +308 ms] D/BluetoothGatt(20221): onConnectionUpdated() - Device=XX:XX:XX:XX:E6:1A interval=6 latency=0
timeout=500 status=0
[  +49 ms] D/[FBP-Android](20221): [FBP] onMethodCall: requestMtu
[        ] D/BluetoothGatt(20221): configureMTU() - device: XX:XX:XX:XX:E6:1A mtu: 512
[ +172 ms] D/BluetoothGatt(20221): onConfigureMTU() - Device=XX:XX:XX:XX:E6:1A mtu=517 status=0
[   +1 ms] D/[FBP-Android](20221): [FBP] onMtuChanged:
[        ] D/[FBP-Android](20221): [FBP]   mtu: 517
[        ] D/[FBP-Android](20221): [FBP]   status: GATT_SUCCESS (0)
[   +6 ms] D/[FBP-Android](20221): [FBP] onMethodCall: discoverServices
[        ] D/BluetoothGatt(20221): discoverServices() - device: XX:XX:XX:XX:E6:1A
[   +5 ms] D/BluetoothGatt(20221): onSearchComplete() = address=XX:XX:XX:XX:E6:1A status=0
[        ] D/[FBP-Android](20221): [FBP] onServicesDiscovered:
[        ] D/[FBP-Android](20221): [FBP]   count: 3
[   +1 ms] D/[FBP-Android](20221): [FBP]   status: 0GATT_SUCCESS
[  +24 ms] D/[FBP-Android](20221): [FBP] onMethodCall: setNotifyValue
[   +1 ms] D/BluetoothGatt(20221): setCharacteristicNotification() - uuid:
00002a05-0000-1000-8000-00805f9b34fb enable: true
[  +15 ms] D/BluetoothGatt(20221): onConnectionUpdated() - Device=XX:XX:XX:XX:E6:1A interval=39 latency=0
timeout=500 status=0
[  +22 ms] I/PowerHalMgrImpl(20221): hdl:683, pid:20221 
[  +27 ms] D/[FBP-Android](20221): [FBP] onDescriptorWrite:
[   +1 ms] D/[FBP-Android](20221): [FBP]   chr: 2a05
[   +1 ms] D/[FBP-Android](20221): [FBP]   desc: 2902
[        ] D/[FBP-Android](20221): [FBP]   status: GATT_SUCCESS (0)
[   +5 ms] D/[FBP-Android](20221): [FBP] onMethodCall: setNotifyValue
[        ] D/BluetoothGatt(20221): setCharacteristicNotification() - uuid:
beb5483e-36e1-4688-b7f5-ea07361b26a8 enable: true
[  +89 ms] D/[FBP-Android](20221): [FBP] onDescriptorWrite:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[        ] D/[FBP-Android](20221): [FBP]   desc: 2902
[        ] D/[FBP-Android](20221): [FBP]   status: GATT_SUCCESS (0)
[        ] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +97 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +98 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +96 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +94 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +96 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[ +144 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +99 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +99 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +96 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +94 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +97 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +99 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +96 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +96 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +97 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +92 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[ +103 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[ +141 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +97 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +99 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +95 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[ +102 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +91 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +96 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +94 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +98 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +95 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +98 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[ +146 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +94 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +96 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[ +102 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +96 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +96 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +93 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +99 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +96 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +93 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +98 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[ +101 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[ +143 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +94 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +93 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +96 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[ +102 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +90 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[   +1 ms] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[ +101 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +96 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +92 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +98 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[ +101 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +96 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[ +143 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +95 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +97 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +96 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +97 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +94 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +99 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +93 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[ +102 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +91 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +99 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +98 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[ +144 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +98 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[+5086 ms] D/BluetoothGatt(20221): onClientConnectionState() - status=8 clientIf=50 connected=false
device=XX:XX:XX:XX:E6:1A
[        ] D/BluetoothGatt(20221): unregisterApp() - mClientIf=50
[        ] D/[FBP-Android](20221): [FBP] onConnectionStateChange:disconnected
[        ] D/[FBP-Android](20221): [FBP]   status: LINK_SUPERVISION_TIMEOUT
[        ] D/BluetoothGatt(20221): close()
[+14329 ms] I/MIUIInput(20221): [MotionEvent] ViewRootImpl windowName
'com.example.f16_balanza_electronica/com.example.f16_balanza_electronica.MainActivity', {
action=ACTION_DOWN, id[0]=0, pointerCount=1, eventTime=852238, downTime=852238, phoneEventTime=20:41:47.785 
} moveCount:0
[        ] D/VRI[MainActivity](20221): getMiuiFreeformStackInfo mTmpFrames.miuiFreeFormStackInfo: null
[  +88 ms] I/MIUIInput(20221): [MotionEvent] ViewRootImpl windowName
'com.example.f16_balanza_electronica/com.example.f16_balanza_electronica.MainActivity', { action=ACTION_UP, 
id[0]=0, pointerCount=1, eventTime=852304, downTime=852238, phoneEventTime=20:41:47.852 } moveCount:0       
[  +60 ms] W/WindowOnBackDispatcher(20221): sendCancelIfRunning: isInProgress=false
callback=io.flutter.embedding.android.FlutterActivity$1@49ef79b
[ +853 ms] I/PowerHalMgrImpl(20221): hdl:689, pid:20221 
[+2209 ms] I/MIUIInput(20221): [MotionEvent] ViewRootImpl windowName
'com.example.f16_balanza_electronica/com.example.f16_balanza_electronica.MainActivity', {
action=ACTION_DOWN, id[0]=0, pointerCount=1, eventTime=855451, downTime=855451, phoneEventTime=20:41:50.999 
} moveCount:0
[        ] D/VRI[MainActivity](20221): getMiuiFreeformStackInfo mTmpFrames.miuiFreeFormStackInfo: null
[  +82 ms] I/MIUIInput(20221): [MotionEvent] ViewRootImpl windowName
'com.example.f16_balanza_electronica/com.example.f16_balanza_electronica.MainActivity', { action=ACTION_UP, 
id[0]=0, pointerCount=1, eventTime=855530, downTime=855451, phoneEventTime=20:41:51.077 } moveCount:1       
[ +119 ms] D/[FBP-Android](20221): [FBP] onMethodCall: startScan
[        ] D/BluetoothAdapter(20221): isLeEnabled(): ON
[   +3 ms] D/BluetoothLeScanner(20221): onScannerRegistered() - status=0 scannerId=6 mScannerId=0
[ +802 ms] I/PowerHalMgrImpl(20221): hdl:693, pid:20221 
[+9211 ms] D/[FBP-Android](20221): [FBP] onMethodCall: stopScan
[        ] D/BluetoothAdapter(20221): isLeEnabled(): ON
[   +5 ms] I/flutter (20221): [FBP] stopScan: already stopped
[+1315 ms] I/MIUIInput(20221): [MotionEvent] ViewRootImpl windowName
'com.example.f16_balanza_electronica/com.example.f16_balanza_electronica.MainActivity', {
action=ACTION_DOWN, id[0]=0, pointerCount=1, eventTime=866986, downTime=866986, phoneEventTime=20:42:02.534 
} moveCount:0
[        ] D/VRI[MainActivity](20221): getMiuiFreeformStackInfo mTmpFrames.miuiFreeFormStackInfo: null
[  +32 ms] I/MIUIInput(20221): [MotionEvent] ViewRootImpl windowName
'com.example.f16_balanza_electronica/com.example.f16_balanza_electronica.MainActivity', { action=ACTION_UP, 
id[0]=0, pointerCount=1, eventTime=867029, downTime=866986, phoneEventTime=20:42:02.576 } moveCount:0       
[ +968 ms] I/PowerHalMgrImpl(20221): hdl:698, pid:20221 
[+1818 ms] I/MIUIInput(20221): [MotionEvent] ViewRootImpl windowName
'com.example.f16_balanza_electronica/com.example.f16_balanza_electronica.MainActivity', {
action=ACTION_DOWN, id[0]=0, pointerCount=1, eventTime=869805, downTime=869805, phoneEventTime=20:42:05.352 
} moveCount:0
[        ] D/VRI[MainActivity](20221): getMiuiFreeformStackInfo mTmpFrames.miuiFreeFormStackInfo: null
[ +102 ms] I/MIUIInput(20221): [MotionEvent] ViewRootImpl windowName
'com.example.f16_balanza_electronica/com.example.f16_balanza_electronica.MainActivity', { action=ACTION_UP, 
id[0]=0, pointerCount=1, eventTime=869916, downTime=869805, phoneEventTime=20:42:05.463 } moveCount:0       
[ +901 ms] I/PowerHalMgrImpl(20221): hdl:703, pid:20221 
[+1556 ms] I/MIUIInput(20221): [MotionEvent] ViewRootImpl windowName
'com.example.f16_balanza_electronica/com.example.f16_balanza_electronica.MainActivity', {
action=ACTION_DOWN, id[0]=0, pointerCount=1, eventTime=872369, downTime=872369, phoneEventTime=20:42:07.916 
} moveCount:0
[        ] D/VRI[MainActivity](20221): getMiuiFreeformStackInfo mTmpFrames.miuiFreeFormStackInfo: null
[  +34 ms] I/MIUIInput(20221): [MotionEvent] ViewRootImpl windowName
'com.example.f16_balanza_electronica/com.example.f16_balanza_electronica.MainActivity', { action=ACTION_UP, 
id[0]=0, pointerCount=1, eventTime=872402, downTime=872369, phoneEventTime=20:42:07.949 } moveCount:0       
[ +967 ms] I/PowerHalMgrImpl(20221): hdl:707, pid:20221 
[+3855 ms] I/MIUIInput(20221): [MotionEvent] ViewRootImpl windowName
'com.example.f16_balanza_electronica/com.example.f16_balanza_electronica.MainActivity', {
action=ACTION_DOWN, id[0]=0, pointerCount=1, eventTime=877227, downTime=877227, phoneEventTime=20:42:12.774 
} moveCount:0
[   +1 ms] D/VRI[MainActivity](20221): getMiuiFreeformStackInfo mTmpFrames.miuiFreeFormStackInfo: null
[  +45 ms] I/MIUIInput(20221): [MotionEvent] ViewRootImpl windowName
'com.example.f16_balanza_electronica/com.example.f16_balanza_electronica.MainActivity', { action=ACTION_UP, 
id[0]=0, pointerCount=1, eventTime=877281, downTime=877227, phoneEventTime=20:42:12.829 } moveCount:0       
[ +954 ms] I/PowerHalMgrImpl(20221): hdl:711, pid:20221 
[+1614 ms] I/MIUIInput(20221): [MotionEvent] ViewRootImpl windowName
'com.example.f16_balanza_electronica/com.example.f16_balanza_electronica.MainActivity', {
action=ACTION_DOWN, id[0]=0, pointerCount=1, eventTime=879845, downTime=879845, phoneEventTime=20:42:15.392 
} moveCount:0
[        ] D/VRI[MainActivity](20221): getMiuiFreeformStackInfo mTmpFrames.miuiFreeFormStackInfo: null
[  +67 ms] I/MIUIInput(20221): [MotionEvent] ViewRootImpl windowName
'com.example.f16_balanza_electronica/com.example.f16_balanza_electronica.MainActivity', { action=ACTION_UP, 
id[0]=0, pointerCount=1, eventTime=879915, downTime=879845, phoneEventTime=20:42:15.462 } moveCount:0       
[ +934 ms] I/PowerHalMgrImpl(20221): hdl:715, pid:20221 
[ +490 ms] I/MIUIInput(20221): [MotionEvent] ViewRootImpl windowName
'com.example.f16_balanza_electronica/com.example.f16_balanza_electronica.MainActivity', {
action=ACTION_DOWN, id[0]=0, pointerCount=1, eventTime=881337, downTime=881337, phoneEventTime=20:42:16.884 
} moveCount:0
[   +1 ms] D/VRI[MainActivity](20221): getMiuiFreeformStackInfo mTmpFrames.miuiFreeFormStackInfo: null
[  +93 ms] I/MIUIInput(20221): [MotionEvent] ViewRootImpl windowName
'com.example.f16_balanza_electronica/com.example.f16_balanza_electronica.MainActivity', { action=ACTION_UP, 
id[0]=0, pointerCount=1, eventTime=881438, downTime=881337, phoneEventTime=20:42:16.985 } moveCount:0       
[  +19 ms] W/WindowOnBackDispatcher(20221): sendCancelIfRunning: isInProgress=false
callback=io.flutter.embedding.android.FlutterActivity$1@49ef79b
[ +893 ms] I/PowerHalMgrImpl(20221): hdl:719, pid:20221 
[ +979 ms] I/MIUIInput(20221): [MotionEvent] ViewRootImpl windowName
'com.example.f16_balanza_electronica/com.example.f16_balanza_electronica.MainActivity', {
action=ACTION_DOWN, id[0]=0, pointerCount=1, eventTime=883328, downTime=883328, phoneEventTime=20:42:18.875 
} moveCount:0
[        ] D/VRI[MainActivity](20221): getMiuiFreeformStackInfo mTmpFrames.miuiFreeFormStackInfo: null
[  +80 ms] I/MIUIInput(20221): [MotionEvent] ViewRootImpl windowName
'com.example.f16_balanza_electronica/com.example.f16_balanza_electronica.MainActivity', { action=ACTION_UP, 
id[0]=0, pointerCount=1, eventTime=883398, downTime=883328, phoneEventTime=20:42:18.945 } moveCount:0       
[  +66 ms] D/[FBP-Android](20221): [FBP] onMethodCall: startScan
[        ] D/BluetoothAdapter(20221): isLeEnabled(): ON
[   +2 ms] D/BluetoothLeScanner(20221): onScannerRegistered() - status=0 scannerId=6 mScannerId=0
[ +853 ms] I/PowerHalMgrImpl(20221): hdl:723, pid:20221 
[+9155 ms] D/[FBP-Android](20221): [FBP] onMethodCall: stopScan
[        ] D/BluetoothAdapter(20221): isLeEnabled(): ON
[   +3 ms] I/flutter (20221): [FBP] stopScan: already stopped
[+1501 ms] I/MIUIInput(20221): [MotionEvent] ViewRootImpl windowName
'com.example.f16_balanza_electronica/com.example.f16_balanza_electronica.MainActivity', {
action=ACTION_DOWN, id[0]=0, pointerCount=1, eventTime=894988, downTime=894988, phoneEventTime=20:42:30.536 
} moveCount:0
[        ] D/VRI[MainActivity](20221): getMiuiFreeformStackInfo mTmpFrames.miuiFreeFormStackInfo: null
[  +75 ms] I/MIUIInput(20221): [MotionEvent] ViewRootImpl windowName
'com.example.f16_balanza_electronica/com.example.f16_balanza_electronica.MainActivity', { action=ACTION_UP, 
id[0]=0, pointerCount=1, eventTime=895070, downTime=894988, phoneEventTime=20:42:30.617 } moveCount:1       
[  +21 ms] D/[FBP-Android](20221): [FBP] onMethodCall: connect
[   +1 ms] D/BluetoothGatt(20221): connect() - device: XX:XX:XX:XX:E6:1A, auto: false
[        ] D/BluetoothGatt(20221): registerApp()
[        ] D/BluetoothGatt(20221): registerApp() - UUID=e6bf39b5-dfdf-48b2-8a7c-824c6092c80a
[   +6 ms] D/BluetoothGatt(20221): onClientRegistered() - status=0 clientIf=51
[ +301 ms] D/BluetoothGatt(20221): onClientConnectionState() - status=0 clientIf=51 connected=true
device=XX:XX:XX:XX:E6:1A
[        ] D/[FBP-Android](20221): [FBP] onConnectionStateChange:connected
[        ] D/[FBP-Android](20221): [FBP]   status: SUCCESS
[ +307 ms] D/BluetoothGatt(20221): onConnectionUpdated() - Device=XX:XX:XX:XX:E6:1A interval=6 latency=0
timeout=500 status=0
[  +47 ms] D/[FBP-Android](20221): [FBP] onMethodCall: requestMtu
[        ] D/BluetoothGatt(20221): configureMTU() - device: XX:XX:XX:XX:E6:1A mtu: 512
[ +176 ms] D/BluetoothGatt(20221): onConfigureMTU() - Device=XX:XX:XX:XX:E6:1A mtu=517 status=0
[        ] D/[FBP-Android](20221): [FBP] onMtuChanged:
[        ] D/[FBP-Android](20221): [FBP]   mtu: 517
[        ] D/[FBP-Android](20221): [FBP]   status: GATT_SUCCESS (0)
[   +2 ms] D/[FBP-Android](20221): [FBP] onMethodCall: discoverServices
[        ] D/BluetoothGatt(20221): discoverServices() - device: XX:XX:XX:XX:E6:1A
[   +6 ms] D/BluetoothGatt(20221): onSearchComplete() = address=XX:XX:XX:XX:E6:1A status=0
[        ] D/[FBP-Android](20221): [FBP] onServicesDiscovered:
[        ] D/[FBP-Android](20221): [FBP]   count: 3
[        ] D/[FBP-Android](20221): [FBP]   status: 0GATT_SUCCESS
[   +4 ms] D/[FBP-Android](20221): [FBP] onMethodCall: setNotifyValue
[        ] D/BluetoothGatt(20221): setCharacteristicNotification() - uuid:
00002a05-0000-1000-8000-00805f9b34fb enable: true
[  +43 ms] I/PowerHalMgrImpl(20221): hdl:727, pid:20221 
[   +2 ms] D/[FBP-Android](20221): [FBP] onDescriptorWrite:
[        ] D/[FBP-Android](20221): [FBP]   chr: 2a05
[        ] D/[FBP-Android](20221): [FBP]   desc: 2902
[        ] D/[FBP-Android](20221): [FBP]   status: GATT_SUCCESS (0)
[        ] D/BluetoothGatt(20221): onConnectionUpdated() - Device=XX:XX:XX:XX:E6:1A interval=39 latency=0   
timeout=500 status=0
[   +7 ms] D/[FBP-Android](20221): [FBP] onMethodCall: setNotifyValue
[        ] D/BluetoothGatt(20221): setCharacteristicNotification() - uuid:
beb5483e-36e1-4688-b7f5-ea07361b26a8 enable: true
[  +86 ms] D/[FBP-Android](20221): [FBP] onDescriptorWrite:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[        ] D/[FBP-Android](20221): [FBP]   desc: 2902
[        ] D/[FBP-Android](20221): [FBP]   status: GATT_SUCCESS (0)
[  +97 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +97 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +99 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +97 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[ +107 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +84 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +97 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +98 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +96 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +98 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +96 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +94 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[ +149 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +95 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[   +1 ms] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +91 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[ +101 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[   +1 ms] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +97 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +95 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +94 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +96 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[   +2 ms] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +95 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +97 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +95 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[ +147 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +93 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +98 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +92 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[ +102 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +96 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +92 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[ +101 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +94 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[ +100 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +93 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[   +1 ms] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +98 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[ +145 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[   +1 ms] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +92 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[   +1 ms] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +99 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +95 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +94 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[ +101 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +91 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[   +1 ms] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[ +100 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +92 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +97 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[ +101 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[   +1 ms] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +98 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[ +143 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +97 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +93 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +99 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +97 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +98 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +94 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +97 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[   +2 ms] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +95 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +94 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[   +1 ms] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +97 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[   +2 ms] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +97 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[ +147 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +92 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +98 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +94 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +98 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +97 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[ +100 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +93 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +99 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +94 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +97 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +97 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[ +144 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +97 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[ +142 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +48 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[ +101 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +93 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +97 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[   +1 ms] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +96 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[ +102 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +92 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +95 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +98 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[ +195 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +47 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +96 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +95 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +95 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +98 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +94 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[   +1 ms] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +96 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[   +1 ms] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[ +101 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +94 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +97 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[ +146 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +95 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +92 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[   +1 ms] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +99 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[   +1 ms] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[   +8 ms] I/MIUIInput(20221): [MotionEvent] ViewRootImpl windowName
'com.example.f16_balanza_electronica/com.example.f16_balanza_electronica.MainActivity', {
action=ACTION_DOWN, id[0]=0, pointerCount=1, eventTime=906050, downTime=906050, phoneEventTime=20:42:41.598 
} moveCount:0
[   +2 ms] D/VRI[MainActivity](20221): getMiuiFreeformStackInfo mTmpFrames.miuiFreeFormStackInfo: null      
[  +34 ms] I/MIUIInput(20221): [MotionEvent] ViewRootImpl windowName
'com.example.f16_balanza_electronica/com.example.f16_balanza_electronica.MainActivity', { action=ACTION_UP, 
id[0]=0, pointerCount=1, eventTime=906093, downTime=906050, phoneEventTime=20:42:41.641 } moveCount:0       
[  +28 ms] W/WindowOnBackDispatcher(20221): sendCancelIfRunning: isInProgress=false
callback=io.flutter.embedding.android.FlutterActivity$1@49ef79b
[  +25 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +89 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[ +101 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +94 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +96 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[ +101 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +92 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +95 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[ +146 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +93 ms] I/PowerHalMgrImpl(20221): hdl:731, pid:20221 
[   +2 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +98 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +96 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +96 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +97 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[   +1 ms] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +96 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +96 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[   +2 ms] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +95 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[ +100 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +94 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +95 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[ +149 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +94 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +96 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[   +1 ms] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +96 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +96 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +95 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +97 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +97 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +96 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +98 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +95 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +99 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[ +145 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +96 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +95 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +98 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +95 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +99 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +95 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +96 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +98 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +96 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +95 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[   +1 ms] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +99 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[ +147 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[  +94 ms] D/[FBP-Android](20221): [FBP] onCharacteristicChanged:
[        ] D/[FBP-Android](20221): [FBP]   chr: beb5483e-36e1-4688-b7f5-ea07361b26a8
[+5041 ms] D/BluetoothGatt(20221): onClientConnectionState() - status=8 clientIf=51 connected=false
device=XX:XX:XX:XX:E6:1A
[        ] D/BluetoothGatt(20221): unregisterApp() - mClientIf=51
[        ] D/[FBP-Android](20221): [FBP] onConnectionStateChange:disconnected
[        ] D/[FBP-Android](20221): [FBP]   status: LINK_SUPERVISION_TIMEOUT
[        ] D/BluetoothGatt(20221): close()
