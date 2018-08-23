/* ***********
 * Project   : Esp-App-Mobile-iOS - App to connect a Esp32 device by BLE
 * Programmer: Joao Lopes
 * Module    : Util - BLE
 * Comments  : Based in codes of Adafruit (Nordic based) - https://github.com/adafruit/Bluefruit_LE_Connect
 * Versions  :
 * -------   --------     -------------------------
 * 0.1.0     08/08/18     First version
 **/
 
////// BLE - Bluetooh Low Energy for connect to ESP32

import Foundation
import CoreBluetooth
import UIKit

// Protocol

protocol BLEDelegate {
    func bleDidUpdateState(_ state: BLECentralManagerState)
    func bleDidTimeoutScan()
    func bleDidConnectingToPeripheral(_ name: String)
    func bleDidConnectToPeripheral(_ name: String)
    func bleDidReceiveData(data: String)
    func bleDidReceiveLine(line: String)
    func bleDidDisconnectFromPeripheral()
}

// Central Manager State (to isolate CoreBluetooth)

enum BLECentralManagerState {
    case poweredOff, poweredOn, resetting, unauthorized, unknown, unsupported
}

// BLE

class BLE: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    // Variaveis
    
    private (set) var centralManager : CBCentralManager! // Core Bluetooth
    
    private let serviceUUID =           CBUUID(string: "6e400001-b5a3-f393-e0a9-e50e24dcca9e") // ESP32 UART Service
    private let characteristicUUIDTx =  CBUUID(string: "6e400002-b5a3-f393-e0a9-e50e24dcca9e") // ESP32 UART TX (Property = Write without response)
    private let characteristicUUIDRx =  CBUUID(string: "6e400003-b5a3-f393-e0a9-e50e24dcca9e") // ESP32 UART RX (Property = Read/Notify)
    
    private var characteristicTX : CBCharacteristic? // ESP32 TX
    private var characteristicRX : CBCharacteristic? // ESP32 RX
    
    private var timerScanTimeout: Timer = Timer() // Timeout of scan
    private (set) var maxRSSIFound:Int = 0 // To found closer device
    
    private var peripheralStartName:String = "" // Device name to scan
    private (set) var lastPeripheralConnected: String = "" // Last name of device conected
    
    private var peripheralScanned: CBPeripheral? // Peripheral scanned

    private (set) var connected = false // Connection complished ?
    
    private (set) var peripheralConnected: CBPeripheral? = nil // Peripheral connected
    
    private var lastTimeReceived: Int64 = 0 // Time of received data
    private var bufferReceived: String = "" // To store line (to append messages - due limit of BLE)
    
    private var debugLevelBle: debugLevel? = nil
    
    private (set) var sendingNow: Bool = false // Sending now ?
    
    private let BLE_TIMEOUT_RECV: Int = 2000 // Timeout of receive part of messages (avoid dirty ones)
    
    // Delegate
    
    var delegate: BLEDelegate?
    
    /// Save the single instance
    
    static private var instance : BLE {
        return sharedInstance
    }
    
    private static let sharedInstance = BLE()
    
    // Init
    
    override init() {
        super.init()
        
#if !targetEnvironment(simulator) // Device real

        // CB Central Manager
    
        self.centralManager = CBCentralManager(delegate: self, queue: nil, options: [CBCentralManagerOptionShowPowerAlertKey: "1"])
    
        //self.data = NSMutableData()
    
        // Last device connected
    
        self.lastPeripheralConnected = UserDefaults.standard.string(forKey: "bleLastPeripheralConnected") ?? ""

#else // Simulator
        
        self.connected = true
        
#endif
        
    }
    
    /**
     Singleton pattern method
     
     - returns: BLE single instance
     */
    static func getInstance() -> BLE {
        return self.instance
    }
    
    /////// Core Bluetooth Delegates
    
    /*
     Invoked when the central manager’s state is updated.
     This is where we kick off the scan if Bluetooth is turned on.
     */
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        var state: BLECentralManagerState
        switch central.state {
        case .poweredOff:
            state = BLECentralManagerState.poweredOff
            if debugBle(.verbose) {
                debugV("State : Powered Off")
            }
        case .poweredOn:
            state = BLECentralManagerState.poweredOn
            if debugBle(.verbose) {
                debugV("State : Powered On")
            }
        case .resetting:
            state = BLECentralManagerState.resetting
            if debugBle(.verbose) {
                debugV("State : Resetting")
            }
        case .unauthorized:
            state = BLECentralManagerState.unauthorized
            if debugBle(.verbose) {
                debugV("State : Unauthorized")
            }
        case .unknown:
            state = BLECentralManagerState.unknown
            if debugBle(.verbose) {
                debugV("State : Unknown")
            }
        case .unsupported:
            state = BLECentralManagerState.unsupported
            if debugBle(.verbose) {
                debugV("State : Unsupported")
            }
        }
        
        // Clear variables
        
        self.maxRSSIFound = 0
        self.bufferReceived = ""
        self.lastTimeReceived = 0
        self.peripheralStartName = ""
        
        self.peripheralScanned = nil
        self.peripheralConnected = nil
        self.connected = false
        
        // Delegate
        
        delegate?.bleDidUpdateState(state)
        
    }
    
    /*
     Called when the central manager discovers a peripheral while scanning. Also, once peripheral is connected, cancel scanning.
     */
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        if (peripheral.name?.starts(with: peripheralStartName))! {
            
            if debugBle(.verbose) {
                debugV("name -> \(peripheral.name ?? "")", function: "didDiscover")
            }
            
            // Last device connected found ? (faster, not waiting end of scan)
            
            if peripheral.name == self.lastPeripheralConnected {
                
                // Save RSSI
                
                self.maxRSSIFound = RSSI.intValue
                
                // Stop timer
                
                self.timerScanTimeout.invalidate()
                
                // Stop scan
                
                centralManager?.stopScan()
                
                // Connect
                
                connectPeripheral(peripheral)
                
            } else if RSSI.intValue > self.maxRSSIFound {
                
                // Closer device
                
                peripheralScanned = peripheral
                self.maxRSSIFound = RSSI.intValue
            }
        }
    }
    
    /*
     Invoked when a connection is successfully created with a peripheral.
     This method is invoked when a call to connect(_:options:) is successful. You typically implement this method to set the peripheral’s delegate and to discover its services.
     */
    //-Connected
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        
        if debugBle(.verbose) {
            debugV("Peripheral -> \(peripheral.name ?? ""))", function: "didConnect")
        }
        
        // Save last device connected
        
        if peripheral.name != self.lastPeripheralConnected {
            UserDefaults.standard.set(peripheral.name, forKey: "bleLastPeripheralConnected")
        }
        
        //Stop Scan- We don't need to scan once we've connected to a peripheral. We got what we came for.
        
        centralManager?.stopScan()
        
        if debugBle(.verbose) {
            debugV("Scan Stopped", function: "didConnect")
        }
        
        //Discovery callback
        
        peripheral.delegate = self
        
        //Only look for services that matches transmit uuid
        
        peripheral.discoverServices([serviceUUID])
        
        // Delegate
        
        delegate?.bleDidConnectingToPeripheral(peripheral.name!)
        
    }
    
    /*
     Invoked when the central manager fails to create a connection with a peripheral.
     */
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        if error != nil {
            debugE("Failed to connect to peripheral", function: "didFailToConnect")
            return
        }
        
        peripheralConnected = nil
        connected = false
        
        // Delegate
        
        delegate?.bleDidDisconnectFromPeripheral()
        
    }
    
    /*
     Invoked when you discover the peripheral’s available services.
     This method is invoked when your app calls the discoverServices(_:) method. If the services of the peripheral are successfully discovered, you can access them through the peripheral’s services property. If successful, the error parameter is nil. If unsuccessful, the error parameter returns the cause of the failure.
     */
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        
        if ((error) != nil) {
            debugE("Error discovering services: \(error!.localizedDescription)", function: "didDiscoverServices")
            return
        }
        
        guard let services = peripheral.services else {
            return
        }
        //We need to discover the all characteristic
        for service in services {
            
            peripheral.discoverCharacteristics(nil, for: service)
            // bleService = service
        }
        if debugBle(.verbose) {
            debugV("Discovered Services: \(services)", function: "didDiscoverServices")
        }
    }
    
    /*
     Invoked when you discover the characteristics of a specified service.
     This method is invoked when your app calls the discoverCharacteristics(_:for:) method. If the characteristics of the specified service are successfully discovered, you can access them through the service's characteristics property. If successful, the error parameter is nil. If unsuccessful, the error parameter returns the cause of the failure.
     */
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        
        if ((error) != nil) {
            debugE("Error discovering services: \(error!.localizedDescription)", function: "didDiscoverCharacteristicsFor")
            return
        }
        
        guard let characteristics = service.characteristics else {
            return
        }
        
        if debugBle(.verbose) {
            debugV("Found \(characteristics.count) characteristics!", function: "didDiscoverCharacteristicsFor")
        }
        
        for characteristic in characteristics {
            //looks for the right characteristic
            
            if characteristic.uuid.isEqual(characteristicUUIDRx)  {
                
                // RX
                
                characteristicRX = characteristic
                
                //Once found, subscribe to the this particular characteristic...
                peripheral.setNotifyValue(true, for: characteristicRX!)
                // We can return after calling CBPeripheral.setNotifyValue because CBPeripheralDelegate's
                // didUpdateNotificationStateForCharacteristic method will be called automatically
                peripheral.readValue(for: characteristic)
                if debugBle(.verbose) {
                    debugV("Rx Characteristic: \(characteristic.uuid)", function: "didDiscoverCharacteristicsFor")
                }
            }
            if characteristic.uuid.isEqual(characteristicUUIDTx){
                
                // TX
                
                characteristicTX = characteristic
                if debugBle(.verbose) {
                    debugV("Tx Characteristic: \(characteristic.uuid)", function: "didDiscoverCharacteristicsFor")
                }
            }
            peripheral.discoverDescriptors(for: characteristic)
            
        }
        
        // Finish connection (after discoveries)
        
        connected = true
        
        if debugBle(.debug) {
            debugD("Connection sucessfull to device: \(peripheral.name ?? "")", function: "didDiscoverCharacteristicsFor")
        }
        
        // Delegate
        
        delegate?.bleDidConnectToPeripheral(peripheral.name!)
        
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: Error?) {
        
        if error != nil {
            debugE("error -> \(error.debugDescription)", function: "didDiscoverDescriptorsFor")
            return
        }
        
        //        if debugBle(.verbose) { debugV("", function:"didDiscoverDescriptorsFor") }
        
        //        if ((characteristic.descriptors) != nil) {
        //
        //            for x in characteristic.descriptors!{
        //                let descript = x as CBDescriptor!
        //                if debugBle(.verbose) { debugV("function name: DidDiscoverDescriptorForChar \(String(describing: descript?.description))")
        //                if debugBle(.verbose) { debugV("Rx Value \(String(describing: bleRxCharacteristic?.value))")
        //                if debugBle(.verbose) { debugV("Tx Value \(String(describing: bleTxCharacteristic?.value))")
        //            }
        //        }
        
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        
        if (error != nil) {
            debugE("Error changing notification state:\(String(describing: error?.localizedDescription))", function: "didUpdateNotificationStateFor")
            
        } else {
            if debugBle(.verbose) {
                debugV("Characteristic's value subscribed", function: "didUpdateNotificationStateFor")
            }
        }
        
        if (characteristic.isNotifying) {
            if debugBle(.verbose) {
                debugV ("Subscribed. Notification has begun for: \(characteristic.uuid)", function: "didUpdateNotificationStateFor")
            }
        }
        
    }
    
    // Getting Values From Characteristic
    
    /*After you've found a characteristic of a service that you are interested in, you can read the characteristic's value by calling the peripheral "readValueForCharacteristic" method within the "didDiscoverCharacteristicsFor service" delegate.
     */
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        
        if characteristic == characteristicRX {
            
            if let value:String = NSString(data: characteristic.value!, encoding: String.Encoding.utf8.rawValue) as String? {
                
                // Dirty message ? First message can be a dirty with a lot of \0
                
                let dirty = (value.extIndexOf("\0") >= 0)
                
                // Recevied data
                
                if !dirty {
                    if debugBle(.verbose) { // Debug unicodes (to show hidden chars)
                        debugV("Value recevied [\(value.count)]: \(debugEscapedStr(value as String))", function: "didUpdateValueFor")
                    }
                }
                
                // Dirty ?
                
                if dirty {
                    
                    let show = "\(debugEscapedStr(value.extSubstring(0, 20))) ..."
 
                    debugV("data discarded: \(show)")
                    
                } else { // Good data
                    
                    // Delegate
                    
                    delegate?.bleDidReceiveData(data: value)
                    
                    // Process data
                    
                    // Verify timeout (to discart dirt buffer)
                    
                    let currentTimeInMiliseconds = Int64(Date().timeIntervalSince1970 * 1000)
                    
                    if bufferReceived.count > 0 &&
                        lastTimeReceived > 0 &&
                        (currentTimeInMiliseconds - lastTimeReceived) > BLE_TIMEOUT_RECV {
                        bufferReceived = ""
                    }
                    lastTimeReceived = currentTimeInMiliseconds
                    
                    // Process data
                    
                    for char in value {
                        
                        if char == "\n" { // Received a line
                            
                            if debugBle(.debug) {
//                                debugD("Line Received:", bufferReceived, function: "didUpdateValueFor")
                                debugD("Line received [\(value.count)]: \(debugEscapedStr(bufferReceived))", function: "didUpdateValueFor")
                            }
                            
                            // Delegate
                            
                            delegate?.bleDidReceiveLine(line: bufferReceived)
                            
                            // Clear it
                            
                            bufferReceived = ""
                            
                        } else {
                            
                            bufferReceived.append(char)
                            
                        }
                    }
                }
            }
        }
    }
    
    // Disconnect
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        
        if debugBle(.verbose) {
            debugV("Disconnected", function: "didDisconnectPeripheral")
        }
        
        // Clear
        
        self.peripheralConnected = nil
        self.connected = false
        
        // Delegate
        
        delegate?.bleDidDisconnectFromPeripheral()
        
    }
    
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil else {
            debugE("Error discovering services: error")
            return
        }
        //        if debugBle(.verbose) { debugV("Message sent", function: "didWriteValueFor") }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor descriptor: CBDescriptor, error: Error?) {
        guard error == nil else {
            debugE("Error discovering services: error", function: "didWriteValueFor")
            return
        }
        //        if debugBle(.verbose) { debugV("Succeeded!") }
    }
    
    /////////// Public routines
    
    // Start an scan
    
    func startScan(_ peripheralStartName: String = "", scanTimeOut:Double = 17) {
        
        // Peripheral
        
        peripheralScanned = nil
        peripheralConnected = nil
        connected = false
        
        // Name
        
        self.peripheralStartName = peripheralStartName
        
        // Last
        
        if peripheralStartName == "" || !lastPeripheralConnected.starts(with: peripheralStartName) {
            self.lastPeripheralConnected = ""
        }
        
        // Max RSSI
        
        self.maxRSSIFound = -999
        
        if debugBle(.verbose) {
            debugV("init the scan (by name -> \(peripheralStartName))")
        }
        
        // Scan
        
        self.timerScanTimeout.invalidate()
        self.centralManager?.scanForPeripherals(withServices: nil , options: [CBCentralManagerScanOptionAllowDuplicatesKey:false])
        self.timerScanTimeout = Timer.scheduledTimer(timeInterval: scanTimeOut, target: self, selector: #selector(self.timeoutScan), userInfo: nil, repeats: false)
    }
    
    // Stop scan (by timeout or code)
    
    func stopScan() {
        
        self.centralManager?.stopScan()
        
        self.timerScanTimeout.invalidate()
        
        if debugBle(.verbose) {
            debugV("Scan Stopped")
        }
        
    }
    
    // Stop scan by timeout
    
    @objc private func timeoutScan() {
        
        self.centralManager?.stopScan()
        
        if debugBle(.verbose) {
            debugV("Scan Stopped by timeout")
        }
        
        // Device found  ?
        
        if peripheralScanned != nil {
            
            // Connect to device
            
            connectPeripheral(peripheralScanned!)
            
        } else {
            
            // Scan not success -> timeout
            
            if debugBle(.verbose) {
                debugV("not find -> timeout")
            }
            
            // Delegate
            
            delegate?.bleDidTimeoutScan()
            
        }
        
    }
    
    // Connect to device
    
    private func connectPeripheral(_ peripheral: CBPeripheral) {
        
        // Connect
        
        //        bleScanPeripheral?.delegate = self
        //
        peripheralConnected = peripheral
        connected = false
        peripheralScanned = nil
        
        peripheralConnected?.delegate = self
        
        if debugBle(.verbose) {
            debugV ("connecting to ->  \(peripheralConnected?.name ?? "")")
        }
        
        self.centralManager?.connect(peripheralConnected!, options: nil)
        
    }

//    func restoreCentralManager() {
//        //Restores Central Manager delegate if something went wrong
//        centralManager?.delegate = self
//    }
    
    // Disconnect
    
    func disconnectPeripheral() {
        
        // Connected ?
        
        if peripheralConnected != nil { // Not use connected variable, why this is setted only after discoveries
            
            centralManager.cancelPeripheralConnection(peripheralConnected!)
            
        } else { // Not connected
            
            if timerScanTimeout.isValid { // Scanning
                
                // Stop scan
                
                stopScan()
            }
        }
        
        // Clear it now
        
        connected = false
        peripheralConnected = nil
        peripheralScanned = nil
            
    }

    // Send data to BLE peripheral, respecting limit of BLE, spliting it if necessary
    
    func send(_ message: String) {
        
        // Connected ?
        
        if !self.connected {
            debugE("not connected!")
            return
        }
        
        // Not sending ?
        
        if sendingNow { // Not allowed this
            debugE("Still sending now - not allowed")
            return
        }
        
        // Message to send
        
        var data = message
        
        // Verify if have a new line (to indicate end of message
        
        if !data.hasSuffix("\n") {
            
            data.append("\n")
            
        }
        
        // Send it
        
        sendingNow = true // Indicates it
        
        if debugBle(.debug) {
            debugD ("data send-> \(debugExpandStr(data)) size->\(data.count)")
        }
        
        var size: Int = 0
        var send: String = ""
        
        for char in data {
            
            send.append(char)
            size+=1
            
            if (size >= 22) {
                
                sendData(data: send)
                
                send = ""
                size = 0
            }
        }
        
        if size > 0 {
            
            sendData(data: send)
            
        }
        
        sendingNow = false
    }
    
    // Send data
    
    private func sendData(data: String){
        
        if debugBle(.verbose) {
            debugV ("data->\(debugExpandStr(data)) size->\(data.count)")
        }
        
        let send = (data as NSString).data(using: String.Encoding.utf8.rawValue)
        
        if let blePeripheral = peripheralConnected {
            if let txCharacteristic = characteristicTX {
                
                blePeripheral.writeValue(send!, for: txCharacteristic, type: CBCharacteristicWriteType.withResponse)
            }
        }
    }
    
    // Debug
    
    func showDebug (_ level:debugLevel) {
        
        self.debugLevelBle = level
        
        if debugLevelBle != nil {
            debugA("Debug BLE is ON (\(debugShowLevel(debugLevelBle!)))")
        }
    }
    
    private func debugBle(_ level:debugLevel)  -> Bool {
        
        return self.debugLevelBle != nil && (self.debugLevelBle?.rawValue)! <= level.rawValue
    }
}


//////// End
