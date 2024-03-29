/* ------ BooksApp, written by Zachary Brewster-Geisz
   (and others)
   contains code from 
 * textReader.app -  kludged up by Jim Beesley for volume control of page turning
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
#import <Celestial/AVSystemController.h>
#import <CoreFoundation/CoreFoundation.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIWindow.h>
#import <UIKit/UIView-Hierarchy.h>
#import <UIKit/UIAlertSheet.h>
#import <UIKit/UIView-Geometry.h>
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
#import <UIKit/UIProgressHUD.h>
#import "EBookView.h"
#import "EBookImageView.h"
#import "FileBrowser.h"
#import "BooksDefaultsController.h"
#import "HideableNavBar.h"
#import "common.h"
#import "BoundsChangedNotification.h"
#import "HTMLFixer.h"

#import "BooksApp.h"
#import "PreferencesController.h"

#include <stdio.h>
#import "FileNavigationItem.h"

@implementation BooksApp
/**
 * Log all notifications.
 */
+ (void)debugNotification:(NSNotification*)p_note {
	 GSLog(@"NOTIFICATION: %@", [p_note name]);
}
/*
   enum {
   kFACEUP = 0,
   kNORMAL = 1,
   kUPSIDEDOWN = 2,
   kLANDL = 3,
   kLANDR = 4,
   kFACEDOWN = 6
   };
   */
// Delegate methods
/**
 * Handle warning dialog button click from file access problems.
 */
- (void)alertSheet:(UIAlertSheet *)sheet buttonClicked:(int)button {
	[sheet dismissAnimated:YES];
	[sheet release];

	// It's a warning dialog for file access problems
	if(button != 1) {
		// Help button for warning dialog: show website.
 NSURL *websiteURL = [NSURL URLWithString:PERMISSION_HELP_URL_STRING];
 [UIApp openURL:websiteURL];
	} else if(!m_openedFirstDoc) {
		// FIXME: Quit!
		[UIApp terminateWithSuccess];
	}

	[defaults setRotateLocked:[defaults isRotateLocked]];
	//	[self setUIOrientation:uiOrientation];
}

/**
 * Hide the navbars before we rotate.
 */
- (void)boundsWillChange:(BoundsChangedNotification*)p_note {
	// Hide the nav bars.
	[self hideNavbars];

	struct CGRect rect = [p_note newBounds];;
	struct CGRect frameRect = CGRectMake(rect.origin.x, rect.size.height, rect.size.width, TOOLBAR_HEIGHT);
	[bottomNavBar setFrame:frameRect];

	// Hide the slider.
	UIView *topView = [navBar topView];
	if([topView isKindOfClass:[EBookView class]]) {
		EBookView *ebv = (EBookView*)topView;
		[ebv hideSlider];
	}
}

/**
 * Notification when our bounds change - we probably rotated.
 */
- (void)boundsDidChange:(BoundsChangedNotification*)p_note {
	[defaults setUiOrientation:[p_note uiOrientationCode]];

	// Fix the transition view's size
	[m_transitionView setFrame:[p_note newBounds]];

	// Fix the position of the prefs button.
	struct CGSize newSize = [p_note newBounds].size;
	float lMargin = 45.0f;
	[prefsButton retain];
	[prefsButton removeFromSuperview];
	[prefsButton setFrame:CGRectMake(newSize.width - lMargin, 9, 40, 30)];
	[navBar addSubview:prefsButton];
	[prefsButton release];

	[self hideNavbars];

	UIView *topView = [navBar topView];
	if([topView isKindOfClass:[FileBrowser class]]) {
	[NSTimer scheduledTimerWithTimeInterval:0.2f target:navBar selector:@selector(show) userInfo:nil repeats:NO];
	}

	[self adjustStatusBarColorWithUiOrientation:[p_note uiOrientationCode]];
}

