//
// Created by ota42y on 2015/12/23.
// Copyright (c) 2015 ota42y. All rights reserved.
//

import Foundation
import CoreBluetooth

protocol BluetoothStateDelegate {
    func changeState(text: String)
}

class BluetoothConnector : NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    var centralManager: CBCentralManager?
    var device: CBPeripheral?
    var deletage: BluetoothStateDelegate?

    var cbuuid = CBUUID(string: "5B2D690E-2AD9-4243-8E33-77DFCF318383")

    func createManager(stateDelegate: BluetoothStateDelegate) {
        centralManager = CBCentralManager(delegate: self, queue: nil, options: nil)
        deletage = stateDelegate
    }

    func connectionStart() {
        if device == nil {
            NSLog("connection start")
            centralManager?.scanForPeripheralsWithServices([cbuuid], options: [CBCentralManagerScanOptionAllowDuplicatesKey:false])
        }
    }

    func centralManagerDidUpdateState(central: CBCentralManager) {
        print("state: \(central.state)")
    }

    func centralManager(central: CBCentralManager,
                        didDiscoverPeripheral peripheral: CBPeripheral,
                        advertisementData: [String : AnyObject],
                        RSSI: NSNumber!)
    {
        device = peripheral;
        device!.delegate = self;

        print("find!")
        NSLog("%@", peripheral)

        // 発見されたデバイスに接続
        if (peripheral.state != CBPeripheralState.Connected)
        {
            centralManager?.stopScan()
            centralManager?.connectPeripheral(device!, options: nil)
        }
    }

    func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
        if (error != nil) {
            deletage!.changeState("error \(error) and retry")
            connectionStart()
            return
        }

        if !(peripheral.services?.count > 0) {
            deletage!.changeState("no services and not retry...")
            return
        }

        let services = peripheral.services!
        deletage!.changeState("secvices found...")
    }

    func centralManager(central: CBCentralManager,
                        didConnectPeripheral peripheral: CBPeripheral)
    {
        deletage!.changeState("connected")

        device!.discoverServices([cbuuid])
    }

    func centralManager(central: CBCentralManager,
                        didFailToConnectPeripheral peripheral: CBPeripheral,
                        error: NSError?)
    {
        deletage!.changeState("faild...")
    }

    func centralManager(central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: NSError?){
        deletage!.changeState("disconnected and retry..")

        centralManager?.connectPeripheral(device!, options: nil)
    }

    func getRSSI() -> (rssi: Double, success: Bool) {
        if let d = device {
            if (d.state == CBPeripheralState.Connected) {
                d.readRSSI()

                if let rssiValue = d.RSSI {
                    let rssi = rssiValue.doubleValue
                    if  -0.1 < rssi && rssi < 0.1 { // if get 0, not success
                        return (-1, false)
                    }

                    return (rssi, true)
                }
            }
        }
        return (-1, false)
    }
}
