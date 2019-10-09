//
//  BLEBrowserMainViewController.swift
//  BLEBrowser
//
//  Created by Backlin,Gene on 2/1/18.
//  Copyright © 2018 Backlin,Gene. All rights reserved.
//

import UIKit
import CoreBluetooth

class BLEBrowserMainViewController: UIViewController {
    @IBOutlet weak var identifierLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var stateLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var connectButton: UIBarButtonItem!
    
    var centralManager: CBCentralManager!
    let genericServiceCBUUID = CBUUID(string: "0x1800")
    var blePeripherals: [String : CBPeripheral] = [String : CBPeripheral]()
    var peripheralServices: [String : [String : CBService]] = [String : [String : CBService]]()
    var serviceCharacteristics: [String : [String : CBCharacteristic]] = [String : [String : CBCharacteristic]]()
    
    private let bleQueryTimeInterval: TimeInterval = 3.0
    private var bleQueryTimer: Timer?
    private var selectedPeripheral: CBPeripheral?
    
    // MARK: - View lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        centralManager = CBCentralManager(delegate: self, queue: nil)
        identifierLabel.text = "Scanning for devices..."
        nameLabel.text = ""
        stateLabel.text = ""
        connectButton.isEnabled = false
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    deinit {
        stopTimer()
    }
    
    // MARK: - Timers
    
    func startTimer() {
        weak var weakSelf = self
        bleQueryTimer = Timer.scheduledTimer(withTimeInterval: bleQueryTimeInterval, repeats: true, block: { (timer) in
            weakSelf!.refreshTableView()
        })
    }
    
    func stopTimer() {
        bleQueryTimer?.invalidate()
    }
    
    // MARK: - Selector methods
    
    func refreshTableView() {
        tableView.reloadData()
    }
    
    // MARK: - Utility
    
    func peripheralState(state: CBPeripheralState) -> String {
        switch state {
        case .disconnected:
            return "disconnected"
        case .connecting:
            return "connecting"
        case .connected:
            return "connected"
        case .disconnecting:
            return "disconnecting"
        @unknown default:
            return "unknown state"
        }
    }
    
    // MARK: - @IBAction methods
    
    @IBAction func connect(_ sender: UIButton) {
        weak var weakSelf = self
        
        let alertController = UIAlertController(title: nameLabel.text, message: nil, preferredStyle: .alert)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let OKAction = UIAlertAction(title: "Connect", style: .default) { action in
            DispatchQueue.main.async {
                print("connecting...")
                weakSelf!.textView.text = ""
                weakSelf!.stateLabel.text = "connecting..."
            }
            weakSelf!.centralManager.connect(weakSelf!.selectedPeripheral!, options: nil)
        }
        
        alertController.addAction(cancelAction)
        alertController.addAction(OKAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
}

// MARK: - UITableViewDataSource

extension BLEBrowserMainViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return blePeripherals.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let keys = Array(blePeripherals.keys).sorted()
        let key = keys[indexPath.row]
        let peripheral: CBPeripheral = blePeripherals[key]!
        
        // Configure the cell...
        cell.textLabel?.text = "\(String(describing: peripheral.name!))"
        cell.detailTextLabel?.text = "\(peripheral.identifier)"
        
        return cell
    }
    
}

// MARK: - UITableViewDelegate

extension BLEBrowserMainViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let keys = Array(blePeripherals.keys).sorted()
        let key = keys[indexPath.row]
        let peripheral: CBPeripheral = blePeripherals[key]!
        
        peripheral.delegate = self // CBPeripheralDelegate
        
        identifierLabel.text = "\(peripheral.identifier)"
        nameLabel.text = "\(String(describing: peripheral.name!))"
        stateLabel.text = peripheralState(state: peripheral.state)
        connectButton.isEnabled = true
        selectedPeripheral = peripheral
    }
}

