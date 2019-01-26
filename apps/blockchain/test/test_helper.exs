ExUnit.configure(timeout: :infinity)
ExUnit.configure(formatters: [ExUnit.CLIFormatter, TestmetricsElixirClient])
ExUnit.start(exclude: :slow)
