REQUIRED_KEYS = %w[ BASE_DOMAIN]
DEV_REQUIRED_KEYS = REQUIRED_KEYS + [ "DB_NAME" ]

keys = Rails.env.development? ? DEV_REQUIRED_KEYS : REQUIRED_KEYS

Figaro.require_keys(*keys)
