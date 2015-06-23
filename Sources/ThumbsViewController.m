//
//	ThumbsViewController.m
//	Reader v2.8.6
//
//	Created by Julius Oklamcak on 2011-09-01.
//	Copyright © 2011-2015 Julius Oklamcak. All rights reserved.
//
//	Permission is hereby granted, free of charge, to any person obtaining a copy
//	of this software and associated documentation files (the "Software"), to deal
//	in the Software without restriction, including without limitation the rights to
//	use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
//	of the Software, and to permit persons to whom the Software is furnished to
//	do so, subject to the following conditions:
//
//	The above copyright notice and this permission notice shall be included in all
//	copies or substantial portions of the Software.
//
//	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
//	OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//	WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
//	CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "ReaderConstants.h"
#import "ThumbsViewController.h"
#import "ReaderThumbRequest.h"
#import "ReaderThumbCache.h"
#import "ReaderDocument.h"
#import "ReaderCustomPresentAnimaton.h"
#import "ThumbsBookmarkCell.h"

#import <QuartzCore/QuartzCore.h>
#import "BookmarkShowModel.h"

@interface ThumbsViewController () <ThumbsMainToolbarDelegate, ReaderThumbsViewDelegate,UITableViewDataSource,UITableViewDelegate,UIViewControllerTransitioningDelegate>

@property(nonatomic,strong) UISegmentedControl *segmentedControl;

@end

@implementation ThumbsViewController
{
	ReaderDocument *document;

	ThumbsMainToolbar *mainToolbar;

	ReaderThumbsView *theThumbsView;

	NSMutableArray *bookmarked;

	CGPoint thumbsOffset;
	CGPoint markedOffset;

	BOOL updateBookmarked;
	BOOL showBookmarked;
    
    UIScrollView *_scrollView;
    UITableView *_bookmarkTableView;
    UIImageView *_nobookmarkImageView;
}

#pragma mark - Constants

#define STATUS_HEIGHT 20.0f

#define SEGMENT_CONTROL_HEIGHT 44.0f

#define PAGE_THUMB_SMALL 160
#define PAGE_THUMB_LARGE 256

#pragma mark - Properties

@synthesize delegate;

#pragma mark - UIViewController methods

- (instancetype)initWithReaderDocument:(ReaderDocument *)object
{
	if ((self = [super initWithNibName:nil bundle:nil])) // Initialize superclass
	{
		if ((object != nil) && ([object isKindOfClass:[ReaderDocument class]])) // Valid object
		{
			updateBookmarked = YES; bookmarked = [NSMutableArray new]; // Bookmarked pages

			document = object; // Retain the ReaderDocument object for our use
		}
		else // Invalid ReaderDocument object
		{
			self = nil;
		}
	}

	return self;
}

