# frozen_string_literal: true

# Rails reads locale files in alphabetical order. The last file it reads wins.
#
# This puts the OHM locale files at the end of that list, so they win in every
# locale. Rails also picks them up earlier on its own; reading them twice does no
# harm.
#
# The zz_ prefix makes this file run last, after anything else that touches i18n.
Rails.application.config.i18n.load_path += Rails.root.glob("config/locales/overrides/*.yml")
