/* ***********
 * Project   : Esp-App-Mobile-iOS - App to connect a Esp32 device by BLE
 * Programmer: Joao Lopes
 * Module    : Util - iOS utilities
 * Comments  : For field delimited text
 * Versions  :
 * -------   --------     -------------------------
 * 0.1.0     08/08/18     First version
 **/
 
import Foundation

// Fields - For field delimited text

class Fields  {
    
    // Variables

    var fields: [String] = []
    var lastField: Int = 0
    
    // Init

    init (_ content: String, delim:String = ":") {
        
        // Split a string in a array

        fields = content.components(separatedBy: delim)
        
        lastField = 0
        
        // Debug
        
        var show: String = "fields: "
        var pos: Int = 1
        for field in fields {
            show.append("\(pos)=\(debugEscapedStr(field)) ")
            pos += 1
        }
        debugV(show)
    }
    
    // Get a field - string

    func getField (_ field:Int) -> String {
        
        var ret: String = ""
        
        if field >= 1 && field <= fields.count {
            ret = fields[field-1]
        }
        return ret
        
    }
    
    // Get a field - integer

    func getFieldInt (_ field:Int) -> Int {
        
        var ret: Int = 0
        
        let aux:String = getField(field)
        
        if aux != "" {
            ret = Int(aux)!
        }
        
        return ret
    }
    
    // Get a total of fields processed

    func getTotalFields() -> Int {
    
        return fields.count
    }
    
    // Get a next field

    func getNextField() -> String {
        
        lastField += 1
        
        return getField(lastField)
    }

    // Get a next field - int

    func getNextFieldInt() -> Int {
        
        lastField += 1
        
        return getFieldInt(lastField)
    }

}


///// End

// Discontinued codes:
//
//        // Manual split
//
//        var field: String = ""
//
//        for char in content {
//
//            if char != delim {
//
//                field.append(char)
//
//            } else { // End of this field
//
//                fields.append(field)
//                field = ""
//            }
//        }
//