- (void)applicationDidFinishLaunching:(id)unused {  
	GSLog(@"%s:%d %s .",__FILE__, __LINE__, _cmd);
  m_documentExtensions = [[NSArray arrayWithObjects:@"txt", @"htm", @"html", @"pdb", @"jpg", @"png", @"gif", nil] retain];

  m_openedFirstDoc = NO;
	GSLog(@"%s:%d %s .",__FILE__, __LINE__, _cmd);

  //investigate using [self setUIOrientation 3] that may alleviate for the need of a weirdly sized window
  defaults = [BooksDefaultsController sharedBooksDefaultsController];

  NSString *lAppStatus = [defaults appStatus];
	GSLog(@"%s:%d %s .",__FILE__, __LINE__, _cmd);

  if ([lAppStatus isEqualToString: APPOPENVALUE]) {
	  // I think it's enough to just clear out the last read path -- no need to kill the whole
	  // prefs file.  Probably also no need to prompt since clearing the last read book isn't that
	  // big a deal (as compared to trashing the entire prefs). -ZSB
	  [defaults setLastBrowserPath:[BooksDefaultsController defaultEBookPath]];
  }
	GSLog(@"%s:%d %s .",__FILE__, __LINE__, _cmd);
  //now set the app status to open
  [defaults setAppStatus:APPOPENVALUE];

  [defaults setRotateLocked:[defaults isRotateLocked]];

  [[NSNotificationCenter defaultCenter] addObserver:self
										   selector:@selector(updateToolbar:)
											   name:TOOLBAR_DEFAULTS_CHANGED_NOTIFICATION
											 object:nil];

	GSLog(@"%s:%d %s .",__FILE__, __LINE__, _cmd);
  window = [[UIWindow alloc] initWithContentRect:[UIHardware fullScreenApplicationContentRect]];  
	GSLog(@"%s:%d %s .",__FILE__, __LINE__, _cmd);
  mainView = [[UIView alloc] initWithFrame:[window bounds]];
  [window setContentView:mainView];

	GSLog(@"%s:%d %s .",__FILE__, __LINE__, _cmd);
  m_transitionView = [[UITransitionView alloc] initWithFrame:[window bounds]];
  [mainView addSubview:m_transitionView];
  [m_transitionView setDelegate:self];

	GSLog(@"%s:%d %s .",__FILE__, __LINE__, _cmd);
  /*
   * We need to fix up any prefs-weirdness relating to file path before we try to open a document.
   * Figure out if we have a directory or a file and if it exists.  If it doesn't, jump back to the
   * default root and let them start over.
   */
  NSString *recentFile = [defaults lastBrowserPath];
  BOOL isDir = NO;
  BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:recentFile isDirectory:&isDir];

  readingText = exists && !isDir;

	GSLog(@"%s:%d %s .",__FILE__, __LINE__, _cmd);
  if(!exists) {
	  [defaults setLastBrowserPath:[BooksDefaultsController defaultEBookPath]];
	  [defaults removePerFileDataForFile:recentFile];
	  recentFile = [defaults lastBrowserPath];
  }

  NSString *defImage = [self _pathToDefaultImageNamed:[self nameOfDefaultImageToUpdateAtSuspension]];

	GSLog(@"%s:%d %s .",__FILE__, __LINE__, _cmd);

  if(![[NSFileManager defaultManager] fileExistsAtPath:defImage]) {
	 defImage = [[NSBundle mainBundle] pathForResource:@"Default" ofType:@"png"];
  }

  m_startupImage = [[EBookImageView alloc] initWithContentsOfFile:defImage
														withFrame:[window bounds] 
													  scaleAspect:NO];
	GSLog(@"%s:%d %s .",__FILE__, __LINE__, _cmd);
  [m_transitionView transition:0 toView:m_startupImage];

  // At this point, we're showing either the startup book or the cover image in the real imageView and m_startupView is gone.

  [self adjustStatusBarColorWithUiOrientation:-1];

  [window orderFront: self];
  [window makeKey: self];
  [window _setHidden: NO];

  [[NSNotificationCenter defaultCenter] addObserver:self
										   selector:@selector(boundsDidChange:)
											   name:[BoundsChangedNotification didChangeName]
											 object:nil];
	GSLog(@"%s:%d %s .",__FILE__, __LINE__, _cmd);

  [[NSNotificationCenter defaultCenter] addObserver:self
										   selector:@selector(boundsWillChange:)
											   name:[BoundsChangedNotification willChangeName]
											 object:nil];
	GSLog(@"%s:%d %s .",__FILE__, __LINE__, _cmd);

  [self showPleaseWait];
//#define volumeScroll
#ifdef volumeScroll
  // // Volume scrolling ...  
  [self setSystemVolumeHUDEnabled:NO];
	GSLog(@"%s:%d %s .",__FILE__, __LINE__, _cmd);
  AVSystemController *avsc = [AVSystemController sharedAVSystemController];
	GSLog(@"%s:%d %s .",__FILE__, __LINE__, _cmd);

  [[NSNotificationCenter defaultCenter] addObserver:self 
										   selector:@selector(volumeChanged:) 
											   name:@"AVSystemController_SystemVolumeDidChangeNotification" 
											 object:avsc];

	GSLog(@"%s:%d %s .",__FILE__, __LINE__, _cmd);
  NSString *name;
  [avsc getActiveCategoryVolume:&initVol andName:&name];

	GSLog(@"%s:%d %s .",__FILE__, __LINE__, _cmd);
  // We need to set the current volume so it has some up and down room
  // Can't do this here because the HUDEnabled:NO has not yet taken effect - use a timer
			// [avsc setActiveCategoryVolumeTo:curVol];
  [NSTimer scheduledTimerWithTimeInterval:0.1f target:self selector:@selector(setCurVolume:) userInfo:nil repeats:NO];

	GSLog(@"%s:%d %s .",__FILE__, __LINE__, _cmd);
#endif
  // We need to get back to the main runloop for some things to finish up.  Schedule a timer to
  // fire almost immediately.  Doing this with performSelectorOnMainThread: doesn't actually get back
  // to the runloop - we're already running in the main thread, so it just executes it directly instead
  // of inserting a message for later.
  [NSTimer scheduledTimerWithTimeInterval:0.0f target:self selector:@selector(finishUpLaunch) userInfo:nil repeats:NO];

	GSLog(@"%s:%d %s .",__FILE__, __LINE__, _cmd);
}

// Make sure the current volume is within bounds
- (void)setCurVolume {  

	curVol = initVol;

	// There are 16 bars on the volume HUD
	// 1/16 = 0.0625, but apparently that isn't quite enough - add 0.005
	if (curVol == 1.0f) 
		curVol = 1.0f - 0.063f;
	if (curVol < 0.063f) 
		curVol = 0.063f;

	AVSystemController *avsc = [AVSystemController sharedAVSystemController];
	[avsc setActiveCategoryVolumeTo:curVol];
}

// This is used to "de-bounce" the volume buttons
// We start a timer to call this func to reset the changed flag
// Until the timer fires we won't accept another vol change
- (void)clearVolumeChanged:(id)unused {  
    volChanged = false;
} // clearVolumeChanged


