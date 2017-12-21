//
//  ViewController.swift
//  BLEScanner
//
//  Created by Sergio Cabrero Barros on 18/12/2017.
//  Copyright © 2017 Sergio Cabrero Barros. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    var BLEscanner: NearableScanner!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        BLEscanner = NearableScanner(bleOffHandler: bleOffHandler)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
  
    // What to say to the user if BLE is not available
    func bleOffHandler(){
        showOkAlertMessage(title: "BLE", message: "Bluetooth is not activated in this device, turn it on")
    }
  
    func showOkAlertMessage(title:String, message:String)
    {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        let action = UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: nil)
        alert.addAction(action)
        self.show(alert, sender: self)
    }
  

}
