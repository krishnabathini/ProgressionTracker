# Privacy Policy for GitLifting

**Last Updated:** January 2025

## Introduction

GitLifting ("we," "our," or "the app") is committed to protecting your privacy. This Privacy Policy explains how we handle information when you use our iOS application.

## Data Collection

**GitLifting does not collect, store, or transmit any personal data to external servers.**

All workout data, including:
- Workout programs and exercises
- Sets, weights, and repetitions
- Workout history and dates
- Personal records and progress metrics

is stored **exclusively on your device** using Apple's SwiftData framework. This data never leaves your device unless you explicitly choose to use the optional GitHub integration feature.

## No User Accounts

GitLifting does not require user accounts or registration. There is no authentication system, and we do not collect email addresses, usernames, or any other identifying information.

## No Analytics or Tracking

GitLifting does not use:
- Analytics services
- Advertising networks
- Third-party tracking
- Crash reporting services (except Apple's built-in crash reporting)
- User behavior analytics

## Optional GitHub Integration

GitLifting offers an optional feature to sync workout data to your own GitHub repository. This feature:

- Requires explicit user authentication via GitHub OAuth
- Only activates when you choose to enable it
- Stores workout data in repositories you own and control
- Uses GitHub's standard OAuth scopes (`public_repo` and `user:email`)
- Stores authentication tokens securely in your device's Keychain

When you use this feature, your workout data is subject to GitHub's privacy policy and terms of service. You can revoke access at any time through GitHub's settings or by signing out within the app.

## Local Data Storage

All workout data is stored locally on your device using:
- **SwiftData**: Apple's local database framework for workout programs, exercises, and sessions
- **UserDefaults**: For app preferences and settings (repository name, auto-log toggle)
- **Keychain**: For secure storage of GitHub OAuth tokens (only if you use GitHub integration)

## Data Deletion

When you uninstall GitLifting:
- All local workout data is automatically deleted
- All app preferences are removed
- GitHub OAuth tokens stored in Keychain are removed

To manually clear all data, you can uninstall and reinstall the app.

## Bug Reports

GitLifting includes an optional bug reporting feature that:
- Sends bug reports to Firebase Firestore (cloud database)
- Includes device metadata (app version, device model, iOS version, timestamp)
- Sends notifications to a Slack channel for development purposes
- Does not include any personal workout data
- Is completely optional and only sent when you explicitly submit a bug report

## Children's Privacy

GitLifting is not intended for children under the age of 13. We do not knowingly collect information from children.

## Changes to This Privacy Policy

We may update this Privacy Policy from time to time. Any changes will be reflected in the app's update notes and this document.

## Contact Us

If you have questions about this Privacy Policy or our data practices, please contact us at:

**Email:** kbathini12@gmail.com


## Your Rights

Since all data is stored locally on your device:
- You have complete control over your workout data
- You can delete all data by uninstalling the app
- You can export data through the optional GitHub integration
- No third parties have access to your data

## Compliance

This Privacy Policy complies with:
- Apple's App Store Review Guidelines
- General Data Protection Regulation (GDPR) principles
- California Consumer Privacy Act (CCPA) requirements

---

**Summary:** GitLifting is designed with privacy as a core principle. Your workout data stays on your device, and we don't collect, track, or sell any information about you. The optional GitHub integration uses your own repositories and requires explicit opt-in.