// This gets called every time the vol keys get pressed
- (void) volumeChanged:(NSNotification *)notify
{
	float newVol;
	NSString * name;
	UIView *top = [navBar topView];
	if([top isKindOfClass:[EBookView class]]) 
	{
		AVSystemController *avsc = [AVSystemController sharedAVSystemController];

		[avsc getActiveCategoryVolume:&newVol andName:&name];

		if (newVol < curVol) 
		{
			// Scroll down
			if (!volChanged)
			{
				volChanged = true;
				[(EBookView*)top pageDownWithTopBar:![defaults navbar]
										  bottomBar:![defaults toolbar]];
				[NSTimer scheduledTimerWithTimeInterval:0.2f target:self 
											   selector:@selector(clearVolumeChanged:) userInfo:nil repeats:NO];
			}
		}
		else if (newVol > curVol)
		{
			// Scroll up
			if (!volChanged)
			{
				volChanged = true;
				[(EBookView*)top pageUpWithTopBar:![defaults navbar]
										  bottomBar:![defaults toolbar]];
				[NSTimer scheduledTimerWithTimeInterval:0.2f target:self 
											   selector:@selector(clearVolumeChanged:) userInfo:nil repeats:NO];
			}
		}

		if (newVol != curVol)
			[avsc setActiveCategoryVolumeTo:curVol];

		// Restore our initial volume
	}
}

/**
 * This needs to be called once at startup.
 *
 * Should be called at the point where the next toolbar or view change needs
 * to trigger animation.  If readingText, call right before swtiching to the text view.
 * If not reading text call right before pushing the top-most path entry (even it it's the root).
 *
 * Clear as mud, right?
 */
- (void)transitionNavbarAnimation {
	[mainView addSubview:navBar];
	[mainView addSubview:bottomNavBar];

	[navBar enableAnimation];
}

/**
 * Store screen shot (if enabled), setup navigation bar, and start displaying the 
 * last read file.  Takes down splash image if it was present.
 */
- (void)finishUpLaunch {
	GSLog(@"%s:%d %s .",__FILE__, __LINE__, _cmd);
	NSString *recentFile = [defaults lastBrowserPath];
#ifdef volumeScroll
	[self setCurVolume];
#endif
	[self setupNavbar];
	[self setupToolbar];

	[self hideNavbars];

	// Get last browser path and start loading files
	NSString *lastBrowserPath;
	if(readingText) {
		lastBrowserPath = [recentFile stringByDeletingLastPathComponent];
	} else {
		lastBrowserPath = [defaults lastBrowserPath];
	}

	NSMutableArray *arPathComponents = [[NSMutableArray alloc] init]; 

	[arPathComponents addObject:lastBrowserPath];
	lastBrowserPath = [lastBrowserPath stringByDeletingLastPathComponent]; // prime for loop

	NSString *stopAtPath = [[BooksDefaultsController defaultEBookPath] stringByDeletingLastPathComponent];
	while(![lastBrowserPath isEqualToString:stopAtPath] && ![lastBrowserPath isEqualToString:@"/"]) {
				[arPathComponents addObject:lastBrowserPath];
				lastBrowserPath = [lastBrowserPath stringByDeletingLastPathComponent];
	} // while

	// Loop over all the paths and add them to the nav bar.
	int pathCount = [arPathComponents count];
	for(pathCount = pathCount-1; pathCount >= 0 ; pathCount--) {    
		if(!readingText && pathCount == 0) {
			/*
			 * We're not reading a book and we're on the last item.  We want animation on so the 
			 * book image gets transitioned off.
			 */
			[self transitionNavbarAnimation];
			[navBar setTransitionOffView:m_startupImage];
			if(![defaults startupIsCover]) {
				[navBar skipNextTransition];
			}
		}

		NSString *curPath = [arPathComponents objectAtIndex:pathCount];
		// Add the current path to the toolbar
		[self fileBrowser:nil fileSelected:curPath];
	}


	if(readingText) {
		/*
		 * If we are reading text, then we DIDN'T finish setting up the navbar during
		 * the path-push process.  So we'd better do it now!
		 */
		[self transitionNavbarAnimation];


		GSLog(@"%s:%d %s .",__FILE__, __LINE__, _cmd);
		// We don't want a transition if we already have an image of text on the screen.
		if(![defaults startupIsCover]) {
			[navBar skipNextTransition];
			//only freeze the next rotation animation if a rotation is needed
			if ([defaults uiOrientation] != 1)
				[self freezeNextAnimation];
		}
		else
			[navBar setTransitionOffView:m_startupImage];

		// Pushing the file onto the toolbar will trigger it being opened.
		GSLog(@"%s:%d %s .",__FILE__, __LINE__, _cmd);
		UIView *view = [self showDocumentAtPath:recentFile];    
		GSLog(@"%s:%d %s .",__FILE__, __LINE__, _cmd);
		FileNavigationItem *fni = [[FileNavigationItem alloc] initWithDocument:recentFile view:view];
		[navBar pushNavigationItem:fni];
		[fni release];
	}

	[arPathComponents release];

	if([defaults uiOrientation] != 1 && !readingText) {
		// No sense triggering rotation if it isn't going to do anything - I think it also messed up the
		// clock at startup. -ZSB
		[NSTimer scheduledTimerWithTimeInterval:0.0f target:self selector:@selector(applyOrientationLater) userInfo:nil repeats:NO];
	}
}

/**
 * Apply the app rotation at startup - but we need to do it from the main thread after a runloop.
 */
- (void)applyOrientationLater {
	[self setUIOrientation:[defaults uiOrientation]];
}

/**
 * Need to cleanup after the first transition is done.
 *
 * This is called from the deferred transition code in HideableNavBar.  We need this
 * object to stay alive long enough for the book to finish loading (which is async) and
 * for the final transition to complete.
 */
