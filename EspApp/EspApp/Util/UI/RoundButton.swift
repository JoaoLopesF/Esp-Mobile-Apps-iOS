/* ***********
 * Project   : Esp-App-Mobile-iOS - App to connect a Esp32 device by BLE
 * Programmer: Joao Lopes
 * Module    : Util/UI - iOS UI utilities
 * Comments  : Rounded button
 * Versions  :
 * -------   --------     -------------------------
 * 0.1.0     08/08/18     First version
 **/

import UIKit

// Round button 

@IBDesignable
class RoundButton: UIButton {
    
    @IBInspectable var cornerRadius: CGFloat = 0 {
        didSet{
            self.layer.cornerRadius = cornerRadius
        }
    }
    
    @IBInspectable var borderWidth: CGFloat = 0 {
        didSet{
            self.layer.borderWidth = borderWidth
        }
    }


    @IBInspectable var borderColor: UIColor = UIColor.clear {
        didSet{
            self.layer.borderColor = borderColor.cgColor
        }
    }

    @IBInspectable var edgeInsetsAll: CGFloat = 0 {
        didSet{
            self.contentEdgeInsets = UIEdgeInsets(top: edgeInsetsAll, left: edgeInsetsAll, bottom: edgeInsetsAll, right: edgeInsetsAll)
        }
    }

}

///// End