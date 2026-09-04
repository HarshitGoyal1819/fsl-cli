"""Rich theme and colour palette for fsl-cli — Firstsource branding."""

from rich.theme import Theme

FSL_THEME = Theme(
    {
        # Brand colours — Firstsource orange
        "fsl.brand":     "bold #FF6A13",       # Firstsource orange
        "fsl.accent":    "#FF8C42",            # lighter orange
        "fsl.dim":       "dim #8A8A8A",        # muted grey

        # Message roles
        "fsl.user":      "bold #F5A623",       # warm amber (user)
        "fsl.assistant": "bold #FF6A13",       # Firstsource orange
        "fsl.system":    "dim #9CA3AF",        # grey

        # Tool events
        "fsl.tool_name": "bold #FFB347",       # soft amber
        "fsl.tool_ok":   "#34D399",            # green
        "fsl.tool_err":  "bold #F87171",       # red
        "fsl.tool_io":   "dim #D1D5DB",        # light grey

        # Status / misc
        "fsl.success":   "bold #34D399",
        "fsl.warning":   "bold #FBBF24",
        "fsl.error":     "bold #F87171",
        "fsl.info":      "#FFC98A",             # pale orange
        "fsl.border":    "#5A3A1A",             # dark warm brown

        # Code / Markdown
        "markdown.code":  "#E5E7EB on #1F2937",
        "markdown.h1":    "bold #FF6A13",
        "markdown.h2":    "bold #FF8C42",
        "markdown.h3":    "bold #FFB347",
    }
)

SPINNER = "dots"
BORDER_STYLE = "fsl.border"