- (void)cleanupStartupImage {
	[m_startupImage removeFromSuperview];
	m_startupImage = nil;
}

- (void)setNavForItem:(FileNavigationItem*)p_item {
	if([p_item isDocument]) {
		// Set nav bars for a document
		[self hideNavbars];
	} else {
		// Set nav bars for a file browser
		[bottomNavBar hide];
		[navBar show];
	}
}

/**
 * Show just the top nav bar.
 */
- (void)showTopNav {
	[navBar show];
	[bottomNavBar hide];
}

/**
 * Hide the navigation bars.
 */
- (void)hideNavbars {
	[navBar hide];
	[bottomNavBar hide];
	/*
	//bcc, it used to be:
	GSLog(@"%s .", _cmd);
	struct CGRect rect = [defaults fullScreenApplicationContentRect];
	[textView setFrame:rect];
	[navBar hide:NO];
	[bottomNavBar hide:NO];
	[self hideSlider];
	//are we sure of this change
	*/
}

/**
 * Show the navigation bars.
 */
- (void)showNavbars {
	[navBar show];
	[bottomNavBar show];
}

/**
 * Show the please wait / progress spinner view.
 */
- (void)showPleaseWait {
	FileBrowser *topB = [navBar topBrowser];
	[topB setEnabled:NO];

	if(m_progressIndicator == nil) {
		// We might already be showing the progressHUD if this is startup.
		// Don't show it again if it's already there.

		UIView *progView;
		if(m_startupImage != nil) {
			progView = m_startupImage;
		} else {
			progView = [navBar topView];
		}

		const int PROG_SIZE = 32;
		const int progHeight = 70;
		const int progWidth = 64;
		struct CGRect progRect = CGRectMake([progView bounds].size.width - (progWidth + 10),
				[progView bounds].size.height - (progHeight + 10),
				progWidth, 
				progHeight);

		m_progressIndicator = [[UIProgressHUD alloc] initWithFrame:progRect];
		[m_progressIndicator setFontSize:6];
		[m_progressIndicator setText:@" "];
		[mainView addSubview:m_progressIndicator];
		[m_progressIndicator show:YES];
	}
}

/**
 * Hide the please wait / progress spinner view, apply book preferences.
 */
- (void)hidePleaseWait {
	[m_progressIndicator show:NO];
	[m_progressIndicator removeFromSuperview];
	[m_progressIndicator release];
	m_progressIndicator = nil;

	FileBrowser *topB = [navBar topBrowser];
	[topB setEnabled:YES];
}

/**
 * Show the document and return the view used to allow for transition.
 */
- (UIView*)showDocumentAtPath:(NSString*)p_path {
  BOOL isPicture = [HTMLFixer isDocumentImage:p_path];
  UIView *ret = nil;

  [defaults setLastBrowserPath:p_path];
  if (isPicture) {
	  ret = [[[EBookImageView alloc] initWithContentsOfFile:p_path withFrame:[mainView bounds] scaleAspect:YES] autorelease];
  } else { 
	  //text or HTML file
	  readingText = YES;
	  UIView *progView;
	  int subchapter = [defaults lastSubchapterForFile:p_path];
	  EBookView *ebv = [[[EBookView alloc] initWithFrame:[mainView bounds] delegate:self parentView:mainView] autorelease];
	  [ebv setDelegate:self];
	  [ebv setBookPath:p_path subchapter:subchapter];

	  // FIXME: It might make sense to move this kludge into the toolbar -- if m_offViewKludge is set,
	  // return that for topView instead of a document or filebrowser.  Not sure if that would
	  // break anything that calls topView, though.
	  if(m_startupImage != nil) {
		  progView = m_startupImage;
	  } else {
		  progView = [navBar topView];
	  }

	  [self showPleaseWait];
	  GSLog(@"%s:%d %s .",__FILE__, __LINE__, _cmd);
	  [NSThread detachNewThreadSelector:@selector(reallyLoadBook) toTarget:ebv withObject:nil];

	  ret = ebv;
  }  

  if(m_startupImage != nil) {
	  if (isPicture) {
		  [navBar show];
		  [bottomNavBar hide];
	  } else {
		  [navBar hide];
		  if (![defaults toolbar]) {
			  [bottomNavBar show];
		  } else {
			  [bottomNavBar hide];
		  }
	  }
  }

  // Make sure the "file read" dot is updated.
  [[NSNotificationCenter defaultCenter] postNotificationName:OPENEDTHISFILE object:p_path];

  return ret;
}

/**
 * Called by the file browser objects when a user taps a file or folder.  Calls to navBar
 * to push whatever was tapped.  Navbar will call us back to actually open something.
 */
