//
//  BXQuickMessagesViewController.m
//  Baixing
//
//  Created by hyice on 15/3/22.
//  Copyright (c) 2015年 baixing. All rights reserved.
//

#import "BXQuickMessagesViewController.h"
#import "BXQuickMessagesMultiInputView.h"
#import "BXMessagesInputMoreChoiceCell.h"

#import "BXQuickMessage.h"

#import "BXQuickMessagesBaseChatCell.h"
#import "BXQuickMessagesTextChatCell.h"
#import "BXQuickMessagesMediaChatCell.h"
#import "BXQuickMessagesStatusCell.h"

#import <UIImageView+WebCache.h>

#import "NSBundle+MessagesUIKit.h"

static NSString * const incomingBXQuickMessagesTextChatCell = @"incomingBXQuickMessagesTextChatCell";
static NSString * const incomingBXQuickMessagesMediaChatCell = @"incomingBXQuickMessagesMediaChatCell";
static NSString * const outgoingBXQuickMessagesTextChatCell = @"outgoingBXQuickMessagesTextChatCell";
static NSString * const outgoingBXQuickMessagesMediaChatCell = @"outgoingBXQuickMessagesMediaChatCell";

@interface BXQuickMessagesViewController () <BXQuickMessagesMultiInputViewDelegate,
BXQuickMessagesChatCellDelegate>

@property (strong, nonatomic) BXQuickMessagesMultiInputView *multiInputView;

@property (strong, nonatomic) NSMutableDictionary *displayNameCacheDic;
@property (strong, nonatomic) NSMutableDictionary *displayAvatarCacheDic;
@property (strong, nonatomic) NSMutableDictionary *calculateHeightCells;

@property (assign, nonatomic) BOOL isLoading;

@property (assign, nonatomic) BOOL viewDidAppearOnce;

@end

@implementation BXQuickMessagesViewController

@synthesize multiInputView = _multiInputView;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self addCollectionViewContentOffsetKVOObserver];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (!_viewDidAppearOnce) {
        _viewDidAppearOnce = YES;
    }
}

- (NSMutableArray *)dataSource
{
    if (!_dataSource) {
        _dataSource = [[NSMutableArray alloc] init];
    }
    
    return _dataSource;
}

#pragma mark - need override methods
- (void)bxSendTextMessage:(NSString *)text{}

- (void)bxStartRecordAudio {}
- (void)bxFinishRecordAudio {}
- (void)bxCancelRecordAudio {}

- (NSInteger)bxNumberOfItemsInMoreChoicesView
{
    return 3;
}

- (BXMessagesInputMoreChoiceItem *)bxItemForMoreChoicesViewAtIndex:(NSUInteger)index
{
    BXMessagesInputMoreChoiceItem *item = [[BXMessagesInputMoreChoiceItem alloc] init];
    
    item.cellNibName = NSStringFromClass([BXMessagesInputMoreChoiceCell class]);
    
    [item setConfigureBlock:^(UICollectionViewCell *cell) {
        [self bxConfigureCell:(BXMessagesInputMoreChoiceCell *)cell atIndex:index];
    }];
    
    [item setSelectBlock:^{
        [self bxSelectMoreChoiceItemAtIndex:index];
    }];
    
    return item;
}

- (void)bxPickPhotoFromLibraryButtonPressed {}
- (void)bxTakePhotoFromCameraButtonPressed {}
- (void)bxSendMyLocationButtonPressed {}

#pragma mark - multi input view
- (BXQuickMessagesMultiInputView *)multiInputView
{
    if (!_multiInputView) {
        _multiInputView = [[BXQuickMessagesMultiInputView alloc] init];
        _multiInputView.delegate = self;
    }
    
    return _multiInputView;
}

- (void)bxQuickMessagesMultiInputView:(BXMessagesMultiInputView *)multiInputView sendText:(NSString *)text
{
    [self bxSendTextMessage:text];
}

- (void)bxQuickMessagesMultiInputView:(BXMessagesMultiInputView *)multiInputView startRecordAudio:(UIButton *)audioButton
{
    [self bxStartRecordAudio];
}

- (void)bxQuickMessagesMultiInputView:(BXMessagesMultiInputView *)multiInputView finishRecordAudio:(UIButton *)audioButton
{
    [self bxFinishRecordAudio];
}

- (void)bxQuickMessagesMultiInputView:(BXMessagesMultiInputView *)multiInputView cancelRecordAudio:(UIButton *)audioButton
{
    [self bxCancelRecordAudio];
}

- (NSInteger)bxNumberOfMoreChoicesItems:(BXMessagesMultiInputView *)multiInputView
{
    return [self bxNumberOfItemsInMoreChoicesView];
}

