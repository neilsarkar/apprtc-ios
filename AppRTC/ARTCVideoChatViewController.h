//
//  ARTCVideoChatViewController.h
//  AppRTC
//
//  Created by Kelly Chu on 3/7/15.
//  Copyright (c) 2015 ISBX. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <libjingle_peerconnection/RTCEAGLVideoView.h>
#import <AppRTC/ARDAppClient.h>
#import "AFNetworking.h"

@interface ARTCVideoChatViewController : UIViewController <ARDAppClientDelegate, RTCEAGLVideoViewDelegate>

//Views, Labels, and Buttons
@property (strong, nonatomic) IBOutlet RTCEAGLVideoView *remoteView;
@property (strong, nonatomic) IBOutlet UILabel *urlLabel;
@property (strong, nonatomic) IBOutlet UIButton *hangupButton;
@property (strong, nonatomic) IBOutlet UIButton *timeButton;

//Auto Layout Constraints used for animations
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *remoteViewTopConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *remoteViewRightConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *remoteViewLeftConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *remoteViewBottomConstraint;

@property (strong, nonatomic) NSString *roomUrl;
@property (strong, nonatomic) NSString *roomName;
@property (strong, nonatomic) ARDAppClient *client;
@property (strong, nonatomic) RTCVideoTrack *localVideoTrack;
@property (strong, nonatomic) RTCVideoTrack *remoteVideoTrack;
@property (assign, nonatomic) CGSize localVideoSize;
@property (assign, nonatomic) CGSize remoteVideoSize;
@property (assign, nonatomic) BOOL isZoom; //used for double tap remote view

//toggle button parameter
@property (assign, nonatomic) BOOL isAudioMute;
@property (assign, nonatomic) BOOL isVideoMute;

//Time left in seconds
@property (assign, nonatomic) int timeLeft;
@property (assign, nonatomic) NSTimer *timer;

- (IBAction)hangupButtonPressed:(id)sender;
- (IBAction)extensionPressed:(id)sender;

@end