- (void)fileBrowser:(FileBrowser *)browser fileSelected:(NSString *)file {
	BOOL isDir = NO;
	NSFileManager *fileManager = [NSFileManager defaultManager];

	if(![fileManager fileExistsAtPath:file isDirectory:&isDir]) {
			   [self setUIOrientation:1];
			   [self lockUIOrientation];
			   CGRect rect = [[UIWindow keyWindow] bounds];
			   UIAlertSheet * alertSheet = [[UIAlertSheet alloc] initWithFrame:CGRectMake(0,rect.size.height - TOOLBAR_HEIGHT, rect.size.width,240)];
			   // NOTE: Leave this retained - we'll release it in the delegate callback.
  [alertSheet setTitle:@"Folder not found"];
  [alertSheet setBodyText:[NSString stringWithFormat:@"%@ doesn't appear to exist.  Try restarting Books to refresh folders.", file]];
  [alertSheet addButtonWithTitle:(m_openedFirstDoc ? @"OK" : @"Quit")];
  [alertSheet setDelegate: self];
  [alertSheet presentSheetInView:mainView];
  return;
	}

	if(![[NSFileManager defaultManager] isReadableFileAtPath:file]) {
									  [self setUIOrientation:1];
									  [self lockUIOrientation];
									  CGRect rect = [[UIWindow keyWindow] bounds];
									  UIAlertSheet * alertSheet = [[UIAlertSheet alloc] initWithFrame:CGRectMake(0,rect.size.height - TOOLBAR_HEIGHT, rect.size.width,240)];
									  // NOTE: Leave this retained - we'll release it in the delegate callback.
						 [alertSheet setTitle:@"Access Denied"];
						 [alertSheet setBodyText:[NSString stringWithFormat:@"Error reading %@.  Perhaps user mobile lacks the rights to do so?", file]];
						 [alertSheet addButtonWithTitle:(m_openedFirstDoc ? @"OK" : @"Quit")];
						 [alertSheet addButtonWithTitle:@"Help (Wiki)"];
						 [alertSheet setDelegate: self];
						 [alertSheet presentSheetInView:mainView];
						 return;
	}

	[defaults setLastBrowserPath:file];

	FileNavigationItem *tempItem;
	if (isDir) {
		FileBrowser *browser = [[FileBrowser alloc] initWithFrame:[mainView bounds]];
		[browser setExtensions:m_documentExtensions]; // Important: Set extensions before path!
		[browser setPath:file];
		[browser setDelegate:self];
		tempItem = [[FileNavigationItem alloc] initWithPath:file browser:browser];
		[browser release];
	} else {
		// not a directory
		UIView *displayView = [self showDocumentAtPath:file];
		tempItem = [[FileNavigationItem alloc] initWithDocument:file view:displayView];
	}

	// Until we get through a document load once, we're just going to quit if permissions fail.
	m_openedFirstDoc = YES;

	[navBar pushNavigationItem:tempItem];
	[tempItem release];
}

- (void)cleanUpBeforeQuit {
	FileNavigationItem *topItem = [navBar topItem];
	NSString *filename = [topItem path];
	[defaults setLastBrowserPath:filename];

	// Need to kick the top-most EBookView.  It doesn't clean up on its own at shutdown.
	UIView *top = [topItem view];
	if([top isKindOfClass:[EBookView class]]) {
		EBookView *eb = (EBookView*)top;
		[eb saveBookPosition];
	}
}

/**
 * Will suspend is called (after suspend for events only, sometimes)
 * in cases where the phone is going to do something else but might 
 * come back to Books without compeltely quitting it.
 */
- (void)applicationWillSuspend {
	//if([[defaults appStatus] isEqualToString:APPOPENVALUE]) {
	// Only clean up is we haven't done it yet (clean up sets this to NO)
	[self cleanUpBeforeQuit];
	//}
}

/**
 * Application suspend is called before the app is REALLY going to go down.
 */
- (void)applicationSuspend:(struct __GSEvent *)fp8 {
	[defaults setAppStatus:APPCLOSEDVALUE];
}

/**
 * Note sure when/if this gets called...
 */
- (void)anotherApplicationFinishedLaunching:(struct __GSEvent *)event {
	[self applicationWillSuspend];
}

/**
 * Fix the status bar location after a resume.
 */
- (void)applicationDidResume {
	[self adjustStatusBarColorWithUiOrientation:[defaults uiOrientation]];
}

/*
 * Will suspend for events only is called before the app goes down when
 * the phone is probably going to switch to another app (phone call).
 - (void)applicationWillSuspendForEventsOnly {
 GSLog(@"%s .", _cmd);
 }
 */

/*
 * Will suspend under lock is called before the phone is going
 * to lock (oddly enough)...  One of the other functions we monitor
 * will always be called as well, so we'll ignore this one.
 - (void)applicationWillSuspendUnderLock {
 GSLog(@"%s .", _cmd);
 }
 */

- (void)embiggenText:(UINavBarButton *)button {
	if (![button isPressed]) {// mouse up events only, kids!
		[(EBookView*)[navBar topView] embiggenText];
		[defaults setTextSize:[(EBookView*)[navBar topView] textSize]];
	}
}

- (void)ensmallenText:(UINavBarButton *)button {
	if (![button isPressed]) {// mouse up events only, kids!
		[(EBookView*)[navBar topView] ensmallenText];
		[defaults setTextSize:[(EBookView*)[navBar topView] textSize]];
	}
}

- (void)invertText:(UINavBarButton *)button {
	if (![button isPressed]) { // mouse up events only, kids!
		textInverted = !textInverted;
		[(EBookView*)[navBar topView] invertText:textInverted];
		[defaults setInverted:textInverted];
		[self adjustStatusBarColorWithUiOrientation:-1];
	}	
}

- (void)pageDown:(UINavBarButton *)button {
	if (![button isPressed]) {
		[(EBookView*)[navBar topView] pageDownWithTopBar:![defaults navbar]
											   bottomBar:![defaults toolbar]];
	}	
}

- (void)pageUp:(UINavBarButton *)button {
	if (![button isPressed]) {
		[(EBookView*)[navBar topView] pageUpWithTopBar:![defaults navbar]
											 bottomBar:![defaults toolbar]];
	}	
}

/**
 * Advance to the next chapter, either using chapterdHtml or moving to the
 * next file in the file browser.
 */
