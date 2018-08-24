/* ***********
 * Project   : Esp-App-Mobile-iOS - App to connect a Esp32 device by BLE
 * Programmer: Joao Lopes
 * Module    : TerminalBLEViewController - VC Terminal BLE
 * Comments  :
 * Versions  :
 * -------  --------    -------------------------
 * 0.1.0    08/08/18    First version
 * 0.2.0    20/08/18    Option to disable logging br BLE (used during repeated sends)
 **/

import UIKit

class TerminalBLEViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate {
    
    ////// MainController instance
    
    private let mainController = MainController.getInstance()
    
    ////// Variables
    
    private (set) var repeatSend: Bool = false // Repeated sends ?

    public var bleTotRepeatPSec: Int = 0    // Total of repeat (send/receive echo) per second

    private var savedDebugLevel: debugLevel = debugLevelCurrent
    
    ////// Outlets
    
    @IBOutlet weak var tableViewDebug: UITableView!
    
    @IBOutlet weak var labelTypeConn: UILabel!
    @IBOutlet weak var labelTypeDisconn: UILabel!
    @IBOutlet weak var labelTypeRecv: UILabel!
    @IBOutlet weak var labelTypeSend: UILabel!
    @IBOutlet weak var labelTypeOther: UILabel!
    
    @IBOutlet weak var textViewSend: UITextField!
    @IBOutlet weak var buttonRepeat: UIButton!
    
    @IBOutlet weak var buttonSend: UIButton!
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
    
    @IBAction func buttonSend(_ sender: UIButton) {
        
        // Send
        
        send(repeated: false)
    }
    
    @IBAction func buttonRepeat(_ sender: UIButton) {

        // Send repeat (new send at each receive - only for echos (70:xxx))
        
        if buttonRepeat.titleLabel?.text == "Stop" {
            
            // Stop this

            stopRepeat()
            
            extShowToast(message: "Repeat sends is stopped")

        } else {

            // Send and repeat

            send(repeated: true)
        }
    }
    
    /////// Events
    
    // Did load
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Tableview
        
        self.tableViewDebug.delegate = self
        self.tableViewDebug.dataSource = self
        self.tableViewDebug.rowHeight = UITableViewAutomaticDimension
        self.tableViewDebug.estimatedRowHeight = 44
        
        // Default send text
        
        if textViewSend.text?.count == 0 {
            textViewSend.text = "\(MessagesBLE.MESSAGE_ECHO)Echo test"
        }
        
        // Automatically hide keyboard on out tap
        
        extHideKeyboard()
        
        // Delegate
        
