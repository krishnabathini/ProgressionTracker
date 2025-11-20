# App Store Connect Submission Checklist for GitLifting

Use this checklist to ensure all requirements are met before submitting to the App Store.

## 📱 App Information

### Basic Details
- [x] App Name: "GitLifting" (30 characters max) ✓
- [x] Subtitle: "Version Control for Gains" (30 characters max) ✓
- [x] Bundle Identifier: `com.krishnabathini.gitlifting` ✓
- [x] Version: 1.0 ✓
- [x] Build Number: 1 ✓
- [x] Display Name: "GitLifting" ✓

### App Store Listing
- [ ] App Description (4000 chars max) - See `AppStoreMetadata.md`
- [ ] Keywords (100 chars max) - See `AppStoreMetadata.md`
- [ ] Promotional Text (170 chars max) - See `AppStoreMetadata.md`
- [ ] What's New (4000 chars max) - See `AppStoreMetadata.md`
- [ ] Support URL (required)
- [ ] Marketing URL (optional)
- [ ] Privacy Policy URL (required) - See `privacy-policy.md`

## 🎨 Visual Assets

### App Icon
- [ ] App icon 1024x1024 pixels (PNG, no transparency, no rounded corners)
- [ ] App icon meets Apple's design guidelines
- [ ] App icon is unique and recognizable

### Screenshots (Required for each device size)
- [ ] iPhone 6.7" display (iPhone 14 Pro Max, 15 Pro Max, etc.)
  - [ ] At least 1 screenshot (up to 10 allowed)
  - [ ] Screenshots show key features:
    - [ ] Workout program list
    - [ ] Exercise tracking interface
    - [ ] Progression recommendations
    - [ ] Workout history/heatmap
- [ ] iPhone 6.5" display (if supporting older devices)
- [ ] iPad Pro 12.9" (if iPad support is enabled)

### Screenshot Guidelines
- [ ] Screenshots are actual app screens (not mockups)
- [ ] No placeholder text or "Lorem ipsum"
- [ ] Screenshots demonstrate real functionality
- [ ] Screenshots are high quality and clear
- [ ] No device frames (Apple adds these automatically)

## 🔧 Technical Requirements

### Build Configuration
- [x] Bundle identifier updated to `com.krishnabathini.gitlifting` ✓
- [x] Display name set to "GitLifting" ✓
- [x] Version set to 1.0 ✓
- [x] Build number set to 1 ✓
- [x] Info.plist entries configured ✓
- [x] URL scheme updated to `gitlifting://` ✓
- [x] Supported orientations: Portrait only ✓
- [x] Required device capabilities: arm64 ✓

### Code Signing
- [ ] Development team selected
- [ ] Provisioning profile configured
- [ ] Code signing identity set
- [ ] Distribution certificate valid

### App Capabilities
- [ ] Background modes (if any) declared in Info.plist
- [ ] App Transport Security configured (if needed)
- [ ] Required usage descriptions added:
  - [ ] Camera usage (if applicable)
  - [ ] Photo library access (if applicable)
  - [ ] Location services (if applicable)
  - [ ] HealthKit (if applicable)
  - [ ] Notifications permission (for streak reminders)

## 📋 App Store Connect Setup

### App Information
- [ ] App created in App Store Connect
- [ ] Bundle ID matches Xcode project
- [ ] App category selected: Health & Fitness
- [ ] Age rating completed
- [ ] App privacy details completed:
  - [ ] Data collection: None (all data local)
  - [ ] Third-party data sharing: None
  - [ ] Tracking: No

### Pricing and Availability
- [ ] Price tier selected (Free or Paid)
- [ ] Availability countries selected
- [ ] App availability scheduled (if not immediate)

### Version Information
- [ ] Version number: 1.0
- [ ] Copyright information added
- [ ] Trade representative contact (if applicable)
- [ ] App review information:
  - [ ] Contact information
  - [ ] Demo account (if needed)
  - [ ] Review notes explaining any special features

