/* ***********
 * Project   : Esp-App-Mobile-iOS - App to connect a Esp32 device by BLE
 * Programmer: Joao Lopes
 * Module    : TemplateViewController - VC template - just copy it if you need a new VC
 * Comments  :
 * Versions  :
 * -------   --------     -------------------------
 * 0.1.0     08/08/18     First version
 **/

import UIKit

class TemplateViewController: UIViewController {
    
    ////// MainController instance
    
    private let mainController = MainController.getInstance()
    
    ////// Outlets
    
    @IBOutlet weak var labelStatus: UILabel!
    @IBOutlet weak var imageViewBattery: UIImageView!
    @IBOutlet weak var labelPercentBattery: UILabel!
    @IBOutlet weak var imageViewBluetooth: UIImageView!

    ////// Actions
   
    @IBAction func buttonExit(_ sender: Any) {
        
        // Exit button
        
        debugD("")
        
        // Finish App with confirmation
        
        Alert.confirm("Confirm exit?", viewController: self, callBackOK: { () in
            
            // Finish
            
            self.mainController.finishApp()
            
        })
        
    }
    
    ////// Variables
    
    /////// Events
    
    // Did load
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Put here your code
    }

    // Will appear
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        debugV("")
        
        // Show status of battery

        mainController.showStatusBattery()
        
    }
    
    // Will disappear
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        debugV("")
    }
    
    // Memory warning
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning ()
    }
    
    // Statusbar
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    /////// Routines
    
}

////// End
