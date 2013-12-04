//
//  IBoxpayBTUtil.m
//  IBoxpayBTDemo
//
//  Created by ZKF on 13-8-23.
//  Copyright (c) 2013年 朱克锋. All rights reserved.
//

#import "IBoxpayBTUtil.h"
static eventHardwareBlock privateBlock;
@interface IBoxpayBTUtil (Private)

- (BOOL)supportLEHardware;

@end
@implementation IBoxpayBTUtil
@synthesize centralManager, dicoveredPeripherals, curPeripheral, servicesCBUUID, characteristicsCBUUID, letWriteDataCBUUID, delegate,serverCBUUID;

- (BOOL)supportLEHardware
{
    NSString * state = nil;
    
    switch ([centralManager state])
    {
        case CBCentralManagerStateUnsupported:
            state = @"The platform/hardware doesn't support Bluetooth Low Energy.";
            break;
        case CBCentralManagerStateUnauthorized:
            state = @"The app is not authorized to use Bluetooth Low Energy.";
            break;
        case CBCentralManagerStatePoweredOff:
            state = @"Bluetooth is currently powered off.";
            break;
        case CBCentralManagerStatePoweredOn:
            return TRUE;
        case CBCentralManagerStateUnknown:
        default:
            return false;
    }
    
    NSLog(@"Central manager state: %@", state);
    
    return false;
}

- (void)setCharacteristics:(NSArray *)characteristics forServiceCBUUID:(NSString *)serviceCBUUID
{
    [self.characteristicsCBUUID setValue:characteristics forKey:serviceCBUUID];
}

- (void)setServicesUID:(NSArray *)cbuuid
{
    self.servicesCBUUID = cbuuid;
}

- (void)setValuesToNotify:(NSArray *)notifiers
{
    [notifiers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        
        CBCharacteristic *localChar = (CBCharacteristic *)obj;
        [curPeripheral setNotifyValue:YES forCharacteristic:localChar];
    }];
}

- (void)hardwareResponse:(eventHardwareBlock)block
{
    privateBlock = [block copy];
}

+ (IBoxpayBTUtil *)sharedIBoxpayBTUtil
{
    static IBoxpayBTUtil *iBoxpayBTUtilInstance;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        iBoxpayBTUtilInstance = [[IBoxpayBTUtil alloc] init];
    });
    
    return iBoxpayBTUtilInstance;
}

- (id)init
{
    if ((self = [super init]))
    {
        self.characteristicsCBUUID = [NSMutableDictionary new];
        self.dicoveredPeripherals = [NSMutableArray new];
        centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    }
    
    return self;
}

- (void)startScanPeripherals
{
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:FALSE], CBCentralManagerScanOptionAllowDuplicatesKey, nil];
    
    //    [manager scanForPeripheralsWithServices:self.dicoveredPeripherals options:options];
    [centralManager scanForPeripheralsWithServices:nil options:options];
}

- (void)stopScanPeripherals
{
    [centralManager stopScan];
}


#pragma mark -
#pragma mark CBManagerDelegate methods

/*
 Invoked whenever the central manager's state is updated.
 */
- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    if (![self supportLEHardware])
    {
        NSLog(@"Bluetooth LE not supported");
    }
}

/*
 Invoked when the central discovers peripheral while scanning.
 */
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    NSLog(@"Did discover peripheral. peripheral: %@ rssi: %@, UUID: %@ advertisementData: %@ ", peripheral, RSSI, peripheral.UUID, advertisementData);

    self.servicesCBUUID = [advertisementData objectForKey:@"kCBAdvDataServiceUUIDs"];
    if(![self.dicoveredPeripherals containsObject:peripheral])
    {
        [self.dicoveredPeripherals addObject:peripheral];
    }
    
    if (peripheral.UUID) {
        [centralManager retrievePeripherals:[NSArray arrayWithObject:(id)peripheral.UUID]];
    }
    
}

-(void)centralManager:(CBCentralManager *)central didRetrieveConnectedPeripherals:(NSArray *)peripherals
{
    NSLog(@"Did discover peripherals:%@ ", peripherals);
}

/*
 Invoked when the central manager retrieves the list of known peripherals.
 Automatically connect to first known peripheral
 */
- (void)centralManager:(CBCentralManager *)central didRetrievePeripherals:(NSArray *)peripherals
{
    NSLog(@"Retrieved peripheral: %d - %@", [peripherals count], peripherals);
    
    [self stopScanPeripherals];
    
    /* If there are any known devices, automatically connect to it.*/
    if ([self.delegate respondsToSelector:@selector(centralManager: didRetrievePeripherals:)])
    {
        [self.delegate centralManager:central didRetrievePeripherals:peripherals];
    }
}