- (void)viewDidLoad
{
	[super viewDidLoad];

	assert(delegate != nil); assert(document != nil);

	self.view.backgroundColor = PDFUIColorFromRGB(0xEDEDEE); // Neutral gray
    UIView *headerView = [self createSegmentView];
    
    [self.view addSubview:headerView];
    
    
    
    CGRect listRect =  CGRectMake(0, CGRectGetMaxY(headerView.frame) + 25, CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame) - CGRectGetMaxY(headerView.frame));
    
    _scrollView = [[UIScrollView alloc]initWithFrame:listRect];
    _scrollView.pagingEnabled = YES;
    _scrollView.showsHorizontalScrollIndicator = NO;
    _scrollView.showsVerticalScrollIndicator = NO;
    [_scrollView setContentSize:CGSizeMake(_scrollView.frame.size.width * 2, _scrollView.frame.size.height)];
    
    [self.view addSubview:_scrollView];
    
	theThumbsView = [[ReaderThumbsView alloc] initWithFrame:_scrollView.bounds]; // ReaderThumbsView
 	theThumbsView.thumbsDelegate = self; // ReaderThumbsViewDelegate
    theThumbsView.backgroundColor =[UIColor clearColor];
    theThumbsView.currentIndex = [document.pageNumber integerValue] - 1;
	[_scrollView addSubview:theThumbsView];

    [theThumbsView setThumbSize:CGSizeMake(PAGE_THUMB_SMALL, PAGE_THUMB_SMALL)];
	 
    CGRect bookmarkRect = CGRectOffset(_scrollView.bounds, listRect.size.width, 0);
    
    //书签
    _bookmarkTableView = [[UITableView alloc] initWithFrame:bookmarkRect style:UITableViewStylePlain];
    _bookmarkTableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    _bookmarkTableView.delegate = self;
    _bookmarkTableView.dataSource = self;
    _bookmarkTableView.separatorInset = UIEdgeInsetsZero;
    _bookmarkTableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
   
    _bookmarkTableView.backgroundColor =  PDFUIColorFromRGB(0xededef);
    
    _bookmarkTableView.hidden = NO;
    _bookmarkTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    [_scrollView addSubview:_bookmarkTableView];
    [_bookmarkTableView reloadData];
    
    CGFloat backImageViewWidth = 33;
    CGFloat backImageViewHeight = 66;
    
    UIButton *backButton = [[UIButton alloc]initWithFrame:CGRectMake( CGRectGetWidth(self.view.frame) - backImageViewWidth, (CGRectGetHeight(self.view.frame) - backImageViewHeight)/2.0, backImageViewWidth, backImageViewHeight) ];
    [backButton setImage:[UIImage imageNamed:@"TYReader-day_backread"] forState:UIControlStateNormal];
    //[backButton addTarget:self action:@selector(backActionff) forControlEvents:UIControlEventTouchUpInside];
    [backButton addTarget:self action:@selector(backAction) forControlEvents:UIControlEventTouchUpInside];
   
    
    [self.view addSubview:backButton];
  
    _nobookmarkImageView = [[UIImageView alloc] initWithFrame:CGRectMake((self.view.frame.size.width-211)/2, 125, 211, 224)];
    [_nobookmarkImageView setImage:[UIImage imageNamed:@"TYReader-day_bookmarktip"]];
    _nobookmarkImageView.hidden = YES;
    [_bookmarkTableView addSubview:_nobookmarkImageView];
    
}

-(void)backAction
{
    [delegate dismissThumbsViewController:self];
}


-(UIView *)createSegmentView
{
    UIView *tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 20, self.view.frame.size.width, SEGMENT_CONTROL_HEIGHT)];
    
    CGFloat segmentedControlWidth = 200;
    CGFloat segmentedControlHeigth = 29;
    CGFloat segmentedControlX = self.view.frame.size.width /2.0 - segmentedControlWidth / 2.0;
    CGFloat segmentedControlY = 15;
    UISegmentedControl *segmentedControl = [[UISegmentedControl alloc] initWithItems:@[@"目录",@"书签"]];
    
    [segmentedControl setTitleTextAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:16]} forState:UIControlStateNormal];
    [segmentedControl setTitleTextAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:16]} forState:UIControlStateHighlighted];
    segmentedControl.selectedSegmentIndex = 0;
    segmentedControl.frame = CGRectMake(segmentedControlX, segmentedControlY, segmentedControlWidth, segmentedControlHeigth);
    [segmentedControl addTarget:self action:@selector(segmentSelected:) forControlEvents:UIControlEventValueChanged];
    self.segmentedControl = segmentedControl;
    [tableHeaderView addSubview:segmentedControl];
    
    return tableHeaderView;
}


#pragma mark - UIViewControllerTransitioningDelegate

