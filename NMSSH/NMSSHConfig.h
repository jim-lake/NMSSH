#import "NMSSH.h"

/// -----------------------------------------------------------------------------
/// @name NMSSHHostConfig
/// -----------------------------------------------------------------------------

/**
 NMSSHHostConfig describes a single host's configuration.
 */
@interface NMSSHHostConfig : NSObject
/**
 Patterns specified in the config file.
 */
@property(nonatomic, readonly) NSArray *hostPatterns;

/**
 Specifies the real host name to log into. If the hostname contains the
 character sequence `%h', then the client should replace this with the
 user-specified host name (this is useful for manipulating unqualified names).
 This may be an IP address.
 */
@property(nonatomic, strong) NSString *hostname;

/**
 Specifies the user name to log in as.
 */
@property(nonatomic, strong) NSString *user;

/**
 Specifies the port number to connect on the remote host.
 */
@property(nonatomic, strong) NSNumber *port;

/**
 Specifies a list of file names from which the user's DSA, ECDSA or RSA
 authentication identity are read. It is empty by default. Tildes will be
 expanded to home directories. The client should perform the following
 substitutions on each file name:
   "%d" should be replaced with the local user home directory
   "%u" should be replaced with the local user name
   "%l" should be replaced with the local host name
   "%h" should be replaced with the remote host name
   "%r" should be replaced with the remote user name
 If multiple identities are provided, the client should try them in order.
 */
@property(nonatomic, strong) NSArray *identityFiles;

/** Copies values from {other} unless they are already set. */
- (void)mergeFrom:(NMSSHHostConfig *)other;

@end

/// -----------------------------------------------------------------------------
/// @name NMSSHConfig
/// -----------------------------------------------------------------------------

/**
 NMSSHConfig parses ssh config files and returns matching entries for a given
 host name.
 */
@interface NMSSHConfig : NSObject

/** The array of parsed NMSSHHostConfig objects. */
@property(nonatomic, readonly) NSArray *hostConfigs;

/**
 Creates a new NMSSHConfig, reads the given {filename} and parses it.

 @param filename Path to an ssh config file.
 @returns NMSSHConfig instance or nil if the config file couldn't be parsed.
 */
+ (instancetype)configFromFile:(NSString *)filename;

/**
 Initializes an NMSSHConfig from a config file's contents in a string.

 @param contents A config file's contents.
 @returns An NMSSHConfig object or nil if the contents were malformed.
 */
- (instancetype)initWithString:(NSString *)contents;

/**
 Searches the config for an entry matching {host}.

 @param host A host name to search for.
 @returns An NMSSHHostConfig object whose patterns match host or nil if none is
     found.
 */
- (NMSSHHostConfig *)hostConfigForHost:(NSString *)host;

@end
