#!/usr/bin/env python3
import re
import sys
import os
import tty
import termios

# Toggle debugging output (set to True or pass --debug on the command line)
DEBUG = False

def log_debug(msg):
    if DEBUG:
        print(f"[DEBUG] {msg}", file=sys.stderr)

def prompt_yn(question):
    sys.stderr.write(question)
    sys.stderr.flush()
    fd = sys.stdin.fileno()
    old_settings = termios.tcgetattr(fd)
    try:
        tty.setraw(fd)
        ch = sys.stdin.read(1)
    finally:
        termios.tcsetattr(fd, termios.TCSADRAIN, old_settings)

    # Echo the pressed character and a newline so the terminal output looks clean
    sys.stderr.write(ch + "\n")
    sys.stderr.flush()
    return ch.lower() == 'y'

def parse_script(filepath):
    log_debug(f"Opening and reading script: {filepath}")
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    script_name = os.path.basename(filepath)

    # Count total usage blocks to distinguish multi-command vs single-command scripts
    all_usages = re.findall(r'(?:function\s+)?usage\s*\(\)\s*\{', content)
    total_usages = len(all_usages)
    log_debug(f"Total usage blocks found: {total_usages}")

    # If single-command script (1 or 0 usage blocks)
    if total_usages <= 1:
        log_debug("Single-command script detected. Extracting global flags.")

        optstr_match = re.search(r'OPTSTR=["\']([^"\']+)["\']', content)
        optstr = optstr_match.group(1) if optstr_match else ""

        flag_descs = {}
        echo_lines = re.findall(r'echo\s+(?:-e\s+)?["\'](.*?)["\']', content)
        for eline in echo_lines:
            parts = eline.split('-')
            for part in parts[1:]:
                if len(part) > 0 and part[0].isalpha():
                    flag = part[0]
                    desc = part[1:]
                    desc = re.sub(r'\$\{[A-Z_]+\}|\$\(.*?\)|\\033\[[0-9;]*m|[\\()\n]', '', desc).strip()
                    desc = desc.split('}')[0].strip()
                    if desc and len(desc) < 80 and not desc.startswith('-'):
                        if desc.count('(') > desc.count(')'):
                            desc += ')'
                        flag_descs[flag] = desc

        for char in optstr:
            if char.isalpha() and char not in flag_descs:
                if char == 'H':
                    flag_descs[char] = "help"
                elif char == 'D':
                    flag_descs[char] = "debug"
                else:
                    flag_descs[char] = f"option -{char}"

        if not flag_descs and '-H' in content:
            flag_descs['H'] = "help"

        # Check for explicit file checks (-f, -e, -d) or file-handling helpers
        has_file_inspections = bool(
            re.search(r'\-[efd]\s+["\']?\$', content) or
            '_files' in content or
            'is_file' in content or
            'is_dir' in content
        )

        has_files = False
        if has_file_inspections:
            prompt_text = f"\n[?] Script '{script_name}' contains file inspections (-f/-e/-d). Does it accept file arguments? [y/N]: "
            if prompt_yn(prompt_text):
                has_files = True
                log_debug("User confirmed file arguments are accepted.")
            else:
                log_debug("User indicated no file arguments accepted.")

        return script_name, {'mode': 'single', 'flags': flag_descs, 'has_files': has_files}

    # Multi-command script parsing
    func_pattern = re.compile(r'^([a-z_][a-z0-9_]*)\s*\(\)\s*\{', re.MULTILINE)
    matches = list(func_pattern.finditer(content))
    log_debug(f"Total top-level functions matched: {len(matches)}")

    commands = {}

    for i, match in enumerate(matches):
        func_name = match.group(1)
        start_pos = match.end()
        end_pos = matches[i+1].start() if i + 1 < len(matches) else len(content)
        body = content[start_pos:end_pos]

        log_debug(f"Inspecting function: '{func_name}'")

        # Exclude the container's global usage helper function
        if func_name == 'usage':
            log_debug("-> Skipping 'usage': Container help function.")
            continue

        has_nested_usage = bool(re.search(r'\busage\s*\(\)', body))
        has_desc = 'DESC' in body

        if not (has_nested_usage or has_desc):
            log_debug(f"-> Skipping '{func_name}': Not a subcommand (no nested usage() or DESC).")
            continue

        log_debug(f"-> Valid subcommand found: '{func_name}'")

        desc_match = re.search(r'read\s+-r\s+-d\s+\'\'\s+DESC\s*<<[-_\w]*\s*\n(.*?)\n\s*[-_\w]*', body, re.DOTALL)
        if desc_match:
            description = desc_match.group(1).strip().split('\n')[0]
            description = re.sub(r'^\t+', '', description)
        else:
            description = "No description"

        flag_descs = {}
        echo_lines = re.findall(r'echo\s+(?:-e\s+)?["\'](.*?)["\']', body)
        for eline in echo_lines:
            parts = eline.split('-')
            for part in parts[1:]:
                if len(part) > 0 and part[0].isalpha():
                    flag = part[0]
                    desc = part[1:]
                    desc = re.sub(r'\$\{[A-Z_]+\}|\$\(.*?\)|\\033\[[0-9;]*m|[\\()\n]', '', desc).strip()
                    desc = desc.split('}')[0].strip()
                    if desc and len(desc) < 80 and not desc.startswith('-'):
                        if desc.count('(') > desc.count(')'):
                            desc += ')'
                        flag_descs[flag] = desc

        if not flag_descs and ('-H' in body or '== \'-H\'' in body or '== "-H"' in body):
            flag_descs['H'] = "help"

        has_file_inspections = bool(
            re.search(r'\-[efd]\s+["\']?\$', body) or
            '_files' in body or
            'is_file' in body or
            'is_dir' in body or
            'ARGS' in body
        )

        has_files = False
        if has_file_inspections:
            prompt_text = f"\n[?] Subcommand '{func_name}' in '{script_name}' contains file inspections. Does it accept file arguments? [y/N]: "
            if prompt_yn(prompt_text):
                has_files = True
                log_debug(f"User confirmed file arguments for '{func_name}'.")
            else:
                log_debug(f"User indicated no file arguments for '{func_name}'.")

        commands[func_name] = {
            'description': description,
            'flags': flag_descs,
            'has_files': has_files
        }

    return script_name, {'mode': 'multi', 'commands': commands}

