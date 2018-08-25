/* ***********
 * Project   : Esp-App-Mobile-iOS - App to connect a Esp32 device by BLE
 * Programmer: Joao Lopes
 * Module    : Util/UI - iOS UI utilities
 * Comments  : Utilities
 * Versions  :
 * -------   --------     -------------------------
 * 0.1.0     08/08/18     First version
 **/
 
import UIKit

// Utilities for iOS UI

class UtilUI {

    // Get Root ViewController - based on https://stackoverflow.com/questions/12418177/how-to-get-root-view-controller
    
    class func getRootViewController() -> UIViewController? {
        
        return UIApplication.shared.keyWindow!.rootViewController

    }

    // Set background of Table View as a gradient - (based em https://stackoverflow.com/questions/30018035/set-gradient-behind-uitableview)
    
    class func setTableViewBackgroundGradient(sender: UITableViewController, _ topColor:UIColor, _ bottomColor:UIColor) {
        
        let gradientBackgroundColors = [topColor.cgColor, bottomColor.cgColor]
        let gradientLocations = [0.0,1.0]
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = gradientBackgroundColors
        gradientLayer.locations = gradientLocations as [NSNumber]
        
        gradientLayer.frame = sender.tableView.bounds
        let backgroundView = UIView(frame: sender.tableView.bounds)
        backgroundView.layer.insertSublayer(gradientLayer, at: 0)
        sender.tableView.backgroundView = backgroundView
    }
    
    // Set background of Table View cell as a gradient 

    class func setTableCellViewBackgroundGradient(sender: UITableViewCell, _ topColor:UIColor, _ bottomColor:UIColor) {
        
        let gradientBackgroundColors = [topColor.cgColor, bottomColor.cgColor]
        let gradientLocations = [0.0,1.0]
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = gradientBackgroundColors
        gradientLayer.locations = gradientLocations as [NSNumber]
        
        gradientLayer.frame = sender.bounds
        let backgroundView = UIView(frame: sender.bounds)
        backgroundView.layer.insertSublayer(gradientLayer, at: 0)
        sender.backgroundView = backgroundView
    }

    // Convert a image to gray scale using a filter
    
    class func filterImageNoir(image: UIImage) -> UIImage {
        
        let context = CIContext(options: nil)
        let currentFilter = CIFilter(name: "CIPhotoEffectNoir")
        currentFilter!.setValue(CIImage(image: image), forKey: kCIInputImageKey)
        let output = currentFilter!.outputImage
        let cgimg = context.createCGImage(output!,from: output!.extent)
        let processedImage = UIImage(cgImage: cgimg!)
        return processedImage
    }
    
    // Shows the App image on the right of the navigation
    
    class func showAppImageNav(controller: UIViewController) {
        
        let height = controller.navigationItem.leftBarButtonItem?.customView?.frame.size.height ?? 24
        if #available(iOS 11.0, *) {
            let menuBtn = UIButton(type: .custom)
            menuBtn.setImage(UIImage(named:"app.png"), for: .normal)
            let menuBarItem = UIBarButtonItem(customView: menuBtn)
            let currWidth = menuBarItem.customView?.widthAnchor.constraint(equalToConstant: 100)
            currWidth?.isActive = true
            let currHeight = menuBarItem.customView?.heightAnchor.constraint(equalToConstant: height)
            currHeight?.isActive = true
            controller.navigationItem.rightBarButtonItem = menuBarItem
        } else {
            let button = UIButton.init(type: .custom)
            button.setImage(UIImage.init(named: "app.png"), for: UIControlState.normal)
            button.frame = CGRect.init(x: 0, y: 0, width: 100, height: height)
            let barButton = UIBarButtonItem.init(customView: button)
            controller.navigationItem.rightBarButtonItem = barButton
        }
    }
    
    // Add a border
    
    class func addBorder (view: UIView, color: UIColor, width: CGFloat) {
        
        let border = CALayer()
        border.backgroundColor = color.cgColor
        
        border.frame = CGRect(x: 0, y: 0, width: view.frame.size.width, height: width)
        
        border.frame = CGRect(x: 0, y: view.frame.size.height - width, width: view.frame.size.width, height: width)
        
        border.frame = CGRect(x: 0, y: 0, width: width, height: view.frame.size.height)
        
        border.frame = CGRect(x: view.frame.size.width - width, y: 0, width: width, height: view.frame.size.height)
        
        view.layer.addSublayer(border)
    }

    // Load imagem from a file
    
    class func loadImageFile(path: String) -> UIImage? {
        
        do {
            let url = NSURL(fileURLWithPath: path) as URL
            let imageData = try Data(contentsOf: url)
            return UIImage(data: imageData)
        } catch {
            debugE("Error in loading image: \(error)")
            return nil
        }
    }
    
    // Return a color of an pixel
    
    class func getPixelColor(in image: UIImage, at point: CGPoint) -> (UInt8, UInt8, UInt8, UInt8)? {
        let width = Int(image.size.width)
        let height = Int(image.size.height)
        let x = Int(point.x)
        let y = Int(point.y)
        guard x < width && y < height else {
            return nil
        }
        guard let cfData:CFData = image.cgImage?.dataProvider?.data, let pointer = CFDataGetBytePtr(cfData) else {
            return nil
        }
        let bytesPerPixel = 4
        let offset = (x + y * width) * bytesPerPixel
        return (pointer[offset], pointer[offset + 1], pointer[offset + 2], pointer[offset + 3])
    }
    
}

////// End
