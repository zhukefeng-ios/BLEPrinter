//
//  IBoxpayBTUtil.h
//  IBoxpayBTDemo
//
//  Created by ZKF on 13-8-23.
//  Copyright (c) 2013年 朱克锋. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

@protocol IBoxpayBTUtilDelegate <NSObject>
@required

- (void)peripheralDidWriteChracteristic:(CBCharacteristic *)characteristic
                         withPeripheral:(CBPeripheral *)peripheral
                              withError:(NSError *)error;

- (void)peripheralDidReadChracteristic:(CBCharacteristic *)characteristic
                        withPeripheral:(CBPeripheral *)peripheral
                             withError:(NSError *)error;

@optional
- (void)centralManager:(CBCentralManager *)central didRetrievePeripherals:(NSArray *)peripherals;
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral;
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error;

- (void)hardwareDidNotifyBehaviourOnCharacteristic:(CBCharacteristic *)characteristic
                                    withPeripheral:(CBPeripheral *)peripheral
                                             error:(NSError *)error;


@end

typedef enum
{
    BLUETOOTH_STATUS_DISCONNECTED = 0,
    BLUETOOTH_STATUS_FAIL_TO_CONNECT = 1,
    BLUETOOTH_STATUS_CONNECTED = 2
}BLUETOOTH_STATUS;

typedef void (^eventHardwareBlock)(CBPeripheral *peripheral, BLUETOOTH_STATUS status, NSError *error);

@interface IBoxpayBTUtil : NSObject <CBCentralManagerDelegate, CBPeripheralDelegate>
{
    NSMutableArray *dicoveredPeripherals;
    NSArray *letWriteDataCBUUID;
    id delegate;
    CBUUID *serverCBUUID;
    
@private
    CBCentralManager *centralManager;
    CBPeripheral *curPeripheral;
    NSArray *servicesCBUUID;
    NSDictionary *characteristicsCBUUID;
}

+ (IBoxpayBTUtil *)sharedIBoxpayBTUtil;
- (void)startScanPeripherals;
- (void)stopScanPeripherals;
- (void)setServicesUID:(NSArray *)cbuuid;
- (void)setCharacteristics:(NSArray *)characteristics forServiceCBUUID:(NSString *)serviceCBUUID;
- (void)setValuesToNotify:(NSArray *)notifiers;
- (void)hardwareResponse:(eventHardwareBlock)block;
- (void)startConnectPeripheral:(CBPeripheral *)peripheral options:(NSDictionary *)options;
- (void)startDiscoverSreverPeripheral:(CBPeripheral *)peripheral serviceUUIDs:(NSArray *)serviceUUIDs;
- (void)startPrint:(CBPeripheral *)peripheral writeValue:(NSData*)valData forCharacteristic:(CBCharacteristic *)characteristic type:(CBCharacteristicWriteType)type;

@property (nonatomic, strong) CBCentralManager *centralManager;
@property (nonatomic, strong) NSMutableArray *dicoveredPeripherals;
@property (nonatomic, strong) NSArray *servicesCBUUID;
@property (nonatomic, strong) CBPeripheral *curPeripheral;
@property (nonatomic, strong) NSDictionary *characteristicsCBUUID;
@property (nonatomic, strong) NSArray *letWriteDataCBUUID;
@property (nonatomic, strong) id<IBoxpayBTUtilDelegate> delegate;
@property (nonatomic, strong) CBUUID *serverCBUUID;

@end
