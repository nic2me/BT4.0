//
//  KKBlueTooth.h
//  BTConnection
//
//  Created by 茹赟 on 2018/3/30.
//  Copyright © 2018年 茹赟. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
typedef NS_ENUM(NSInteger,ConnecttionStatus)
{
    ConnecttionPeripheralNotConnected=0,
    ConnecttionPeripheralConnected,
};
@protocol KKBluetoothDelegate <NSObject>

@required
//主设备的蓝牙状态
-(void)checkBlueToothStatus:(int)state;
-(void)receiveBLEData:(NSData *)data;
@optional
//蓝牙连接的提示信息
-(void)showConnectingStatusInfo:(NSString *)infoString;
@end
@interface KKBlueTooth : NSObject
@property (nonatomic,assign) id <KKBluetoothDelegate> bluetoothDelegate;
@property (nonatomic,assign,readonly) BOOL isBlueToothConnected;


+(instancetype)shareInstance;
-(void)scanPeripheral;
-(void)disConnectHuluPeripheral;
@end
