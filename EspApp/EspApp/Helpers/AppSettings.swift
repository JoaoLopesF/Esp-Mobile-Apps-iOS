/* ***********
 * Project   : Esp-App-Mobile-iOS - App to connect a Esp32 device by BLE
 * Programmer: Joao Lopes
 * Module    : Settings - A helper class to settings
 * Comments  : Put here settings for app - can be imuttable (let) or muttable (var)
 * Versions  :
 * -------   --------     -------------------------
 * 0.1.0     08/08/18     First version
 **/

import Foundation
import UIKit

// AppSettings - Defaults values to app
// TODO: see it! please change device name and that you need

class AppSettings {
    
    // - Time & timeouts (in seconds)
    
    static let TIME_SEND_FEEDBACK : Int = 30      // Send feedbacks at this interval - put 0 to disable this
    
    static let TIME_MAX_INACTITIVY : Int = 300    // Maximum time of inactivity
    
    // - Colors
    
    static let COLOR_DARKBLUE: UIColor = UIColor(red: 29, green: 98, blue: 172)
    static let COLOR_DARKGRAY: UIColor = UIColor(red: 112, green: 128, blue: 144)
    static let COLOR_LIGHTGRAY: UIColor = UIColor(red: 211, green: 211, blue: 211)

    // - BLE
    
    static let BLE_DEVICE_NAME: String = "Esp32_Device"     // Device name (start with)
    static let BLE_TIMEOUT: Int = 2                         // Timeout for BLE (in seconds)

    // - Turn off - send a message to ESP32 device enter in deep sleep on exit of this app ?
    // (if the device not have standby function (deep sleep), it will restarted)
    
    static let TURN_OFF_DEVICE_ON_EXIT: Bool = true
    
    // - Terminal BLE
    
    // Enable terminal BLE ? (put false to disable it)

#if DEBUG // Only for in development (debug) - force it if you want it in release app

    static let TERMINAL_BLE: Bool = true

#else // Release

    static let TERMINAL_BLE: Bool = false

#endif
    
    // Order descend ? (last show first ?)
    
    static let TERMINAL_BLE_ORDER_DESC: Bool = true
    
    // - ESP32 Informations
    
    // Enable ESP32 Informations ? (put false to disable it)
    
#if DEBUG // Only for in development (debug) - force it if you want it in release app
    
    static let ESP32_INFORMATIONS: Bool = true
    
#else // Release
    
    static let ESP32_INFORMATIONS: Bool = false
    
#endif

}

