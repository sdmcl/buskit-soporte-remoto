use hbb_common::config;
use std::sync::Once;

include!("../buskit/brand.rs");
static INIT: Once = Once::new();

pub fn init() {
    INIT.call_once(|| {
        *config::APP_NAME.write().unwrap() = APP_ID.to_owned();
        let mut options = config::OVERWRITE_SETTINGS.write().unwrap();
        for (key, value) in [
            ("custom-rendezvous-server", ID_SERVER),
            ("relay-server", RELAY_SERVER),
            ("key", PUBLIC_KEY),
            ("api-server", ""),
            ("allow-auto-update", "N"),
        ] {
            options.insert(key.to_owned(), value.to_owned());
        }
        config::DEFAULT_LOCAL_SETTINGS.write().unwrap()
            .insert("lang".to_owned(), "es".to_owned());
        config::OVERWRITE_LOCAL_SETTINGS.write().unwrap()
            .insert("enable-check-update".to_owned(), "N".to_owned());
        let mut hard = config::HARD_SETTINGS.write().unwrap();
        hard.insert("disable-account".to_owned(), "Y".to_owned());
        hard.insert("disable-ab".to_owned(), "Y".to_owned());
        config::BUILTIN_SETTINGS.write().unwrap()
            .insert("register-device".to_owned(), "N".to_owned());
        config::BUILTIN_SETTINGS.write().unwrap()
            .insert("hide-powered-by-me".to_owned(), "Y".to_owned());
    });
}