/****************************************************************************************************
 Generic Access                     org.bluetooth.service.generic_access                0x1800    GSS
 Alert Notification Service         org.bluetooth.service.alert_notification            0x1811    GSS
 Automation IO                      org.bluetooth.service.automation_io                 0x1815    GSS
 Battery Service                    org.bluetooth.service.battery_service               0x180F    GSS
 Blood Pressure                     org.bluetooth.service.blood_pressure                0x1810    GSS
 Body Composition                   org.bluetooth.service.body_composition              0x181B    GSS
 Bond Management Service            org.bluetooth.service.bond_management               0x181E    GSS
 Continuous Glucose Monitoring      org.bluetooth.service.continuous_glucose_monitoring 0x181F    GSS
 Current Time Service               org.bluetooth.service.current_time                  0x1805    GSS
 Cycling Power                      org.bluetooth.service.cycling_power                 0x1818    GSS
 Cycling Speed and Cadence          org.bluetooth.service.cycling_speed_and_cadence     0x1816    GSS
 Device Information                 org.bluetooth.service.device_information            0x180A    GSS
 Environmental Sensing              org.bluetooth.service.environmental_sensing         0x181A    GSS
 Fitness Machine                    org.bluetooth.service.fitness_machine               0x1826    GSS
 Generic Attribute                  org.bluetooth.service.generic_attribute             0x1801    GSS
 Glucose                            org.bluetooth.service.glucose                       0x1808    GSS
 Health Thermometer                 org.bluetooth.service.health_thermometer            0x1809    GSS
 Heart Rate                         org.bluetooth.service.heart_rate                    0x180D    GSS
 HTTP Proxy                         org.bluetooth.service.http_proxy                    0x1823    GSS
 Human Interface Device             org.bluetooth.service.human_interface_device        0x1812    GSS
 Immediate Alert                    org.bluetooth.service.immediate_alert               0x1802    GSS
 Indoor Positioning                 org.bluetooth.service.indoor_positioning            0x1821    GSS
 Internet Protocol Support Service  org.bluetooth.service.internet_protocol_support     0x1820    GSS
 Link Loss                          org.bluetooth.service.link_loss                     0x1803    GSS
 Location and Navigation            org.bluetooth.service.location_and_navigation       0x1819    GSS
 Mesh Provisioning Service          org.bluetooth.service.mesh_provisioning             0x1827    GSS
 Mesh Proxy Service                 org.bluetooth.service.mesh_proxy                    0x1828    GSS
 Next DST Change Service            org.bluetooth.service.next_dst_change               0x1807    GSS
 Object Transfer Service            org.bluetooth.service.object_transfer               0x1825    GSS
 Phone Alert Status Service         org.bluetooth.service.phone_alert_status            0x180E    GSS
 Pulse Oximeter Service             org.bluetooth.service.pulse_oximeter                0x1822    GSS
 Reconnection Configuration         org.bluetooth.service.reconnection_configuration    0x1829    GSS
 Reference Time Update Service      org.bluetooth.service.reference_time_update         0x1806    GSS
 Running Speed and Cadence          org.bluetooth.service.running_speed_and_cadence     0x1814    GSS
 Scan Parameters                    org.bluetooth.service.scan_parameters               0x1813    GSS
 Transport Discovery                org.bluetooth.service.transport_discovery           0x1824    GSS
 Tx Power                           org.bluetooth.service.tx_power                      0x1804    GSS
 User Data                          org.bluetooth.service.user_data                     0x181C    GSS
 Weight Scale                       org.bluetooth.service.weight_scale                  0x181D    GSS
 ****************************************************************************************************/

// MARK: - CBCentralManagerDelegate

extension BLEBrowserMainViewController: CBCentralManagerDelegate {
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .unknown:
            stateLabel.text = "central.state is .unknown"
        case .resetting:
            stateLabel.text = "central.state is .resetting"
        case .unsupported:
            stateLabel.text = "central.state is .unsupported"
        case .unauthorized:
            stateLabel.text = "central.state is .unauthorized"
        case .poweredOff:
            stateLabel.text = "central.state is .poweredOff"
            stopTimer()
        case .poweredOn:
            stateLabel.text = "central.state is .poweredOn"
            centralManager.scanForPeripherals(withServices: nil, options: nil)
            startTimer()
        @unknown default:
            stateLabel.text = "central.state is .unknown"
        }
        
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        if let _: String = peripheral.name {
            let key = "\(peripheral.identifier)"
            blePeripherals[key] = peripheral
            if identifierLabel.text == "Scanning for devices..." {
                identifierLabel.text = ""
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        stateLabel.text = peripheralState(state: peripheral.state)
        print("\(String(describing: peripheral.name!)) didDisconnectPeripheral")
        stateLabel.text = "disconnected"
        connectButton.isEnabled = true
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        stateLabel.text = peripheralState(state: peripheral.state)
        print("\(String(describing: peripheral.name!)) didConnect")
        peripheral.discoverServices(nil)
        connectButton.isEnabled = false
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        stateLabel.text = peripheralState(state: peripheral.state)
        print("\(String(describing: peripheral.name!)) didFailToConnect")
        connectButton.isEnabled = true
    }
    
}