- (void)chapForward:(UINavBarButton *)button {
	if (![button isPressed]) {
		if ([(EBookView*)[navBar topView] gotoNextSubchapter] == YES) {
			[navBar hide];
			[bottomNavBar hide];
		} else {
			NSString *nextFile = [[navBar topBrowser] fileAfterFileNamed:[defaults lastBrowserPath]];
			if(nextFile != nil) {
				UIView *newView = [self showDocumentAtPath:nextFile];
				FileNavigationItem *tempItem = [[FileNavigationItem alloc] initWithDocument:nextFile view:newView];
				[navBar replaceTopNavigationItem:tempItem transition: 1];
				[tempItem release];
			}
		}
	}	
}

/**
 * Retreat to the last chapter, either using chapteredHtml or moving
 * to the next file in the file browser.
 */
- (void)chapBack:(UINavBarButton *)button {
	if (![button isPressed]) {
		if ([(EBookView*)[navBar topView] gotoPreviousSubchapter] == YES) {
			[navBar hide];
			[bottomNavBar hide];
		} else {
			FileBrowser *fb = [navBar topBrowser];
			NSString *prevFile = [fb fileBeforeFileNamed:[defaults lastBrowserPath]];
			if(nil != prevFile) {
				UIView *newView = [self showDocumentAtPath:prevFile];
				FileNavigationItem *tempItem = [[FileNavigationItem alloc] initWithDocument:prevFile view:newView];
				[navBar replaceTopNavigationItem:tempItem transition: 2];
				[tempItem release];
			}
		}
	}	
}

/**
 * Create or reconfigure the nav bar (file browser).
 */
- (void)setupNavbar {
	// Only create the navbar once.
	if(navBar == nil) {    
		struct CGRect rect = [mainView bounds];
		struct CGRect frameRect = CGRectMake(rect.origin.x, rect.origin.y - (TOOLBAR_FUDGE+TOOLBAR_HEIGHT), rect.size.width, TOOLBAR_HEIGHT);

		navBar = [[HideableNavBar alloc] initWithFrame:frameRect delegate:self transitionView:m_transitionView asTop:YES];
		[navBar hideButtons];

		float lMargin = 45.0f;
		[navBar setRightMargin:lMargin];
		prefsButton = [self toolbarButtonWithName:@"prefs" rect:CGRectMake(rect.size.width-lMargin,9,40,30) selector:@selector(showPrefs:) flipped:NO];

		[navBar addSubview:prefsButton];
	}
}

/**
 * Create or reconfigure the tool bar (reader).
 */
- (void)setupToolbar {
	// Only create the navbar once
	if(bottomNavBar == nil) {
		struct CGRect rect = [mainView bounds];
		struct CGRect frameRect = CGRectMake(rect.origin.x, rect.size.height, rect.size.width, TOOLBAR_HEIGHT);

		// FIXME: Will this ever redraw the nav bars after prefs?
	bottomNavBar = [[HideableNavBar alloc] initWithFrame:frameRect delegate:self transitionView:m_transitionView asTop:NO];
	[bottomNavBar setBarStyle:0];

	// Put the buttons back
	if ([defaults flipped]) {
		downButton = [self toolbarButtonWithName:@"down" rect:CGRectMake(5,9,40,30) selector:@selector(pageDown:) flipped:YES];
		upButton = [self toolbarButtonWithName:@"up" rect:CGRectMake(45,9,40,30) selector:@selector(pageUp:) flipped:YES];

		if (![defaults pagenav]) { // If pagnav buttons should be off, then move the chapter buttons over
			leftButton = [self toolbarButtonWithName:@"left" rect:CGRectMake(5,9,40,30) selector:@selector(chapBack:) flipped:NO];
			rightButton = [self toolbarButtonWithName:@"right" rect:CGRectMake(45,9,40,30) selector:@selector(chapForward:) flipped:NO];
		} else {
			leftButton = [self toolbarButtonWithName:@"left" rect:CGRectMake(88,9,40,30) selector:@selector(chapBack:) flipped:NO];
			rightButton = [self toolbarButtonWithName:@"right" rect:CGRectMake(128,9,40,30) selector:@selector(chapForward:) flipped:NO];	
		}

		rotateButton = [self toolbarButtonWithName:@"rotate" rect:CGRectMake(171,9,30,30) selector:@selector(rotateButtonCallback:) flipped:NO];
		invertButton = [self toolbarButtonWithName:@"inv" rect:CGRectMake(203,9,30,30) selector:@selector(invertText:) flipped:NO];
		minusButton = [self toolbarButtonWithName:@"emsmall" rect:CGRectMake(235,9,40,30) selector:@selector(ensmallenText:) flipped:NO];
		plusButton = [self toolbarButtonWithName:@"embig" rect:CGRectMake(275,9,40,30) selector:@selector(embiggenText:) flipped:NO];
	} else {
		minusButton = [self toolbarButtonWithName:@"emsmall" rect:CGRectMake(5,9,40,30) selector:@selector(ensmallenText:) flipped:NO];
		plusButton = [self toolbarButtonWithName:@"embig" rect:CGRectMake(45,9,40,30) selector:@selector(embiggenText:) flipped:NO];
		invertButton = [self toolbarButtonWithName:@"inv" rect:CGRectMake(87,9,30,30) selector:@selector(invertText:) flipped:NO];
		rotateButton = [self toolbarButtonWithName:@"rotate" rect:CGRectMake(119,9,30,30) selector:@selector(rotateButtonCallback:) flipped:NO];

		if (![defaults pagenav]) { // If pagnav buttons should be off, then move the chapter buttons over
			leftButton = [self toolbarButtonWithName:@"left" rect:CGRectMake(235,9,40,30) selector:@selector(chapBack:) flipped:NO];
			rightButton = [self toolbarButtonWithName:@"right" rect:CGRectMake(275,9,40,30) selector:@selector(chapForward:) flipped:NO];
		} else {
			leftButton = [self toolbarButtonWithName:@"left" rect:CGRectMake(152,9,40,30) selector:@selector(chapBack:) flipped:NO];
			rightButton = [self toolbarButtonWithName:@"right" rect:CGRectMake(192,9,40,30) selector:@selector(chapForward:) flipped:NO];
		}

		upButton = [self toolbarButtonWithName:@"up" rect:CGRectMake(235,9,40,30) selector:@selector(pageUp:) flipped:NO];
		downButton = [self toolbarButtonWithName:@"down" rect:CGRectMake(275,9,40,30) selector:@selector(pageDown:) flipped:NO];
	}

	[bottomNavBar addSubview:minusButton];
	[bottomNavBar addSubview:plusButton];
	[bottomNavBar addSubview:invertButton];
	[bottomNavBar addSubview:rotateButton];

	if ([defaults chapternav]) {
		[bottomNavBar addSubview:leftButton];
		[bottomNavBar addSubview:rightButton];
	}

	if ([defaults pagenav]) {	
		[bottomNavBar addSubview:upButton];
		[bottomNavBar addSubview:downButton];
	}
	}
}

