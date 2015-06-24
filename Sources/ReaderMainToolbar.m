//
//	ReaderMainToolbar.m
//	Reader v2.8.6
//
//	Created by Julius Oklamcak on 2011-07-01.
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
#import "ReaderMainToolbar.h"
#import "ReaderDocument.h"

#import <MessageUI/MessageUI.h>

@implementation ReaderMainToolbar
{
	UIButton *markButton;

	UIImage *markImageN;
	UIImage *markImageY;
}

#pragma mark - Constants

#define BUTTON_X 8.0f
#define BUTTON_Y 8.0f

#define BUTTON_SPACE 8.0f
#define BUTTON_HEIGHT 30.0f

#define BUTTON_FONT_SIZE 15.0f
#define TEXT_BUTTON_PADDING 24.0f

#define ICON_BUTTON_WIDTH 40.0f

#define TITLE_FONT_SIZE 19.0f
#define TITLE_HEIGHT 28.0f

#pragma mark - Properties

@synthesize delegate;

#pragma mark - ReaderMainToolbar instance methods

- (instancetype)initWithFrame:(CGRect)frame
{
	return [self initWithFrame:frame document:nil];
}

- (instancetype)initWithFrame:(CGRect)frame document:(ReaderDocument *)document

{
    
    assert(document != nil); // Must have a valid ReaderDocument
    
    
    
    if ((self = [super initWithFrame:frame]))
        
    {
        
        CGFloat viewWidth = self.bounds.size.width; // Toolbar view width
        
        
        
        UIButton *doneButton = [UIButton buttonWithType:UIButtonTypeCustom];
        
        doneButton.frame = CGRectMake(0, 23, 50, 38);
        
        [doneButton setImage:[UIImage imageNamed:@"TYReader-day_back"] forState:UIControlStateNormal];
        
        [doneButton setImageEdgeInsets:UIEdgeInsetsMake(10, 20, 10, 20)];
        
        
        
        [doneButton addTarget:self action:@selector(doneButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        
        //doneButton.backgroundColor = [UIColor grayColor];
        
        doneButton.exclusiveTouch = YES;
        
        
        [self addSubview:doneButton];
        
        
        
        
//#if (READER_ENABLE_THUMBS == TRUE) // Option
//        
//        
//        
//        UIButton *thumbsButton = [UIButton buttonWithType:UIButtonTypeCustom];
//        
//        thumbsButton.frame = CGRectMake(60, BUTTON_Y, 30, BUTTON_HEIGHT);
//        
//        [thumbsButton setImage:[UIImage imageNamed:@"Reader-Thumbs"] forState:UIControlStateNormal];
//        
//        [thumbsButton addTarget:self action:@selector(thumbsButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
//        
//        //[thumbsButton setBackgroundImage:buttonH forState:UIControlStateHighlighted];
//        
//        //[thumbsButton setBackgroundImage:buttonN forState:UIControlStateNormal];
//        
//        thumbsButton.autoresizingMask = UIViewAutoresizingNone;
//        
//        //thumbsButton.backgroundColor = [UIColor grayColor];
//        
//        thumbsButton.exclusiveTouch = YES;
//        
//        
//        
//        [self addSubview:thumbsButton]; //leftButtonX += (iconButtonWidth + buttonSpacing);
//        
//        
//        
//        
//        
//#endif // end of READER_ENABLE_THUMBS Option
        
        
        
        
        
        
        
        
        
        UIButton *flagButton = [UIButton buttonWithType:UIButtonTypeCustom];
        
        flagButton.frame = CGRectMake(viewWidth-25-22, 21, 42, 42);
        
        
        
        [flagButton addTarget:self action:@selector(markButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        
        [flagButton setImage:[UIImage imageNamed:@"TYReader-day_bookmark"] forState:UIControlStateNormal];
        
        [flagButton setImage:[UIImage imageNamed:@"TYReader-bookmark_pressed"] forState:UIControlStateSelected];
        
        [flagButton setImageEdgeInsets:UIEdgeInsetsMake(10, 10, 10, 10)];
        
        
        
        flagButton.exclusiveTouch = YES;
        
        
        
        [self addSubview:flagButton];
        
        
        
        markButton = flagButton;
        markButton.enabled = NO;
        markButton.tag = NSIntegerMin;
        
        
        
       markImageN = [UIImage imageNamed:@"TYReader-day_bookmark"]; // N image
        
       markImageY = [UIImage imageNamed:@"TYReader-bookmark_pressed"]; // Y image
        
        
        
        
        
    }
    
    
    
    return self;
    
}

- (void)setBookmarkState:(BOOL)state
{
#if (READER_BOOKMARKS == TRUE) // Option

	if (state != markButton.tag) // Only if different state
	{
		if (self.hidden == NO) // Only if toolbar is visible
		{
			UIImage *image = (state ? markImageY : markImageN);

			[markButton setImage:image forState:UIControlStateNormal];
		}

		markButton.tag = state; // Update bookmarked state tag
	}

	if (markButton.enabled == NO) markButton.enabled = YES;

#endif // end of READER_BOOKMARKS Option
}

- (void)updateBookmarkImage
{
#if (READER_BOOKMARKS == TRUE) // Option

	if (markButton.tag != NSIntegerMin) // Valid tag
	{
		BOOL state = markButton.tag; // Bookmarked state

		UIImage *image = (state ? markImageY : markImageN);

		[markButton setImage:image forState:UIControlStateNormal];
	}

	if (markButton.enabled == NO) markButton.enabled = YES;

#endif // end of READER_BOOKMARKS Option
}

- (void)hideToolbar
{
	if (self.hidden == NO)
	{
		[UIView animateWithDuration:0.25 delay:0.0
			options:UIViewAnimationOptionCurveLinear | UIViewAnimationOptionAllowUserInteraction
			animations:^(void)
			{
				self.alpha = 0.0f;
			}
			completion:^(BOOL finished)
			{
				self.hidden = YES;
			}
		];
	}
}

- (void)showToolbar
{
	if (self.hidden == YES)
	{
		[self updateBookmarkImage]; // First

		[UIView animateWithDuration:0.25 delay:0.0
			options:UIViewAnimationOptionCurveLinear | UIViewAnimationOptionAllowUserInteraction
			animations:^(void)
			{
				self.hidden = NO;
				self.alpha = 1.0f;
			}
			completion:NULL
		];
	}
}

#pragma mark - UIButton action methods

- (void)doneButtonTapped:(UIButton *)button
{
	[delegate tappedInToolbar:self doneButton:button];
}

- (void)thumbsButtonTapped:(UIButton *)button
{
	[delegate tappedInToolbar:self thumbsButton:button];
}

- (void)exportButtonTapped:(UIButton *)button
{
	[delegate tappedInToolbar:self exportButton:button];
}

- (void)printButtonTapped:(UIButton *)button
{
	[delegate tappedInToolbar:self printButton:button];
}

- (void)emailButtonTapped:(UIButton *)button
{
	[delegate tappedInToolbar:self emailButton:button];
}

- (void)markButtonTapped:(UIButton *)button
{
	[delegate tappedInToolbar:self markButton:button];
}

@end