extension BLEBrowserMainViewController: CBPeripheralDelegate {
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else {
            return
        }
        
        peripheralServices.removeAll()
        serviceCharacteristics.removeAll()
        
        var servicesDict: [String : CBService] = [String : CBService]()
        
        for service in services {
            let serviceUUID = "\(service.uuid)"
            let key = "\(peripheral.identifier)"
            
            servicesDict[serviceUUID] = service
            peripheralServices[key] = servicesDict
            
            peripheral.discoverCharacteristics(nil, for: service)
        }
        
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else {
            return
        }
        var characteristicsDict: [String : CBCharacteristic] = [String : CBCharacteristic]()
        
        for characteristic in characteristics {
            let characteristicUUID = "\(characteristic.uuid)"
            let key = "\(service.uuid)"
            
            characteristicsDict[characteristicUUID] = characteristic
            serviceCharacteristics[key] = characteristicsDict
            
            if characteristic.properties.contains(.read) {
                textView.textStorage.append(NSAttributedString(string: "\(characteristic.uuid): prop contains .read\n"))
                peripheral.readValue(for: characteristic)
            }
            if characteristic.properties.contains(.notify) {
                textView.textStorage.append(NSAttributedString(string: "\(characteristic.uuid): prop contains .notify\n"))
            }
            if characteristic.properties.contains(.broadcast) {
                textView.textStorage.append(NSAttributedString(string: "\(characteristic.uuid): prop contains .broadcast\n"))
            }
            if characteristic.properties.contains(.write) {
                textView.textStorage.append(NSAttributedString(string: "\(characteristic.uuid): prop contains .write\n"))
            }
            if characteristic.properties.contains(.writeWithoutResponse) {
                textView.textStorage.append(NSAttributedString(string: "\(characteristic.uuid): prop contains .writeWithoutResponse\n"))
            }
            if characteristic.properties.contains(.indicate) {
                textView.textStorage.append(NSAttributedString(string: "\(characteristic.uuid): prop contains .indicate\n"))
            }
            if characteristic.properties.contains(.authenticatedSignedWrites) {
                textView.textStorage.append(NSAttributedString(string: "\(characteristic.uuid): prop contains .authenticatedSignedWrites\n"))
            }
            if characteristic.properties.contains(.extendedProperties) {
                textView.textStorage.append(NSAttributedString(string: "\(characteristic.uuid): prop contains .extendedProperties\n"))
            }
            if characteristic.properties.contains(.notifyEncryptionRequired) {
                textView.textStorage.append(NSAttributedString(string: "\(characteristic.uuid): prop contains .notifyEncryptionRequired\n"))
            }
            if characteristic.properties.contains(.indicateEncryptionRequired) {
                textView.textStorage.append(NSAttributedString(string: "\(characteristic.uuid): prop contains .indicateEncryptionRequired\n"))
            }
        }
        
        textView.textStorage.append(NSAttributedString(string: "\n"))
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        
        let uuid = "\(characteristic.uuid)"
        if let value: Data = characteristic.value {
            if let stringValue = String(data: value, encoding: String.Encoding.utf8) {
                textView.textStorage.append(NSAttributedString(string: "char: \(String(describing: uuid)) - value: [\(stringValue)] "))
            } else {
                textView.textStorage.append(NSAttributedString(string: "char: \(uuid) - value: no value "))
            }
        } else {
            textView.textStorage.append(NSAttributedString(string: "char: \(uuid) - value: no value "))
        }
        
        textView.textStorage.append(NSAttributedString(string: "\n"))
        
        let lastLine = NSMakeRange(textView.text.count - 1, 1)
        textView.scrollRangeToVisible(lastLine)
    }
    
}

