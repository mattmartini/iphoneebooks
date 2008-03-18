// EBookView, for Books.app by Zachary Brewster-Geisz
/*

 This program is free software; you can redistribute it and/or
 modify it under the terms of the GNU General Public License
 as published by the Free Software Foundation; version 2
 of the License.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with this program; if not, write to the Free Software
 Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.

*/
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <UIKit/UITextView.h>
#import <UIKit/UITextTraitsClientProtocol.h>
//#import "UIKeyboardInputProtocol.h"
#import <UIKit/UIWebView.h>
#import <UIKit/UIViewTapInfo.h>
//#import <UIKit/NSString-UIStringDrawing.h>
#import <UIKit/UIView-Geometry.h>

#import "BooksDefaultsController.h" //sigh...
#import "NSString-BooksAppAdditions.h"
#import "HTMLFixer.h"
#import "BooksDefaultsController.h"
#import "ChapteredHTML.h"

@interface EBookView : UITextView
{
  //  UIViewTapInfo *tapinfo;
  NSString                *path;
  float                   size;
  id                      _heartbeatDelegate;
  struct CGRect           lastVisibleRect;
  ChapteredHTML	          *chapteredHTML;
  int                      subchapter;
  BooksDefaultsController *defaults;
 
	//what is the current orientation used in particular to find if the orientation should be changed when receiving a setOrientation message
	int _orient;
	CGAffineTransform _matrixprev;  
	/**
	 * stores the X coordinate of the last mouse down event for swipe detection
	 */
	float _MouseDownX;
	/**
	 * stores the Y coordinate of the last mouse down event for swipe detection
	 */
	float _MouseDownY;
}
typedef enum
{
	kUIViewSwipeUp = 1,
	kUIViewSwipeDown = 2,
	kUIViewSwipeLeft = 4,
	kUIViewSwipeRight = 8
} UIViewSwipeDirection;

- (BOOL)canHandleSwipes;
- (int)  swipe: ( int)num withEvent: ( struct __GSEvent *)event;
- (id)initWithFrame:(struct CGRect)rect;

- (void)loadBookWithPath:(NSString *)thePath subchapter:(int) theSubchapter;
- (void)setCurrentPathWithoutLoading:(NSString *)thePath;
- (NSMutableString *)readHtmlFile:(NSString *)thePath;
- (NSMutableString *)readTextFile:(NSString *)file;
- (NSMutableString *)convertPalmDoc:(NSData*)p_data;

- (NSString *)currentPath;
- (void)embiggenText;
- (void)ensmallenText;
- (void)handleDoubleTapEvent:(struct __GSEvent *)event;
- (void)handleSingleTapEvent:(struct __GSEvent *)event;
- (void)setHeartbeatDelegate:(id)delegate;
- (void)heartbeatCallback:(id)unused;
- (void)hideNavbars;
- (void)toggleNavbars;
- (void)pageDownWithTopBar:(BOOL)hasTopBar bottomBar:(BOOL)hasBotBar;
- (void)pageUpWithTopBar:(BOOL)hasTopBar bottomBar:(BOOL)hasBotBar;
- (int)textSize;
- (void)setTextSize:(int)newSize;
- (void)invertText:(BOOL)b;
- (void)scrollSpeedDidChange:(NSNotification *)aNotification;

- (int) getSubchapter;
- (int) getMaxSubchapter;
- (void) setSubchapter: (int) chapter;
- (BOOL) gotoNextSubchapter;
- (BOOL) gotoPreviousSubchapter;
-(void) redraw;
//-(void) setOrientation: (int) orientation animate:(bool)anime;
//- (void) fitRect;
//-(void) afterRotate: (NSTimer*) timer;
-(void)reflowBook;

@end
//informal protocol declaration for _heartbeatDelegate
@interface NSObject (EBookViewHeartbeatDelegate)
- (void)heartbeatCallback:(id)ignored;
- (void)hideNavbars ;
- (void)toggleNavbars ;
- (void)chapForward:(UINavBarButton *)button;
- (void)chapBack:(UINavBarButton *)button;
@end
