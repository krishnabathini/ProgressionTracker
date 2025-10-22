# GitHub OAuth Scopes - Privacy-First Approach

## ✅ Reduced to Minimal Necessary Permissions

### Previous (Overly Broad) Scopes
```
❌ repo    - Full access to ALL repositories (public AND private)
❌ user    - Full access to ALL user data
```

**Problems:**
- Access to private repositories (unnecessary)
- Access to all user data (privacy concern)
- Broader permissions than needed
- User trust issues

---

### New (Minimal) Scopes
```
✅ public_repo  - Create/write to PUBLIC repositories ONLY
✅ user:email   - Basic profile info (email, username, avatar)
```

**Benefits:**
- ✅ No access to private repositories
- ✅ Only basic profile information
- ✅ Minimal permissions principle
- ✅ Better user trust and privacy
- ✅ Transparent about what we access

---

## 🔐 Scope Comparison

| Permission | Old Scope | New Scope | What It Allows |
|------------|-----------|-----------|----------------|
| Private repos | ✅ Yes (`repo`) | ❌ No | Old had access to all private repos |
| Public repos | ✅ Yes (`repo`) | ✅ Yes (`public_repo`) | Both can create public repos |
| Full user data | ✅ Yes (`user`) | ❌ No | Old had access to all user info |
| Email & profile | ✅ Yes (`user`) | ✅ Yes (`user:email`) | Both have basic profile access |
| **Privacy Level** | 🔴 Low | 🟢 High | New is much more privacy-focused |

---

## 📊 What Each Scope Provides

### `public_repo` (Repository Access)
**Grants access to:**
- ✅ Create new public repositories
- ✅ Read public repository content
- ✅ Write/commit to public repositories
- ✅ Create branches and tags in public repos

**Does NOT grant access to:**
- ❌ Private repositories (read or write)
- ❌ Delete repositories
- ❌ Change repository settings
- ❌ Manage repository collaborators

**Why we need it:**
- Create the `workout-tracker` public repository
- Commit workout logs as markdown files
- Update existing workout files

---

### `user:email` (Profile Access)
**Grants access to:**
- ✅ User's public profile information (username, name, avatar)
- ✅ User's email address
- ✅ Basic account information

**Does NOT grant access to:**
- ❌ Private user data
- ❌ Organization memberships
- ❌ Follow/unfollow actions
- ❌ User's starred repositories
- ❌ User's gists

**Why we need it:**
- Display user's name and avatar in the app
- Identify the user for repository operations
- Show who is logged in

---

## 🎯 Privacy-First Design Principles

### 1. Minimal Permissions
Only request what's absolutely necessary for core functionality.

```swift
// We ask for:
let scopes = "public_repo user:email"

// NOT:
let scopes = "repo user admin:org delete_repo"  // ❌ Way too much!
```

### 2. Transparent Communication
Clearly explain what permissions are requested and why.

**In the UI:**
- ✅ "Public Repositories" - Create and write to public workout tracker repo only
- ✅ "Basic Profile" - Your email and public profile information

### 3. User Control
Users maintain full control of their data:
- Repository is in their account
- They can delete it anytime
- They can revoke access anytime
- No app access to private data

### 4. Secure Storage
- Tokens stored in iOS Keychain (device-only)
- No cloud sync of tokens
- Deleted when app is uninstalled
- User can sign out to clear token

---

## 🔍 Scope Verification

### How to Verify Scopes Being Requested

1. **Check Console Output:**
```
🔐 Requesting minimal OAuth scopes: public_repo user:email
```

2. **During Authorization:**
When user authorizes on GitHub, they'll see:
```
GitLifting is requesting permission to:
✓ Access public repositories
✓ Know your email address
```

3. **In GitHub Settings:**
After authorization, user can verify at:
`Settings → Applications → Authorized OAuth Apps → GitLifting`

---

## 📱 User-Facing Communication

### What Users See in the App

#### **Permissions Section:**
```
Minimal Permissions Requested:

📄 Public Repositories
   Create and write to public workout tracker repo only

👤 Basic Profile
   Your email and public profile information
```

#### **Privacy Notice:**
```
🔒 Privacy First
We request minimal permissions. No access to private repos or 
sensitive data. Your workout data stays in your control.
```

---

## 🛡️ Security & Privacy Features

### What We DON'T Have Access To

❌ **Private Repositories**
- Cannot read, write, or access any private repos
- Only public repos that we create

❌ **Sensitive User Data**
- No access to SSH keys
- No access to GPG keys
- No access to payment information
- No access to organization memberships

❌ **Repository Management**
- Cannot delete repositories
- Cannot transfer repositories
- Cannot change repository settings
- Cannot manage collaborators

❌ **Account Control**
- Cannot change user settings
- Cannot follow/unfollow users
- Cannot create/delete repos on behalf of user (except workout-tracker)
- Cannot access user's stars or watches

### What We DO Have Access To

✅ **Public Workout Repository**
- Create `workout-tracker` public repo
- Write workout logs as markdown files
- Read repository content

