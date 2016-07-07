//
//  ViewController.m
//  Omega-Splicer Beta
//
//  Created by Charles Fournier on 04/07/16.
//  Copyright © 2016 Charles Fournier. All rights reserved.
//

#import "ViewController.h"
#import <CoreBluetooth/CoreBluetooth.h>

#define UUID_TEST_SERVICE @"58409710-D5E2-4A7D-B439-10CF9C59E89F"
#define UUID_READ_CHARACTERISTIC @"67636659-E5E5-4A2A-92AE-BABDEC2C0E51"
#define UUID_WRITE_CHARACTERISTIC @"7F88EC10-D269-446A-B26D-6BA9AB70861F"

@interface ViewController() <CBPeripheralManagerDelegate>

@property (strong, nonatomic) CBPeripheralManager *myPeripheralManager;

@property (strong, nonatomic) CBMutableCharacteristic *myCharacteristic;

@property (strong, nonatomic) CBMutableCharacteristic *writeCharacteristic;

@property (strong, nonatomic) CBMutableService *myService;

@property (weak) IBOutlet NSSegmentedControl *segmentedControl;

@property (weak) IBOutlet NSView *char1View;

@property (weak) IBOutlet NSTextField *updateTextField;

@property (weak) IBOutlet NSTextField *char1Label;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupBluetooth];
    
    
    //    [self.char1View setWantsLayer:YES];
    //    [self.char1View.layer setBackgroundColor:[[NSColor whiteColor] CGColor]];
    
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];
}

- (void)setupBluetooth {
    self.myPeripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil options:nil];
    
    
    CBUUID *myServiceUUID = [CBUUID UUIDWithString:UUID_TEST_SERVICE];
    CBUUID *readCharacteristicUUID = [CBUUID UUIDWithString:UUID_READ_CHARACTERISTIC];
    CBUUID *writeCharacteristicUUID = [CBUUID UUIDWithString:UUID_WRITE_CHARACTERISTIC];
    
    
    NSUInteger index = 12;
    NSData *payload = [NSData dataWithBytes:&index length:sizeof(index)];
    
    NSUInteger index2 = 42;
    NSData *payload2 = [NSData dataWithBytes:&index2 length:sizeof(index2)];
    
    self.myCharacteristic = [[CBMutableCharacteristic alloc] initWithType:readCharacteristicUUID
                                                               properties:CBCharacteristicPropertyRead
                                                                    value:payload permissions:CBAttributePermissionsReadable];
    
    
    self.writeCharacteristic = [[CBMutableCharacteristic alloc] initWithType:writeCharacteristicUUID properties:CBCharacteristicPropertyWrite | CBCharacteristicPropertyRead | CBCharacteristicPropertyNotify value:nil permissions:CBAttributePermissionsReadable | CBAttributePermissionsWriteable];
    
    
    self.myService = [[CBMutableService alloc] initWithType:myServiceUUID primary:YES];
    
    
    self.myService.characteristics = @[self.myCharacteristic, self.writeCharacteristic];
    
    
    [self.myPeripheralManager addService:self.myService];
    
    
    [self.myPeripheralManager startAdvertising:@{ CBAdvertisementDataServiceUUIDsKey :
                                                      @[self.myService.UUID] }];
    
    self.myCharacteristic.value = payload2;
    
    NSLog(@"Bluetooth successfully initialized.");
    
}

- (BOOL)valueIsCorrect {
    
    NSString *newString = [[[self.updateTextField stringValue] componentsSeparatedByCharactersInSet:
                            [[NSCharacterSet decimalDigitCharacterSet] invertedSet]]
                           componentsJoinedByString:@""];
    
    if ([newString isEqualToString:@""])
        return false;
    
    return true;
}

- (IBAction)updateCharacteristic1:(id)sender {

    if ([self valueIsCorrect] == false) {
        NSLog(@"Incorect value, only digital value");
        self.updateTextField.stringValue = @"";
        return;
    }
    
    
    NSUInteger decodedInteger;
    [self.writeCharacteristic.value getBytes:&decodedInteger length:sizeof(decodedInteger)];
    NSSwapInt(decodedInteger);
    NSLog(@"before : %lu", (unsigned long)decodedInteger);

    NSUInteger value = [self.updateTextField integerValue];
    NSData *newDataValue = [NSData dataWithBytes:&value length:sizeof(value)];
//    [self.writeCharacteristic setValue:newDataValue];
    [self.myPeripheralManager updateValue:newDataValue forCharacteristic:self.writeCharacteristic onSubscribedCentrals:nil];
    
    NSUInteger afterDecodedInteger;
    [self.writeCharacteristic.value getBytes:&afterDecodedInteger length:sizeof(afterDecodedInteger)];
    NSSwapInt(afterDecodedInteger);
   NSLog(@"after : %lu", (unsigned long)afterDecodedInteger);
}

- (IBAction)segmentedControlValueChanged:(id)sender {
    if (self.segmentedControl.selectedSegment == 0) {
        [self.myPeripheralManager startAdvertising:@{ CBAdvertisementDataServiceUUIDsKey : @[self.myService.UUID] }];
    } else {
        [self.myPeripheralManager stopAdvertising];
    }
}

#pragma mark CoreBluetooth Delegate

- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral {
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral didAddService:(CBService *)service error:(NSError *)error {
    if (error) {
        NSLog(@"Error publishing service: %@", [error localizedDescription]);
    }
}

- (void)peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheral error:(NSError *)error {
    if (error) {
        NSLog(@"Error advertising: %@", [error localizedDescription]);
    }
}

@end
