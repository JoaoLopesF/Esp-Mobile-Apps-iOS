/* ***********
 * Project   : Esp-App-Mobile-iOS - App to connect a Esp32 device by BLE
 * Programmer: Joao Lopes
 * Module    : DisconnectedViewController - VC for when disconnect from device occurs
 * Comments  :
 * Versions  :
 * -------   --------     -------------------------
 * 0.1.0     08/08/18     First version
 **/
import UIKit
import Foundation

class DisconnectedViewController: UIViewController {
    
    ////// MainController instance

    private let mainController = MainController.getInstance()
    
    ////// Outlets
    
    @IBOutlet weak var labelMessage: UILabel!
    
    ////// Actions
    
    @IBAction func buttonTryAgain(_ sender: UIButton) {
        
        // Try a new connection
        
        tryAgain()
    }
    
    @IBAction func buttonExit(_ sender: UIBarButtonItem) {

        // Exit button
            
        mainController.finishApp()

    }
    
    ////// Variables
    
    public var message: String = ""
    
    ///// Events
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Load event
        
        debugV("")
        
        // Remove the back button

        let backButton = UIBarButtonItem(title: "", style: .plain, target: navigationController, action: nil)
        navigationItem.leftBarButtonItem = backButton
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        debugV("")
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // DidAppear event
        
        debugV("")
        
        labelMessage.text = message
        
        message = ""
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        debugV("")
    }
    
    // Try new connection
    
    private func tryAgain() {
        
        // Retorna para a tela de conexao
        
        navigationController?.popToRootViewController(animated:false)
        
        // Tenta a conexao novamente
                
        mainController.bleScanDevice()
        
    }
    
}
