//
//  ARTCVideoChatViewController.m
//  AppRTC
//
//  Created by Kelly Chu on 3/7/15.
//  Copyright (c) 2015 ISBX. All rights reserved.
//

#import "ARTCVideoChatViewController.h"
#import <AVFoundation/AVFoundation.h>

#define SERVER_HOST_URL @"https://apprtc.appspot.com"

@implementation ARTCVideoChatViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.isZoom = NO;
    self.isAudioMute = NO;
    self.isVideoMute = NO;
    self.timeLeft = 20;
    self.timeButton.enabled = NO;
    
    //Add Tap to hide/show controls
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleButtonContainer)];
    [tapGestureRecognizer setNumberOfTapsRequired:1];
    [self.view addGestureRecognizer:tapGestureRecognizer];
    
    //Add Double Tap to zoom
    tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(zoomRemote)];
    [tapGestureRecognizer setNumberOfTapsRequired:2];
    [self.view addGestureRecognizer:tapGestureRecognizer];
    
    //RTCEAGLVideoViewDelegate provides notifications on video frame dimensions
    [self.remoteView setDelegate:self];

    //Getting Orientation change
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(orientationChanged:)
                                                 name:@"UIDeviceOrientationDidChangeNotification"
                                               object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self joinNewRoom];
    [[self navigationController] setNavigationBarHidden:YES animated:YES];
}

- (void)startTimer {
    self.timeButton.enabled = YES;
    self.timeLeft = 20;
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                  target:self
                                                selector:@selector(count)
                                                userInfo:nil
                                                 repeats:YES];
}

- (void)count {
    self.timeLeft--;
    
    NSLog(@"%d", self.timeLeft);
    NSString *label;
    if( self.timeLeft > 0 ) {
        label = [NSString stringWithFormat:@"%02d:%02d", self.timeLeft / 60, self.timeLeft % 60];
    } else {
        [self.timer invalidate];
        label = @"YA BURNT";
        self.timeButton.enabled = NO;
        [self joinNewRoom];
    }
    
    [UIView performWithoutAnimation:^{
        [self.timeButton setTitle:label forState:UIControlStateNormal];
        [self.timeButton layoutIfNeeded];
    }];
}

- (void)joinNewRoom {
    NSLog(@"Joining new room");
    [self.timer invalidate];
    
    // Automatically join room
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];
    
    NSURL *URL = [NSURL URLWithString:@"https://devnull.tindersandbox.com/room"];
    NSURLRequest *request = [NSURLRequest requestWithURL:URL];
    
    NSURLSessionDataTask *dataTask = [manager dataTaskWithRequest:request completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
        if (error) {
            NSLog(@"Error: %@", error);
        } else {
            [self setRoomName:responseObject[@"room"]];
            //Connect to the room
            [self disconnect];
            self.client = [[ARDAppClient alloc] initWithDelegate:self];
            [self.client setServerHostUrl:SERVER_HOST_URL];
            [self.client connectToRoomWithId:self.roomName options:nil];
            
            [self.urlLabel setText:self.roomName];
        }
    }];
    [dataTask resume];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"UIDeviceOrientationDidChangeNotification" object:nil];
    [self disconnect];
}

- (void)applicationWillResignActive:(UIApplication*)application {
    [self disconnect];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)orientationChanged:(NSNotification *)notification{
    [self videoView:self.remoteView didChangeVideoSize:self.remoteVideoSize];
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)setRoomName:(NSString *)roomName {
    _roomName = roomName;
    self.roomUrl = [NSString stringWithFormat:@"%@/r/%@", SERVER_HOST_URL, roomName];
}

- (void)disconnect {
    if (self.client) {
        if (self.remoteVideoTrack) [self.remoteVideoTrack removeRenderer:self.remoteView];
        self.localVideoTrack = nil;
        self.remoteVideoTrack = nil;
        [self.remoteView renderFrame:nil];
        [self.client disconnect];
    }
}

- (void)remoteDisconnected {
    if (self.remoteVideoTrack) [self.remoteVideoTrack removeRenderer:self.remoteView];
    self.remoteVideoTrack = nil;
    [self.remoteView renderFrame:nil];
    
}

