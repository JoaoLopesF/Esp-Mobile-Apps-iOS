/* ***********
 * Project   : Esp-App-Mobile-iOS - App to connect a Esp32 device by BLE
 * Programmer: Joao Lopes
 * Module    : Util - iOS utilities
 * Comments  : File - utilities to files
 * Versions  :
 * -------   --------     -------------------------
 * 0.1.0     08/08/18     First version
 **/
 
import Foundation

class File {
    
    // Document directory
    
    class func documentDirectory() -> URL {
        
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first as URL!
    }
    
    // File exists ?
    
    class func exists (path: String) -> Bool {
        
        return FileManager.default.fileExists(atPath: path)
        
    }

    class func exists (url: URL?) -> Bool {

        if (url != nil) {
            return exists(path: url!.path)
        } else {
            debugE("exists: nil")
            return false
        }
        
    }
    
    // Is a file ?
    
    class func isFile(path: String) -> Bool {
        
        return exists(path: path) // TODO: verify is is a file or directory
    }

    // Is a directory?
    
    class func isDirectory(path: String) -> Bool {
        
        return exists(path: path) // TODO: verify is is a file or directory
    }

    // Move file
    
    class func move (from: String, to: String) -> Bool {
        
        do {
            try FileManager.default.moveItem(atPath: from, toPath: to)
            return true
        } catch let error {
            debugE("move: Error \(error.localizedDescription)")
            return false
        }
    }
    
    class func move (from: URL?, to: URL?) -> Bool {
        if (from != nil && to != nil) {
            return move(from: from!.path, to: to!.path)
        } else {
            debugE("move: nil")
            return false
        }
    }
    
    // copy file
    
    class func copy (from: String, to: String) -> Bool {
        
        do {
            try FileManager.default.copyItem(atPath: from, toPath: to)
            return true
        } catch let error {
            debugE("copy: Error \(error.localizedDescription)")
            return false
        }
    }
    
    class func copy (from: URL?, to: URL?) -> Bool {
        if (from != nil && to != nil) {
            return copy(from: from!.path, to: to!.path)
        } else {
            debugE("copy: nil")
            return false
        }
    }
    
    // Delete file
    
    class func delete (path: String) -> Bool {
        
        do {
            try FileManager.default.removeItem(atPath: path)
            return true
        } catch let error {
            debugE("delete: Error \(error.localizedDescription)")
            return false
        }
    }
    
    class func delete (url: URL?) -> Bool {
        if (url != nil) {
            return delete(path: url!.path)
        } else {
            debugE("delete: nil")
            return false
        }
    }
    
    // Create directory
    
    class func createDirectory (path: String, subDirs: Bool = false) -> Bool {
        
        do {
            try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: subDirs, attributes: nil)
            return true
        } catch let error as NSError {
            debugE("createDirectory: Error \(error.localizedDescription)")
            return false
        }
    }
    
    class func createDirectory (url: URL?, subDirs: Bool = false) -> Bool {
        if (url != nil) {
            return createDirectory(path: url!.path, subDirs: subDirs)
        } else {
            debugE("createDirectory: nil")
            return false
        }
    }
    
    // Size of file
   
    class func size (path: String) -> Int{

        // Based em: https://stackoverflow.com/questions/43797281/swift-get-file-size-from-url
        
//        let file: String = "file://" + path
        
        if let url: URL = URL(fileURLWithPath: path) {
        
            return size(url: url)
        
        } else {
            
            return -1
        }
    }
    
    class func size (url: URL) -> Int {
        
        do {
            let resources = try url.resourceValues(forKeys:[.fileSizeKey])
            return resources.fileSize!
            
        }
        catch{
            debugE("size: Error: \(error)")
            return -1
        }
    }
    
    // Returns a directory from a file path
    
    class func directoryPath (path: String) -> String {
        
        let ret : NSString = path as NSString
        return ret.deletingLastPathComponent as String
        
    }
    
    // Read content of file
    
    class func readFile(_ path: String) -> String {
        
        // Read file
        
        do {
            
            let data = try NSString(contentsOfFile: path,
                                    encoding: String.Encoding.ascii.rawValue)
            return data as String
        } catch {
            debugE("path:", path, "error:", error)
            return ""
        }

    }
    
    // Disk free space
    
    class func getMbFree() -> Int? {

        // Based on  https://stackoverflow.com/questions/26198073/query-available-ios-disk-space-with-swift

        let documentDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).last!
        guard
            let systemAttributes = try? FileManager.default.attributesOfFileSystem(forPath: documentDirectory),
            let freeSize = systemAttributes[.systemFreeSize] as? NSNumber
            else {
                // something failed
                return nil
        }
        
        // Calcule in megabytes
        
        let aux: Double = Double(freeSize.int64Value / 1048576)
        let ret: Int = Int(aux.rounded())
        
        return ret
    }

}

/////// End
