//
//  BXMessagesCollectionView.h
//  Baixing
//
//  Created by hyice on 15/3/24.
//  Copyright (c) 2015年 baixing. All rights reserved.
//

@import UIKit;

@interface BXMessagesCollectionView : UICollectionView

@property (nonatomic, readonly) UIActivityIndicatorView *loadingIndicator;
@property (nonatomic, assign) BOOL showIndicatorAtBottom;

- (void)scrollToBottomAnimated:(BOOL)animated;

@end