- (void)toggleButtonContainer {
    [UIView animateWithDuration:0.3f animations:^{
        [self.view layoutIfNeeded];
    }];
}

- (void)zoomRemote {
    //Toggle Aspect Fill or Fit
    self.isZoom = !self.isZoom;
    [self videoView:self.remoteView didChangeVideoSize:self.remoteVideoSize];
}

- (IBAction)hangupButtonPressed:(id)sender {
    //Clean up
    [self disconnect];
    [self joinNewRoom];
}

- (IBAction)extensionPressed:(id)sender {
    self.timeLeft += 120;
}


#pragma mark - ARDAppClientDelegate

- (void)appClient:(ARDAppClient *)client didChangeState:(ARDAppClientState)state {
    switch (state) {
        case kARDAppClientStateConnected:
            NSLog(@"Client connected.");
            break;
        case kARDAppClientStateConnecting:
            NSLog(@"Client connecting.");
            break;
        case kARDAppClientStateDisconnected:
            NSLog(@"Client disconnected.");
            [self remoteDisconnected];
            break;
    }
}

- (void)appClient:(ARDAppClient *)client didReceiveLocalVideoTrack:(RTCVideoTrack *)localVideoTrack {
    NSLog(@"Received local video track, ignoring it.");
}

- (void)appClient:(ARDAppClient *)client didReceiveRemoteVideoTrack:(RTCVideoTrack *)remoteVideoTrack {
    self.remoteVideoTrack = remoteVideoTrack;
    [self.remoteVideoTrack addRenderer:self.remoteView];
    
    [UIView animateWithDuration:0.4f animations:^{
        //Instead of using 0.4 of screen size, we re-calculate the local view and keep our aspect ratio
        UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
        CGRect videoRect = CGRectMake(0.0f, 0.0f, self.view.frame.size.width/4.0f, self.view.frame.size.height/4.0f);
        if (orientation == UIDeviceOrientationLandscapeLeft || orientation == UIDeviceOrientationLandscapeRight) {
            videoRect = CGRectMake(0.0f, 0.0f, self.view.frame.size.height/4.0f, self.view.frame.size.width/4.0f);
        }
        [self startTimer];
        [self.view layoutIfNeeded];
    }];
}

- (void)appClient:(ARDAppClient *)client didError:(NSError *)error {
    UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:nil
                                                        message:[NSString stringWithFormat:@"%@", error]
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
    [alertView show];
    [self disconnect];
}

#pragma mark - RTCEAGLVideoViewDelegate

- (void)videoView:(RTCEAGLVideoView *)videoView didChangeVideoSize:(CGSize)size {
    [UIView animateWithDuration:0.4f animations:^{
        CGFloat containerWidth = self.view.frame.size.width;
        CGFloat containerHeight = self.view.frame.size.height;
        CGSize defaultAspectRatio = CGSizeMake(4, 3);
        if (videoView == self.remoteView) {
            //Resize Remote View
            self.remoteVideoSize = size;
            CGSize aspectRatio = CGSizeEqualToSize(size, CGSizeZero) ? defaultAspectRatio : size;
            CGRect videoRect = self.view.bounds;
            CGRect videoFrame = AVMakeRectWithAspectRatioInsideRect(aspectRatio, videoRect);

            //Set Aspect Fill
            CGFloat scale = MAX(containerWidth/videoFrame.size.width, containerHeight/videoFrame.size.height);
            videoFrame.size.width *= scale;
            videoFrame.size.height *= scale;

            [self.remoteViewTopConstraint setConstant:containerHeight/2.0f - videoFrame.size.height/2.0f];
            [self.remoteViewBottomConstraint setConstant:containerHeight/2.0f - videoFrame.size.height/2.0f];
            [self.remoteViewLeftConstraint setConstant:containerWidth/2.0f - videoFrame.size.width/2.0f]; //center
            [self.remoteViewRightConstraint setConstant:containerWidth/2.0f - videoFrame.size.width/2.0f]; //center
            
        }
        [self.view layoutIfNeeded];
    }];

}


@end