def generate_completion(script_name, data):
    comp_lines = [
        f"#compdef {script_name}",
        f""
    ]

    if data['mode'] == 'single':
        comp_lines.extend([
            f"_{script_name}() {{",
            f"    _arguments -s \\"
        ])
        for flag, fdesc in data['flags'].items():
            safe_fdesc = fdesc.replace('[', '(').replace(']', ')')
            comp_lines.append(f"        '-{flag}[{safe_fdesc}]' \\")

        comp_lines.append("")
        if data['has_files']:
            comp_lines.append("        _files -W ${PWD} ${0}")
        comp_lines.extend([
            "}",
            ""
        ])
        return "\n".join(comp_lines)

    commands = data['commands']
    comp_lines.extend([
        f"_{script_name}() {{",
        f"    local context curcontext=\"$curcontext\" state line",
        f"    typeset -A opt_args",
        f"",
        f"    _arguments -C \\",
        f"\t\t'1: :->cmds' \\",
        f"\t\t'-H[help]' \\",
        f"\t\t'-D[debug]' \\",
        f"\t\t'*::arg:->args'",
        f"    case \"$state\" in",
        f"        cmds)",
        f"\t\t_values 'Commands:' \\"
    ])

    for cmd, info in commands.items():
        safe_desc = info['description'].replace('[', '(').replace(']', ')')
        comp_lines.append(f"\t\t'{cmd}[{safe_desc}]' \\")

    comp_lines.append("\t\t;;")
    comp_lines.append("        args)")
    comp_lines.append("            case $line[1] in")

    for cmd in commands.keys():
        comp_lines.append(f"                {cmd}) _do_{cmd};;")

    comp_lines.append("            esac")
    comp_lines.append("            ;;")
    comp_lines.append("    esac")
    comp_lines.append("}")
    comp_lines.append("")

    for cmd, info in commands.items():
        comp_lines.append(f"_do_{cmd}() {{")
        comp_lines.append("    _arguments -s \\")

        for flag, fdesc in info['flags'].items():
            safe_fdesc = fdesc.replace('[', '(').replace(']', ')')
            comp_lines.append(f"			'-{flag}[{safe_fdesc}]' \\")

        comp_lines.append("")

        if info['has_files']:
            comp_lines.append("\t_files -W ${PWD} ${0}")

        comp_lines.append("}")
        comp_lines.append("")

    return "\n".join(comp_lines)

if __name__ == "__main__":
    if "--debug" in sys.argv:
        DEBUG = True
        sys.argv.remove("--debug")

    if len(sys.argv) < 2:
        print("Usage: python3 mkcomps.py [--debug] <path_to_script>", file=sys.stderr)
        sys.exit(1)

    s_name, parsed_data = parse_script(sys.argv[1])
    if parsed_data['mode'] == 'multi':
        log_debug(f"Parsing complete. Discovered {len(parsed_data['commands'])} subcommands.")
    else:
        log_debug("Parsing complete. Single-command completion generated.")
    print(generate_completion(s_name, parsed_data))
