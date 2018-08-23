/* ***********
 * Project   : Esp-App-Mobile-iOS - App to connect a Esp32 device by BLE
 * Programmer: Joao Lopes
 * Module    : Util - iOS utilities
 * Comments  : WiFi utilities
 * Versions  :
 * -------   --------     -------------------------
 * 0.1.0     08/08/18     First version
 **/
 
import Foundation
import SystemConfiguration.CaptiveNetwork

// UtilWiFi - WiFi utilities

class UtilWiFi {
    
    // SSID of WiFi connected
    
    class func getSSID() -> String {
        
        var currentSSID = ""
        if let interfaces:CFArray = CNCopySupportedInterfaces() {
            for i in 0..<CFArrayGetCount(interfaces){
                let interfaceName: UnsafeRawPointer = CFArrayGetValueAtIndex(interfaces, i)
                let rec = unsafeBitCast(interfaceName, to: AnyObject.self)
                let unsafeInterfaceData = CNCopyCurrentNetworkInfo("\(rec)" as CFString)
                if unsafeInterfaceData != nil {
                    let interfaceData = unsafeInterfaceData! as Dictionary!
                    for dictData in interfaceData! {
                        if dictData.key as! String == "SSID" {
                            currentSSID = dictData.value as! String
                        }
                    }
                }
            }
        }
        
        return currentSSID

    }
    
}

////// End
