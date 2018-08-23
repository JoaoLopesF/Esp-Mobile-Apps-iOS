/* ***********
 * Project   : Esp-App-Mobile-iOS - App to connect a Esp32 device by BLE
 * Programmer: Joao Lopes
 * Module    : Util/UI - iOS UI utilities
 * Comments  : UI extensions - all routines begin with ext to identify that is a extension
 * Versions  :
 * -------   --------     -------------------------
 * 0.1.0     08/08/18     First version
 **/
 
import Foundation
import UIKit

/////// For colors

extension UIColor {

    // Based em https://stackoverflow.com/questions/24263007/how-to-use-hex-colour-values-in-swift-ios
    
    convenience init(red: Int, green: Int, blue: Int) {
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")
        
        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
    }
    
    convenience init(rgb: Int) {
        self.init(
            red: (rgb >> 16) & 0xFF,
            green: (rgb >> 8) & 0xFF,
            blue: rgb & 0xFF
        )
    }
}

////// For views

extension UIView {

    // Add a backgroud gradient

    func extAddGradientWithColor(colorTop: UIColor, colorButton: UIColor){

        // With bugs, Better use GradientView !!!! //TODO: change all
        if self.backgroundColor != UIColor.clear { // Clear it before
            self.backgroundColor = UIColor.clear
        }
        let gradient = CAGradientLayer() // Add layer
        gradient.frame = self.bounds
        gradient.colors = [colorTop.cgColor, colorButton.cgColor]
        self.layer.insertSublayer(gradient, at: 0)
    }

    // Add a shadow // TODO: settings

    func extAddShadow() {
                
        self.layer.cornerRadius = 10
        self.clipsToBounds = false
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowOpacity = 1
        self.layer.shadowOffset = CGSize.zero
        self.layer.shadowRadius = 10
        self.layer.shadowPath = UIBezierPath(roundedRect: self.bounds, cornerRadius: 10).cgPath
    }

    // Return a parent view controller

    var extParentViewController: UIViewController? {

        var parentResponder: UIResponder? = self
        while parentResponder != nil {
            parentResponder = parentResponder!.next
            if let viewController = parentResponder as? UIViewController {
                return viewController
            }
        }
        return nil
    }
}

////// For device (iphone, ipad, etc.)

extension UIDevice {

    // Return the model name of device 

    public var extModelName: String {
    
        // Based em https://stackoverflow.com/questions/44558642/how-to-detect-ipod-and-iphone-device-with-swift-3

        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }

        switch identifier {
        case "iPod5,1":                                 return "iPod Touch 5"
        case "iPod7,1":                                 return "iPod Touch 6"
        case "iPhone3,1", "iPhone3,2", "iPhone3,3":     return "iPhone 4"
        case "iPhone4,1":                               return "iPhone 4s"
        case "iPhone5,1", "iPhone5,2":                  return "iPhone 5"
        case "iPhone5,3", "iPhone5,4":                  return "iPhone 5c"
        case "iPhone6,1", "iPhone6,2":                  return "iPhone 5s"
        case "iPhone7,2":                               return "iPhone 6"
        case "iPhone7,1":                               return "iPhone 6 Plus"
        case "iPhone8,1":                               return "iPhone 6s"
        case "iPhone9,1", "iPhone9,3":                  return "iPhone 7"
        case "iPhone9,2", "iPhone9,4":                  return "iPhone 7 Plus"
        case "iPad2,1", "iPad2,2", "iPad2,3", "iPad2,4":return "iPad 2"
        case "iPad3,1", "iPad3,2", "iPad3,3":           return "iPad 3"
        case "iPad3,4", "iPad3,5", "iPad3,6":           return "iPad 4"
        case "iPad4,1", "iPad4,2", "iPad4,3":           return "iPad Air"
        case "iPad5,3", "iPad5,4":                      return "iPad Air 2"
        case "iPad2,5", "iPad2,6", "iPad2,7":           return "iPad Mini"
        case "iPad4,4", "iPad4,5", "iPad4,6":           return "iPad Mini 2"
        case "iPad4,7", "iPad4,8", "iPad4,9":           return "iPad Mini 3"
        case "iPad5,1", "iPad5,2":                      return "iPad Mini 4"
        case "iPad6,7", "iPad6,8":                      return "iPad Pro"
        case "AppleTV5,3":                              return "Apple TV"
        case "i386", "x86_64":                          return "Simulator"
        default:                                        return identifier
        }
    }
        
    // Small screen device ?

    public var extIsSmallScreen: Bool {
    
        get {
            let screenSize: CGRect = UIScreen.main.bounds
            
            return (screenSize.width <= 640)
            
        }
    }

    // Large screen device ?

    public var extIsLargeScreen: Bool {

        get {
            let screenSize: CGRect = UIScreen.main.bounds
            
            return (screenSize.width > 750)
            
        }
    }
}

/////// For view controllers

extension UIViewController {
    
    // Show a toast (like a Android app)
    
    func extShowToast(message : String, width: CGFloat = UIDevice.current.extIsSmallScreen ? 300: 600) {

        // Based em: https://stackoverflow.com/questions/31540375/how-to-toast-message-in-swift

        // Only have one line  ?
        
        let oneLine = !(message.extIndexOf("\n") > 0)
            
        // Show a toast 
        
        let toastLabel = UILabel(frame: CGRect(x: self.view.frame.size.width/2 - (width / 2),
                                               y: self.view.frame.size.height-((oneLine) ? 100 : 125),
                                               width: width, height: (oneLine) ? 35 : 70))
        toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        toastLabel.textColor = UIColor.white
        toastLabel.textAlignment = .center
        toastLabel.font = UIFont.systemFont(ofSize: UIDevice.current.extIsSmallScreen ? 12 : 18)
        toastLabel.text = message
        toastLabel.alpha = 1.0
        toastLabel.layer.cornerRadius = 10
        toastLabel.clipsToBounds  =  true
        toastLabel.numberOfLines = (oneLine) ? 1 : 0
        self.view.addSubview(toastLabel)
        UIView.animate(withDuration: 4.0, delay: 0.1, options: .curveEaseOut, animations: {
            toastLabel.alpha = 0.0
        }, completion: {(isCompleted) in
            toastLabel.removeFromSuperview()
        })
    }
    
    // Keyboard treats - based in https://stackoverflow.com/questions/32281651/how-to-dismiss-keyboard-when-touching-anywhere-outside-uitextfield-in-swift
    
    func extHideKeyboard()  {
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(
            target: self,
            action: #selector(UIViewController.extDismissKeyboard))
        
        view.addGestureRecognizer(tap)
    }
        
    @objc func extDismissKeyboard() {
        
        view.endEditing(true)
    }
    
    // Top most
    
    func extTopMostViewController() -> UIViewController {

        // Based in https://gist.github.com/db0company/369bfa43cb84b145dfd8

        if self.presentedViewController == nil {
            return self
        }
        if let navigation = self.presentedViewController as? UINavigationController {
            return navigation.visibleViewController!.extTopMostViewController()
        }
        if let tab = self.presentedViewController as? UITabBarController {
            if let selectedTab = tab.selectedViewController {
                return selectedTab.extTopMostViewController()
            }
            return tab.extTopMostViewController()
        }
        return self.presentedViewController!.extTopMostViewController()
    }
}

////// End
