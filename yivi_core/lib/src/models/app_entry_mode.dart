/// How the app was entered: as the user's wallet, or to answer one Digital
/// Credentials API request a browser is waiting on.
///
/// Threaded from the platform entry point down to routing as an enum rather
/// than a boolean, so each call site names which case it is in.
enum AppEntryMode { wallet, dcApiPresentation }
