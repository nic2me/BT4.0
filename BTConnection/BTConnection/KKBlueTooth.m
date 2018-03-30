//
//  KKBlueTooth.m
//  BTConnection
//
//  Created by 茹赟 on 2018/3/30.
//  Copyright © 2018年 茹赟. All rights reserved.
//


/*CBUUID  自己获取，这里只是个例子
 */
#define serviceString @"FFE0"
#define characteristicsString @"FFE1"
#define peripheralName @""

#import "KKBlueTooth.h"
#import <CoreBluetooth/CoreBluetooth.h>


@interface KKBlueTooth()<CBCentralManagerDelegate,CBPeripheralDelegate>
{
    BOOL                isBackground;
    CBCentralManager    *manager;
    CBPeripheral        *desPeripheral;
    CBCharacteristic    *desCharacteristic;
}
@end
@implementation KKBlueTooth
@synthesize isBlueToothConnected;
+ (instancetype)shareInstance
{
    static KKBlueTooth * instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}
-(id)init
{
    self = [super init];
    if (self) {
        manager = [[CBCentralManager alloc]initWithDelegate:self queue:nil];
    }
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground) name: UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
    return self;
}
/**
 蓝牙状态
 */
-(void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    /**
     CBManagerStateUnknown //0
     CBManagerStateResetting //1
     CBManagerStateUnsupported //2
     CBManagerStateUnauthorized //3
     CBManagerStatePoweredOff //4
     CBManagerStatePoweredOn //5
     */
    [self.bluetoothDelegate checkBlueToothStatus:central.state];
}
-(void)scanPeripheral
{
    NSArray *arr = [manager retrieveConnectedPeripheralsWithServices:@[[CBUUID UUIDWithString:serviceString]]];
    if(arr.count>0)
    {
        for (CBPeripheral* peripheral in arr)
        {
            if([peripheral.name containsString:peripheralName])
                {
                    peripheral.delegate = self;
                    desPeripheral = peripheral;
                    [manager connectPeripheral:desPeripheral options:nil];
                    return;
                }
                else
                {
                    continue;
                }
        }
    }
    if(desPeripheral==nil)
    {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(){
            [manager scanForPeripheralsWithServices:nil options:nil];
        });
    }
}
-(void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI
{
    NSLog(@"discovered peripheral----> %@",peripheral.name);
    if([peripheral.name containsString:peripheralName])
    {
        desPeripheral  = peripheral;
        desPeripheral.delegate = self;
        [self setConnectingStatus:ConnecttionPeripheralNotConnected];
        [self connectHuluPeripheral];
    }else
    {
        [self.bluetoothDelegate showConnectingStatusInfo:@"没有发现蓝牙设备"];
    }
    
}
/**
 连接外设
 */
- (void)connectHuluPeripheral
{
    //连接外设
    if(desPeripheral)
    {
        [manager connectPeripheral:desPeripheral options:nil];
    }else
    {
        [self scanPeripheral];
    }
}
-(void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    isBlueToothConnected = NO;
    [self.bluetoothDelegate showConnectingStatusInfo:@"蓝牙已断开"];
    [self setConnectingStatus:ConnecttionPeripheralNotConnected];
    if(!isBackground)
    {
        //已断开，尝试重新连接
        [self connectHuluPeripheral];
    }else
    {
        //进入后台，不会继续连接
    }
    
}
-(void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    isBlueToothConnected = NO;
    [self setConnectingStatus:ConnecttionPeripheralNotConnected];
    [self connectHuluPeripheral];
}
-(void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    [self.bluetoothDelegate showConnectingStatusInfo:@"蓝牙已连接"];
    [self setConnectingStatus:ConnecttionPeripheralConnected];
    isBlueToothConnected = YES;
    desPeripheral.delegate = self;
    [central stopScan];
    [desPeripheral discoverServices:@[[CBUUID UUIDWithString:serviceString]]];
}
/**
 连接外设的服务
 */
-(void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    for (CBService *service in peripheral.services) {
        [peripheral discoverCharacteristics:@[[CBUUID UUIDWithString:characteristicsString]] forService:service];
    }
}
-(void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    NSArray *characteristicArray = service.characteristics;
    desCharacteristic = [characteristicArray firstObject];
    [self notifyCharacteristic:desPeripheral characteristic:desCharacteristic];
    
    [NSThread sleepForTimeInterval:1.0];
}
-(void)notifyCharacteristic:(CBPeripheral *)peripheral
             characteristic:(CBCharacteristic *)characteristic
{
    [peripheral setNotifyValue:YES forCharacteristic:characteristic];
}
/*
向外设写数据
 */
-(void)writeData
{
    [desPeripheral writeValue:[@"BBBB" dataUsingEncoding:NSUTF8StringEncoding] forCharacteristic:desCharacteristic type:CBCharacteristicWriteWithoutResponse];
}
/*
 接收外部蓝牙外设的数据
 */
-(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    [self.bluetoothDelegate receiveBLEData:characteristic.value];
}
/**
 断开连接
 */
-(void)disConnectHuluPeripheral
{
    isBlueToothConnected = NO;
    [self disconnectPeripheral:manager peripheral:desPeripheral];
    [self setConnectingStatus:ConnecttionPeripheralNotConnected];
}

-(void)disconnectPeripheral:(CBCentralManager *)centralManager
                 peripheral:(CBPeripheral *)peripheral
{
    [centralManager cancelPeripheralConnection:peripheral];
}
/*
 全局发送蓝牙连接状态的通知
 */
-(void)setConnectingStatus:(ConnecttionStatus )status
{
    BOOL isConnected = (status==1)?YES:NO;
    NSDictionary *dic = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:isConnected] forKey:@"kBLEConnectingStatus"];
    [[NSNotificationCenter defaultCenter]postNotificationName:@"kBLEConnectingNotification" object:self userInfo:dic];
}

#pragma mark   进入后台时断开连接
-(void)applicationDidEnterBackground
{
    if(desPeripheral)
    {
        isBackground = YES;
        [self disconnectPeripheral:manager peripheral:desPeripheral];
    }
}
#pragma mark   从后台进入前台，即开始搜索外设
-(void)applicationDidBecomeActive
{
    if(isBackground)
    {
        isBackground = NO;
        [self connectHuluPeripheral];
    }
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end
