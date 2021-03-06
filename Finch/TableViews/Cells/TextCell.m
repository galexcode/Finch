//
//  TextCell.m
//  Finch
//
//  Created by Eugene Dorfman on 1/29/13.
//
//

#import "TextCell.h"
#import "TextCellAdapter.h"

NSString* const kTextCellBeginEditingNotification = @"kTextCellBeginEditingNotification";
NSString* const kTextCellDidEndEditingNotification = @"kTextCellDidEndEditingNotification";
NSString* const kTextCellResignFirstResponderNotification = @"kTextCellResignFirstResponderNotification";

@interface TextCell ()<UITextViewDelegate>
@property (nonatomic,weak) TextCellAdapter* textCellAdapter;
@property (nonatomic,strong) IBOutlet UITextView* textView;
@end

@implementation TextCell

- (void) dealloc {
    if (self.textView.editable) {
        [[NSNotificationCenter defaultCenter] removeObserver:self.textView];
    }
}

- (CGFloat) cellHeight {
    NSString* text = _textView.text;
    CGSize frameSize = _textView.frame.size;
    frameSize.height = INFINITY;
    CGSize size = [text sizeWithFont:_textView.font constrainedToSize:frameSize lineBreakMode:NSLineBreakByWordWrapping];
    static const CGFloat margins = 15;
    BOOL hasLineFeedAtEnd = NO;
    if ([text length]) {
        hasLineFeedAtEnd = [text characterAtIndex:[text length]-1]=='\n';
    }
    return size.height+margins+(hasLineFeedAtEnd ? margins : 0);
}

- (void) updateWithAdapter:(TextCellAdapter *)adapter {
    self.textCellAdapter = adapter;
    [self.textView setEditable:[adapter isEditable]];
    [self.textView setText:[adapter text]];
    self.textView.scrollEnabled = NO;
    if (self.textView.editable) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleResignFirstResponderNotification:) name:kTextCellResignFirstResponderNotification object:nil];
        self.textView.delegate = self;
    }
}

- (void) updateTextView {
    CGRect frame = self.textView.frame;
    frame.size.height = self.bounds.size.height;
    self.textView.frame = frame;
}

- (void)handleResignFirstResponderNotification:(NSNotification*)notification {
    [self.textView resignFirstResponder];
}

#pragma mark - UITextViewDelegate

- (void)textViewDidBeginEditing:(UITextView *)textView {
    [[NSNotificationCenter defaultCenter] postNotificationName:kTextCellBeginEditingNotification object:self];
}

- (void)textViewDidChange:(UITextView *)textView {
    self.textCellAdapter.text = textView.text;
    [self.tableView beginUpdates];
    [self.tableView endUpdates];
    [self updateTextView];
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    [[NSNotificationCenter defaultCenter] postNotificationName:kTextCellDidEndEditingNotification object:self];
}

@end