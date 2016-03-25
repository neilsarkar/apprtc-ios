//
//  ARTCRoomTextInputViewCell.m
//  AppRTC
//
//  Created by Kelly Chu on 3/7/15.
//  Copyright (c) 2015 ISBX. All rights reserved.
//

#import "ARTCRoomTextInputViewCell.h"

@implementation ARTCRoomTextInputViewCell

- (void)awakeFromNib {
    // Initialization code
    [self.joinButton.layer setCornerRadius:3.0f];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (IBAction)touchButtonPressed:(id)sender {
    NSLog(@"Button pressed");
    if ([self.delegate respondsToSelector:@selector(roomTextInputViewCell:shouldJoinRoom:)]) {
        [self.delegate roomTextInputViewCell:self shouldJoinRoom:@"neilio"];
    }
}

@end
