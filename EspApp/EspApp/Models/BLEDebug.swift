/* ***********
 * Project   : Esp-App-Mobile-iOS - App to connect a Esp32 device by BLE
 * Programmer: Joao Lopes
 * Module    :BLEDebug - object model to debug BLE
 * Comments  :
 * Versions  :
 * -------   --------     -------------------------
 * 0.1.0     08/08/18     First version
 **/

import Foundation

class BLEDebug {
    
    var time: String = ""           // Time of debug
    var type: Character = " "       // Type of debug: C=connection/D-disconnection/F-Find/P-Problem/R-Receive/S-Send
    var message: String = ""        // Message
    var extra: String = ""          // Message extra (for example: type of message)
}
