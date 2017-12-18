//
//  ViewController.swift
//  BLEScanner
//
//  Created by Sergio Cabrero Barros on 18/12/2017.
//  Copyright © 2017 Sergio Cabrero Barros. All rights reserved.
//

import UIKit
import CoreBluetooth

class ViewController: UIViewController, CBCentralManagerDelegate {
    var centralManager:CBCentralManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        centralManager = CBCentralManager(delegate: self,
                                          queue: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
  
    
    // Invoked when the central manager’s state is updated.
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            print("Scanning for Advertisements")
            centralManager.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
        }
        else{
            let alert = UIAlertController(title: "BLE", message: "Bluetooth is not activated in this device, turn it on", preferredStyle: UIAlertControllerStyle.alert)
            let action = UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: nil)
            alert.addAction(action)
            self.show(alert, sender: self)
        }
    }
    
    
    /*
     Invoked when the central manager discovers a peripheral while scanning.
     */

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber)
    {
        //print(advertisementData)
//        print("-")
        if let manufacturerData = advertisementData[CBAdvertisementDataManufacturerDataKey] as? NSData{

            let companyId:UInt16 = UInt16(littleEndian: manufacturerData.subdata(with: NSRange(location: 0, length:2)).withUnsafeBytes { $0.pointee })
          //  let companyId:Data = manufacturerData.subdata(with: NSRange(location: 0, length:2))

            if companyId == 0x015d {
                 // Nearable id bytes 3–10 (8 bytes total)
                let nearableId:Data = manufacturerData.subdata(with: NSRange(location: 3, length:8))

                // byte 13 and the first 4 bits of byte 14 is the temperature in signed,
                // fixed-point format, with 4 decimal places
                var temperatureRawValue: Int16 = manufacturerData.subdata(with: NSRange(location: 13, length:2)).withUnsafeBytes { $0.pointee & 0x0fff }

                if (temperatureRawValue > 2047) {
                    // convert a 12-bit unsigned integer to a signed one
                    temperatureRawValue = temperatureRawValue - 4096
                }
                temperatureRawValue = temperatureRawValue/16
                print("\(nearableId as NSData) --- Temperature: \(temperatureRawValue)")
            }
    }

}
}