- (BXMessagesInputMoreChoiceItem *)bxQuickMessagesMultiInputView:(BXMessagesMultiInputView *)multiInputView moreChoicesItemAtIndex:(NSUInteger)index
{
    return [self bxItemForMoreChoicesViewAtIndex:index];
}

#pragma mark - collection view
- (NSInteger)bx_numberOfRowsInCollectionView:(UICollectionView *)collectionView
{
    return self.dataSource.count;
}

- (UICollectionViewCell *)bx_collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    BXQuickMessage *message = [self.dataSource objectAtIndex:indexPath.item];
    BOOL isMyMessage = [message.senderId isEqualToString:self.selfId];
    
    UICollectionViewCell *cell;
    
    if (message.messageType == BXQuickMessageType_Status) {
        BXQuickMessagesStatusCell *statusCell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([BXQuickMessagesStatusCell class]) forIndexPath:indexPath];
        [statusCell setupCellWithMessage:message];
        cell = statusCell;
    }else if (message.messageType == BXQuickMessageType_Media) {
        BXQuickMessagesMediaChatCell *mediaCell = [collectionView dequeueReusableCellWithReuseIdentifier:isMyMessage?outgoingBXQuickMessagesMediaChatCell:incomingBXQuickMessagesMediaChatCell forIndexPath:indexPath];
        mediaCell.avatarPosition = isMyMessage? BXQuickMessagesChatCellAvatarPostion_RightTop : BXQuickMessagesChatCellAvatarPostion_LeftTop;
        
        [mediaCell setupCellWithMessage:message];
        mediaCell.delegate = self;
        
        [self bx_setupUserInfoForCell:mediaCell atIndexPath:indexPath];
        
        mediaCell.sendStatus = message.sendStatus;
        
        cell = mediaCell;
    }else {
        BXQuickMessagesTextChatCell *textCell = [collectionView dequeueReusableCellWithReuseIdentifier:isMyMessage?outgoingBXQuickMessagesTextChatCell:incomingBXQuickMessagesTextChatCell forIndexPath:indexPath];
        textCell.avatarPosition = isMyMessage? BXQuickMessagesChatCellAvatarPostion_RightTop : BXQuickMessagesChatCellAvatarPostion_LeftTop;
        
        [textCell setupCellWithMessage:message];
        textCell.delegate = self;
        [self bx_setupUserInfoForCell:textCell atIndexPath:indexPath];
        
        textCell.sendStatus = message.sendStatus;

        cell = textCell;
    }
    
    if ([cell respondsToSelector:@selector(showTimeWithDate:)]) {
        BOOL showDate = [self bx_showTimeForCellAtIndexPath:indexPath];
        [cell performSelector:@selector(showTimeWithDate:) withObject:showDate? message.date : nil];
    }
    
    return cell;
}

- (void)bx_collectionView:(UICollectionView *)collectionView updateUserInfoForItem:(BXQuickMessagesBaseChatCell *)item atIndexPath:(NSIndexPath *)indexPath
{
    [self bx_setupUserInfoForCell:item atIndexPath:indexPath];
}

- (void)bx_setupUserInfoForCell:(BXQuickMessagesBaseChatCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    if (!cell) {
        return;
    }
    
    BXQuickMessage *message = [self.dataSource objectAtIndex:indexPath.item];

    NSString *storedName = [self.displayNameCacheDic objectForKey:message.senderId];
    NSString *storedImage = [self.displayAvatarCacheDic objectForKey:message.senderId];
    
    if (!storedName) {
        storedName = [self bx_collectionView:self.collectionView displayNameForItem:cell atIndexPath:indexPath];
        
        if (storedName) {
            [self.displayNameCacheDic setObject:storedName forKey:message.senderId];
        }
    }
    
    if (!storedImage) {
        storedImage = [self bx_collectionView:self.collectionView displayAvatarForItem:cell atIndexPath:indexPath];
        
        if (storedImage) {
            [self.displayAvatarCacheDic setObject:storedImage forKey:message.senderId];
        }
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (storedName) {
            cell.senderName.text = storedName;
        }
        
        if (storedImage) {
            [cell.avatar sd_setImageWithURL:[NSURL URLWithString:storedImage] placeholderImage:[UIImage imageNamed:@"avator" inBundle:[NSBundle buk_bundle] compatibleWithTraitCollection:nil]];
        }
    });
}

- (NSString *)bx_collectionView:(UICollectionView *)collectionView displayNameForItem:(BXQuickMessagesBaseChatCell *)item atIndexPath:(NSIndexPath *)indexPath
{
    return @"测试用户";
}

