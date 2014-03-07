//
//  ViewController.m
//  QrCodeScannerIOS7API
//
//  Created by Webonise on 05/03/14.
//  Copyright (c) 2014 Webonise. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>

@interface ViewController ()<AVCaptureMetadataOutputObjectsDelegate>
@property (nonatomic) BOOL isReading;
@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *videoPreviewLayer;
@property (nonatomic, strong) AVAudioPlayer *audioPlayer;
@property (nonatomic, strong) UIView *highlightView;
@end

@implementation ViewController
@synthesize barBtnItemStart,lblStatus,lblPrompt,highlightView;

- (void)viewDidLoad
{
    [super viewDidLoad];
    highlightView = [[UIView alloc] init];
    highlightView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleBottomMargin;
    highlightView.layer.borderColor = [UIColor greenColor].CGColor;
    highlightView.layer.borderWidth = 3;
    [self.view addSubview:highlightView];
	self.isReading = NO;
    self.captureSession=nil;
    [self loadBeepSound];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)startStopReading:(id)sender {
    if (!_isReading) {
        if ([self startReading]) {
            [barBtnItemStart setTitle:@"Stop"];
            [lblStatus setText:@"Scanning for QR Code..."];
        }
    }
    else{
        [self stopReading];
        [barBtnItemStart setTitle:@"Start!"];
    }
    
    _isReading = !_isReading;
}

- (BOOL)startReading {
    NSError *error;
    //we access our device, telling at the same time that we’ll capture video. The NSError object is going to be used right next.
    AVCaptureDevice *captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    //In our case the input device is the camera
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error:&error];

    if (!input) {
        NSLog(@"%@", [error localizedDescription]);
    }
    //captureSession object needs both an input and an output device in order to properly work
    //This class in combination with the AVCaptureMetadataOutputObjectsDelegate protocol will manage to intercept any metadata found in the input device (meaning data in a QR code captured by our camera) and translate it to a human readable format
    //this queue must be a serial dispatch queue, and it should not execute any other task other than the one that’s assigned with
    self.captureSession = [[AVCaptureSession alloc]init];
    [self.captureSession addInput:input];
    
    AVCaptureMetadataOutput *captureMetadataOutput = [[AVCaptureMetadataOutput alloc] init];
    [_captureSession addOutput:captureMetadataOutput];
    
    dispatch_queue_t dispatchQueue;
    dispatchQueue = dispatch_queue_create("myQueue", NULL);
    [captureMetadataOutput setMetadataObjectsDelegate:self queue:dispatchQueue];
    [captureMetadataOutput setMetadataObjectTypes: [captureMetadataOutput availableMetadataObjectTypes]];//[NSArray arrayWithObject:AVMetadataObjectTypeQRCode]

    //Now that we have set and configured a AVCaptureMetadataOutput object, we need to show to user what the camera of the device sees
    self.videoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.captureSession];
    [self.videoPreviewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    [self.videoPreviewLayer setFrame:self.viewPreview.layer.bounds];
    [self.viewPreview.layer addSublayer:self.videoPreviewLayer];
    
    //Finally, we just have to let the session run by using the following command:
    [self.captureSession startRunning];
    
    return YES;
}

-(void)stopReading{
    [self.captureSession stopRunning];
    self.captureSession = nil;
    
    [self.videoPreviewLayer removeFromSuperlayer];
}

-(void)loadBeepSound{
    NSString *beepFilePath = [[NSBundle mainBundle] pathForResource:@"beep" ofType:@"mp3"];
    NSURL *beepURL = [NSURL URLWithString:beepFilePath];
    NSError *error;
    
    self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:beepURL error:&error];
    if (error) {
        NSLog(@"Could not play beep file.");
        NSLog(@"%@", [error localizedDescription]);
    }
    else{
        [self.audioPlayer prepareToPlay];
    }
}

-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection{
    
//    if (metadataObjects != nil && [metadataObjects count] > 0) {
//        AVMetadataMachineReadableCodeObject *metadataObj = [metadataObjects objectAtIndex:0];
//        if ([[metadataObj type] isEqualToString:AVMetadataObjectTypeQRCode]) {
//            [lblStatus performSelectorOnMainThread:@selector(setText:) withObject:[metadataObj stringValue] waitUntilDone:NO];
//            
//            [self performSelectorOnMainThread:@selector(stopReading) withObject:nil waitUntilDone:NO];
//            [barBtnItemStart performSelectorOnMainThread:@selector(setTitle:) withObject:@"Start!" waitUntilDone:NO];
//            self.isReading = NO;
//            
//            if (self.audioPlayer) {
//                [self.audioPlayer play];
//            }
//            
//        }
//    }
    
    
    CGRect highlightViewRect = CGRectZero;
    AVMetadataMachineReadableCodeObject *barCodeObject;
    NSString *detectionString = nil;
    NSArray *barCodeTypes = @[AVMetadataObjectTypeUPCECode, AVMetadataObjectTypeCode39Code, AVMetadataObjectTypeCode39Mod43Code,
                              AVMetadataObjectTypeEAN13Code, AVMetadataObjectTypeEAN8Code, AVMetadataObjectTypeCode93Code, AVMetadataObjectTypeCode128Code,
                              AVMetadataObjectTypePDF417Code, AVMetadataObjectTypeQRCode, AVMetadataObjectTypeAztecCode];
    
    for (AVMetadataObject *metadata in metadataObjects) {
        for (NSString *type in barCodeTypes) {
            if ([metadata.type isEqualToString:type])
            {
                barCodeObject = (AVMetadataMachineReadableCodeObject *)[self.videoPreviewLayer transformedMetadataObjectForMetadataObject:(AVMetadataMachineReadableCodeObject *)metadata];
                highlightViewRect = barCodeObject.bounds;
                detectionString = [(AVMetadataMachineReadableCodeObject *)metadata stringValue];
                break;
            }
        }
        
        if (detectionString != nil)
        {
           [lblStatus performSelectorOnMainThread:@selector(setText:) withObject:detectionString waitUntilDone:NO];
            break;
        }
        else
            [lblStatus performSelectorOnMainThread:@selector(setText:) withObject:@"" waitUntilDone:NO];
    }
    
    self.highlightView.frame = highlightViewRect;
    
    
}

@end
