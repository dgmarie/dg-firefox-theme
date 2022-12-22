/* user.js
 * https://github.com/dgsasha/dg-firefox-theme/
 */

// Enable customChrome.css
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);

// Set UI density to normal
user_pref("browser.uidensity", 0);

// Enable SVG context-propertes
user_pref("svg.context-properties.content.enabled", true);

// Don't force dark theme in private windows
user_pref("browser.theme.dark-private-windows", false);

// Default to having settings pages themed
user_pref("qualia.themeSettingsPages", true);