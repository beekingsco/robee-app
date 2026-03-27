# RoBee App — Developer Setup Guide

## Prerequisites (already installed on Mac Studio)
- Flutter 3.41.6 ✅
- Xcode 26.3 ✅
- CocoaPods 1.16.2 ✅

## 1. Clone the repo
```bash
git clone https://github.com/beekingsco/robee-app.git
cd robee-app
```

## 2. Set PATH (Mac Studio only — already in ~/.zshrc)
```bash
export PATH="/opt/homebrew/lib/ruby/gems/4.0.0/bin:/opt/homebrew/opt/ruby/bin:/opt/homebrew/bin:$PATH"
```

## 3. Install dependencies
```bash
flutter pub get
cd ios && pod install && cd ..
```

## 4. Configure environment
Create a `.env` file in the project root:
```
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_supabase_anon_key
STRIPE_PUBLISHABLE_KEY=your_stripe_publishable_key
```

## 5. Run on simulator
```bash
# List available simulators
flutter devices

# Run on iPhone simulator
flutter run -d "iPhone 16"
```

## 6. Build for TestFlight

### One-time setup
1. Open Xcode: `open ios/Runner.xcworkspace`
2. Select the **Runner** target
3. Under **Signing & Capabilities**:
   - Team: select Chris Miller's Apple Developer account
   - Bundle Identifier: `com.beekings.robee`
4. Close Xcode

### Build and upload
```bash
# Build release IPA
flutter build ipa --release

# The IPA will be at:
# build/ios/ipa/robee_app.ipa

# Upload to TestFlight via Xcode Organizer:
# 1. Open Xcode → Window → Organizer
# 2. Select the RoBee archive
# 3. Click "Distribute App" → App Store Connect → Upload
```

### App Store Connect setup (one-time)
1. Go to appstoreconnect.apple.com
2. Create new app: "RoBee"
3. Bundle ID: com.beekings.robee
4. SKU: robee-2026
5. After upload, go to TestFlight tab and add internal testers

## 7. Add testers to TestFlight
- Chris Miller (chris@beekings.com)
- Darren Thomas
- Marie Lambert
- Any other team members

## Troubleshooting
- `pod install` fails → make sure PATH includes Homebrew Ruby (`export PATH="/opt/homebrew/opt/ruby/bin:$PATH"`)
- Signing errors → open `ios/Runner.xcworkspace` in Xcode and set team manually
- Flutter not found → run `export PATH="/opt/homebrew/bin:$PATH"` first
