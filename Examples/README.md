# NMSSH Examples

This directory contains example projects demonstrating how to use the NMSSH framework.

## PTYExample

A complete iOS application that demonstrates SSH terminal functionality using NMSSH. The example shows:

- SSH connection establishment
- Interactive terminal session
- Password and key-based authentication
- Real-time command execution

### Building the Example

#### Prerequisites

1. **Xcode** with iOS development tools
2. **Development Team** configured in Xcode for code signing

#### Build Steps

**Option 1: Using Xcode IDE**
1. Open `Examples.xcworkspace` in Xcode
2. Select the PTYExample scheme
3. Choose your target device/simulator
4. Configure signing team in project settings
5. Build and run

**Option 2: Command Line**

First, build the NMSSH framework:
```bash
# Build macOS framework (works on all architectures)
cd /path/to/NMSSH
xcodebuild build -project NMSSH.xcodeproj -scheme NMSSH

# Build iOS framework (requires signing configuration)
xcodebuild build -workspace Examples/Examples.xcworkspace -scheme "NMSSH Framework" -destination 'platform=iOS Simulator,name=iPhone 16'
```

Then build the example:
```bash
cd Examples/PTYExample
xcodebuild build -project PTYExample.xcodeproj -scheme PTYExample -destination 'platform=iOS Simulator,name=iPhone 16'
```

### Known Issues

1. **Code Signing Required**: The iOS example requires a development team to be configured for code signing
2. **Deployment Target**: The example may need iOS deployment target updates for newer Xcode versions
3. **Framework Dependencies**: The example depends on the NMSSH iOS framework being built first

### Using the Example

1. Launch the app
2. Enter SSH server details:
   - Host (e.g., `example.com:22`)
   - Username
   - Choose authentication method (password or key)
3. Tap Connect to establish SSH session
4. Use the terminal interface for command execution

### Code Structure

- `NMViewController` - Main connection interface
- `NMTerminalViewController` - Terminal session handling
- `NMAppDelegate` - Application lifecycle management

## Integration Guide

To integrate NMSSH into your own project:

1. **Add Framework**: Include NMSSH.framework in your project
2. **Import Headers**: Add `#import <NMSSH/NMSSH.h>` to your source files
3. **Basic Usage**:

```objc
// Create session
NMSSHSession *session = [NMSSHSession connectToHost:@"example.com:22" 
                                       withUsername:@"user"];

// Authenticate
if (session.isConnected) {
    [session authenticateByPassword:@"password"];
    
    if (session.isAuthorized) {
        // Execute commands
        NSString *response = [session.channel execute:@"ls -la" error:nil];
        NSLog(@"Response: %@", response);
    }
}

// Cleanup
[session disconnect];
```

## Framework Compatibility

- **macOS**: Builds and runs on all architectures (arm64, x86_64)
- **iOS**: Requires code signing and may need deployment target updates
- **Dependencies**: Uses libssh2 and OpenSSL (included as precompiled binaries)

For more detailed API documentation, see the main project README and the [API documentation](http://cocoadocs.org/docsets/NMSSH/).
