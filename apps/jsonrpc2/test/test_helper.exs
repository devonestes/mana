Enum.map([:ranch, :hackney], &Application.ensure_all_started/1)
ExUnit.configure(formatters: [ExUnit.CLIFormatter, TestmetricsElixirClient])
ExUnit.start()
