from fsl_cli.tools.file_tools import (
    read_file,
    write_file,
    edit_file,
    delete_file,
    list_directory,
    search_files,
)
from fsl_cli.tools.shell_tools import run_command
from fsl_cli.tools.web_tools import web_search, web_fetch
from fsl_cli.tools.doc_tools import create_excel, create_pdf, create_yaml, create_csv
from fsl_cli.tools.pkg_tools import manage_packages
from fsl_cli.tools.mcp_tools import (
    mcp_add_server,
    mcp_list_servers,
    mcp_call_tool,
    mcp_remove_server,
    mcp_get_tools,
)
from fsl_cli.memory import update_memory

ALL_TOOLS = [
    # filesystem
    read_file,
    write_file,
    edit_file,
    delete_file,
    list_directory,
    search_files,
    # shell
    run_command,
    # package management
    manage_packages,
    # web / research
    web_search,
    web_fetch,
    # document creation
    create_excel,
    create_pdf,
    create_yaml,
    create_csv,
    # MCP
    mcp_add_server,
    mcp_list_servers,
    mcp_call_tool,
    mcp_remove_server,
    mcp_get_tools,
    # memory
    update_memory,
]