        textViewSend.delegate = self
    }
    
    // Will appear
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        debugV("")
        
        // Reload data
        
        reloadData()
        

        // Show status of battery
        
        mainController.showStatusBattery()
        
    }
    
    // Will disappear
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        debugV("")
        
        // Stop repeat
        
        stopRepeat()
    }
    
    // Memory warning
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning ()
    }
    
    // Statusbar
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    /////// TableView methods
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return mainController.bleDebugs.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") as! TerminalBLECell
        
        let row = (indexPath as NSIndexPath).row
        
        let item: BLEDebug = mainController.bleDebugs [row]
        
        var debug = ""
        if item.type == "R" || item.type == "S" {
            debug = "\(item.time): \(item.type)[\(item.message.count)]: \(item.message) [\(item.extra)]"
        } else {
            debug = "\(item.time): \(item.type): \(item.message) \(item.extra)"
        }
        
        cell.labelDebug.text = debug
        
        switch item.type {
        case "C": // Connection
            cell.labelDebug.textColor = labelTypeConn.textColor
        case "D": // Disconnection
            cell.labelDebug.textColor = labelTypeDisconn.textColor
        case "R": // Receive
            cell.labelDebug.textColor = labelTypeRecv.textColor
        case "S": // Send
            cell.labelDebug.textColor = labelTypeSend.textColor
        case "O": // Other
            cell.labelDebug.textColor = labelTypeOther.textColor
        default:
            cell.labelDebug.textColor = UIColor.white
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        // No selection yet
    }
    
    ///// Text view
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {   //delegate method
        textField.resignFirstResponder()
        
        send(repeated: false)
        
        return true
    }
    
    ///// Routines
    
    // Reload
    
    func reloadData() {
        
        // Debug
//        debugV("count-> ", self.mainController.bleDebugs.count-1)
//        for bleDebug in self.mainController.bleDebugs {
//            debugV(bleDebug.time, bleDebug.type, bleDebug.message)
//        }

        // Update UI
        
        DispatchQueue.main.async {
            
            // Reload
            
            self.tableViewDebug.reloadData()
            
            // Scroll

            if AppSettings.TERMINAL_BLE_ORDER_DESC { // To top
                let indexPath = IndexPath(row: 0, section: 0)
                self.tableViewDebug.scrollToRow(at: indexPath, at: .top, animated: false)
            } else { // To end
                let indexPath = IndexPath(row: self.mainController.bleDebugs.count-1, section: 0)
                self.tableViewDebug.scrollToRow(at: indexPath, at: .bottom, animated: false)
            }
        }
    }

    // Insert a new row in table view
    
    func insertRow() {
        
        // Update UI
        
        DispatchQueue.main.async {
            
            self.tableViewDebug.beginUpdates()
            
            if AppSettings.TERMINAL_BLE_ORDER_DESC {
                self.tableViewDebug.insertRows(at: [IndexPath.init(row: 0, section: 0)], with: .none) // TOP
            } else {
                self.tableViewDebug.insertRows(at: [IndexPath(row: self.mainController.bleDebugs.count-1, section: 0)], with: .none) // BOTTOM
            }
            self.tableViewDebug.endUpdates()
        }
    }
    
    // Update last row in table view
    
    func updateLastRow () {
        
        // Update UI
        
        DispatchQueue.main.async {
            
            self.tableViewDebug.beginUpdates()
            
            if AppSettings.TERMINAL_BLE_ORDER_DESC {
                self.tableViewDebug.reloadRows(at: [NSIndexPath(row: 0, section: 0) as IndexPath], with: UITableViewRowAnimation.none) // TOP
            } else {
                self.tableViewDebug.reloadRows(at: [NSIndexPath(row: self.mainController.bleDebugs.count-1, section: 0) as IndexPath], with: UITableViewRowAnimation.none) // BOTTOM
            }
            self.tableViewDebug.endUpdates()
        }
    }
    
    // Send
    
    func send (repeated: Bool) {
        
        // Have content to send ?
        
        let content:String = textViewSend.text!
        
        if content.count == 0 {
            
            extShowToast(message: "Empty data")
            return
        }
        
        // Hide keyboard
        
        extDismissKeyboard()
        
        // For repeat -> only type echo messages allowed
        
        if repeated && !content.starts(with: MessagesBLE.MESSAGE_ECHO) {
            
            extShowToast(message: "For repeat, only echo is allowed (\(MessagesBLE.MESSAGE_ECHO)")
            return
        }
    
        // Send it
    
        mainController.bleSendMessage(content, debugExtra: "by terminal")

        // Repeated
        
        if repeated && !repeatSend {
            
            startRepeats()
        }
    }
    
    // Start repeats
    
    func startRepeats() {
    
        repeatSend = true
        
        buttonRepeat.setTitle("Stop", for: .normal)
        
        extShowToast(message: "Repeated sends now")
        
        textViewSend.isHidden = true
        buttonSend.isHidden = true
        
        // Deactivate debugs on App and ESP32 to better performance

        mainController.bleDebugEnabled = false  // Disable it, for send repeated

        mainController.bleSendMessage("\(MessagesBLE.MESSAGE_LOGGING)N", debugExtra: "by terminal")
        
        // No debug during tests to improve performance
        
        savedDebugLevel = debugLevelCurrent // Save it
        
        debugSetLevel(.none)
        
    }
    // Stop repeats
    
    func stopRepeat() {
        
        buttonRepeat.setTitle("Repeat", for: .normal)

        textViewSend.isHidden = false
        buttonSend.isHidden = false
        
        // Restore debugs
        
        mainController.bleDebugEnabled = true // Enable it
        
        debugSetLevel(savedDebugLevel) // Enable it
        
        mainController.bleSendMessage("\(MessagesBLE.MESSAGE_LOGGING)R", debugExtra: "by terminal") // Restore it

        // Indicate to no repeat
        
        repeatSend = false
        bleTotRepeatPSec = 0
        
    }
}

////// End
