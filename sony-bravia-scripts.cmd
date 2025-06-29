@set scriptver=1
@setlocal DisableDelayedExpansion
@echo off

:: Set title
:set_title
title Sony Bravia Scripts %scriptver%

:: Cleanup screen
:cleanup_screen
cls

:: Set Color
:set_color
color 07
::mode 600,200

:: Main menu
:main_menu
echo:
echo: [107m[31m[ Sony Bravia Scripts %scriptver% ][0m[0m
echo:
echo: [31m+ ADB connection [0m
echo:  (A1) Connect ^| (A2) Disconnect ^| (A3) List devices
echo: [31m+ General [0m
echo:  (B1) Start shell ^| (B2) Logcat ^| (B3) List ADB commands
echo: [31m+ Equipment processes [0m
echo:  (C1) List processes ^| (C2) List connections ^| (C3) List services
echo:  (C4) Check specific service
echo: [31m+ Equipment information [0m
echo:  (D1) Serial number ^| (D2) Device state ^| (D3) Get model ^| (D4) Get features
echo:  (D5) Memory information ^| (D6) Free memory ^| (D7) Get processes (most cpu)
echo:  (D8) Get processes (most vss)
echo: [31m+ Power management [0m
echo:  (E1) Reboot ^| (E2) Shutdown
echo: [31m+ Device name [0m
echo:  (F1) Getdevice name ^| (F2) Get bluetooth name ^| (F3) Get both names
echo:  (F4) Set device name ^| (F5) Set bluetooth name ^| (F6) Set both names
echo: [31m+ Activities [0m
echo:  (G1) Start settings ^| (G2) Open home ^|(G3) Open URL ^| (G4) Clear recent apps
echo: [31m+ Screen density [0m
echo:  (H1) Current value ^| (H2) Set custom ^| (H3) Set to 260 ^| (H4) Reset
echo: [31m+ Screen resolution [0m
echo:  (H5) Current value ^| (H6) Set custom ^| (H7) Reset
echo: [31m+ Screen animations [0m
echo:  (H8) Current value ^| (H9) Set custom ^| (H10) Set to 0.2x ^| (H11) Reset
echo: [31m+ Applications [0m
echo:  (I1) List all ^| (I2) Clear all caches ^| (I3) Reset permissions
echo:  (I4) Disable apps (debloat) ^| (I5) Enable apps (reverse)
echo:  (I6) Install ^| (I7) Install multi package ^| (I8) Enable ^| (I9) Disable
echo:  (I10) Uninstall ^| (I11) Force stop ^| (I12) Restart
echo: [31m+ Default launcher (Home) [0m
echo:  (J1) Get current ^| (J2) Set custom?? ^| (J3) Enable ^| (J4) Disable
echo: [31m+ Proxy [0m
echo:  (K1) Get current ^| (K2) Set custom^| (K3) Reset
echo:  (K4) Get exclusions ^| (K5) Set exclusions ^| (K6) Reset exclusion list
echo: [31m+ Wi-Fi (Wireless networking) [0m
echo:  (L1) Current network ^| (L2) Current detailed network information
echo:  (L3) Connect to known network ^| (L4) Connect to new network
echo:  (L5) Enable Wi-Fi display ^| (L6) Disable Wi-Fi display
echo: [31m+ Miscellaneous [0m
echo:  (M1) Print custom text
echo: [31m+ Factory reset (danger zone) [0m
echo:  (N1) Factory reset ^| (N2) Factory reset (alternative method)
echo:
echo: (X) Exit script
echo:
set /p "menuOption=Enter an option (x): "
call :option_lowercase "%menuOption%" commandId
call :check_exit "%commandId%" isExit
if "%isExit%"=="1" goto :x
call :check_option "%commandId%" isOption
if "%isOption%"=="1" (
	call :selected_option %menuOption%
	call :command_proxy %commandId%
	goto :set_title
) else (
	call :selected_option_invalid %menuOption%
	goto :main_menu
)

:: Convert input lowercase
:option_lowercase
setlocal
set commandinput=%~1
for /f "delims=" %%A in ('powershell -command "[Console]::WriteLine('%commandinput%'.ToLower())"') do (
    set "commandId=%%A"
)
endlocal & set "%~2=%commandId%"
exit /b 0

:: Check if option is valid
:check_option
setlocal
set "optionToFind=%~1"
set "labelFound=0"
powershell -Command "if (Select-String -Path '%~f0' -Pattern ':%optionToFind%' -CaseSensitive) { exit 0 } else { exit 1 }"
if %errorlevel% equ 0 set "labelFound=1"
:foundLabel
endlocal & set "%~2=%labelFound%"
exit /b 0

:: Check if is exit option
:check_exit
setlocal
set "value=%~1"
set "isExitValue=0"
if "%~1"=="x" set "isExitValue=1"
endlocal & set "%~2=%isExitValue%"
exit /b 0

:: Selected option message
:selected_option
setlocal
echo:
echo:Selected option %~1.
echo:
timeout /t 1 /nobreak > NUL
pause> nul | set /p "=Press any key to continue with selected option."
echo:
cls
endlocal
exit /b 0

:: Selected option invalid
:selected_option_invalid
setlocal
echo:
echo:Selected option %~1 isn't valid. Please try again.
echo:
timeout /t 2 /nobreak > NUL
cls
endlocal
exit /b 0

:: Command Proxy
:command_proxy
setlocal
call :%~1
call :command_done
endlocal
exit /b 0

:: Command done
:command_done
setlocal
echo:
echo:Finished executing..
echo:
pause> nul | set /p "=Press any key to go back to main menu."
endlocal
exit /b 0

:: Command being executed
:command_execute
setlocal
echo:
echo:Executing "%~1", please wait...
echo:
%~1
echo:
endlocal
exit /b 0

:: Command title set
:command_title
setlocal
title %~1
echo:
echo:%~1
echo:
endlocal
exit /b 0

:: Section, connection

:: Connect ADB
:connect_adb
:a1
setlocal
call :command_title "Connect ADB"
set /p "hostport=Hostname/IP[:port]: "
set command="adb connect %hostport%"
call :command_execute %command%
endlocal
exit /b 0

:: Disconnect ADB
:disconnect_adb
:a2
setlocal
call :command_title "Disconnect ADB"
call :command_execute "adb disconnect"
endlocal
exit /b 0

:: List ADB devices
:list_adb
:a3
setlocal
call :command_title "List ADB devices"
call :command_execute "adb devices"
endlocal
exit /b 0

:: Section, general

:: Open adb shell
:start_shell
:b1
setlocal
call :command_title "Start shell"
call :command_execute "adb shell"
endlocal
exit /b 0

:: Logcat
:logcat
:b2
setlocal
call :command_title "Logcat"
call :command_execute "adb logcat"
endlocal
exit /b 0

:: List ADB commands
:list_adb_commands
:b3
setlocal
call :command_title "List ADB commands"
call :command_execute "adb help"
endlocal
exit /b 0

:: Section, equipment processes

:: List processes
:list_processes
:c1
setlocal
call :command_title "List processes"
set /p "params=Additional 'ps' parameters: "
set command="adb shell ps %params%"
call :command_execute %command%
endlocal
exit /b 0

:: List connections
:list_connections
:c2
setlocal
call :command_title "List connections"
set /p "params=Additional 'netstat' parameters: "
set command="adb shell netstat %params%"
call :command_execute %command%
endlocal
exit /b 0

:: List services
:list_services
:c3
setlocal
call :command_title "List services"
call :command_execute "adb shell service list"
endlocal
exit /b 0

:: Check specific service
:check_service
:c4
setlocal
call :command_title "Check specific service"
set /p "params=Service name: "
set command="adb shell service check %params%"
call :command_execute %command%
endlocal
exit /b 0

:: Section, device information

:: Get serial number
:get_serial
:d1
setlocal
call :command_title "Get serial number"
call :command_execute "adb get-serialno"
endlocal
exit /b 0

:: Get device state
:get_device_state
:d2
setlocal
call :command_title "Get device state"
call :command_execute "adb get-state"
endlocal
exit /b 0

:: Get device model
:get_device_model
:d3
setlocal
call :command_title "Get device model"
call :command_execute "adb shell getprop ro.opera.tvstore.model"
endlocal
exit /b 0

:: Get features list
:get_features_list
:d4
setlocal
call :command_title "Get features list"
call :command_execute "adb shell pm list features"
endlocal
exit /b 0

:: Section, memory information

:: Get memory info
:get_memory_info
:d5
setlocal
call :command_title "Get memory information"
call :command_execute "adb shell cat /proc/meminfo"
endlocal
exit /b 0

:: Get free memory
:get_free_memory
:d6
setlocal
call :command_title "Get free memory"
call :command_execute "adb shell free -h"
endlocal
exit /b 0

:: Section, processes information

:: Get processes using most cpu
:get_process_most_cpu
:d7
setlocal
call :command_title "Get processes (most cpu)"
call :command_execute "adb shell top -n 1 -s cpu"
endlocal
exit /b 0

:: Get processes using most vss
:get_process_most_vss
:d8
setlocal
call :command_title "Get processes (most vss)"
call :command_execute "adb shell top -n 1 -s vss"
endlocal
exit /b 0

:: Section, power management

:: Reboot
:reboot
:e1
setlocal
call :command_title "Reboot"
call :command_execute "adb reboot"
endlocal
exit /b 0

:: Shutdown
:shutdown
:e2
setlocal
call :command_title "Shutdown"
call :command_execute "adb shell reboot -p"
endlocal
exit /b 0

:: Section, device naming

:: Get device name
:get_device_name
:f1
setlocal
call :command_title "Get device name"
call :command_execute "adb shell settings get global device_name"
endlocal
exit /b 0

:: Get bluetooth name
:get_bluetooth_name
:f2
setlocal
call :command_title "Get bluetooth name"
call :command_execute "adb shell settings get global bluetooth_name"
endlocal
exit /b 0

:: Get both names
:get_both_names
:f3
setlocal
call :command_title "Get both names"
call :command_execute "adb shell settings get global device_name"
call :command_execute "adb shell settings get global bluetooth_name"
endlocal
exit /b 0

:: Set device name
:set_device_name
:f4
setlocal
call :command_title "Set device name"
set /p "params=Device name: "
set command="adb shell settings put global device_name %params%"
call :command_execute %command%
endlocal
exit /b 0

:: Get bluetooth name
:set_blutooth_name
:f5
setlocal
call :command_title "Set bluetooth name"
set /p "params=Bluetooth name: "
set command="adb shell settings put global bluetooth_name %params%"
call :command_execute %command%
endlocal
exit /b 0

:: Set both names
:set_both_names
:f6
setlocal
call :command_title "Set both names"
set /p "params=Both names: "
set command="adb shell settings put global device_name %params%"
call :command_execute %command%
set command="adb shell settings put global bluetooth_name %params%"
call :command_execute %command%
endlocal
exit /b 0

:: Section, activities

:: Start settings
:start_settings
:g1
setlocal
call :command_title "Start settings"
call :command_execute "adb shell am start -a android.settings.SETTINGS"
endlocal
exit /b 0

:: Go to home
:go_home
:g2
setlocal
call :command_title "Go to home"
call :command_execute "adb shell input keyevent 3"
endlocal
exit /b 0

:: Open URL
:open_url
:g3
setlocal
call :command_title "Open URL"
set /p "params=URL: "
set command="adb shell am start -a android.intent.action.VIEW -d %params%"
call :command_execute %command%
endlocal
exit /b 0

:: Clear recent apps
:clear_recent_apps
:g4
setlocal
call :command_title "Clear recent apps"
call :command_execute "adb shell \"input keyevent KEYCODE_APP_SWITCH && while (dumpsys activity recents | grep -q 'Recent #'); do input keyevent DEL; done\""
endlocal
exit /b 0

:: Section, screen density 

:: Get current density
:get_current_density
:h1
setlocal
call :command_title "Get current density"
call :command_execute "adb shell wm density"
endlocal
exit /b 0

:: Set custom density
:set_custom_density
:h2
setlocal
call :command_title "Set custom density"
set /p "params=New density: "
set command="adb shell wm density %params%"
call :command_execute %command%
endlocal
exit /b 0

:: Set density to 260
:set_density_260
:h3
setlocal
call :command_title "Set density to 260"
call :command_execute "adb shell wm density 260"
endlocal
exit /b 0

:: Reset density to default value
:reset_density_to_default
:h4
setlocal
call :command_title "Reset density to default"
call :command_execute "adb shell wm density reset"
endlocal
exit /b 0

:: Section, screen resolution

:: Get current resolution
:get_current_resolution
:h5
setlocal
call :command_title "Get current resolution"
call :command_execute "adb shell wm size"
endlocal
exit /b 0

:: Set custom resolution
:set_custom_resolution
:h6
setlocal
call :command_title "Set custom resolution"
set /p "params=New resolution: "
set command="adb shell wm size %params%"
call :command_execute %command%
endlocal
exit /b 0

:: Reset resolution to default
:reset_resolution_to_default
:h7
setlocal
call :command_title "Reset resolution to default"
call :command_execute "adb shell size reset"
endlocal
exit /b 0

:: Section, screen animations

:: Get animation speed
:get_animation_speed
:h8
setlocal

endlocal
exit /b 0

:: Set animation speed
:set_animation_speed
:h9
setlocal


endlocal
exit /b 0


:: Set fast animation speed to 0.2x
:set_animation_02
:h10
setlocal

endlocal
exit /b 0

:: Reset animation speed to 1x
:reset_animation_speed
:h11
setlocal


endlocal
exit /b 0

:: Section, applications

:: List all Applications
:get_apps_list
:i1
setlocal

endlocal
exit /b 0

:: Clear all app caches
:clear_all_app_caches
:i2
setlocal

endlocal
exit /b 0

:: Reset app permissions
:reset_app_permissions
:i3
setlocal

endlocal
exit /b 0

:: Disable apps (debloat)
:disable_apps
:i4
setlocal

endlocal
exit /b 0

:: Enable apps (reverse)
:enable_apps
:i5
setlocal

endlocal
exit /b 0

:: Install an app
:install_app
:i6
setlocal

endlocal
exit /b 0

:: Install a multi package app
:install_multi_package_app
:i7
setlocal

endlocal
exit /b 0

:: Enable app
:enable_app
:i8
setlocal

endlocal
exit /b 0

:: Disable app
:disable_app
:i9
setlocal

endlocal
exit /b 0

:: Uninstall app
:remove_app
:i10
setlocal

endlocal
exit /b 0

:: Force stop
:force_stop_app
:i11
setlocal

endlocal
exit /b 0

:: Restart app
:restart_app
:i12
setlocal

endlocal
exit /b 0

:: Section, Default launcher

:: Get current launcher
:get_current_launcher
:j1
setlocal

endlocal
exit /b 0

:: Set custom launcher
:set_custom_launcher
:j2
setlocal

endlocal
exit /b 0

:: Enable default launcher
:enable_default_launcher
:j3
setlocal

endlocal
exit /b 0

:: Disable default launcher
:disable_default_launcher
:j4
setlocal

endlocal
exit /b 0

:: Section, proxy

:: Get current proxy
:get_current_proxy
:k1
setlocal

endlocal
exit /b 0

:: Set custom proxy
:set_custom_proxy
:k2
setlocal

endlocal
exit /b 0

:: Reset proxy
:reset_proxy
:k3
setlocal

endlocal
exit /b 0

:: Get proxy exclusion list
:get_proxy_exclusion_list
:k4
setlocal

endlocal
exit /b 0

:: Set proxy exclusion list
:set_proxy_exclusion_list
:k5
setlocal

endlocal
exit /b 0

:: Reset proxy exclusion list
:reset_proxy_exclusion_list
:k6
setlocal

endlocal
exit /b 0

:: Section, Wi-Fi networking

:: Get current Wi-Fi network
:get_current_wifi
:l1
setlocal

endlocal
exit /b 0

:: Get current Wi-Fi network detailed information
:get_current_wifi_detailed
:l2
setlocal

endlocal
exit /b 0

:: Connect to known Wi-Fi network
:connect_known_wifi
:l3
setlocal

endlocal
exit /b 0

:: Connect to a new Wi-Fi network
:connect_new_wifi
:l4
setlocal

endlocal
exit /b 0

:: Enable Wi-Fi display
:enable_wifi_display
:l5
setlocal

endlocal
exit /b 0

:: Disable Wi-Fi display
:disable_wifi_display
:l6
setlocal

endlocal
exit /b 0

:: Miscellaneous

adb shell dumpsys window windows | grep -E ‘mCurrentFocus|mFocusedApp’

adb shell input keyevent KEYCODE_APP_SWITCH

adb shell input keyevent 20

adb shell input keyevent DEL



adb shell 'am broadcast -a org.example.app.sp.CLEAR --ez restart true'


adb shell pm reset-permissions -p your.app.package 

adb shell svc wifi enable

adb shell svc wifi disable

adb shell am broadcast -a android.net.wifi.STATE_CHANGE --es SSID "your_SSID_here"

adb shell am start -n com.android.settings/.wifi.WifiSettings
adb shell input keyevent 20
adb shell input keyevent 66
adb shell input text your_SSID_here
adb shell input keyevent 66
adb shell input text your_password_here
adb shell input keyevent 66




adb shell am force-stop com.cas.myapp

adb shell am start -a android.intent.action.VIEW -d URL	

adb shell getprop ro.build.version.release

adb shell ps

adb shell wm density 288

adb shell wm density


adb shell
recovery --wipe_data

adb shell am broadcast -a android.intent.action.MASTER_CLEAR


adb shell pm uninstall -k --user 0 com.google.android.inputmethod.japanese;

adb shell am start -W -c android.intent.category.HOME -a android.intent.action.MAIN


adb shell pm install -r --user 0 /system/app/WifiDirect_SM/WifiDirect_SM.apk







:: Quit script 
:quit_script
:x
cls
exit /b 0