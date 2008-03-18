// BooksApp, (c) 2007 by Zachary Brewster-Geisz

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
#import <CoreFoundation/CoreFoundation.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIWindow.h>
#import <UIKit/UIView-Hierarchy.h>
#import <UIKit/UIHardware.h>
#import <UIKit/UIKit.h>
#import <UIKit/UIApplication.h>
#import <UIKit/UITextView.h>
#import <UIKit/UIView.h>
#import <UIKit/UIKeyboard.h>
#import <UIKit/UITransitionView.h>
#import <UIKit/UINavigationItem.h>
#import <UIKit/UINavBarButton.h>
#import <UIKit/UIFontChooser.h>
#import <UIKit/UIProgressIndicator.h>
#import "EBookView.h"
#import "EBookImageView.h"
#import "FileBrowser.h"
#import "BooksDefaultsController.h"
#import "HideableNavBar.h"
#import "common.h"

enum PreferenceAnimationType;
@class PreferencesController;

@interface BooksApp : UIApplication {
	UIWindow 	*window;
	UIView      *mainView;
	HideableNavBar  *navBar, *bottomNavBar;
	UITransitionView *transitionView;
  
  EBookImageView *m_startupImage;
  
	NSString    *path;
  
	BOOL        bookHasChapters;
	BOOL        readingText;
	BOOL        textInverted;
	BOOL        rotate90;
  
	BooksDefaultsController *defaults;
	UINavBarButton *minusButton;
	UINavBarButton *plusButton;
	UINavBarButton *invertButton;
	UINavBarButton *rotateButton;
	UINavBarButton *prefsButton;
	UINavBarButton *downButton;
	UINavBarButton *upButton;
	UINavBarButton *rightButton;
	UINavBarButton *leftButton;
	
	//UIProgressIndicator *progressIndicator;
  
	NSString *imgPath;
  NSArray *m_documentExtensions;
}

- (BOOL)isDocumentImage:(NSString*)p_path;
- (UIView*)showDocumentAtPath:(NSString*)p_path;
- (void)fileBrowser: (FileBrowser *)browser fileSelected:(NSString *)file;
- (void)setNavForItem:(FileNavigationItem*)p_item;
- (void)showNavbars;
- (void)hideNavbars;
- (void)toggleNavbars;
- (void)embiggenText:(UINavBarButton *)button;
- (void)ensmallenText:(UINavBarButton *)button;
- (void)invertText:(UINavBarButton *)button;
- (void)setTextInverted:(BOOL)b;
- (void)setupNavbar;
- (void)setupToolbar;
- (void)updateToolbar:(NSNotification *)notification;
- (void)updateNavbar;
- (UINavBarButton *)toolbarButtonWithName:(NSString *)name rect:(struct CGRect)rect selector:(SEL)selector flipped:(BOOL)flipped;
- (UIImage *)navBarImage:(NSString *)name flipped:(BOOL)flipped;
- (void)showPrefs:(UINavBarButton *)button;
- (UIWindow *)appsMainWindow;
- (void)toggleStatusBarColor;
- (NSString *)currentBrowserPath;
- (void)cleanUpBeforeQuit;
- (void)rotateApp;
- (void)rotateButtonCallback:(UINavBarButton*) button;
- (void)applicationDidFinishLaunching: (id) unused;
- (void)finishUpLaunch;
- (void)preferenceAnimationDidFinish;
@end