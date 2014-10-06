//
//  WLXCentralManagerDelegate.m
//  Pods
//
//  Created by Guido Marucci Blas on 10/2/14.
//
//

#import "WLXCentralManagerDelegate.h"

#import "WLXBluetoothDeviceLogger.h"
#import "WLXBluetoothDeviceConnectionError.h"
#import "WLXBluetoothDeviceHelpers.h"

@interface WLXCentralManagerDelegate ()

@property (nonatomic) NSNotificationCenter * notificationCenter;
@property (nonatomic) NSMutableDictionary * connectionMangers;

@end

@implementation WLXCentralManagerDelegate

- (instancetype)initWithDiscoverer:(WLXBluetoothDeviceDiscoverer *)discoverer
                notificationCenter:(NSNotificationCenter *)notificationCenter {
    WLXAssertNotNil(notificationCenter);
    WLXAssertNotNil(discoverer);
    self = [super init];
    if (self) {
        _notificationCenter = notificationCenter;
        _discoverer = discoverer;
        _connectionMangers = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)registerConnectionManager:(WLXBluetoothConnectionManager *)connectionManager {
    WLXAssertNotNil(connectionManager);
    NSString * message = [NSString stringWithFormat:@"A connection manager has already been registered for peripheral '%@'",
                          connectionManager.peripheralUUID];
    NSAssert(self.connectionMangers[connectionManager.peripheralUUID] == nil, message);
    self.connectionMangers[connectionManager.peripheralUUID] = connectionManager;
}

- (void)unregisterConnectionManager:(WLXBluetoothConnectionManager *)connectionManager {
    WLXAssertNotNil(connectionManager);
    [self.connectionMangers removeObjectForKey:connectionManager.peripheralUUID];
}


- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    switch (central.state) {
        case CBCentralManagerStateUnknown:
            DDLogDebug(@"The Bluetooth manager state is unknown");
            self.bluetoothOn = NO;
            break;
        case CBCentralManagerStateResetting:
            DDLogDebug(@"The Bluetooth connection was temporaly lost.");
            self.bluetoothOn = NO;
            break;
        case CBCentralManagerStateUnsupported:
            DDLogDebug(@"Bluetooth Low Energy is not supported on this platform");
            self.bluetoothOn = NO;
            break;
        case CBCentralManagerStateUnauthorized:
            DDLogDebug(@"This app is not authorized to use Bluetooth");
            self.bluetoothOn = NO;
            // TODO Notify the delegate that the app is not authorized to use bluetooth
            break;
        case CBCentralManagerStatePoweredOn:
            DDLogDebug(@"Bluetooh is turned on");
            self.bluetoothOn = YES;
            [self.notificationCenter postNotificationName:WLXBluetoothDeviceBluetoothIsOn object:self];
            break;
        case CBCentralManagerStatePoweredOff:
            DDLogDebug(@"Bluetooth is turned off");
            self.bluetoothOn = NO;
            [self.notificationCenter postNotificationName:WLXBluetoothDeviceBluetoothIsOff object:self];
            break;
        default:
            DDLogDebug(@"Central Manager did change state to %ld", (long)central.state);
            break;
    }
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral
     advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
    WLXDeviceDiscoveryData * data = [[WLXDeviceDiscoveryData alloc] initWithPeripheral:peripheral
                                                                     advertisementData:advertisementData
                                                                                  RSSI:RSSI];
    [self.discoverer addDiscoveredDevice:data];
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    NSString * UUID = peripheral.identifier.UUIDString;
    WLXBluetoothConnectionManager * connectionManager = self.connectionMangers[UUID];
    if (connectionManager) {
        [connectionManager didConnect];
    } else {
        DDLogWarn(@"There is no registered connection manager for peripheral with UUID '%@'", UUID);
    }
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral
                 error:(NSError *)error {
    NSString * UUID = peripheral.identifier.UUIDString;
    WLXBluetoothConnectionManager * connectionManager = self.connectionMangers[UUID];
    if (connectionManager) {
        [connectionManager didFailToConnect:error];
    } else {
        DDLogWarn(@"There is no registered connection manager for peripheral with UUID '%@'", UUID);
    }
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral
                 error:(NSError *)error {
    NSString * UUID = peripheral.identifier.UUIDString;
    WLXBluetoothConnectionManager * connectionManager = self.connectionMangers[UUID];
    if (connectionManager) {
        [connectionManager didDisconnect:error];
    } else {
        DDLogWarn(@"There is no registered connection manager for peripheral with UUID '%@'", UUID);
    }
}

@end