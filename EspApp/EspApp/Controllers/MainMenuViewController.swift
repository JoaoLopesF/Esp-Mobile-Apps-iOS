/* ***********
 * Project   : Esp-App-Mobile-iOS - App to connect a Esp32 device by BLE
 * Programmer: Joao Lopes
 * Module    : MainMenuViewController - VC for main menu
 * Comments  :
 * Versions  :
 * -------  --------    -------------------------
 * 0.1.0    08/08/18    First version
 **/

import UIKit

class MainMenuViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    ////// MainController instance
    
    private let mainController = MainController.getInstance()
    
    ////// Outlets
    
    @IBOutlet weak var tableViewMainMenu: UITableView!
    
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
    
    // Menu options array
    
    private var mainMenuOptions: [MenuOption] = []

    /////// Events
    
    // Did load
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Replace the back button with information labels on the connection
        
        let backButton = UIBarButtonItem(title: "", style: .plain, target: navigationController, action: nil)
        navigationItem.leftBarButtonItem = backButton
        
        // Show app and device versions
        
        let labelApp = UILabel()
        labelApp.text = "App....: \(mainController.versionApp)"
        labelApp.font = UIFont.systemFont(ofSize: 9)
        labelApp.sizeToFit ()
        
        let labelDispositivo = UILabel ()
        labelDispositivo.text = "Device: \(mainController.versionDevice)"
        labelDispositivo.font = UIFont.systemFont (ofSize: 9)
        labelDispositivo.sizeToFit ()
        
        let stackView = UIStackView(arrangedSubviews: [labelApp, labelDispositivo])
        stackView.distribution = .equalCentering
        stackView.axis = .vertical
        
        let width = max(labelApp.frame.size.width, labelDispositivo.frame.size.width)
        stackView.frame = CGRect(x: 0, y: 0, width: width, height: 25)
        
        labelApp.sizeToFit()
        labelDispositivo.sizeToFit()
        
        navigationItem.leftBarButtonItem?.customView = stackView
        
        // Displays a connection message
        
        self.extShowToast (message: "Connection made with device - firmware (\(mainController.versionDevice))")
        
        // Menu options
        
        // App have a Esp32 Informations enabled (debug) ?
        
        if AppSettings.ESP32_INFORMATIONS {
            
            self.mainMenuOptions.append(MenuOption(code: "INFO",
                                                   name: "Informations",
                                                   description: "Show informations about ESP32 connected device",
                                                   image: "info",
                                                   enabled: true))
        }
        
        // App have a Terminal BLE enabled (debug) ?
        
        if AppSettings.TERMINAL_BLE {
            
            self.mainMenuOptions.append(MenuOption(code: "TERMINAL",
                                                   name: "Terminal BLE",
                                                   description: "Terminal to see or send messages BLE",
                                                   image: "terminal",
                                                   enabled: true))
        }

        // AppSettings - remove it if you not need this

        self.mainMenuOptions.append(MenuOption(code: "SETTINGS",
                                               name: "Settings",
                                               description: "Settings of this app",
                                               image: "settings",
                                               enabled: false))

        // Arrow to table view
        
        self.tableViewMainMenu.delegate = self
        self.tableViewMainMenu.dataSource = self
            
        // Status
        
        self.labelStatus.text = mainController.bleNameDeviceConnected()
        
        mainController.showStatusBattery()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Event
        
        debugV("")
        
        // Refresh the screen
        
        mainController.showStatusBattery()
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        debugV("")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning ()
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    /////// TableView methods
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //debugV(self.mainMenuOptions.count)
        return self.mainMenuOptions.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") as! MainMenuCell
        
        let row = (indexPath as NSIndexPath).row
        
        let item = self.mainMenuOptions [row]
        
        debugV("code-> ", item.code)
        
        cell.imageViewImage.image = (item.enabled) ? UIImage (named: item.image): UtilUI.filterImageNoir (image: UIImage (named: item.image)!)
        
        cell.labelName.text = item.name
        cell.labelDescription.text = item.description
        
        if item.enabled {
            cell.labelName.textColor = UIColor.white
            cell.labelDescription.textColor = AppSettings.COLOR_DARKBLUE
            cell.startColor = UIColor(rgb: 0x3DABF6)
            cell.endColor = UIColor(rgb: 0xc6e1f2)
        } else {
            cell.labelName.textColor = UIColor.gray
            cell.labelDescription.textColor = AppSettings.COLOR_DARKGRAY
            cell.startColor = UIColor(rgb: 0xBEBEBE)
            cell.endColor = UIColor(rgb: 0xF5F5F5)
        }
            
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        // Get a menu option selected
        
        let row = (indexPath as NSIndexPath).row
        let item = self.mainMenuOptions [row]
        
        // Unmark row
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        // Validate the option
        
        if (!item.enabled) {
            
            return
        }

        // Process the menu option
        
        debugV("code of menu selected: \(item.code)")
        
        switch item.code {
            
        case "INFO":
            
            // Show informations
            
            showVCInformations()
            
        case "TERMINAL":
            
            // Show terminal BLE (debug)
            
            showVCTerminalBLE()

        case "SETTINGS":
            
            // Show settings
            
            showVCSettings()

        default:
            
            // Error - show a message

            self.extShowToast (message: "Invalid option - code \(item.code)")
            return

        }
        
    }
    
    ///// Routines
    
    func showVCInformations () {
        
        // Displays the informations VC

        debugV("")
        
        if let infoVC: InformationsViewController = mainController.storyBoardMain?.instantiateViewController(withIdentifier: "Informations") as? InformationsViewController {

            self.navigationController?.pushViewController(infoVC, animated: true)

        }
        
    }
    
    func showVCTerminalBLE () {
        
        // Displays the terminal BLE VC
        
        if let terminalBLEVC: TerminalBLEViewController = mainController.storyBoardMain?.instantiateViewController(withIdentifier: "TerminalBLE") as? TerminalBLEViewController {
        
                    self.navigationController?.pushViewController(terminalBLEVC, animated: true)
        
        }
        
    }
    
    func showVCSettings () {
        
        // Displays the informations VC
        
        //        if let menuBaixarVC: MenuBaixarViewController = mainController.storyBoardMain?.instantiateViewController(withIdentifier: "MenuBaixar") as? MenuBaixarViewController {
        //
        //            self.navigationController?.pushViewController(menuBaixarVC, animated: true)
        //
        //        }
        
    }
}

////// End
