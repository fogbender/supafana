# This file is also used as runtime dynamic configuration file for release
# So it should follow next restrictions from https://hexdocs.pm/mix/Mix.Tasks.Release.html#module-runtime-configuration:
# It MUST import Config at the top instead of the deprecated use Mix.Config
# It MUST NOT import any other configuration file via import_config
# It MUST NOT access Mix in any way, as Mix is a build tool and it not available inside releases

import Config

import_config "releases.exs"
