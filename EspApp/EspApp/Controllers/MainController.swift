/* ***********
 * Project   : Esp-App-Mobile-iOS - App to connect a Esp32 device by BLE
 * Programmer: Joao Lopes
 * Module    : MainController - main controller and main code in app
 * Comments  : Uses a singleton pattern to share instance to all app
 * Versions  :
 * -------  --------    -------------------------
 * 0.1.0    08/08/18    First version
 * 0.1.1    17.08.18    Adjusts in send repeat echoes
 * 0.1.2    17/08/18    Adjusts in Terminal BLE and Debug
 * 0.2.0    20/08/18    Option to disable logging br BLE (used during repeated sends)
 * 0.3.0    23/08/18    Changed name of github repos to Esp-App-Mobile-Apps-*
 *                      Few adjustments
 * 0.3.1    24/08/18    Alert for BLE device low battery
 **/

/*
 // TODO:
 */

import Foundation
import UIKit

public class MainController: NSObject, BLEDelegate {
    
    /////// Singleton
    
    static private var instance : MainController {
        return sharedInstance
    }
    
    private static let sharedInstance = MainController()
    
    // Singleton pattern method
    
    static func getInstance() -> MainController {
        return self.instance
    }
    
    ////// BLE instance
    
#if !targetEnvironment(simulator) // Real device ? (not for simulator)
    
    private let ble = BLE.getInstance ()
    
#endif
    
    ////// Objects
    
    var navigationController: UINavigationController? = nil // Navegation
    
    var storyBoardMain: UIStoryboard? = nil // Story board Main
    
    @objc var timerSeconds: Timer? = nil // Timer in seconds
    
    var imageBattery: UIImage? = nil // Battery
    
    ///// Variables
    
    public let versionApp:String = "0.3.1" // Version of this APP
    
    private (set) var versionDevice: String = "?" // Version of BLE device
    
    private (set) var timeFeedback: Int = 0 // Time to send feedbacks
    private (set) var sendFeedback: Bool = false // Send feedbacks ?
        
    private (set) var timeActive: Int = 0 // Time of last activity
    private var exiting: Bool = false
    
    private (set) var deviceHaveBattery: Bool = false       // Device connected have a battery
    private (set) var deviceHaveSenCharging: Bool = false   // Device connected have a sensor of charging of battery
    private (set) var poweredExternal: Bool = false         // Powered by external (USB or power supply)?
    private (set) var chargingBattery: Bool = false         // Charging battery ?
    private (set) var statusBattery:String = "100%"         // Battery status
    private (set) var voltageBattery: Float = 0.0           // Voltage calculated of battery
    private (set) var readADCBattery: Int = 0               // Value of ADC read of battery
    
    private (set) var debugging: Bool = true // Debugging ?
    
    // Global exception treatment // TODO: make it in future
    // private let mExceptionHandler: ExceptionHandler
        
    // BLE
            
    private var bleStatusActive: Bool = false       // Active BLE status in the panel?
    
    private var bleTimeout: Int = 0                 // BLE Timeout
    private var bleVerifyTimeout: Bool = true       // Check timeout?
    
    private var bleAbortingConnection: Bool = false // Aborting connection ?
    
    private (set) var bleDebugs: [BLEDebug] = []    // Array for BLE debugs
    public var bleDebugEnabled: Bool =
                    AppSettings.TERMINAL_BLE        // It is enabled ?
    
    /////////////////// Init
    
    // Init
    
    override init() {
        super.init()
        
        // Initialize App
        
        initializeApp ()
        
    }
    
    /////////////////// Methods
    