#pragma mark - Action
-(void)backActionff
{
    [UIView animateWithDuration:0.35 animations:^{
        self.view.frame =  CGRectOffset(self.view.frame, -CGRectGetWidth(self.view.frame), 0);
    } completion:^(BOOL finished) {
        [self.view removeFromSuperview];
    }];
}
-(void)segmentSelected:(id)sender
{
    UISegmentedControl *segmentedControl = sender;
    NSInteger selectedIndex = segmentedControl.selectedSegmentIndex;
    [_scrollView setContentOffset:CGPointMake(selectedIndex * CGRectGetWidth(_scrollView.frame), 0) animated:YES];
    if (selectedIndex == 1) {
        [self reloadBookmarkTable];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];

	[theThumbsView reloadThumbsCenterOnIndex:([document.pageNumber integerValue] - 1)]; // Page
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (BOOL)prefersStatusBarHidden
{
	return YES;
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
	return UIStatusBarStyleLightContent;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

/*
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation duration:(NSTimeInterval)duration
{
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
	//if (fromInterfaceOrientation == self.interfaceOrientation) return;
}
*/

- (void)didReceiveMemoryWarning
{
#ifdef DEBUG
	NSLog(@"%s", __FUNCTION__);
#endif

	[super didReceiveMemoryWarning];
}
#pragma mark - UITableViewDelegate
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
     NSNumber *page = [[((BookmarkShowModel *)[bookmarked objectAtIndex:indexPath.section]).bookmarkArray objectAtIndex:indexPath.row] objectForKey:@"page"];
    [delegate thumbsViewController:self gotoPage:page.integerValue]; // Show the selected page
    [delegate dismissThumbsViewController:self]; // Dismiss thumbs display
}
#pragma mark - UITableViewDatasource
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    NSInteger count = [bookmarked count];
    _nobookmarkImageView.hidden = (count != 0) || _segmentedControl.selectedSegmentIndex == 0;
    return count;
}
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 50.0f;
}
-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 40.0f;
}
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [((BookmarkShowModel *)[bookmarked objectAtIndex:section]).bookmarkArray count];
}


