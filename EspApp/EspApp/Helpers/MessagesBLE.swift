/* ***********
 * Project   : Esp-App-Mobile-iOS - App to connect a Esp32 device by BLE
 * Programmer: Joao Lopes
 * Module    : MessagesBLE - static class helper to messages
 * Comments  :
 * Versions  :
 * -------  --------    -------------------------
 * 0.1.0    08/08/18    First version
 * 0.2.0    20/08/18    Option to disable logging br BLE (used during repeated sends)
 **/

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
 * 71 Logging
 * 80 Feedback
 * 98 Restart (reset the ESP32)
 * 99 Standby (enter in deep sleep)
 *
 * // TODO: see it! please remove that you not use and keep it updated
 **/


import Foundation

public class MessagesBLE {
    
    // Messages code
    
    public static let CODE_OK:Int =          0
    public static let CODE_INITIAL:Int =     1
    public static let CODE_ENERGY:Int =     10
    public static let CODE_INFO:Int =       11
    public static let CODE_ECHO:Int =       70
    public static let CODE_LOGGING:Int =    71
    public static let CODE_FEEDBACK:Int =   80
    public static let CODE_RESTART:Int =    98
    public static let CODE_STANDBY:Int =    99
    
    // Messages start text (with code)
    
    public static let MESSAGE_OK:String =       "\(String(format: "%02d",CODE_OK)):"
    public static let MESSAGE_INITIAL:String =  "\(String(format: "%02d",CODE_INITIAL)):"
    public static let MESSAGE_ENERGY:String =   "\(String(format: "%02d",CODE_ENERGY)):"
    public static let MESSAGE_INFO:String =     "\(String(format: "%02d",CODE_INFO)):"
    public static let MESSAGE_ECHO:String =     "\(String(format: "%02d",CODE_ECHO)):"
    public static let MESSAGE_LOGGING:String =  "\(String(format: "%02d",CODE_LOGGING)):"
    public static let MESSAGE_FEEDBACK:String = "\(String(format: "%02d",CODE_FEEDBACK)):"
    public static let MESSAGE_RESTART:String =  "\(String(format: "%02d",CODE_RESTART)):"
    public static let MESSAGE_STANDBY:String =  "\(String(format: "%02d",CODE_STANDBY)):"
    
    public static let MESSAGE_ERROR:String =    "-1:"
    
}

///// End
