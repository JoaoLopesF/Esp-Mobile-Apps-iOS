/* ***********
 * Project   : Esp-App-Mobile-iOS - App to connect a Esp32 device by BLE
 * Programmer: Joao Lopes
 * Module    : Util - iOS utilities
 * Comments  : General utilities
 * Versions  :
 * -------   --------     -------------------------
 * 0.1.0     08/08/18     First version
 **/
 
import Foundation

// Util - General utilities

class Util {
    
    // Current milliseconds
    
    class func currentMilliseconds () -> Int64 {

        // Return current milliseconds
        
        return Int64(Date().timeIntervalSince1970 * 1000)

    }

    // Round a float
    
    class func round (_ value: Float, _ decimals: Int = 0) -> Float {
        
        // Round it
        
        if decimals > 0 {
            let divisor:Float = pow(10.0, Float(decimals))
            return (value * divisor).rounded() / divisor
        } else {
            return value.rounded()
        }
    }

    // Round a double

    class func round (_ value: Double, _ decimals: Int = 0) -> Double {
        
        // Round it
        
        if decimals > 0 {
            let divisor:Double = pow(10.0, Double(decimals))
            return (value * divisor).rounded() / divisor
        } else {
            return value.rounded()
        }
    }
    
    // Formats a time

    class func formatTime(time:TimeInterval, showHours:Bool = false) -> String {
    
        // Format a time for hh:mm:ss ou mm:ss
     
        let horas = Int(time) / 3600
        let minutos = Int(time) / 60 % 60
        let segundos = Int(time) % 60
        
        if horas > 0 || showHours  {
            return String(format:"%02i:%02i:%02i", horas, minutos, segundos)
        } else {
            return String(format:"%02i:%02i", minutos, segundos)
        }
    }
}

////// End
