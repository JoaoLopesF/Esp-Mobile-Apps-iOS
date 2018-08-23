/* ***********
 * Project   : Esp-App-Mobile-iOS - App to connect a Esp32 device by BLE
 * Programmer: Joao Lopes
 * Module    : ConnectingViewController - VC for connecting
 * Comments  :
 * Versions  :
 * -------   --------     -------------------------
 * 0.1.0     08/08/18     First version
 **/

import UIKit
import Foundation

class ConnectingViewController: UIViewController {
    
    ////// MainController instance

    private let mainController = MainController.getInstance()
    
    /////// Outlets
    
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    @IBOutlet weak var labelScanning: UILabel!
    @IBOutlet weak var labelMessage: UILabel!
    
    /////// Actions
    
    @IBAction func buttonExit(_ sender: UIBarButtonItem) {
        
        // Exit
        
        debugV("Exiting")
        exit(0)
    }

    /////// Variables
    
    /////// Events
    
    override func viewDidLoad () {
        super.viewDidLoad ()
        
        debugV("")

        // Remove the back button
        
        let backButton = UIBarButtonItem(title: "", style: .plain, target: navigationController, action: nil)

        navigationItem.leftBarButtonItem = backButton
        
        // Navigation controller
        
        mainController.navigationController = navigationController
        
        // Simulator -> displays the main screen
        
        #if targetEnvironment (simulator)
        
            labelMessage.text = "Simulator detected"
            mainController.showVCMainMenu ()
        
        #endif
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        debugV("")
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        debugV("")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        debugV("")
    }
    
}