/**
 * Return a pre-configured toolbar button with _up and _down images setup.
 */
- (UINavBarButton *)toolbarButtonWithName:(NSString *)name rect:(struct CGRect)rect selector:(SEL)selector flipped:(BOOL)flipped 
{
	UINavBarButton	*button = [[UINavBarButton alloc] initWithFrame:rect];

	[button setAutosizesToFit:NO];
	if ([name isEqualToString: @"rotate"])
	{
		BOOL lLockState = [defaults isRotateLocked];

		if (lLockState)
		{
			[button setImage:[self navBarImage:@"rotate_lock_up" flipped:flipped] forState:0];
			[button setImage:[self navBarImage:@"rotate_lock_down" flipped:flipped] forState:1];
		}
		else
		{
			[button setImage:[self navBarImage:@"rotate_up" flipped:flipped] forState:0];
			[button setImage:[self navBarImage:@"rotate_down" flipped:flipped] forState:1];
		}
	}
	else
	{
		[button setImage:[self navBarImage:[NSString stringWithFormat:@"%@_up",name] flipped:flipped] forState:0];
		[button setImage:[self navBarImage:[NSString stringWithFormat:@"%@_down",name] flipped:flipped] forState:1];
	}
	[button setDrawContentsCentered:YES];
	[button addTarget:self action:selector forEvents: (255)];
	[button setNavBarButtonStyle:0];
	//bcc this complains about an invalid context, it seems to work fine without anyway
	//	[button drawImageAtPoint:CGPointMake(5.0f,0.0f) fraction:0.5];
	[button setEnabled:YES];
	return button;
}

/**
 * Get an image from the bundle.
 */
- (UIImage *)navBarImage:(NSString *)name flipped:(BOOL)flipped {
	NSBundle *bundle = [NSBundle mainBundle];
	imgPath = [bundle pathForResource:name ofType:@"png"];
	UIImage *buttonImg = [[UIImage alloc]initWithContentsOfFile:imgPath];
	if (flipped) [buttonImg setOrientation:4];
	return [buttonImg autorelease];
}

/**
 * Redraw the toolbar when the user's choice of visible buttons changes.
 */
- (void)updateToolbar:(NSNotification *)notification {
	BOOL lBottomBarHidden = [bottomNavBar hidden];
	[bottomNavBar retain];
	[bottomNavBar removeFromSuperview];
	[self setupToolbar];
	[mainView addSubview:bottomNavBar];
	[bottomNavBar release];
	if (lBottomBarHidden) {
		[bottomNavBar hide];
	}
}

- (void)setTextInverted:(BOOL)b 
{
	textInverted = b;
}

- (void)showPrefs:(UINavBarButton *)button 
{
	if (![button isPressed]) // mouseUp only
	{
		GSLog(@"Showing Preferences View");
		PreferencesController *prefsController = [[PreferencesController alloc] initWithAppController:self];
		[prefsButton setEnabled:false];
		[prefsController showPreferences];
	}
}

- (UIWindow *)appsMainWindow {
	return window;
}



- (NSString *)currentBrowserPath {
	return [[navBar topBrowser] path];
}

/**
 * Adjust toolbar to match current inversion status.
 *
 * @param p_orientation UI Orientation - pass -1 to use the current hardware orientation.
 */
- (void)adjustStatusBarColorWithUiOrientation:(int)p_orientation {
	int ori = p_orientation;
	if(p_orientation == -1) {
		ori = [defaults uiOrientation];
	}

	int angle = [self angleForOrientation:ori];

	if ([defaults inverted]) {
		[self setStatusBarMode:3 orientation:angle duration:0.25];
	} else {
		[self setStatusBarMode:0 orientation:angle duration:0.25];
	}
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];

	[m_progressIndicator removeFromSuperview];  
	[m_progressIndicator release];

	[navBar release];
	[bottomNavBar release];
	[mainView release];
	[defaults release];
	[minusButton release];
	[plusButton release];
	[invertButton release];
	[rotateButton release];
	[m_documentExtensions release];
	[super dealloc];
}

/**
 * Callback for the rotation toolbar button to call.
 */
