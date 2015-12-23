//
//  ViewController.swift
//  corona-clone-slave
//
//  Created by ota42y on 2015/12/23.
//  Copyright © 2015年 ota42y. All rights reserved.
//

import UIKit
import CoreBluetooth

class ViewController: UIViewController, CBPeripheralManagerDelegate {
    @IBOutlet weak var mainLabel: UILabel!
    
    var peripheralManager: CBPeripheralManager?
    var device: CBPeripheral?
    var service: CBMutableService?

    var BLUETOOTH_UUID = CBUUID(string: "8E89706B-B35B-4E2F-BE2E-E7E915DC3E56")
    var timer : NSTimer!

    override func viewDidLoad() {
        super.viewDidLoad()

        peripheralManager = CBPeripheralManager(delegate: self, queue: nil, options: nil)

        timer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: Selector("start"), userInfo: nil, repeats: true)
    }
    
    internal func start() {
        timer!.invalidate()
        peripheralManager?.startAdvertising([CBAdvertisementDataServiceUUIDsKey:[BLUETOOTH_UUID]])
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    internal func peripheralManagerDidUpdateState(peripheral: CBPeripheralManager) {
        if (peripheral.state == CBPeripheralManagerState.PoweredOn) {
            startService()
        }

        NSLog("state: \(peripheral.state)")
    }

    internal func startService() {
        mainLabel.text = "start"
        service = CBMutableService(type: BLUETOOTH_UUID, primary: true)
        peripheralManager?.addService(service!)
    }
}

