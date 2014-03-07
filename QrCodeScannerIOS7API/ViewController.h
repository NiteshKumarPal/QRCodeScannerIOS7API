//
//  ViewController.h
//  QrCodeScannerIOS7API
//
//  Created by Webonise on 05/03/14.
//  Copyright (c) 2014 Webonise. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController
@property (weak, nonatomic) IBOutlet UIView *viewPreview;
@property (weak, nonatomic) IBOutlet UILabel *lblStatus;
@property (weak, nonatomic) IBOutlet UILabel *lblPrompt;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *barBtnItemStart;

- (IBAction)startStopReading:(id)sender;
@end