    private func activateTimer (activate: Bool) {
        
        // Timer of seconds
        
        debugV("activate:", activate)
        
        // Zera veriaveis
        
        timeFeedback = 0
        
        // active?
        
        if activate {
            
            if timerSeconds != nil {
                
                // Disable before the previous one
                
                timerSeconds?.invalidate()
                
            }
            
            // Activate the timer
            
            self.timerSeconds = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.timerTickSeconds), userInfo: nil, repeats: true)
            
        } else {
            
            // Cancel timer
            
            if timerSeconds != nil {
                
                self.timerSeconds?.invalidate()
            }
        }
        
    }
    
    @objc private func timerTickSeconds() {
        
        // Timer every second - only when connected
        
    #if !targetEnvironment (simulator) // Real device ? (not for simulator)
        
        if ble.connected == false {
            
            // Timer - deactivate
            
            activateTimer (activate: false)
            
            return
        }
    
        if self.bleStatusActive {
            
            showStatusBle (active: false)
            
        }
    
        // Send Timeout
    
        if bleVerifyTimeout == true && !debugging {
            
            bleTimeout -= 1
            
            if bleTimeout <= 0 {
                
                debugE("*** Timeout")
                
                bleAbortConnection (message: "No response from BLE device (code B2)")
                
                return
            }
        }

#endif

    // Check inactivity

    if let _:MainMenuViewController = navigationController?.topViewController
        as? MainMenuViewController { // In main menu ?
        
        // Remaining time to go into inactivity
        
        timeActive -= 1
        
        // debugV ("Active time =" + mTimeActive)
        
        if timeActive <= 0 {
            
            // Abort connection
            
            bleAbortConnection (message: "The connection and device was shutdown, due to having reached maximum time of inactivity (\(AppSettings.TIME_MAX_INACTITIVY)s.)")
            return
        }
        
    } else { // For others - set it as active
        
        timeActive = AppSettings.TIME_MAX_INACTITIVY
        
    }

#if !targetEnvironment (simulator) // Real device

    if ble.sendingNow == false && sendFeedback == true  {
        
        // Send feedback periodically
        
        timeFeedback += 1
        
        if timeFeedback == AppSettings.TIME_SEND_FEEDBACK {
            
            bleSendFeedback()
            timeFeedback = 0
            
        }
    }
#endif

    // Terminal BLE
        
    if AppSettings.TERMINAL_BLE {
        
        if let terminalBLEVC:TerminalBLEViewController = navigationController?.topViewController as? TerminalBLEViewController {
            
            // Is to send repeated (only for echoes) ?
            
            if terminalBLEVC.repeatSend {
                
                // Show a debug with the total per second
                
                if terminalBLEVC.bleTotRepeatPSec > 0 {
                    
                    bleAddDebug(type: "O", message: "*** Repeats(send/receive) p/sec.: \(terminalBLEVC.bleTotRepeatPSec)", extra: "", forced: true)

                } else { // Send again, if no responses received
                    
                    terminalBLEVC.send(repeated: true)
                    
                }
                
                // Clear the total
                
                terminalBLEVC.bleTotRepeatPSec = 0
                
            }
        }
    }

}

public func initializeVariables () {
    
    // Initialize control variables
        
    bleVerifyTimeout = false
    bleTimeout = 0
    
    sendFeedback = false
    
    timeActive = AppSettings.TIME_MAX_INACTITIVY
    
}

func showVCMainMenu () {
    
    // Show the main menu view controller
    
    if storyBoardMain == nil {
        storyBoardMain = UIStoryboard(name: "Main", bundle: nil)
    }
    
    // Update the UI
    
    DispatchQueue.main.async {
        
        let mainMenuVC = self.storyBoardMain?.instantiateViewController(withIdentifier: "Main menu") as? MainMenuViewController
        
        self.navigationController?.pushViewController(mainMenuVC!, animated: true)
    }
    
}