## 🔍 Pre-Submission Testing

### Functionality Testing
- [ ] App launches without crashes
- [ ] All core features work correctly:
  - [ ] Creating workout programs
  - [ ] Adding exercises
  - [ ] Logging sets during workouts
  - [ ] Viewing progression recommendations
  - [ ] Viewing workout history
  - [ ] Streak tracking
  - [ ] GitHub integration (if enabled)
- [ ] No placeholder content visible
- [ ] All navigation works correctly
- [ ] No broken links or missing resources

### Edge Cases
- [ ] App handles empty states gracefully
- [ ] App handles network errors (for GitHub integration)
- [ ] App handles invalid input
- [ ] App handles missing data gracefully
- [ ] No force unwraps causing crashes

### Performance
- [ ] App loads quickly
- [ ] Smooth scrolling and animations
- [ ] No memory leaks
- [ ] Efficient data queries
- [ ] Battery usage is reasonable

### Device Testing
- [ ] Tested on iPhone (latest iOS version)
- [ ] Tested on iPad (if supported)
- [ ] Tested on different screen sizes
- [ ] Tested in portrait orientation
- [ ] Tested with different iOS versions (minimum: iOS 18.1)

## 📝 Legal and Compliance

### Privacy
- [x] Privacy policy created - See `privacy-policy.md` ✓
- [ ] Privacy policy hosted at accessible URL
- [ ] Privacy policy URL added to App Store Connect
- [ ] Privacy policy accurately describes data practices

### Content Guidelines
- [ ] App complies with App Store Review Guidelines
- [ ] No prohibited content
- [ ] No misleading claims
- [ ] Accurate app description
- [ ] No references to beta/alpha status in production

### Intellectual Property
- [ ] All assets are original or properly licensed
- [ ] No trademark violations
- [ ] App name is available and not infringing

## 🚀 Submission Process

### Final Checks
- [ ] All metadata filled in App Store Connect
- [ ] All screenshots uploaded
- [ ] App icon uploaded
- [ ] Privacy policy URL added
- [ ] Support URL added
- [ ] Version information complete
- [ ] Build uploaded via Xcode or Transporter
- [ ] Build processing completed in App Store Connect

### Submission
- [ ] Build selected for submission
- [ ] Version information reviewed
- [ ] "Submit for Review" clicked
- [ ] Submission confirmation received

## 📧 Post-Submission

### Review Process
- [ ] Monitor App Store Connect for review status
- [ ] Respond promptly to any review questions
- [ ] Address any rejection reasons if needed
- [ ] Resubmit if necessary

### After Approval
- [ ] App appears in App Store
- [ ] Test download and installation
- [ ] Monitor for user feedback
- [ ] Prepare for future updates

## 🔗 Required URLs

Before submission, ensure you have:

1. **Privacy Policy URL**: Host `privacy-policy.md` at a publicly accessible URL
   - Example: `https://yourwebsite.com/gitlifting/privacy-policy`
   - Can use GitHub Pages, your own website, or a privacy policy generator

2. **Support URL**: A page where users can contact you
   - Example: `https://yourwebsite.com/gitlifting/support`
   - Or use a contact form, email link, or GitHub issues page

## 📌 Notes

- Replace placeholder email in `privacy-policy.md` before hosting
- Ensure all screenshots are from actual app (not mockups)
- Test the app thoroughly on physical devices before submission
- Review App Store Review Guidelines: https://developer.apple.com/app-store/review/guidelines/
- Check Human Interface Guidelines: https://developer.apple.com/design/human-interface-guidelines/

## ✅ Quick Reference

**Bundle ID**: `com.krishnabathini.gitlifting`  
**App Name**: GitLifting  
**Version**: 1.0  
**Build**: 1  
**Minimum iOS**: 18.1  
**Category**: Health & Fitness  
**Privacy Policy**: Required (see `privacy-policy.md`)  
**Support URL**: Required  

---

**Last Updated**: January 2025

