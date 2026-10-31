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
        config::DEFAULT_SETTINGS.write().unwrap().insert(
            base::config::keys::OPTION_ACCESS_MODE.to_owned(),
            "full".to_owned(),
        );
        config::DEFAULT_SETTINGS.write().unwrap().insert(
            base::config::keys::OPTION_ALLOW_REMOTE_CONFIG_MODIFICATION.to_owned(),
            "Y".to_owned(),
        );
        config::DEFAULT_SETTINGS.write().unwrap().insert(
            base::config::keys::OPTION_ALLOW_NUMERNIC_ONE_TIME_PASSWORD.to_owned(),
            "Y".to_owned(),
        );
        config::DEFAULT_SETTINGS.write().unwrap().insert(
            base::config::keys::OPTION_TEMPORARY_PASSWORD_LENGTH.to_owned(),
            "6".to_owned(),
        );
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

pub fn technician_identity() -> Option<(String, String)> {
    if config::LocalConfig::get_option("buskit-technician-profile") != "Y" {
        return None;
    }
    let name = config::LocalConfig::get_option("buskit-technician-name");
    let name = if name.trim().is_empty() {
        TECHNICIAN_DISPLAY_NAME.to_owned()
    } else {
        name.trim().to_owned()
    };
    let avatar = format!(
        "data:image/png;base64,{}",
        hbb_common::base64::encode(include_bytes!(
            "../buskit/brand/buskit-soporte-remoto-icon.png"
        ))
    );
    Some((avatar, name))
}