- (NSString *)bx_collectionView:(UICollectionView *)collectionView displayAvatarForItem:(BXQuickMessagesBaseChatCell *)item atIndexPath:(NSIndexPath *)indexPath
{
    return @"avator";
}

- (NSMutableDictionary *)calculateHeightCells
{
    if (!_calculateHeightCells) {
        _calculateHeightCells = [[NSMutableDictionary alloc] initWithCapacity:3];
    }
    
    return _calculateHeightCells;
}

- (CGFloat)bx_collectionView:(UICollectionView *)collectionView heightForItemAtIndexPath:(NSIndexPath *)indexPath
{
    BXQuickMessage *message = [self.dataSource objectAtIndex:indexPath.item];
    
    UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];

    if (!cell) {
        Class cellClass;

        if (message.messageType == BXQuickMessageType_Status) {
            cellClass = [BXQuickMessagesStatusCell class];
        }else if (message.messageType == BXQuickMessageType_Media) {
            cellClass = [BXQuickMessagesMediaChatCell class];
        }else {
            cellClass = [BXQuickMessagesTextChatCell class];
        }
       
        NSString *key = NSStringFromClass(cellClass);
        cell = [self.calculateHeightCells objectForKey:key];
        if (!cell) {
            cell = [[cellClass alloc] initWithFrame:self.view.bounds];
        }
        
        if ([cell respondsToSelector:@selector(setupCellWithMessage:)]) {
            [cell performSelector:@selector(setupCellWithMessage:) withObject:message];
        }
        
        if ([cell respondsToSelector:@selector(showTimeWithDate:)]) {
            BOOL showDate = [self bx_showTimeForCellAtIndexPath:indexPath];
            [cell performSelector:@selector(showTimeWithDate:) withObject:showDate? message.date : nil];
        }
    }
    
    return [cell systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height;
}

- (void)bx_registerCellsForCollectionView:(UICollectionView *)collectionView
{
    [super bx_registerCellsForCollectionView:collectionView];
    
    [collectionView registerClass:[BXQuickMessagesTextChatCell class] forCellWithReuseIdentifier:incomingBXQuickMessagesTextChatCell];
    [collectionView registerClass:[BXQuickMessagesTextChatCell class] forCellWithReuseIdentifier:outgoingBXQuickMessagesTextChatCell];
    [collectionView registerClass:[BXQuickMessagesMediaChatCell class] forCellWithReuseIdentifier:incomingBXQuickMessagesMediaChatCell];
    [collectionView registerClass:[BXQuickMessagesMediaChatCell class] forCellWithReuseIdentifier:outgoingBXQuickMessagesMediaChatCell];
    [collectionView registerClass:[BXQuickMessagesStatusCell class] forCellWithReuseIdentifier:NSStringFromClass([BXQuickMessagesStatusCell class])];
}

- (NSMutableDictionary *)displayAvatarCacheDic
{
    if (!_displayAvatarCacheDic) {
        _displayAvatarCacheDic = [[NSMutableDictionary alloc] init];
    }
    
    return _displayAvatarCacheDic;
}

- (NSMutableDictionary *)displayNameCacheDic
{
    if (!_displayNameCacheDic) {
        _displayNameCacheDic = [[NSMutableDictionary alloc] init];
    }
    
    return _displayNameCacheDic;
}

- (void)bx_collectionView:(UICollectionView *)collectionView didTapAvatarAtIndexPath:(NSIndexPath *)indexPath {}

- (void)bx_collectionView:(UICollectionView *)collectionView didTapBubleAtIndexPath:(NSIndexPath *)indexPath {}

- (void)bx_collectionView:(UICollectionView *)collectionView didTapResendButtonAtIndexPath:(NSIndexPath *)indexPath {}

- (BOOL)bx_showTimeForCellAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger row = indexPath.item;
    
    if (row == 0) {
        return YES;
    }
    
    BXQuickMessage *message = [self.dataSource objectAtIndex:row];
    BXQuickMessage *preMessage = [self.dataSource objectAtIndex:row-1];
    
    if ([message.date compare:[preMessage.date dateByAddingTimeInterval:60]] == NSOrderedDescending) {
        return YES;
    }
    
    return NO;
}

#pragma mark - chat cell delegate
- (void)bxQuickMessagesChatCellDidTappedAvatar:(BXQuickMessagesBaseChatCell *)cell
{
    NSIndexPath *indexPath = [self.collectionView indexPathForCell:cell];
    [self bx_collectionView:self.collectionView didTapAvatarAtIndexPath:indexPath];
}

