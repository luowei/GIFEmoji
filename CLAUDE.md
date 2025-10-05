# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

GIFEmoji (斗图王/GIFMaster) is an iOS app for creating, editing, searching, and sharing GIF animations. Built with Objective-C, it supports converting LivePhotos, videos, and photo collections into GIFs, plus editing and organizing GIF collections.

## Build & Development Commands

### Installing Dependencies
```bash
pod install
```

### Building the App
Open `GIFEmoji.xcworkspace` (NOT the .xcodeproj) in Xcode after running `pod install`.

### Targets
- **GIFEmoji**: Main app target
- **GIFShareExtension**: Share extension for importing media from other apps

## Architecture

### Module Structure
The app follows a feature-based architecture organized into three main modules:

1. **Make** (`GIFEmoji/Make/`) - GIF creation from source media
   - `GenGIFViewController`: Main controller for selecting and generating GIFs from LivePhotos, videos, or photo collections
   - Preview controllers (`LWGIFPreviewViewController`, `LWVideoPreviewViewController`, `LWFramePreviewViewController`) handle different source types
   - Custom views (`LWAVPlayerView`, `LWLivePhotoView`) for media playback

2. **Search** (`GIFEmoji/Search/`) - GIF search and browsing
   - `SearchGIFViewController`: Main search interface for discovering GIFs
   - `LWImageModel`: Data model for GIF metadata
   - `ReportViewController`: Content reporting interface

3. **MyGIF** (`GIFEmoji/MyGIF/`) - Collection management
   - `LWMyGIFViewController`: User's saved/favorited GIF collection
   - `LWCategoriesPopoverViewController`: Category management for organizing GIFs

### Core Components
- **AppDelegate.m**: App initialization, third-party SDK setup (UMeng Analytics, Google Ads, WeChat/QQ sharing)
- **AppDefines.h**: Global constants, macros, and `SelectedMode` enum (LivePhoto/StaticPhotos/Video/GIF modes)
- **Helper/**: Utility categories and helpers including `NSGIF` for GIF generation
- **Common/**: Shared components like web views and services

### Data Storage
- SQLite database named `GIFEmojiData` for persistent storage
- Local file storage in `animoji` directory for saved GIF files

### Third-Party Dependencies (via CocoaPods)
Key libraries embedded in `GIFEmoji/Libs/`:
- **FLAnimatedImage**: High-performance GIF rendering
- **SDWebImage**: Image loading and caching
- **YMSPhotoPicker**: Custom photo picker
- **NSGIF**: Video to GIF conversion
- **OpenShare**: WeChat/QQ social sharing
- **FLEX**: Debug tool (development only)
- **Google-Mobile-Ads-SDK**: Ad integration
- **UMeng** (UMCAnalytics, UMCPush): Analytics and push notifications

### Share Extension
`GIFShareExtension/` provides system-level sharing from other apps:
- `ShareNavigationViewController`: Handles incoming media from iOS share sheet
- `SDAVAssetExportSession`: Video asset export utilities
- Uses Masonry for layout

## Key Implementation Notes

### GIF Generation Modes
The app supports 4 modes defined in `SelectedMode` enum:
- `LivePhotoMode (0)`: Convert LivePhotos to GIF/video
- `StaticPhotosMode (1)`: Create GIF from multiple photos
- `VideoMode (2)`: Extract GIF from video
- `GIFMode (3)`: Edit existing GIF

### Main Tab Structure
UITabBarController with 3 tabs (configured in Main.storyboard):
1. GIF creation (GenGIFViewController)
2. GIF search (SearchGIFViewController)
3. My GIFs collection (LWMyGIFViewController)

### Notifications
Custom notifications for data sync:
- `Notification_CategoryChanged`: Category list updated
- `Notification_FavoriteChanged`: Favorites collection changed

### Social Integration
- WeChat App ID: `wxb4b64828a439e04b`
- QQ App ID: `1106605943`
- Configured in AppDelegate via OpenShare

### iPad Compatibility
Recent commit indicates iPad adaptations for `ActivityController`
