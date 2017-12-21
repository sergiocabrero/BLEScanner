//
//  BLEScanner.swift
//  BLEScanner
//
//  Created by Sergio Cabrero Barros on 19/12/2017.
//  Copyright © 2017 Sergio Cabrero Barros. All rights reserved.
//
import CoreBluetooth
import UIKit

struct Acceleration{
    var x, y, z: Double
    var magnitude: Double {
        return sqrt(pow(x,2)+pow(y,2)+pow(z,2))
    }
}

struct MotionDuration{
    var unit: String
    var number: UInt8
    var describe: String {
        return String(number) + " " + unit
    }
}

// Extend Data to generate hex Strings from bytes: https://stackoverflow.com/questions/39075043/how-to-convert-data-to-hex-string-in-swift
extension Data {
    func hexEncodedString() -> String {
        return map { String(format: "%02hhx", $0) }.joined()
    }
}

// Reimplements JS code from Estimote in: https://github.com/Estimote/estimote-specs/blob/master/estimote-nearable.js
class NearableData{
    let companyId: UInt16 = 0x015d
    let frameType: UInt8 = 0x01

    var nearableId: String!
    var temperature: Double!
    var isMoving: Bool!
    var acceleration: Acceleration!
    var previousMotionStateDuration: MotionDuration!
    var currentMotionStateDuration: MotionDuration!
    var asString: String {
        return "nearableId: \(nearableId), temperature: \(temperature), isMoving: \(isMoving), Acc: \(acceleration), motion duration: \(previousMotionStateDuration.describe),\(currentMotionStateDuration.describe)"
    }
    
    init?(data: NSData){
        // *** Check Nearable
        let dataCompanyId = data.bytes.load(fromByteOffset: 0, as: UInt16.self)
        let dataFrameType = data.bytes.load(fromByteOffset: 2, as: UInt8.self)
        if dataCompanyId != companyId || dataFrameType != frameType || data.length != 22 {
            return nil  // not a Nearable
        }

        // *** Nearable id bytes 3–10 (8 bytes total)
        nearableId = data.subdata(with: NSRange(3...10)).hexEncodedString()
        
        // *** Temperature
        // byte 13 and the first 4 bits of byte 14 is the temperature in signed, fixed-point format, with 4 decimal places
        var temperatureRawValue = Int16(data.subdata(with: NSRange(13...14)).withUnsafeBytes { $0.pointee & 0x0fff})
        if (temperatureRawValue > 2047) {
            // convert a 12-bit unsigned integer to a signed one
            temperatureRawValue = temperatureRawValue - 4096
        }
        self.temperature = Double(temperatureRawValue)/16.0

        // *** Acceleration
        // byte 16 => acceleration RAW_VALUE on the X axis
        // byte 17 => acceleration RAW_VALUE on the Y axis
        // byte 18 => acceleration RAW_VALUE on the Z axis
        // RAW_VALUE is a signed (two's complement) 8-bit integer
        // RAW_VALUE * 15.625 = acceleration in milli-"g-unit" (http://www.helmets.org/g.htm)
        let ax = 15.625 * Double(data.bytes.load(fromByteOffset: 16, as: Int8.self))
        let ay = 15.625 * Double(data.bytes.load(fromByteOffset: 17, as: Int8.self))
        let az = 15.625 * Double(data.bytes.load(fromByteOffset: 18, as: Int8.self))
        acceleration = Acceleration(x: ax, y: ay, z: az)

        // *** isMoving: byte 15, 7th bit = is the nearable moving or not
        isMoving = ((data.bytes.load(fromByteOffset: 15, as: UInt8.self) & 0b01000000) > 0)

        // *** MotionStateDuration
        // ***** MOTION STATE DURATION
        // byte 19 => "current" motion state duration
        // byte 20 => "previous" motion state duration
        // e.g., if the beacon is currently still, "current" will state how long
        // it's been still and "previous" will state how long it's previously been
        // in motion before it stopped moving
        //
        // motion state duration is composed of two parts:
        // - lower 6 bits is a NUMBER (unsigned 6-bit integer)
        // - upper 2 bits is a unit:
        //     - 0b00 ("0") => seconds
        //     - 0b01 ("1") => minutes
        //     - 0b10 ("2") => hours
        //     - 0b11 ("3") => days if NUMBER is < 32
        //                     if it's >= 32, then it's "NUMBER - 32" weeks
        previousMotionStateDuration = parseMotionStateDuration(data.bytes.load(fromByteOffset: 20, as: UInt8.self))
        currentMotionStateDuration = parseMotionStateDuration(data.bytes.load(fromByteOffset: 20, as: UInt8.self))

    }
    
    private func parseMotionStateDuration(_ byte: UInt8) -> MotionDuration{
        var number = byte & 0b00111111
        let unitCode = (byte & 0b11000000) >> 6
        let unit: String
        if (unitCode == 0) {
            unit = "seconds"
        } else if (unitCode == 1) {
            unit = "minutes"
        } else if (unitCode == 2) {
            unit = "hours"
        } else if (unitCode == 3 && number < 32) {
            unit = "days"
        } else {
            unit = "weeks"
            number = number - 32
        }
        return MotionDuration(unit: unit, number: number)
        
    }
}

class NearableScanner: NSObject, CBCentralManagerDelegate {
    var centralManager:CBCentralManager!
    var offHandler: () -> Void = {}

    init(bleOffHandler: @escaping () -> Void){
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
        self.offHandler = bleOffHandler
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            print("Scanning for Advertisements")
            centralManager.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
        }
        else{
            self.offHandler()
        }
    }
    
    /* Receives advertisements */
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber)
    {
        //print(advertisementData)
        if let manufacturerData = advertisementData[CBAdvertisementDataManufacturerDataKey] as? NSData{
            if let nearablePacket = NearableData(data: manufacturerData){
                print(nearablePacket.asString)
            }
        }
    }
}
