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

@class UIView;
@class UITextView;
@class UISliderControl;

@class ChapteredHTML;
@class BooksDefaultsController;

@interface EBookView : UITextView {
  NSString                *path;
  struct CGRect           lastVisibleRect;
  ChapteredHTML	          *chapteredHTML;
  int                      subchapter;
  BooksDefaultsController *defaults;
 	UISliderControl *m_scrollerSlider;
  
	/**
	 * stores the X coordinate of the last mouse down event for swipe detection
	 */
	float _MouseDownX;
	/**
	 * stores the Y coordinate of the last mouse down event for swipe detection
	 */
	float _MouseDownY;

  BOOL m_navBarsVisible;
  
  BOOL m_readyToShow;
  
  BOOL m_bDocIsHtml;
}
typedef enum
{
	kUIViewSwipeUp = 1,
	kUIViewSwipeDown = 2,
	kUIViewSwipeLeft = 4,
	kUIViewSwipeRight = 8
} UIViewSwipeDirection;

- (BOOL)canHandleSwipes;
- (id)initWithFrame:(struct CGRect)rect delegate:(id)p_del parentView:(UIView*)p_par;
- (void)setupScrollerWithFrame:(struct CGRect)p_bounds parent:(UIView*)p_par;
- (void)setBookPath:(NSString*)p_path subchapter:(int)p_chap;
- (void)reallyLoadBook;
- (void)loadBookWithPath:(NSString *)thePath subchapter:(int) theSubchapter;

- (NSMutableString *)readHtmlFile:(NSString *)thePath;
- (NSMutableString *)readTextFile:(NSString *)file;
- (NSMutableString *)convertPalmDoc:(NSData*)p_data;

- (BOOL)isReadyToShow;

- (NSString *)currentPath;
- (void)embiggenText;
- (void)ensmallenText;
- (void)hideNavbars;
- (void)toggleNavbars;
- (void)pageDownWithTopBar:(BOOL)hasTopBar bottomBar:(BOOL)hasBotBar;
- (void)pageUpWithTopBar:(BOOL)hasTopBar bottomBar:(BOOL)hasBotBar;
- (void)invertText:(BOOL)b;
- (void)scrollSpeedDidChange:(NSNotification *)aNotification;

- (int)getSubchapter;
- (int)getMaxSubchapter;
- (BOOL)setSubchapter:(int)chapter;
- (BOOL)gotoNextSubchapter;
- (BOOL)gotoPreviousSubchapter;

-(void)reflowBook;
- (void)saveBookPosition;
- (void)applyTextDisplayPreferences;
- (void)applyBarPreferences;

- (void)showSlider;
- (void)hideSlider;
- (void)handleSlider:(id)sender;
- (void)updateSliderPosition;
- (void)scrollToPoint:(float)p_pt;
@end

//informal protocol declaration for _heartbeatDelegate
@interface NSObject (EBookViewHeartbeatDelegate)
- (void)heartbeatCallback:(id)ignored;
- (void)hideNavbars ;
- (void)toggleNavbars ;
- (void)chapForward:(UINavBarButton *)button;
- (void)chapBack:(UINavBarButton *)button;
@end
