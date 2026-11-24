// RobinOS: run Firefox's admin config file (robinos.cfg, next to the firefox binary)
// at startup. It only registers the kit's colours (T-188); the privacy settings
// stay in policies.json.
pref("general.config.filename", "robinos.cfg");
pref("general.config.obscure_value", 0);
pref("general.config.sandbox_enabled", false);
