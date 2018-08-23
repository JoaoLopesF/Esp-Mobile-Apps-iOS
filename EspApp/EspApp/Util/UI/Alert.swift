/* ***********
 * Project   : Esp-App-Mobile-iOS - App to connect a Esp32 device by BLE
 * Programmer: Joao Lopes
 * Module    : Util/UI - iOS UI utilities
 * Comments  : Alert
 * Versions  :
 * -------   --------     -------------------------
 * 0.1.0     08/08/18     First version
 **/
 
import UIKit

// Alert - show a alert message

class Alert {
    
    typealias callBack = () -> ()
    
    // Alert message

    class func alert(_ message:String, title:String = "Alert", viewController: UIViewController) {
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
        
        // Show a message
        
        viewController.present(alertController, animated: true, completion: nil)
    }

    // Alert message with callback

    class func alert(_ message:String, title:String = "Alerta",  viewController: UIViewController, callBackOK: @escaping callBack) {
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        
        // Button OK
        
        let OKAction = UIAlertAction(title: "OK", style: .default) { (action:UIAlertAction!) in
            
            // Execute a function (calback)
            
            callBackOK()
        }

        alertController.addAction(OKAction)
        
        // Show a message
        
        viewController.present(alertController, animated: true, completion: nil)
    }

    // Confirm message

    class func confirm(_ message:String, title:String = "Confirm", viewController: UIViewController, callBackOK: @escaping callBack) {
        
        let alertController = UIAlertController(title: title , message: message, preferredStyle: .alert)
        
        // Buttons
        
        let OKAction = UIAlertAction(title: "OK", style: .default) { (action:UIAlertAction!) in
            
            // Execute a function (calback)
            
            callBackOK()
        }
        
        alertController.addAction(OKAction)
        
        alertController.addAction(UIAlertAction(title: "Cancelar", style: .default, handler: nil))
        
        // Shows a message
        
        viewController.present(alertController, animated: true, completion:nil)
    }
}

////// End