- (void)startConnectPeripheral:(CBPeripheral *)peripheral options:(NSDictionary *)options
{
    [centralManager connectPeripheral:peripheral
                                options:options];
    curPeripheral = peripheral;
}

/*
 Invoked whenever a connection is succesfully created with the peripheral.
 Discover available services on the peripheral
 */
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    NSLog(@"Did connect to peripheral: %@", peripheral);
    
    privateBlock(peripheral, BLUETOOTH_STATUS_CONNECTED, nil);
}

- (void)startDiscoverSreverPeripheral:(CBPeripheral *)peripheral serviceUUIDs:(NSArray *)serviceUUIDs
{
    [peripheral setDelegate:self];
    [peripheral discoverServices:nil];
}

/*
 Invoked whenever an existing connection with the peripheral is torn down.
 Reset local variables
 */
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"Did Disconnect to peripheral: %@ with error = %@", peripheral, [error localizedDescription]);
    
    privateBlock(peripheral, BLUETOOTH_STATUS_DISCONNECTED, error);
    
    if (curPeripheral)
    {
        [curPeripheral setDelegate:nil];
        curPeripheral = nil;
    }
}

/*
 Invoked whenever the central manager fails to create a connection with the peripheral.
 */
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"Fail to connect to peripheral: %@ with error = %@", peripheral, [error localizedDescription]);
    
    privateBlock(peripheral, BLUETOOTH_STATUS_FAIL_TO_CONNECT, error);
    
    if (curPeripheral)
    {
        [curPeripheral setDelegate:nil];
        curPeripheral = nil;
    }
}

#pragma mark -
#pragma mark CBPeripheralDelegate methods

/*
 Invoked upon completion of a -[discoverServices:] request.
 */
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    if (error)
    {
        NSLog(@"Discovered services for %@ with error: %@", peripheral.name, [error localizedDescription]);
        return;
    }
    NSLog(@"peripheral:%@;peripheral.services:%@",peripheral,peripheral.services);
    for (CBService *service in peripheral.services)
    {
        NSLog(@"Service found with UUID: %@", service.UUID);
        
        [curPeripheral discoverCharacteristics:@[[CBUUID UUIDWithCFUUID:curPeripheral.UUID]]
                                     forService:service];
    }

}

/*
 Invoked upon completion of a -[discoverCharacteristics:forService:] request.
 */
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    if (error)
    {
        NSLog(@"Discovered characteristics for %@ with error: %@", service.UUID, [error localizedDescription]);
        return;
    }
    NSLog(@"service.UUID:%@",service.UUID);
    
    if ([self.delegate respondsToSelector:@selector(peripheral: didDiscoverCharacteristicsForService: error:)])
    {
        [self.delegate peripheral:peripheral didDiscoverCharacteristicsForService:service error:error];
    }
}

- (void)startPrint:(CBPeripheral *)peripheral writeValue:(NSData*)valData forCharacteristic:(CBCharacteristic *)characteristic type:(CBCharacteristicWriteType)type
{
    [peripheral writeValue:valData forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
//    [peripheral setNotifyValue:YES forCharacteristic:characteristic];
}
/*
 Invoked upon completion of a -[readValueForCharacteristic:] request or on the reception of a notification/indication.
 */
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (error)
    {
        NSLog(@"Error updating value for characteristic %@ error: %@", characteristic.UUID, [error localizedDescription]);
        return;
    }
    
    if ([self.delegate respondsToSelector:@selector(peripheralDidReadChracteristic:withPeripheral:withError:)])
    {
        [self.delegate peripheralDidReadChracteristic:characteristic withPeripheral:peripheral withError:error];
    }
}

/*
 Invoked upon completion of a -[writeValue:forCharacteristic:] request.
 */
- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (error)
    {
        NSLog(@"Error writing value for characteristic %@ error: %@", characteristic.UUID, [error localizedDescription]);
        return;
    }
    
    if ([self.delegate respondsToSelector:@selector(peripheralDidWriteChracteristic:withPeripheral:withError:)])
    {
        [self.delegate peripheralDidWriteChracteristic:characteristic withPeripheral:peripheral withError:error];
    }
}

/*
 Invoked upon completion of a -[setNotifyValue:forCharacteristic:] request.
 */
- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (error)
    {
        NSLog(@"Error updating notification state for characteristic %@ error: %@", characteristic.UUID, [error localizedDescription]);
        return;
    }
    
    NSLog(@"Updated notification state for characteristic %@ (newState:%@)", characteristic.UUID, [characteristic isNotifying] ? @"Notifying" : @"Not Notifying");
    
    if ([self.delegate respondsToSelector:@selector(hardwareDidNotifyBehaviourOnCharacteristic:withPeripheral:error:)])
    {
        [self.delegate hardwareDidNotifyBehaviourOnCharacteristic:characteristic withPeripheral:peripheral error:error];
    }
}

@end