✅ **Basic Profile**
- Username (to display in app)
- Name (to show who's logged in)
- Avatar (to personalize UI)
- Email (basic contact info)

---

## 🔄 Comparison with Other Apps

| App Type | Typical Scopes | GitLifting Scopes | Privacy Level |
|----------|---------------|-------------------|---------------|
| Code Editors (VS Code) | `repo`, `user`, `gist`, `workflow` | `public_repo`, `user:email` | 🟢 Much Better |
| CI/CD Tools | `repo`, `admin:repo_hook`, `user` | `public_repo`, `user:email` | 🟢 Much Better |
| Project Management | `repo`, `read:org`, `user` | `public_repo`, `user:email` | 🟢 Much Better |
| GitLifting | - | `public_repo`, `user:email` | 🟢 Minimal |

---

## 📋 Implementation Details

### Authorization URL Structure

```swift
https://github.com/login/oauth/authorize?
    client_id=Ov23livLsewsXSLD10qj
    &redirect_uri=progressiontracker://oauth
    &scope=public_repo%20user:email
    &state=random_string
```

### Scope String Format
```swift
// Scopes separated by space
let scopes = "public_repo user:email"

// NOT comma-separated for GitHub OAuth
// let scopes = "public_repo,user:email"  ❌ Wrong!
```

### Code Location
```swift
// File: GitHubAuthService.swift
// Method: generateAuthorizationURL()

let scopes = "public_repo user:email"
components.queryItems = [
    URLQueryItem(name: "scope", value: scopes)
]
```

---

## 🎓 Best Practices Applied

### ✅ 1. Principle of Least Privilege
Only request permissions absolutely necessary for core functionality.

### ✅ 2. Defense in Depth
Even if token is compromised, damage is minimal (only public repos).

### ✅ 3. Transparency
Users know exactly what they're granting access to.

### ✅ 4. User Control
Users can revoke access anytime from GitHub settings.

### ✅ 5. Secure Storage
Tokens stored in iOS Keychain with device-only access.

---

## 🧪 Testing the Scope Reduction

### Manual Testing Steps

1. **Sign out** (if already authenticated)
2. **Tap "Connect to GitHub"**
3. **Observe GitHub authorization page:**
   - Should see "Access public repositories"
   - Should see "Know your email address"
   - Should NOT see "Access private repositories"
4. **Authorize the app**
5. **Verify in GitHub:**
   - Go to Settings → Applications → Authorized OAuth Apps
   - Click on GitLifting
   - Should show: `public_repo`, `user:email`

### Automated Verification

```swift
// Check console output:
🔐 Requesting minimal OAuth scopes: public_repo user:email

// After authorization, check token response:
// The scope field should contain: "public_repo,user:email"
```

---

## 📞 User Support - FAQs

### "Why does GitLifting need access to my repositories?"

We need to create a public `workout-tracker` repository to log your workouts. We only have access to **public** repositories, not your private ones.

### "Can GitLifting access my private code?"

**No.** We only request access to public repositories. Your private repositories are completely inaccessible to GitLifting.

### "What user data does GitLifting collect?"

Only your:
- Username (to display in the app)
- Name (optional, from GitHub profile)
- Avatar (to show your profile picture)
- Email (to identify you)

We do NOT collect or access any sensitive data.

### "Can I revoke access later?"

**Yes!** Go to GitHub Settings → Applications → Authorized OAuth Apps → GitLifting → Revoke Access. You can revoke access anytime.

### "Will GitLifting modify my existing repositories?"

**No.** GitLifting only creates and writes to a new public repository called `workout-tracker`. Your existing repositories are never touched.

---

## 🔐 Security Checklist

- [x] Reduced to minimal necessary scopes
- [x] No access to private repositories
- [x] No access to sensitive user data
- [x] Clear communication in UI
- [x] Tokens stored securely in Keychain
- [x] Users can revoke access anytime
- [x] Transparent about permissions
- [x] Documented for auditing
- [x] Follows OAuth best practices
- [x] Privacy-first design

---

## 📚 References

### GitHub OAuth Scopes Documentation
https://docs.github.com/en/developers/apps/building-oauth-apps/scopes-for-oauth-apps

### Relevant Scopes:
- `public_repo`: Access public repositories
- `user:email`: Access user email addresses (read-only)

### Alternative Scope Combinations Considered:

| Combination | Pros | Cons | Chosen? |
|-------------|------|------|---------|
| `repo`, `user` | Full access | Too broad, privacy concerns | ❌ |
| `public_repo`, `user` | Public repos + full user data | User data too broad | ❌ |
| `public_repo`, `user:email` | Minimal necessary | Most privacy-focused | ✅ |
| `repo`, `user:email` | Private repo access | Unnecessary private access | ❌ |

---

## ✨ Summary

**Previous Scopes:**
```
repo user  (Broad access to everything)
```

**New Scopes:**
```
public_repo user:email  (Minimal necessary access)
```

**Impact:**
- 🔒 **Better Privacy** - No access to private repos or sensitive data
- 🎯 **Minimal Permissions** - Only what's absolutely necessary
- 💚 **User Trust** - Clear and transparent about access
- ✅ **Still Functional** - Can create and log to workout repository

---

**Updated:** October 21, 2025  
**Change:** Reduced OAuth scopes from `repo user` to `public_repo user:email`  
**Reason:** Privacy-first design, minimal permissions principle  
**Status:** ✅ Implemented and documented