- (void)bxQuickMessagesChatCellDidTappedBuble:(BXQuickMessagesBaseChatCell *)cell
{
    NSIndexPath *indexPath = [self.collectionView indexPathForCell:cell];
    [self bx_collectionView:self.collectionView didTapBubleAtIndexPath:indexPath];
}

- (void)bxQuickMessagesChatCellDidTappedResendButton:(BXQuickMessagesBaseChatCell *)cell
{
    NSIndexPath *indexPath = [self.collectionView indexPathForCell:cell];
    [self bx_collectionView:self.collectionView didTapResendButtonAtIndexPath:indexPath];
}

- (void)bxConfigureCell:(BXMessagesInputMoreChoiceCell *)cell atIndex:(NSUInteger)index
{
    NSString *imageName;
    NSString *titleName;
    
    switch (index) {
        case 0:
            imageName = @"sharemore_pic";
            titleName = @"照片";
            break;
            
        case 1:
            imageName = @"sharemore_video";
            titleName = @"拍摄";
            break;
            
        case 2:
            imageName = @"sharemore_location";
            titleName = @"位置";
            break;
            
        default:
            imageName = @"sharemore_openapi";
            titleName = @"更多";
            break;
    }
    
    [cell.ibImageView setImage:[UIImage imageNamed:imageName inBundle:[NSBundle buk_bundle] compatibleWithTraitCollection:nil]];
    cell.ibLabel.text = titleName;
}

- (void)bxSelectMoreChoiceItemAtIndex:(NSUInteger)index
{
    switch (index) {
        case 0:
            [self bxPickPhotoFromLibraryButtonPressed];
            break;
            
        case 1:
            [self bxTakePhotoFromCameraButtonPressed];
            break;
            
        case 2:
            [self bxSendMyLocationButtonPressed];
            break;
            
        default:
            break;
    }
}

#pragma mark - load more collection view data
- (void)setShowLoadMore:(BOOL)showLoadMore
{
    if (_showLoadMore == showLoadMore) {
        return;
    }
    [self willChangeValueForKey:NSStringFromSelector(@selector(showLoadMore))];
    _showLoadMore = showLoadMore;
    [self didChangeValueForKey:NSStringFromSelector(@selector(showLoadMore))];
    
    if (showLoadMore) {
        [self.collectionView.loadingIndicator startAnimating];
    }else {
        [self.collectionView.loadingIndicator stopAnimating];
    }
}

- (void)addCollectionViewContentOffsetKVOObserver
{
    @try {
        [self.collectionView addObserver:self forKeyPath:NSStringFromSelector(@selector(contentOffset)) options:NSKeyValueObservingOptionNew context:nil];
    }
    @catch (NSException *exception) {
        NSLog(@"Messages Kit: Add CollectionView ContentOffset Error!");
    }
}

- (void)removeCollectionViewContentOffsetKVOObserver
{
    @try {
        [self.collectionView removeObserver:self forKeyPath:NSStringFromSelector(@selector(contentOffset))];
    }
    @catch (NSException *exception) {
        NSLog(@"Messages Kit: Remove CollectionView ContentOffset Error!");
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == self.collectionView && [keyPath isEqualToString:NSStringFromSelector(@selector(contentOffset))]) {

        if (!_showLoadMore || self.isLoading || self.collectionView.contentOffset.y > 0 || !self.viewDidAppearOnce || self.collectionView.isDragging) {
            return;
        }
    
        self.isLoading = YES;
        
        [UIView animateWithDuration:0.25f animations:^{
            self.collectionView.contentInset = UIEdgeInsetsMake(25, 0, 0, 0);
        } completion:^(BOOL finished) {
            NSArray *moreData = [self bx_moreCollectionViewDataSourceForLoadMore:self.collectionView];
            
            if (moreData && moreData.count) {
                [moreData enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                    [self.dataSource insertObject:obj atIndex:0];
                }];
                
                CGFloat oldOffset = self.collectionView.contentSize.height - self.collectionView.contentOffset.y;
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    [self.collectionView setContentOffset:self.collectionView.contentOffset animated:NO];
                    [self.collectionView reloadData];
                    [self.collectionView layoutIfNeeded];
                    [self.collectionView setContentOffset:CGPointMake(0.0, self.collectionView.contentSize.height - oldOffset) animated:NO];
                    self.isLoading = NO;
                    self.collectionView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
                });
            }
        }];

    }else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (NSArray *)bx_moreCollectionViewDataSourceForLoadMore:(UICollectionView *)collectionView
{
    return nil;
}

#pragma mark - 

- (void)dealloc
{
    [self removeCollectionViewContentOffsetKVOObserver];
}
@end
