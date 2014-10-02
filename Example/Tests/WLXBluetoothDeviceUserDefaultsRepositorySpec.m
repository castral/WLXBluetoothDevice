//
//  WLXBluetoothDeviceUserDefaultsRepositorySpec.m
//  WLXBluetoothDevice
//
//  Created by Guido Marucci Blas on 10/1/14.
//  Copyright (c) 2014 Guido Marucci Blas. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <WLXBluetoothDevice/WLXBluetoothDeviceUserDefaultsRepository.h>

SpecBegin(WLXBluetoothDeviceUserDefaultsRepository)

    __block WLXBluetoothDeviceUserDefaultsRepository * repository;
    __block NSUserDefaults * mockUserDefaults;
    __block WLXBluetoothDeviceConnectionRecord * connectionRecord;

    beforeEach(^{
        mockUserDefaults = mock([NSUserDefaults class]);
        repository = [[WLXBluetoothDeviceUserDefaultsRepository alloc] initWithUserDefaults:mockUserDefaults];
        connectionRecord = [[WLXBluetoothDeviceConnectionRecord alloc] initWithUUID:@"FAKEUUID"
                                                                               name:@"Fake name"
                                                                     connectionDate:[NSDate date]];
    });

    afterEach(^{
        mockUserDefaults = nil;
        repository = nil;
        connectionRecord = nil;
    });

    describe(@"#saveConnectionRecord:", ^{
        
        it(@"stores the record in the user defaults", ^{
            [repository saveConnectionRecord:connectionRecord];
            [MKTVerify(mockUserDefaults) setObject:connectionRecord forKey:WLXBluetoothDeviceLastConnectionRecord];
        });
        
    });

    describe(@"#fetchLastConnectionRecord", ^{
    
        context(@"when a connection record was saved", ^{
        
            beforeEach(^{
                [MKTGiven([mockUserDefaults objectForKey:WLXBluetoothDeviceLastConnectionRecord]) willReturn:connectionRecord];
            });
            
            it(@"fetches the record from the user defaults", ^{
                expect([repository fetchLastConnectionRecord]).to.beNil;
            });
            
        });
        
        context(@"when a connection record was not saved", ^{
            
            beforeEach(^{
                [MKTGiven([mockUserDefaults objectForKey:WLXBluetoothDeviceLastConnectionRecord]) willReturn:nil];
            });
            
            it(@"fetches the record from the user defaults", ^{
                expect([repository fetchLastConnectionRecord]).notTo.beNil;
            });
            
        });
        
    });

SpecEnd