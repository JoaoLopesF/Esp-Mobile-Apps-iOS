/* ***********
 * Project   : Esp-App-Mobile-iOS - App to connect a Esp32 device by BLE
 * Programmer: Joao Lopes
 * Module    : InformationsViewController - VC to show ESP32 device infomartions
 * Comments  :
 * Versions  :
 * -------   --------     -------------------------
 * 0.1.0     08/08/18     First version
 **/

import UIKit

class InformationsViewController: UIViewController {
    
    ////// MainController instance
    
    private let mainController = MainController.getInstance()
    
    ////// Outlets
    
    @IBOutlet weak var textViewAboutEsp32: UITextView!
    @IBOutlet weak var labelFreeMemory: UILabel!
    @IBOutlet weak var labelVoltageEsp32: UILabel!
    @IBOutlet weak var labelPowered: UILabel!
    @IBOutlet weak var labelCharging: UILabel!
    @IBOutlet weak var labelVoltageBattery: UILabel!

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
    
    @IBAction func buttonRefreshFreeMem(_ sender: Any) {
        
        // Request info
        
        sendInfoMessage(message: "\(MessagesBLE.MESSAGE_INFO)FMEM")
        
    }
    @IBAction func buttonRefreshVoltageEsp32(_ sender: Any) {

        // Request info
        
        sendInfoMessage(message: "\(MessagesBLE.MESSAGE_INFO)VDD33")
        
    }

    @IBAction func buttonRefreshVoltageBattery(_ sender: Any) {

        // Request info (by message of energy)
        
        sendInfoMessage(message: "\(MessagesBLE.MESSAGE_ENERGY)")
        
    }
    
    @IBAction func buttonRefreshAll(_ sender: Any) {
        
        // Request all
        // Note: Example for  send more than 1 message once time
        // Due BLE routines handle large message
        // Its is better than send 3 messages
        
        var messages:String = ""
        messages.append ("\(MessagesBLE.MESSAGE_INFO)FMEM")
        messages.append ("\n")
        messages.append ("\(MessagesBLE.MESSAGE_INFO)VDD33")
        messages.append ("\n")
        messages.append ("\(MessagesBLE.MESSAGE_ENERGY)")
        messages.append ("\n")

        sendInfoMessage(message: messages)
        
    }

    ////// Variables
    
    /////// Events
    
    // Did load
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Request all informations (example how send BLE messages from another VC)
        // the true indicate to wait to response (timeout, if not receive nothing a time)
        
        sendInfoMessage(message: "\(MessagesBLE.MESSAGE_INFO)ALL")
        
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

    // Update energy info
    
    public func updateEnergyInfo() {

        if !mainController.deviceHaveBattery || mainController.poweredExternal {
           
            labelPowered.text = "External"
        
        } else {
            
            labelPowered.text = "Battery"
        
        }
        
        if mainController.deviceHaveSenCharging {
            
            labelCharging.text = (mainController.chargingBattery) ? "Yes" : "No"

        } else {
            
            labelCharging.text = "?"
            
        }
        
        labelVoltageBattery.text = "\(mainController.readADCBattery) (\(mainController.voltageBattery)v)"

    }
    
    // Send BLE message for info
    
    func sendInfoMessage (message: String) {
        
        mainController.bleSendMessage(message, verifyResponse: true, debugExtra: "Info")
    }
}