func showVCDisconnected (message: String) {
    
    // Show disconnected view controller
    
    if storyBoardMain == nil {
        storyBoardMain = UIStoryboard(name: "Main", bundle: nil)
    }
    
    // Update the UI
    
    DispatchQueue.main.async {
        
        // Returns to VC root
        
        self.navigationController?.popToRootViewController(animated:false)
        
        //Show disconnected view controller
        
        if self.storyBoardMain == nil {
            self.storyBoardMain = UIStoryboard(name: "Main", bundle: nil)
        }
        
        if let disconnectedVC = self.storyBoardMain?.instantiateViewController(withIdentifier: "Disconnected") as? DisconnectedViewController {
            
            self.navigationController?.pushViewController(disconnectedVC, animated: false)
            
            disconnectedVC.message = message
        }
    }
}

    
    // Show status of battery

    func showStatusBattery () {
        
        // Show data saved before
        
        var imageViewBattery: UIImageView!
        var labelPercentBattery: UILabel!
        
        // Process VC // TODO: see it! put here all VC that have a statusbar
        
        if let mainMenu = navigationController?.topViewController as? MainMenuViewController {
            labelPercentBattery = mainMenu.labelPercentBattery
            imageViewBattery = mainMenu.imageViewBattery
        } else if let infoVC = navigationController?.topViewController as? InformationsViewController {
            labelPercentBattery = infoVC.labelPercentBattery
            imageViewBattery = infoVC.imageViewBattery
        } else if let terminalBLEVC = navigationController?.topViewController as? TerminalBLEViewController {
            labelPercentBattery = terminalBLEVC.labelPercentBattery
            imageViewBattery = terminalBLEVC.imageViewBattery
//        } else if let settingsVC = navigationController?.topViewController as? SettingsViewController {
//            labelPercentBattery = mainMenu.labelPercentBattery
//            imageViewBattery = mainMenu.imageViewBattery
        }
        
        // Show status of battery
        
        if labelPercentBattery != nil {
            
            // Update  UI
            
            DispatchQueue.main.async {
                
                if self.deviceHaveBattery {
                    imageViewBattery.isHidden = false
                    labelPercentBattery.isHidden = false
                    imageViewBattery.image = self.imageBattery
                    labelPercentBattery.text = self.statusBattery
                } else {
                    imageViewBattery.isHidden = true
                    labelPercentBattery.isHidden = true
                }
            }
        }
    }
    
    // Show status of BLE (icon)

    func showStatusBle (active:Bool) {
        
        var imageViewBluetooth: UIImageView!
        
        // TODO: see it! need put all VC that have a statusbar here

        if let mainMenuVC = navigationController?.topViewController as? MainMenuViewController {
            imageViewBluetooth = mainMenuVC.imageViewBluetooth
        } else if let infoVC = navigationController?.topViewController as? InformationsViewController {
            imageViewBluetooth = infoVC.imageViewBluetooth
        } else if let terminalBLEVC = navigationController?.topViewController as? TerminalBLEViewController {
            imageViewBluetooth = terminalBLEVC.imageViewBluetooth
//        } else if let terminalVC = navigationController?.topViewController as? TerminalViewController {
//        } else if let settingsVC = navigationController?.topViewController as? SettingsViewController {
//            imageViewBluetooth = settingsVC.imageViewBluetooth
        }
        
        // Update UI
        
        if imageViewBluetooth != nil {
            
            DispatchQueue.main.async {
                imageViewBluetooth.image = (active) ? #imageLiteral(resourceName: "bt_icon") : #imageLiteral(resourceName: "bt_icon_inactive")
            }
        }
        
        self.bleStatusActive = true
        
    }
    
    
    
    ////// BLE
    
    // Scan a device

    public func bleScanDevice() {
        
        // Starting the scanning ...
        
        debugV("Scanning device ...")
        
        // Is on screen of connection ?
        
        if let connectingVC:ConnectingViewController = navigationController?.topViewController as? ConnectingViewController {
            
            connectingVC.labelScanning.text = "Scanning now ..."
            
        }
        
    #if !targetEnvironment(simulator) // Real device
        
        ble.startScan(AppSettings.BLE_DEVICE_NAME)
        
    #endif
    }
    
    // Connected 

    private func bleConnected () {
        
        // Connection OK
        
        // Activate the timer
        
        activateTimer(activate: true)
        
        // Message initial
        
        bleSendMessage(MessagesBLE.MESSAGE_INITIAL, verifyResponse: true, debugExtra: "Initial")

        // Send feedbacks
        
        sendFeedback = true
        
    }
    
    // Abort the connection

    func bleAbortConnection(message:String) {
        
        // Only if not still running, to avoid loops
        
        if bleAbortingConnection { 
            return
        }
        
        // On disconnected VC ?
        
        if let _ = navigationController?.topViewController as? DisconnectedViewController {
            return
        }
        
        // Abort
        
        bleAbortingConnection = true
        
        debugV("msg=" + message)
                    
        // Message to device enter in standby or reinitialize
            
#if !targetEnvironment(simulator) // Real device
            
        if ble.connected {
            
            if !poweredExternal {
                
                bleSendMessage(MessagesBLE.MESSAGE_STANDBY, verifyResponse: false, debugExtra: "Standby")
                
            } else {

                bleSendMessage(MessagesBLE.MESSAGE_RESTART, verifyResponse: false, debugExtra: "Restart")

            }
        }
            
#endif
        
        // Abort timers
        
        activateTimer(activate: false)
        
        // Ends connection BLE
        
#if !targetEnvironment(simulator) // Real device
        
        ble.disconnectPeripheral()
        
#endif
                
        // Init variables
        
        initializeVariables()
        
        // Debug
        
        if AppSettings.TERMINAL_BLE && self.bleDebugEnabled { // App have a Terminal BLE (debug) and it is enabled ?
            self.bleAddDebug(type: "O",  message: "Connection aborted: \(message)") // Add debug
        }

        // Shom message on disconnected VC
        
        showVCDisconnected(message: message)
        
        // Abort processed
        
        bleAbortingConnection = false
        
    }
    
    // Send a message by BLE

    func bleSendMessage(_ message:String, verifyResponse:Bool=false, debugExtra: String = "") {
        
#if !targetEnvironment(simulator) // Real device
        
        // If not connected or just sending now, returns
        // To avoid problems
        
        if !ble.connected || ble.sendingNow {
            return
        }
        
        // Multithreading
        
        DispatchQueue.global().async {
            
            // Debug
            
            debugV("send menssage \(message)")
            
            if AppSettings.TERMINAL_BLE && self.bleDebugEnabled { // App have a Terminal BLE (debug) and it is enabled ?
                self.bleAddDebug(type: "S",  message: message, extra: debugExtra) // Add debug
            }

            // Reinitializes the time for feedbacks
            
            self.timeFeedback = 0
            
            // Show status
            
            self.showStatusBle(active: true)
            self.showMessageStatus("Sending data to device ...")
            
            // Send a message by BLE
            
            self.ble.send(message)
            
            // Verify response ? (timeout)
            
            if verifyResponse {
                
                self.bleTimeout = AppSettings.BLE_TIMEOUT
                self.bleVerifyTimeout = true
                
                self.showMessageStatus("Waiting response ...")
                
            } else { // Not waiting a response
                
                self.bleTimeout = 0
                self.bleVerifyTimeout = false
                
                self.showMessageStatus("")
            }
        }
#endif
    }         
    
    // Send a feedback message

    func bleSendFeedback() {
        
#if !targetEnvironment(simulator) // Real device
                
        debugV("")
        
        // Is is just sending now, ignore
        
        if ble.sendingNow {
            return
        }
        
        // Send a message
        
        bleSendMessage(MessagesBLE.MESSAGE_FEEDBACK, verifyResponse: true, debugExtra: "Feedback")

#endif
    }

    // Process the message received by BLE

    func bleProcessMessageRecv(_ message: String) {
        
#if !targetEnvironment(simulator) // Real device
        
        // Process the message
        
        if message.count < 3 {
            
            debugE("invalid msg (<3):", message)
                        
            return
            
        }
        
        // Extract the delimited fields
        
        let fields: Fields = Fields(message, delim:":")

        // Extract code
        
        let codMsg:Int = Int(fields.getField(1)) ?? -1

        // Process the message by code
        
        switch codMsg {
            
        case MessagesBLE.CODE_OK: // OK
            
            // Receive OK response, generally no process need

            if AppSettings.TERMINAL_BLE && self.bleDebugEnabled { // App have a Terminal BLE (debug) and it is enabled ?
                bleUpdateDebug(extra: "OK")
            }

            break
            
        case MessagesBLE.CODE_INITIAL: // Initial message response
            
            // Format O1:Version:HaveBattery:HaveSensorCharging

            if AppSettings.TERMINAL_BLE && self.bleDebugEnabled { // App have a Terminal BLE (debug) and it is enabled ?
                bleUpdateDebug(extra: "Initial")
            }
            
            bleProcessInitial(fields: fields)
            
        case MessagesBLE.CODE_ENERGY: // Status of energy: USB ou Battery
            
            if AppSettings.TERMINAL_BLE && self.bleDebugEnabled { // App have a Terminal BLE (debug) and it is enabled ?
                bleUpdateDebug(extra: "Energy")
            }
            
            debugV("Messagem of energy")
            
            bleProcessEnergy(fields: fields)
            
            // Note: example of call subroutine to update the VC
            
            if let infoVC:InformationsViewController = navigationController?.topViewController as? InformationsViewController {
                infoVC.updateEnergyInfo()
            }

        case MessagesBLE.CODE_INFO: // Status of energy: USB ou Battery
            
            if AppSettings.TERMINAL_BLE && self.bleDebugEnabled { // App have a Terminal BLE (debug) and it is enabled ?
                bleUpdateDebug(extra: "Info")
            }
            
            debugV("Message of info")
            
            bleProcessInfo(fields: fields)
            
        case MessagesBLE.CODE_ECHO: // Echo -> receives the same message sended
            
            // Echo received
            
            if AppSettings.TERMINAL_BLE && self.bleDebugEnabled { // App have a Terminal BLE (debug) and it is enabled ?
                bleUpdateDebug(extra: "Echo")
            }
            
            if let terminalBLEVC:TerminalBLEViewController = navigationController?.topViewController as? TerminalBLEViewController {
                
                // Is to send repeated (only for echoes) ??
                
                if terminalBLEVC.repeatSend {
                    
                    terminalBLEVC.bleTotRepeatPSec += 1
                    
                    bleSendMessage(message, verifyResponse: true, debugExtra: "Echo")
                    
                }
            }

            break
            
        case MessagesBLE.CODE_FEEDBACK: // Feedback
            
            // Feedback received
            
            if AppSettings.TERMINAL_BLE && self.bleDebugEnabled { // App have a Terminal BLE (debug) and it is enabled ?
                bleUpdateDebug(extra: "Feedback")
            }

            break        

        case MessagesBLE.CODE_STANDBY: // Entrou em standby

            if AppSettings.TERMINAL_BLE && self.bleDebugEnabled { // App have a Terminal BLE (debug) and it is enabled ?
                bleUpdateDebug(extra: "Standby")
            }

            bleAbortConnection(message: "The device is turn off")
            
        default: // Invalid code
            
            if AppSettings.TERMINAL_BLE && self.bleDebugEnabled { // App have a Terminal BLE (debug) and it is enabled ?
                bleUpdateDebug(extra: "Invalid")
            }

            debugE("invalid msg code", message)
                        
        }
#endif
    }
    
    // Process initial message
    
    private func bleProcessInitial(fields: Fields) {
        
        // Note: this is a example how this app discovery device hardware
        // This usefull to works with versions or models of hardware
        // For example: if device have a battery, the app show status of this
        
        // Format of message: 01:FIRWARE VERSION:HAVE BATTERY:HAVE SENSOR CHARGING

        debugV("initial msg")
        
        // Version
        
        versionDevice = fields.getField(2)
        
        debugV("version of device ", versionDevice)
        
        // Have a battery
        
        deviceHaveBattery = ( fields.getField(3) == "Y")

        // Have a battery charging sensor
        
        deviceHaveSenCharging = ( fields.getField(4) == "Y")

        // Show the main menu
        
        showVCMainMenu()

    }

    // Process energy message
    
    private func bleProcessEnergy(fields: Fields) {
        
        // Format of message: 10:POWERED:CHARGING:ADC_BATTERY
        
        poweredExternal = (fields.getField(2) == "EXT")
        chargingBattery = (fields.getField(3) == "Y")
        readADCBattery = fields.getFieldInt(4)
        
        debugD("usb=", poweredExternal, "charging=", chargingBattery, "vbat=", readADCBattery)
        
        // Calculate the voltage (done here note in firmware - due more easy to update)
        // TODO: see it! please caliber it first !
        // To caliber:
        //  - A charged battery plugged
        //  - Unplug the USB cable (or energy cable)
        //  - Meter the voltage of battery with multimeter
        //  - See the value of ADC read in monitor serial or in App informations
        
        let voltageCaliber: Float = 3.942
        let readADCCaliber: Float = 3168
        let factorCaliber: Float = (voltageCaliber / readADCCaliber)
        
        // Voltage readed from ADC
        
        let oldVoltage = voltageBattery
        
        voltageBattery = Util.round((Float(readADCBattery) * factorCaliber), 2)
        
        debugV("vbat ->", voltageBattery, "v")
        
        // Calculate the %
        
        var percent:Int = 0
        var voltage:Float = voltageBattery
        
        if voltage >= 2.5 {
            voltage -= 2.5 // Limit  // TODO: see it!
            percent = Int(Util.round(((voltage * 100.0) / 1.7), 0))
            if percent > 100 {
                percent = 100
            }
        } else {
            percent = 0
        }

        // Show o icon of battery and percent of this
        // TODO: see it! Experimental code, please verify this works ok
        
        statusBattery = ""
        imageBattery = nil
        
        if deviceHaveSenCharging { // With sensor of charging
            
            if poweredExternal { // Powered by USB or external
                
                statusBattery = "Ext"
                
            } else {
                
                statusBattery = "Bat"
                
            }
            
            if poweredExternal && chargingBattery { // Charging by USB or external
                
                imageBattery = #imageLiteral(resourceName: "charging")

                statusBattery += "|Chg"

            } else { // Not charging, process a voltage

                statusBattery += "|\(percent)%"
                
            }

            
        } else { //without sensor
            
            if (poweredExternal) { // Powered by USB or external
                
                imageBattery = #imageLiteral(resourceName: "battery7")
                statusBattery = "Ext"
                
            } else { // Not charging, process a voltage
                
                statusBattery = "\(percent)%"

            }
    
        }
        
        // show image of battery by voltage ?
        
        if imageBattery == nil {
            
            if voltageBattery >= 4.2 {
                imageBattery = #imageLiteral(resourceName: "battery6")
            } else if voltageBattery >= 3.9 {
                imageBattery = #imageLiteral(resourceName: "battery6")
            } else if voltageBattery >= 3.7 {
                imageBattery = #imageLiteral(resourceName: "battery5")
            } else if voltageBattery >= 3.5 {
                imageBattery = #imageLiteral(resourceName: "battery4")
            } else if voltageBattery >= 3.3 {
                imageBattery = #imageLiteral(resourceName: "battery3")
            } else if voltageBattery >= 3.0 {
                imageBattery = #imageLiteral(resourceName: "battery2")
            } else {
                imageBattery = #imageLiteral(resourceName: "battery1")
            }
        }
        
        // Show it
        
        showStatusBattery()
        
        // Battery low ?
        
        let low: Float = 3.1 // Experimental // TODO do setting

        if voltageBattery <= low &&
            (oldVoltage == 0.0 || oldVoltage > low) {
        
            Alert.alert("Attention: low battery on BLE device!", viewController: UtilUI.getRootViewController()!)
        }

    }

    // Process info messages
    
    func bleProcessInfo(fields: Fields) {
        
        // Example of process content delimited of message
        // Note: field 1 is a code of message
        
        // Is on informations screen ?
        // Note: example of show data in specific view controller
        
        guard let infoVC:InformationsViewController = navigationController?.topViewController as? InformationsViewController else {
            return
        }

        // Extract data
        
        let type: String = fields.getField(2)
        var info: String = fields.getField(3)
        
        debugV("type: \(type) info \(debugEscapedStr(info))")

        // Update UI
        
        DispatchQueue.main.async {

            // Process information by type
            
            switch type {
                
            case "ESP32":
                // About ESP32
                
                // Works with info (\n (message separator) and : (field separator) cannot be send by device
                info = info.replacingOccurrences(of: "#", with: "\n") // replace it
                info = info.replacingOccurrences(of: ";", with: ":") // replace it
#if !targetEnvironment(simulator) // Device real
                info.append("* RSSI of connection: ")
                info.append(String(self.ble.maxRSSIFound))
                info.append("\n")
#endif
                info.append("*** Device hardware")
                info.append("\n")
                info.append("* Have a battery ?: ")
                info.append(((self.deviceHaveBattery) ? "Yes" : "No"))
                info.append("\n")
                info.append("* Have sensor charging ?: ")
                info.append(((self.deviceHaveSenCharging) ? "Yes" : "No"))
                info.append("\n")
                
                infoVC.textViewAboutEsp32.text = info
                
            case "VDD33":
                // Voltage reading of ESP32 - Experimental code!
                // Calculate the voltage (done here note in firmware - due more easy to update)
                // TODO: see it! please caliber it first !
                // To caliber:
                //  - Unplug the USB cable (or energy cable)
                //  - Meter the voltage of 3V3 pin (or 2 pin of ESP32)
                //  - See the value of rom_phy_get_vdd33 read in monitor serial or in App informations
                
                let voltageCaliber: Float = 3.317
                let readPhyCaliber: Float = 6742
                let factorCaliber: Float = (voltageCaliber / readPhyCaliber)
                
                // Voltage readed from ADC
                
                let voltageEsp32: Float = Util.round((Float(info)! * factorCaliber), 2)
                
                infoVC.labelVoltageEsp32.text = "\(info) (\(voltageEsp32)v)"
                
            case "FMEM":
                // Free memory of ESP32
                infoVC.labelFreeMemory.text = info
                
                // VUSB and VBAT is by energy type message
                
            default:
                debugE("Invalid type: \(type)")
            }
        }
    }
    
    // Name of device connected

    func bleNameDeviceConnected () -> String {
        
#if !targetEnvironment(simulator) // Real device
        
        return (ble.connected) ? " Connected a \(ble.peripheralConnected?.name ?? "")" : "Not connected"

#else // Simulator
        
        return "simulator (not connected)"
        
#endif
    }
    
    ///////// BLE delegates
    
    func bleDidUpdateState(_ state: BLECentralManagerState) {
        
#if !targetEnvironment(simulator) // Real device
        
        // Verify status
        
        if state == BLECentralManagerState.poweredOn {
        
            let message = "Bluetooth is enable"
            
            debugW(message)
            
            if AppSettings.TERMINAL_BLE && self.bleDebugEnabled { // App have a Terminal BLE (debug) and it is enabled ?
                bleAddDebug(type: "O",  message: message) // Add debug
            }

            // Search devive
            
            bleScanDevice()
            
        } else {
            
            let message = "Bluetooth is disabled"
            
            debugW(message)
            
            if AppSettings.TERMINAL_BLE && self.bleDebugEnabled { // App have a Terminal BLE (debug) and it is enabled ?
                bleAddDebug(type: "O",  message: message) // Add debug
            }

            bleAbortConnection(message: "Please turn on the Bluetooth")
            
            // On connecting VC ?
            
            if let connectingVC:ConnectingViewController = navigationController?.topViewController as? ConnectingViewController {
                Alert.alert("Please turn on the Bluetooth", title:"Bluetooth is disabled", viewController: connectingVC)
            }
            
        }
#endif
    }
    
    // Timeout of BLE scan

    func bleDidTimeoutScan() {
        
#if !targetEnvironment(simulator) // Real device
        
        let message = "Could not connect to device"
        
        if AppSettings.TERMINAL_BLE && self.bleDebugEnabled { // App have a Terminal BLE (debug) and it is enabled ?
            bleAddDebug(type: "O",  message: message) // Add debug
        }

        bleAbortConnection(message: message)
        
 #endif
    }
    

    // Connecting

    func bleDidConnectingToPeripheral(_ name: String) {
        
#if !targetEnvironment(simulator) // Real device
        
        let message = "Found: \(name)"
        
        // On connecting VC ?
            
        if let connectingVC:ConnectingViewController = navigationController?.topViewController as? ConnectingViewController {
            connectingVC.labelMessage.text = message
        }
        
        if AppSettings.TERMINAL_BLE && self.bleDebugEnabled { // App have a Terminal BLE (debug) and it is enabled ?
            bleAddDebug(type: "C",  message: message) // Add debug
        }

#endif
    }

    // Connection successfully (after discoveries) 

    func bleDidConnectToPeripheral(_ name: String) {
        
#if !targetEnvironment(simulator) // Real device
        
        let message = "Connected a \(name)"
        
        // On connecting VC ?
        
        if let connectingVC:ConnectingViewController = navigationController?.topViewController as? ConnectingViewController {
            connectingVC.labelMessage.text = message
        }
        
        // Successful connection 
        
        if AppSettings.TERMINAL_BLE && self.bleDebugEnabled { // App have a Terminal BLE (debug) and it is enabled ?
            bleAddDebug(type: "C",  message: message) // Add debug
        }

        bleConnected()
        
#endif
        
    }

    // Received a data from device - not used 

    func bleDidReceiveData(data: String) {
    }
    
    // Received a line from device 

    func bleDidReceiveLine(line: String) {
        
#if !targetEnvironment(simulator) // Real device
       
        // Multithreading
        
        DispatchQueue.global().async {

            // Process the message
            
            // Is waiting a response ?
            
            if self.bleVerifyTimeout {
                
                self.showMessageStatus("")
                
                self.bleVerifyTimeout = false
                self.bleTimeout = AppSettings.BLE_TIMEOUT
                
            }
            
            // Restart time of feedback
            
            self.timeFeedback = 0
            
            // Occurs an error in device ?
            
            if line.starts(with: MessagesBLE.MESSAGE_ERROR) {
                
                self.bleUpdateDebug(extra: "Error")
                
                debugE("occurs error: \(line)")
                
                // Can abort or only show a message
                
                //bleAbortConnection(message: "Occurs a exception on device: " + line)
                
                // TODO: show a message
                
                return
                
            }
            
            // Process the message
            
            if AppSettings.TERMINAL_BLE && self.bleDebugEnabled { // App have a Terminal BLE (debug) and it is enabled ?
                self.bleAddDebug(type: "R",  message: line) // Add debug
            }
            
            self.bleProcessMessageRecv(line)
            
        }
#endif
        
    }
    
    // Disconnect 

    func bleDidDisconnectFromPeripheral() {
        
#if !targetEnvironment(simulator) // Real device
        
        let message = "Device disconnected (code B1)"
        
        if AppSettings.TERMINAL_BLE && self.bleDebugEnabled { // App have a Terminal BLE (debug) and it is enabled ?
            bleAddDebug(type: "D",  message: message) // Add debug
        }
        
        bleAbortConnection(message: message) // Abort
        
#endif
    }
    
    // Add Debug BLE
    
    func bleAddDebug (type: Character, message: String, extra: String = "", forced: Bool = false) {
        
        // App have a Terminal BLE (debug)
        
        if !(AppSettings.TERMINAL_BLE && (self.bleDebugEnabled || forced)) { // App have a Terminal BLE (debug) and it is enabled ?
            return
        }

        // Add debug
        
        let bleDebug = BLEDebug()
        
        // Time
        
        let date = Date()
        let calendar = Calendar.current
        
        let hour = calendar.component(.hour, from: date)
        let minutes = calendar.component(.minute, from: date)
        let seconds = calendar.component(.second, from: date)
        
        bleDebug.time = "\(String(format: "%02d",hour)):\(String(format: "%02d",minutes)):\(String(format: "%02d",seconds))"
        
        // Type
        
        bleDebug.type = type
        
        // Message
        
        bleDebug.message = message

        // Extra
        
        bleDebug.extra = extra

        // Add it
        
        if AppSettings.TERMINAL_BLE_ORDER_DESC { // Top

            bleDebugs.insert(bleDebug, at: 0)

        } else { // Bottom
            
            bleDebugs.append(bleDebug)
        }
        
        // In Terminal BLE VC ?
        
        if let terminalBLEVC:TerminalBLEViewController = navigationController?.topViewController
                as? TerminalBLEViewController {
        
            // Not for repeated sends - due can crash the app - in this case use refresh button
            
            if !terminalBLEVC.repeatSend || forced {
                
                // Insert row - reloadData is very slow and much CPU
                
                terminalBLEVC.insertRow()
            }
        }
    }

    // Update last Debug BLE
    
    func bleUpdateDebug (extra: String) {
        
        // App have a Terminal BLE (debug)
        
        if !(AppSettings.TERMINAL_BLE && self.bleDebugEnabled) { // App have a Terminal BLE (debug) and it is enabled ?
            return
        }

        // Update last debug
        
        if bleDebugs.count == 0 {
            return
        }

        let pos: Int = (AppSettings.TERMINAL_BLE_ORDER_DESC) ? 0 : bleDebugs.count-1
            
        let item = bleDebugs[pos]
        
        item.extra = extra
    
        // In Terminal BLE VC ?
        
        if let terminalBLEVC:TerminalBLEViewController = navigationController?.topViewController
            as? TerminalBLEViewController {
            
            // Update last row - reloadData is very slow and much CPU
            
            terminalBLEVC.updateLastRow()
        }
    }
    
    /////// Utilitarias
    
    func showMessageStatus(_ message:String) {
        
        // Show a message on statusbar
        
        var label:UILabel!
        
        // TODO: see it: Put all VC with statusbar here

        if let connectingVC = navigationController?.topViewController as? ConnectingViewController {
            label = connectingVC.labelMessage
        } else if let mainMenuVC = navigationController?.topViewController as? MainMenuViewController {
            label = mainMenuVC.labelStatus
        } else if let infoVC = navigationController?.topViewController as? InformationsViewController {
            label = infoVC.labelStatus
        } else if let terminalVC = navigationController?.topViewController as? TerminalBLEViewController {
            label = terminalVC.labelStatus
//        } else if let settingsVC = navigationController?.topViewController as? SettingsViewController {
//            label = settingsVC.labelStatus
        }
        
        if label != nil {
            
            // Update UI
            
            DispatchQueue.main.async {
                
                label.text = message
            }
            
        } else {
            
            debugV(message)
            
        }
    }

    // Initialize APP
    
    private func initializeApp () {
        
        // Initialize the app
        
        // Debug - set level
        
        debugSetLevel(.verbose)
        
        debugV("Initilializing ...")
                
        // BLE
        
    #if !targetEnvironment(simulator) // Real device
        
        ble.delegate = self
                                    // See it! please left only of 2 below lines uncommented
        ble.showDebug(.debug)       // Less debug of BLE, only essential
        //ble.showDebug(.verbose)   // More debug
        
    #else // Simulador
        
        self.versionDevice = "Simul."
        
    #endif
        
        // Inicializa variaveis
        
        initializeVariables()
        
        // Debug
        
        debugV("Initialized")
        
    }
    
    // Finish App
    
    func finishApp() {
        
        debugD("")
        
#if !targetEnvironment(simulator) // Device real

        // Send a message to device - to turn off or restart
        
        if ble.connected {
            
            var message: String = ""
            
            if AppSettings.TURN_OFF_DEVICE_ON_EXIT {
                message = MessagesBLE.MESSAGE_STANDBY
            } else {
                message = MessagesBLE.MESSAGE_RESTART
            }
            
            ble.send(message)
                
            sleep(1)
        }
#endif
    
        // Exit
    
        debugD("Exiting ...")
    
        exit (0)

    }
}

////// END
