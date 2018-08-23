/* ***********
 * Project   : Esp-App-Mobile-iOS - App to connect a Esp32 device by BLE
 * Programmer: Joao Lopes
 * Module    : Util - iOS utilities
 * Comments  : Swift extensions - starts with ext to indicates a extension
 * Versions  :
 * -------   --------     -------------------------
 * 0.1.0     08/08/18     First version
 **/

import Foundation

// For string 

extension String {
    
    ////// Strings
    
    // Substring

    func extSubstring(_ posStart:Int, _ posEnd:Int = -1) -> String {
        
        // Substring - without ranges :)
        
        var pos:Int = 0
        var ret:String = ""
        
        for char in self {
            
            if pos >= posStart && (posEnd == -1 || pos <= posEnd) {
                ret.append(char)
            }
            pos+=1
        }
        return ret
        
    }
    
    // Index of

    func extIndexOf (_ char:Character) -> Int {
        
        // Search a character in string
        
        var pos:Int = 0
        
        for _char in self {
            
            if _char == char {
                
                // Finded
                
                return pos
            }
            pos+=1
        }
        
        // Not find
        
        return -1
    }
}

// For Date

extension Date {

    // Local date

    func extLocalString(dateStyle: DateFormatter.Style = .medium, timeStyle: DateFormatter.Style = .medium) -> String {
        return DateFormatter.localizedString(from: self, dateStyle: dateStyle, timeStyle: timeStyle)
    }
}

////// End
