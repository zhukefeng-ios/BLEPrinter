//
//  ViewController.m
//  IBoxpayBTDemo
//
//  Created by ZKF on 13-8-23.
//  Copyright (c) 2013年 朱克锋. All rights reserved.
//

#import "ViewController.h"

#define NOTIFY_MTU      20
@interface ViewController()<UITableViewDelegate, UITableViewDataSource>
{
    UITableView     * _tableView;
    NSArray         * gettedPeripheralsArr;
    CBPeripheral    * didDiscoverCBPeripheral;
    CBService       * didDiscoverCBService;
    NSError         * didDiscoverNSError;
}

@property (nonatomic, retain) IBOutlet UITableView* tableView;
@property (nonatomic, retain) NSArray *gettedPeripheralsArr;
@end
@implementation ViewController
@synthesize gettedPeripheralsArr;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    IBoxpayBTUtil *instance = [IBoxpayBTUtil sharedIBoxpayBTUtil];
    [instance setDelegate:self];
    
    [instance hardwareResponse:^(CBPeripheral *peripheral, BLUETOOTH_STATUS status, NSError *error) {
        
        if (status == BLUETOOTH_STATUS_CONNECTED)
        {
            NSLog(@"connected!");
            [self startDiscoverSreverPeripheral:peripheral serviceUUIDs:nil];
        }
        else if (status == BLUETOOTH_STATUS_FAIL_TO_CONNECT)
        {
            NSLog(@"fail to connect!");
        }
        else
        {
            NSLog(@"disconnected!");
        }
        
        NSLog(@"CBUUID: %@, ERROR: %@", (NSString *)peripheral.UUID, error.localizedDescription);
    }];
}

-(IBAction)scanBtn:(id)sender
{
    NSLog(@"开始搜索设备......");
    IBoxpayBTUtil *instance = [IBoxpayBTUtil sharedIBoxpayBTUtil];
    [instance startScanPeripherals];
}

- (void)startDiscoverSreverPeripheral:(CBPeripheral *)peripheral serviceUUIDs:(NSArray *)serviceUUIDs
{
    IBoxpayBTUtil *instance = [IBoxpayBTUtil sharedIBoxpayBTUtil];
    [instance startDiscoverSreverPeripheral:peripheral serviceUUIDs:nil];
}

- (void)centralManager:(CBCentralManager *)central didRetrievePeripherals:(NSArray *)peripherals
{
    NSLog(@"..peripherals:%@",peripherals);
    if ([peripherals count]>0) {
        self.gettedPeripheralsArr = peripherals;
    }
    [self.tableView reloadData];
}

-(void)print:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service
{

    if ([[IBoxpayBTUtil sharedIBoxpayBTUtil].servicesCBUUID count] == 0) {
        return;
    }
    //if([service.UUID isEqual:[CBUUID UUIDWithString:@"FFF0"]])
    if([service.UUID isEqual:[IBoxpayBTUtil sharedIBoxpayBTUtil].servicesCBUUID[0]])
    {
//        NSString *localChar = @"FFF3";
        for (CBCharacteristic * characteristic in service.characteristics)
        {
            NSLog(@"characteristic.UUID:%@",characteristic.UUID);
            NSLog(@"characteristic.UUID:%i",characteristic.properties);
//            if([characteristic.UUID isEqual:[CBUUID UUIDWithString:localChar]])
            if (characteristic.properties == 10)
            {
                //写入文本信息
                IBoxpayBTUtil *instance = [IBoxpayBTUtil sharedIBoxpayBTUtil];
                unsigned char *sendData = (unsigned char *)malloc( 100 * sizeof(unsigned char));
                memset(sendData, 0, 100);
                sendData[0] = 0x1B;
                sendData[1] = 0x40;
                
                
                NSData * valDataa = [NSData dataWithBytes:sendData length:2];
                [instance startPrint:peripheral writeValue:valDataa forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
                
                memset(sendData, 0, 100);
                sendData[0] = 0x1D;
                sendData[1] = 0x57;
                sendData[2] = 120;
                sendData[2] = 12;
                
                
                NSData * valData = [NSData dataWithBytes:sendData length:4];
                [instance startPrint:peripheral writeValue:valData forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
                
for (int i = 1; i < 2; i++) {
                memset(sendData, 0, 100);
                for (int i = 1; i < 10; i++) {
                    sendData[i] = 'c';
                }
                NSData * valDatas = [NSData dataWithBytes:sendData length:10];
                [instance startPrint:peripheral writeValue:valDatas forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
                memset(sendData, 0, 100);
                
                sendData[0] = 0x0A;
//                sendData[1] = 0x21;
//                sendData[2] = 0x10;

                
                NSData * valData = [NSData dataWithBytes:sendData length:1];
                [instance startPrint:peripheral writeValue:valData forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
}
                
//                memset(sendData, 0, 100);
//                for (int i = 1; i < 10; i++) {
//                    sendData[i] = 'c';
//                }
//                NSData * valDatas = [NSData dataWithBytes:sendData length:10];
//                [instance startPrint:peripheral writeValue:valDatas forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
//                for (int i =0; i<20; i++) {
//                    NSData * valData = [NSData dataWithBytes:"163316" length:6];
//                    [instance startPrint:peripheral writeValue:valData forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
//                    NSData * valDataMsg = [NSData dataWithBytes:"TESTDATA" length:8];
//                    [instance startPrint:peripheral writeValue:valDataMsg forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
//                }
            
                NSLog(@"Found a Temperature Measurement Interval Characteristic - Write interval value");
                
            }
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    NSLog(@"service.UUID:%@",service.UUID);
    
    didDiscoverCBPeripheral = peripheral;
    didDiscoverCBService = service;
    
    [self print:didDiscoverCBPeripheral didDiscoverCharacteristicsForService:didDiscoverCBService];
}


- (void)hardwareDidNotifyBehaviourOnCharacteristic:(CBCharacteristic *)characteristic
                                    withPeripheral:(CBPeripheral *)peripheral
                                             error:(NSError *)error
{
    
}

- (void)peripheralDidWriteChracteristic:(CBCharacteristic *)characteristic
                         withPeripheral:(CBPeripheral *)peripheral
                              withError:(NSError *)error
{
    
    if (error) {
        NSLog(@"write data oops!!!!!!!!.");
    }
    else
    {
        NSLog(@"write data  ok .");
    }
}

- (void)peripheralDidReadChracteristic:(CBCharacteristic *)characteristic
                        withPeripheral:(CBPeripheral *)peripheral
                             withError:(NSError *)error
{
    
}
#pragma mark - Table view delegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.gettedPeripheralsArr count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return  60;
}


- (UITableViewCell *)tableView:(UITableView *)TableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{

    static NSString *cellIdentifier = @"Peripherals";
    UITableViewCell *cell = [TableView dequeueReusableCellWithIdentifier:cellIdentifier];
    int row = [indexPath row];
    
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier]
                autorelease];
    
    }

    cell.textLabel.text = ((CBPeripheral *)self.gettedPeripheralsArr[row]).name;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    IBoxpayBTUtil *instance = [IBoxpayBTUtil sharedIBoxpayBTUtil];
    [instance startConnectPeripheral:self.gettedPeripheralsArr[indexPath.row] options:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:CBConnectPeripheralOptionNotifyOnDisconnectionKey]];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
