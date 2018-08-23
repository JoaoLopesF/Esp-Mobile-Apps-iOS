/* ***********
 * Project   : Esp-App-Mobile-iOS - App to connect a Esp32 device by BLE
 * Programmer: Joao Lopes
 * Module    : Util/UI - iOS UI utilities
 * Comments  : Rounded label
 * Versions  :
 * -------   --------     -------------------------
 * 0.1.0     08/08/18     First version
 **/
 
import UIKit

// Round label

// Based in https://stackoverflow.com/questions/39041961/padding-in-uilabel-ios-swift
//      and https://stackoverflow.com/questions/27459746/adding-space-padding-to-a-uilabel

@IBDesignable class RoundLabel: UILabel {

    @IBInspectable var topInset: CGFloat = 5.0
    @IBInspectable var bottomInset: CGFloat = 5.0
    @IBInspectable var leftInset: CGFloat = 5.0
    @IBInspectable var rightInset: CGFloat = 5.0

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
    
    override func drawText(in rect: CGRect) {
        let insets = UIEdgeInsets(top: topInset, left: leftInset, bottom: bottomInset, right: rightInset)
        super.drawText(in: UIEdgeInsetsInsetRect(rect, insets))
    }
        
    override var intrinsicContentSize: CGSize {
        get {
            var contentSize = super.intrinsicContentSize
            contentSize.height += topInset + bottomInset + borderWidth * 2
            contentSize.width += leftInset + rightInset + borderWidth * 2
            return contentSize
        }
    }
}

/////// End
