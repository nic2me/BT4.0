//
//  ViewController.m
//  BTConnection
//
//  Created by 茹赟 on 2018/3/30.
//  Copyright © 2018年 茹赟. All rights reserved.
//

#import "ViewController.h"
#import "KKBlueTooth.h"
@interface ViewController ()<KKBluetoothDelegate>
@property KKBlueTooth   *blueToothManager;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
}
-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self getBluetoothPrepared];
}
-(void)getBluetoothPrepared
{
    if(!_blueToothManager)
    {
        _blueToothManager = [KKBlueTooth shareInstance];
        _blueToothManager.bluetoothDelegate = self;
        [_blueToothManager scanPeripheral];
    }
}


#pragma mark 蓝牙各个代理方法
/*1. 检查主从机的蓝牙状态
 */
-(void)checkBlueToothStatus:(int)state
{
    switch (state) {
        case 5:
            if(_blueToothManager)
            {
                [_blueToothManager scanPeripheral];
            }
            break;
        case 4:
            NSLog(@"请打开本机蓝牙");
            break;
        case 0:case 1:case 3:
            NSLog(@"请检查蓝牙状态");
            break;
        case 2:
            NSLog(@"此设备不支持蓝牙");
            break;
        default:
            break;
    }
}
/*2.向用户显示蓝牙连接状态
 */
-(void)showConnectingStatusInfo:(NSString *)infoString
{
   //在这里获取各种连接状态
}
/*5.接收所有数据
 */
-(void)receiveBLEData:(NSData *)data
{
    /*接收数据......
     怎么处理数据，看你的啦
     */
}





@end
