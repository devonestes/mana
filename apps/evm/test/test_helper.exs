ExUnit.configure(formatters: [ExUnit.CLIFormatter, TestmetricsElixirClient])
ExUnit.configure(timeout: :infinity)
ExUnit.start()
