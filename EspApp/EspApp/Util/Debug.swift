/* ***********
 * Project   : Esp-Idf-App-Mobile-iOS - App to connect a Esp32 device by BLE
 * Programmer: Joao Lopes
 * Module    : Util - iOS UI utilities
 * Comments  : Routines For improve debug messages
 * Versions  :
 * -------   --------     -------------------------
 * 0.1.0     08/08/18     First version
 **/
 
import Foundation

// Debug levels

enum debugLevel: Int8 {
    
    case verbose = 0
    case debug = 1
    case warning = 2
    case error = 3
    case any = 9
    
}

#if DEBUG // Debug environment
    
    // Current debug level setted
    
    private var debugLevelCurrent:debugLevel = debugLevel.debug
    
    // Set the actual level
    
    @inline(__always) func debugSetLevel(_ level:debugLevel) {
        
        if level == .any {
            debugE("Current level can not by Any!")
            return
        }
        
        debugLevelCurrent = level
        debugA("debug: level setted to \(debugShowLevel(level))", file: #file,  function: #function)
    }

    // For show debug level
    
    @inline(__always) func debugShowLevel (_ level: debugLevel) -> String {
        
        switch level {
        case .verbose:
            return "📘V-Verbose"
        case .debug:
            return "📗D-Debug"
        case .warning:
           return "📒W-Warning"
        case .error:
            return "📕E-Error"
        case .any:
            return "📙A-Any"
        }
    }
    
    // Verbose
    
@inline(__always) func debugV(_ items: Any..., file: String = #file, function: String = #function) {
        if debugLevelCurrent.rawValue <= debugLevel.verbose.rawValue {
            debug(nivel: debugLevel.verbose, items: items, file: file, function: function)
        }
    }
    
    // Debug
    
@inline(__always) func debugD(_ items: Any..., file: String = #file, function: String = #function) {
        if debugLevelCurrent.rawValue <= debugLevel.debug.rawValue {
            debug(nivel: debugLevel.debug, items: items, file: file, function: function)
        }
    }
    
    // Warning
    
@inline(__always) func debugW(_ items: Any..., file: String = #file, function: String = #function) {
        if debugLevelCurrent.rawValue <= debugLevel.warning.rawValue {
            debug(nivel: debugLevel.warning, items: items, file: file, function: function)
        }
    }
    
    // Error
    
@inline(__always) func debugE(_ items: Any..., file: String = #file, function: String = #function) {
        if debugLevelCurrent.rawValue <= debugLevel.error.rawValue {
            debug(nivel: debugLevel.error, items: items, file: file, function: function)
        }
    }

    // Any - always show
    
@inline(__always) func debugA(_ items: Any..., file: String = #file, function: String = #function) {
        debug(nivel: debugLevel.any, items: items, file: file, function: function)
    }

    // Show debug
    
@inline(__always) fileprivate func debug(nivel:debugLevel, items:[Any], file:String, function: String) {
        
        // Print info
        
        let url = NSURL(fileURLWithPath: file)
        let aux: String = url.lastPathComponent ?? file
        
        var index = aux.index(of: ".") ?? aux.endIndex
        let file = aux[..<index]
        
        index = function.index(of: "(") ?? function.endIndex
        let function = function[..<index]
        
        var info:String = ""
        
        let formatter = DateFormatter()
//        formatter.dateFormat = "HH:mm:ss.SSS " // TODO: 12h
        formatter.dateFormat = "ss.SSS " // TODO: 12h

        info.append(formatter.string(from: Date()))
        
        switch nivel { // Symbol
        case .verbose:
            info.append("📘V")
        case .debug:
            info.append("📗D")
        case .warning:
            info.append("📒W")
        case .error:
            info.append("📕E")
        case .any:
            info.append("📙A")
        }
        
        info.append(" \(file).\(function): ")
        
//        print (debugEscapedStr(info), separator: "", terminator:"")
        print (info, separator: "", terminator:"")
        
        // Print items
        
        //    print (items, separator: " ") // Not working
        
        for item in items {
            print("\(item) ", separator:" ", terminator:"")
        }
        print("")
        
    }
    
    // Expand chars of string
    
    @inline(__always) func debugExpandStr(_ string:String) -> String {
        
        var ret:String = ""
        
        for char in string {
            
            switch char {
            case "\n":
                ret.append("\\n")
            case "\r":
                ret.append("\\r")
            case "\t":
                ret.append("\\t")
            default:
                if (char >= " ") {
                    ret.append(char)
                } else {
                    ret.append("?")
                }
            }
        }
        
        return ret
    }
    
    // Show Escaped (more complete than debugExpandStr)
    
    @inline(__always) func debugEscapedStr(_ string:String) -> String {
        
        var ret:String = ""
        
        for char in string {
            if let u = UnicodeScalar(String(char)) {
                let display = u.escaped(asASCII: true)
                ret.append(display)
            } else {
                ret.append("?")
            }
        }
        return ret
    }
    
    // Debug in XCode ?
    
    @inline(__always) func debugInXCode() -> Bool {
        
        let info = kinfo_proc()
        return (info.kp_proc.p_flag & P_TRACED) != 0
    }
    
#else // Release
    
    // Do nothing
    
    @inline(__always) func debugSetLevel(level:debugLevel)  {
    }
    @inline(__always) func debugShowLevel (_ level: debugLevel) -> String {
    }
    
    @inline(__always) func debugV(_ items: Any ..., file: String = #file, function: String = #function) {
    }
    @inline(__always) func debugD(_ items: Any ..., file: String = #file, function: String = #function) {
    }
    @inline(__always) func debugW(_ items: Any ..., file: String = #file, function: String = #function) {
    }
    @inline(__always) func debugE(_ items: Any ..., file: String = #file, function: String = #function) {
    }
    
    @inline(__always) func debugA(_ items: Any..., file: String = #file, function: String = #function) {
    }
    
    @inline(__always) func debugExpandStr(_ string:String) -> String {
    }
    @inline(__always) func debugEscapedStr(_ string:String) -> String {
    }

    @inline(__always) func debugInXCode() -> Bool {
        return false
    }

#endif //DEBUG


/////// End
