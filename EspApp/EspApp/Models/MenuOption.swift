/* ***********
 * Project   : Esp-App-Mobile-iOS - App to connect a Esp32 device by BLE
 * Programmer: Joao Lopes
 * Module    : MenuOption - object model to menu options
 * Comments  :
 * Versions  :
 * -------   --------     -------------------------
 * 0.1.0     08/08/18     First version
 
 **/
import Foundation

struct MenuOption {
    
    var code: String = ""           // Code
    var name: String = ""           // Name
    var description: String = ""    // Description
    
    var image: String = ""          // Image name
    
    var enabled: Bool = false       // Enabled ?
}