- (void) rotateButtonCallback:(UINavBarButton*) button {
	if (![button isPressed]) {
		BOOL lLockState = [defaults isRotateLocked];
		[defaults setRotateLocked:!lLockState];
		lLockState = !lLockState;	//bcc prefs was change the line above
		BOOL flipped = NO;

		if (lLockState)
		{
			[button setImage:[self navBarImage:@"rotate_lock_up" flipped:flipped] forState:0];
			[button setImage:[self navBarImage:@"rotate_lock_down" flipped:flipped] forState:1];
		}
		else
		{
			[button setImage:[self navBarImage:@"rotate_up" flipped:flipped] forState:0];
			[button setImage:[self navBarImage:@"rotate_down" flipped:flipped] forState:1];
		}

	}	
}

/**
 * Ensure that the preferences screen can't be shown multiple times while the animation is in progress.
 */
- (void) preferenceAnimationDidFinish {
	[prefsButton setEnabled:true];
}

/**
 * Creates a CGImage containing something appropriate to show the next time Books launches.
 *
 * If we're reading a book with a cover image, it's scaled and used.  If we're reading a book
 * without a cover image, we take a screen shot of the book's text.
 * If we're on the file browser, we take a screen shot of it.
 */
- (struct CGImage *)createApplicationDefaultPNG {
	struct CGImage *ret;
	NSString *sCover = [EBookImageView coverArtForBookPath:[defaults lastBrowserPath]];

	const float SHOT_WIDTH  = 320;
	const float SHOT_HEIGHT = 460;
	const int BYTES_PER_PIXEL = 4;

	BOOL bGotShot = NO;
	if([sCover length] > 0) {
		UIImage *img = [UIImage imageAtPath:sCover];
		struct CGImage *imageRef = [img imageRef];

		// We need to resize this to exactly what the phone wants.
		// Image resize code taken from code believed to be GPL attributed
		// to Sean Heber.  (Thanks Sean!!!)

		// Create a new image of the right size (startup code is picky about the Default image size)

		//CGColorSpaceRef space = CGImageGetColorSpace(imageRef);
		CGColorSpaceRef space = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
		/*
		   if(CGColorSpaceGetModel(space) == 5) {
		   GSLog(@"Indexed color image detected");

		   } else
		   */

		CGContextRef bitmap = CGBitmapContextCreate(
				NULL, SHOT_WIDTH, SHOT_HEIGHT, 8,
				//BYTES_PER_PIXEL*SHOT_WIDTH, space, CGImageGetBitmapInfo(imageRef)
				BYTES_PER_PIXEL*SHOT_WIDTH, space, 8198 							//bcc nice magic number someone needs to figure out the correct constant for it
				);
		//GSLog(@"%s: bpc=%d, space=%@, bitmapinfo=%d", _cmd, (int) CGImageGetBitsPerComponent(imageRef), space, (int)CGImageGetBitmapInfo(imageRef));
		CFShow(space);
		if (bitmap)
		{
			//	GSLog(@"%s: bitmap=%d", _cmd, (int)bitmap);
			// Scale it and set for return.
			CGContextDrawImage( bitmap, CGRectMake(0, 0, SHOT_WIDTH, SHOT_HEIGHT), imageRef );
			ret = CGBitmapContextCreateImage( bitmap );
			if (ret)
			{
				//	GSLog(@"%s: ret=%d", _cmd, (int)ret);
				[defaults setStartupIsCover:YES];
				bGotShot = YES;
			}
			else GSLog(@" could not create image");
			CGContextRelease(bitmap);
		} 
		else GSLog(@" could not create context");
		CGColorSpaceRelease(space);
	}

	if(!bGotShot) {
		// Take a screen shot of the top view.
		// We want this if we don't have a cover OR if the cover scaling failed and we're falling back to 
		// a screen shot.
		ret = [mainView createSnapshotWithRect:CGRectMake(0, 0, SHOT_WIDTH, SHOT_HEIGHT)];
		CGImageRetain(ret);
		[defaults setStartupIsCover:NO];
	}

	return ret;
}

/**
 * Called by UIKit when it's time to write out our default image - usually at shutdown.
 */
- (void)_updateDefaultImage {
	// Check for cover art or get a screen shot:
	struct CGImage *imgRef = [self createApplicationDefaultPNG];

	// Find the path to write it to:
  NSString *pathToDefault = [self _pathToDefaultImageNamed:[self nameOfDefaultImageToUpdateAtSuspension]];  

  // Need to create the directory tree.
  NSString *destDirectory = [pathToDefault stringByDeletingLastPathComponent];
  NSArray *pathComponents = [destDirectory pathComponents];
  NSString *pathPart = @"/";

  int i;
  int n = [pathComponents count];
  for(i=0; i < n; i++) {
	  pathPart = [pathPart stringByAppendingPathComponent:[pathComponents objectAtIndex:i]];
	  [[NSFileManager defaultManager] createDirectoryAtPath:pathPart attributes:nil];
  } 

  // Dump a CGImage to file
  NSURL *urlToDefault = [NSURL fileURLWithPath:pathToDefault];
  CGImageDestinationRef dest = CGImageDestinationCreateWithURL((CFURLRef)urlToDefault, CFSTR("public.jpeg")/*kUTTypeJPEG*/, 1, NULL);
  CGImageDestinationAddImage(dest, imgRef, NULL);
  CGImageDestinationFinalize(dest);
  CGImageRelease(imgRef);
}

/**
 * Gets a suffix for the image name to write for startup.
 */
- (id)nameOfDefaultImageToUpdateAtSuspension {
	return @"Default";
}
@end