-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ThumbsBookmarkCell *tableViewCell = [tableView dequeueReusableCellWithIdentifier:@"PDF_BOOKMARK_CELL"];
    if (tableViewCell == nil) {
        tableViewCell = [[ThumbsBookmarkCell alloc]initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"PDF_BOOKMARK_CELL"];
    }
 
    NSNumber *page = [[((BookmarkShowModel *)[bookmarked objectAtIndex:indexPath.section]).bookmarkArray objectAtIndex:indexPath.row] objectForKey:@"page"];
    tableViewCell.textLabel.text = [NSString stringWithFormat:@"第%@页",page];
    NSDateFormatter *formatter = [[NSDateFormatter alloc]init];
    [formatter setDateFormat:@"HH:mm"];
    tableViewCell.detailTextLabel.text = [formatter stringFromDate:[[((BookmarkShowModel *)[bookmarked objectAtIndex:indexPath.section]).bookmarkArray objectAtIndex:indexPath.row] objectForKey:@"date"]];
    tableViewCell.backgroundColor = [UIColor clearColor];
    return tableViewCell;
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *hederView = [[UIView alloc]init];
    
    UILabel *dateTimeLabel = [[UILabel alloc]initWithFrame:hederView.bounds];
    dateTimeLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    dateTimeLabel.textAlignment = NSTextAlignmentCenter;
    dateTimeLabel.font = [UIFont systemFontOfSize:11];
    dateTimeLabel.textColor = PDFUIColorFromRGB(0x808080);
    dateTimeLabel.backgroundColor = [UIColor clearColor];
    dateTimeLabel.text = ((BookmarkShowModel *)[bookmarked objectAtIndex:section]).addBookmarkDate;
    [hederView addSubview:dateTimeLabel];
    UIImageView *line = [[UIImageView alloc]initWithFrame:CGRectMake(25, 39, CGRectGetWidth(tableView.frame)-50, 1)];
    line.image = [UIImage imageNamed:@"TYReader-day_line"];
    line.tag = 121;
    
    [hederView addSubview:line];
    return hederView;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView == _bookmarkTableView) {
        if (editingStyle == UITableViewCellEditingStyleDelete) {
            BookmarkShowModel *bookmarkInOneDay = [bookmarked objectAtIndex:indexPath.section];
            NSDictionary *bookmarkInfo = [bookmarkInOneDay.bookmarkArray objectAtIndex:indexPath.row];
            [bookmarkInOneDay.bookmarkArray removeObjectAtIndex:indexPath.row];
            // Delete the row from the data source.
            
            [_bookmarkTableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            if (bookmarkInOneDay.bookmarkArray.count == 0) {
                
                [bookmarked removeObject:bookmarkInOneDay];
                [_bookmarkTableView deleteSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationFade];
            }
            
            [delegate thumbsViewController:self deleteBookmark:[bookmarkInfo objectForKey:@"page"] ];
        }
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return @"删除";
}
#pragma mark - ThumbsMainToolbarDelegate methods

- (void)tappedInToolbar:(ThumbsMainToolbar *)toolbar showControl:(UISegmentedControl *)control
{
	switch (control.selectedSegmentIndex)
	{
		case 0: // Show all page thumbs
		{
			showBookmarked = NO; // Show all thumbs

			markedOffset = [theThumbsView insetContentOffset];

			[theThumbsView reloadThumbsContentOffset:thumbsOffset];

			break; // We're done
		}

		case 1: // Show bookmarked thumbs
		{
			showBookmarked = YES; // Only bookmarked

			thumbsOffset = [theThumbsView insetContentOffset];

			if (updateBookmarked == YES) // Update bookmarked list
			{
				[bookmarked removeAllObjects]; // Empty the list first

				[document.bookmarks enumerateIndexesUsingBlock: // Enumerate
					^(NSUInteger page, BOOL *stop)
					{
						[bookmarked addObject:[NSNumber numberWithInteger:page]];
					}
				];

				markedOffset = CGPointZero; updateBookmarked = NO; // Reset
			}

			[theThumbsView reloadThumbsContentOffset:markedOffset];

			break; // We're done
		}
	}
}

-(void) reloadBookmarkTable
{
    [bookmarked removeAllObjects]; // Empty the list first
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    //设定时间格式,这里可以设置成自己需要的格式
    [dateFormatter setDateFormat:@"yyyy-MM-dd"];
    [document.bookmarkDicts enumerateKeysAndObjectsUsingBlock:^(NSNumber *page, NSDate *bookmarkDate, BOOL *stop) {
        __block  BOOL isCreateDate = NO;
        NSString *currentDateStr = [dateFormatter stringFromDate:bookmarkDate];
        //如果已经创建该日期的书签数组
        [bookmarked enumerateObjectsUsingBlock:^(BookmarkShowModel* model, NSUInteger idx, BOOL *stop) {
            if ([model.addBookmarkDate isEqualToString:currentDateStr]) {
                [model.bookmarkArray addObject:@{@"page":page,@"date":bookmarkDate}];
                isCreateDate = YES;
            }
        }];
        //该日期的书签数组没创建
        if (!isCreateDate) {
            BookmarkShowModel *model = [[BookmarkShowModel alloc]init];
            model.bookmarkArray = [[NSMutableArray alloc]init];
            [model.bookmarkArray addObject:@{@"page":page,@"date":bookmarkDate}];
            model.addBookmarkDate = currentDateStr;
            [bookmarked addObject:model];
        }
    }];
   
    [_bookmarkTableView reloadData];
}

- (void)tappedInToolbar:(ThumbsMainToolbar *)toolbar doneButton:(UIButton *)button
{
	[delegate dismissThumbsViewController:self]; // Dismiss thumbs display
}

#pragma mark - UIThumbsViewDelegate methods

- (NSUInteger)numberOfThumbsInThumbsView:(ReaderThumbsView *)thumbsView
{
	return (showBookmarked ? bookmarked.count : [document.pageCount integerValue]);
}

- (id)thumbsView:(ReaderThumbsView *)thumbsView thumbCellWithFrame:(CGRect)frame
{
	return [[ThumbsPageThumb alloc] initWithFrame:frame];
}

- (void)thumbsView:(ReaderThumbsView *)thumbsView updateThumbCell:(ThumbsPageThumb *)thumbCell forIndex:(NSInteger)index
{
	CGSize size = [thumbCell maximumContentSize]; // Get the cell's maximum content size

	NSInteger page = (showBookmarked ? [[bookmarked objectAtIndex:index] integerValue] : (index + 1));

	[thumbCell showText:[[NSString alloc] initWithFormat:@"%i", (int)page]]; // Page number place holder
    
	[thumbCell showBookmark:[document.bookmarks containsIndex:page]]; // Show bookmarked status

    [thumbCell showBackView:[document.pageNumber integerValue] == index + 1];
	NSURL *fileURL = document.fileURL; NSString *guid = document.guid; NSString *phrase = document.password; // Document info

	ReaderThumbRequest *thumbRequest = [ReaderThumbRequest newForView:thumbCell fileURL:fileURL password:phrase guid:guid page:page size:size];

	UIImage *image = [[ReaderThumbCache sharedInstance] thumbRequest:thumbRequest priority:YES]; // Request the thumbnail

	if ([image isKindOfClass:[UIImage class]]) [thumbCell showImage:image]; // Show image from cache
}

- (void)thumbsView:(ReaderThumbsView *)thumbsView refreshThumbCell:(ThumbsPageThumb *)thumbCell forIndex:(NSInteger)index
{
	NSInteger page = (showBookmarked ? [[bookmarked objectAtIndex:index] integerValue] : (index + 1));
	[thumbCell showBookmark:[document.bookmarks containsIndex:page]]; // Show bookmarked status
    [thumbCell showBackView:[document.pageNumber integerValue] == index + 1];
}

- (void)thumbsView:(ReaderThumbsView *)thumbsView updateThumbCell:thumbCell currentThumbCell:currCell didSelectThumbWithIndex:(NSInteger)index
{
	NSInteger page = (showBookmarked ? [[bookmarked objectAtIndex:index] integerValue] : (index + 1));

	[delegate thumbsViewController:self gotoPage:page]; // Show the selected page
    [currCell showBackView:NO];
    [thumbCell showBackView:[document.pageNumber integerValue] == index + 1];
	[delegate dismissThumbsViewController:self]; // Dismiss thumbs display
}

- (void)thumbsView:(ReaderThumbsView *)thumbsView didPressThumbWithIndex:(NSInteger)index
{
	NSInteger page = (showBookmarked ? [[bookmarked objectAtIndex:index] integerValue] : (index + 1));

	if ([document.bookmarks containsIndex:page]) [document.bookmarks removeIndex:page]; else [document.bookmarks addIndex:page];

	updateBookmarked = YES; [thumbsView refreshThumbWithIndex:index]; // Refresh page thumb
}

@end

#pragma mark -

//
//	ThumbsPageThumb class implementation
//

@implementation ThumbsPageThumb
{
	UIView *backView;

	UIView *tintView;

	UILabel *textLabel;

	UIImageView *bookMark;

	CGSize maximumSize;

	CGRect defaultRect;
}

#pragma mark - Constants

#define CONTENT_INSET 8.0f

#pragma mark - ThumbsPageThumb instance methods

- (CGRect)markRectInImageView
{
	CGRect iconRect = bookMark.frame; iconRect.origin.y = (-2.0f);

	iconRect.origin.x = (imageView.bounds.size.width - bookMark.image.size.width - 8.0f);

	return iconRect; // Frame position rect inside of image view
}

- (instancetype)initWithFrame:(CGRect)frame
{
	if ((self = [super initWithFrame:frame]))
	{
		imageView.contentMode = UIViewContentModeCenter;

		defaultRect = CGRectInset(self.bounds, CONTENT_INSET, CONTENT_INSET);

		maximumSize = defaultRect.size; // Maximum thumb content size

		CGFloat newWidth = ((defaultRect.size.width / 4.0f) * 3.0f);

		CGFloat offsetX = ((defaultRect.size.width - newWidth) * 0.5f);

		defaultRect.size.width = newWidth; defaultRect.origin.x += offsetX;

		imageView.frame = defaultRect; // Update the image view frame

		CGFloat fontSize = (([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) ? 19.0f : 16.0f);

		textLabel = [[UILabel alloc] initWithFrame:defaultRect];

		textLabel.autoresizesSubviews = NO;
		textLabel.userInteractionEnabled = NO;
		textLabel.contentMode = UIViewContentModeRedraw;
		textLabel.autoresizingMask = UIViewAutoresizingNone;
		textLabel.textAlignment = NSTextAlignmentCenter;
		textLabel.font = [UIFont systemFontOfSize:fontSize];
		textLabel.textColor = [UIColor colorWithWhite:0.24f alpha:1.0f];
		textLabel.backgroundColor = [UIColor whiteColor];

		[self insertSubview:textLabel belowSubview:imageView];
        CGRect backViewRect = CGRectInset(defaultRect, -2, -2);
		backView = [[UIView alloc] initWithFrame:backViewRect];

		backView.autoresizesSubviews = NO;
		backView.userInteractionEnabled = NO;
		backView.contentMode = UIViewContentModeRedraw;
		backView.autoresizingMask = UIViewAutoresizingNone;
		backView.backgroundColor = [UIColor clearColor];

#if (READER_SHOW_SHADOWS == TRUE) // Option
        backView.layer.borderWidth = 1;
        backView.layer.borderColor = PDFUIColorFromRGB(0x0077fe).CGColor;
		//backView.layer.shadowOffset = CGSizeMake(0.0f, 1.0f);
		//backView.layer.shadowRadius = 3.0f; backView.layer.shadowOpacity = 1.0f;
		//backView.layer.shadowPath = [UIBezierPath bezierPathWithRect:backView.bounds].CGPath;

#endif // end of READER_SHOW_SHADOWS Option

		[self insertSubview:backView belowSubview:textLabel];

		tintView = [[UIView alloc] initWithFrame:imageView.bounds];

		tintView.hidden = YES;
		tintView.autoresizesSubviews = NO;
		tintView.userInteractionEnabled = NO;
		tintView.contentMode = UIViewContentModeRedraw;
		tintView.autoresizingMask = UIViewAutoresizingNone;
		tintView.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.25f];

		[imageView addSubview:tintView];

		UIImage *image = [UIImage imageNamed:@"Reader-Mark-Y"];

		bookMark = [[UIImageView alloc] initWithImage:image];

		bookMark.hidden = YES;
		bookMark.autoresizesSubviews = NO;
		bookMark.userInteractionEnabled = NO;
		bookMark.contentMode = UIViewContentModeCenter;
		bookMark.autoresizingMask = UIViewAutoresizingNone;
		bookMark.frame = [self markRectInImageView];

		[imageView addSubview:bookMark];
	}

	return self;
}

- (CGSize)maximumContentSize
{
	return maximumSize;
}

- (void)showImage:(UIImage *)image
{
	NSInteger x = (self.bounds.size.width * 0.5f);
	NSInteger y = (self.bounds.size.height * 0.5f);

	CGPoint location = CGPointMake(x, y); // Center point

	CGRect viewRect = CGRectZero; viewRect.size = image.size;

	textLabel.bounds = viewRect; textLabel.center = location; // Position

	imageView.bounds = viewRect; imageView.center = location; imageView.image = image;

	bookMark.frame = [self markRectInImageView]; // Position bookmark image

	tintView.frame = imageView.bounds;
    backView.bounds = CGRectInset(viewRect, -6, -6);
    backView.center = location;

#if (READER_SHOW_SHADOWS == TRUE) // Option

	//backView.layer.shadowPath = [UIBezierPath bezierPathWithRect:backView.bounds].CGPath;

#endif // end of READER_SHOW_SHADOWS Option
}

- (void)reuse
{
	[super reuse]; // Reuse thumb view

	textLabel.text = nil; textLabel.frame = defaultRect;

	imageView.image = nil; imageView.frame = defaultRect;

	bookMark.hidden = YES; bookMark.frame = [self markRectInImageView];

	tintView.hidden = YES;
    tintView.frame = imageView.bounds;
    backView.frame = CGRectInset(defaultRect, -6, -6);
   
#if (READER_SHOW_SHADOWS == TRUE) // Option

	//backView.layer.shadowPath = [UIBezierPath bezierPathWithRect:backView.bounds].CGPath;

#endif // end of READER_SHOW_SHADOWS Option
}

- (void)showBookmark:(BOOL)show
{
    bookMark.hidden = YES;//(show ? NO : YES);
}

- (void)showTouched:(BOOL)touched
{
	tintView.hidden = (touched ? NO : YES);
}

- (void)showText:(NSString *)text
{
	textLabel.text = text;
}

-(void)showBackView:(BOOL)show
{
    backView.hidden = !show;
}
@end
