# Esp-Idf-Mobile-Apps-iOS
Esp-Idf-Mobile-Apps is a set of examples apps to start making Esp32 BLE devices connected to mobile applications (Android and iOS)

I have prepared a set of applications, to serve as a basis,
for those who need to make ble connected mobile projects with the ESP32.

* Part I    - __Esp-IDF app__ - Esp32 firmware example  - https://github.com/JoaoLopesF/Esp-Idf-Mobile-Apps-Esp32
* Part II   - __iOS app__ - mobile app example          - this github repo
* Part III  - __Android app__ - mobile app example      - soon, prevision -> 30-Aug-2018

It is a advanced, but simple (ready to go), fully functional set of applications.

![Esp-Idf-Mobile-App](https://i.imgur.com/MuR7gna.png)

## Contents

 - [Esp32](#esp32)
 - [BLE](#ble)
 - [Part II - iOS app](#part-ii---ios-app)
 - [Features](#features)
 - [BLE messages](#blemessages)
 - [Structure](#structure)
 - [Prerequisites](#rrerequisites)
 - [Install](#install)
 - [Feedback and contribution](#feedback-and-contribution)
 - [To-do](#to-do)
 - [Researchs used ](#researchs-used)
 - [Release History](#release-history)
 - [Screenshots](#screenshots)

## Esp32

The Esp32 is a powerful board with 2 cores, 520K RAM, 34 GPIO, 3 UART,
Wifi and Bluetooth Dual Mode. And all this at an excellent price.

Esp-IDF is very good SDK, to developer Esp32 projects.
With Free-RTOS (with multicore), WiFi, BLE, plenty of GPIOs, peripherals support, etc.

## BLE

With Esp32, we can develop, in addition to WIFI applications (IoT, etc.),
devices with Bluetooth connection for mobile applications.

BLE is a Bluetooth Low Energy:

    BLE is suitable for connection to Android and iOS.
    Nearly 100% of devices run Android >= 4.0.3, and most of them should have BLE.
    For iOS, we have support for BLE, and for normal Bluetooth, only some modules with Mfi certification (made for i ...)

    So BLE is the most viable alternative for Esp32 to communicate with mobile devices.

# Part II - iOS app 

    This mobile app for iOS >= 10.3
    All code is written in Swift
    No third part libraries is used

## Features

This app example to iOS, have advanced features like:

    - Support for large BLE messages 
      (if necessary, automatically send / receive in small pieces)

    - Modular and advanced programming
    - Based in mature code (I have used in Bluetooth devices and mobile apps, since years ago)

    - Stand-by support for ESP32 deep-sleep
      (by a button, or by inativity time, no touchpad yet)

    - Support for battery powered devices
      (this mobile app gets status of this)

    - Fast connection
      If not connected yet, do scan and connects a device with strong signal (more close)
      Else, do scan and if located the last device, connect with it (no wait until end of scan)
      No scanned devices list, I no see it in comercial devices

    - Periodic feedback sends, to know if device is ok and to avoid it to enter in standby by inactivity
    
    - General utilities to use
    - Logging macros, to automatically put the function name and level (with images)
    
    - Runs in ioS simulator of XCode, without BLE stuff, due it not have Bluetooth.
      Usefull to help design UI and test in another devices models and screen sizes

## BLE messages

The communication between this App and ESP32 device is made by BLE messages.

This app act as BLE GATT client) and the ESP32 device act as BLE GATT server. 

For this project and mobile app, have only text delimited based messages.
First field of these messages is a code, that indicate the content or action of each message. 

Example:

    /**
    * BLE text messages of this app
    * -----------------------------
    * Format: nn:payload
    * (where nn is code of message and payload is content, can be delimited too)
    * -----------------------------
    * Messages codes:
    * 01 Initial
    * 10 Energy status(External or Battery?)
    * 11 Informations about ESP32 device
    * 70 Echo debug
    * 80 Feedback
    * 98 Restart the ESP32
    * 99 Standby (enter in deep sleep)
    **/

If your project needs to send much data,
I recommend changing to send binary messages.

This project is for a few messages per second (less than 20).
It is more a mobile app limit (more to Android).

If your project need send more, 
I suggest you use a FreeRTOS task to agregate data after send.
(this app supports large messages)

## Structure

Modules of ios example aplication

 - EspApp                   - The iOS application
    
    - Assets.xcassets           - Images

    - Base.lproj                - For internationalization (no yet used)

    - Controllers               - View controllers
                                    Note: have a template here

    - Helpers                   - Helpers (utilities class as AppSettings and MessagesBLE)

    - Models                    - Object models

    - Util                      - Utilities
        - UI                    - For iOS UI
        - BLE                   - BLE comunication
        - Debug                 - Debug with levels and images
        - DownloadManager       - To download files (not used in this app)
        - Extensions            - Good extensions to Swift language
        - Fields                - Used to extract fields in text delimited (as BLE messages)
        - File                  - To files (not used in this app)
        - Util                  - General utilities routines
        - WiFi                  - To WiFi (as get SSID)

    - Views                     - UI of this app
                                    Note: have a template in main storyboard
    
Generally you do not need to change anything in the util directory. 
If you need, please add a Issue or a commit, to put it in repo, to help a upgrades in util

But yes in the other files, to facilitate, I put a comment "// TODO: see it" in the main points, that needs to see. so to start just find it in your IDE.

## EspApp

This app consists of following screens:

    - Connection (Connecting): when connecting a ESP32 device by BLE
    - MainMenu (EspAPP): Main menu of app
    - Informations: Show informations about ESP32 device connected and
      status of battery (if enabled)
    - Terminal BLE: See or send messages BLE
    - Settings: settings of app (disabled by default)
    - Disconnected: when a disconnect has been detected

For it each on have a viewcontroller

And for main processing and BLE stuff have a MainControlller

Have a templates to make a new ones (for example: for the settings)

See screenshots below

## Prerequisites 

    - Esp-Idf-Mobile-Apps-Esp32 EspApp flashed in ESP32 device
    - XCode   
    - iOS device or simulator (only to see, not have Bluetooth)

## Install

To install, just download or use the "Github desktop new" app to do it (is good to updatings).

After open this in XCODE

Please find all __"TODO: see it"__ occorences in all files, it needs your attention

And enjoy :-)

## Feedback and contribution

If you have a problem, bug, sugesttions to report,
 please do it in GitHub Issues.

Feedbacks and contributions is allways well come

Please give a star to this repo, if you like this.

## To-do

* See some Xcode warnings
* Documentation (doxygen)
* Tutorial (guide)
* To try auto reconnection in case of device disconnected
* Revision of translate to english (typing errors or mistranslated)

## Researchs used 

* Nordic github samples repos (very good) - https://github.com/NordicSemiconductor
* Adafruit (based on Nordic codes) - https://github.com/adafruit/Bluefruit_LE_Connect 
* StackOverFlow for iOS doubts or problems - https://stackoverflow.com

## Release History

* 0.1.0
    * First version

## Screenshots 

* Connection (Connecting): 

    - When connecting a ESP32 device by BLE

    ![Connection](https://i.imgur.com/HCVpink.png)

* MainMenu (EspAPP): 

    - Main menu of app

    ![MainMenu](https://i.imgur.com/6dNc8CL.png)

    - If device not enabled battery support 
    - (see bottom rigth that battery status is not showed)

    ![MainMenuNoBat](https://i.imgur.com/pzJ35MJ.png)

* Informations: 

    - Show informations about ESP32 device connected 
    - and status of battery (if enabled)

    ![Informations](https://i.imgur.com/EqdgJmg.png)

* Terminal BLE: 

    - See or send messages BLE
    - Have a repeat funcion too (to send/receive repeated echo messages)

    ![Terminal](https://i.imgur.com/SC3t9FW.png)

        Notes:  
            - See large info message receive with size of 207 bytes
            - See messages ends with [], the app translate codes to extra debug

* Disconnected: 

    - When a disconnect has benn detected

    ![Disconnected](https://i.imgur.com/ogthyAg.png)

* Release 

    - When the app is a release version (to mobile stores)

    ![Release](https://i.imgur.com/Lr9gKKU.png)

        Note: The Informations and Terminal BLE,
        as only enabled if in development (DEBUG)
        It is optimized to not process if a release app (no overheads)

        Tip: Not need delete it in your app, to have this tools while developing
