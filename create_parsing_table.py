import re
import csv
import os

states = {}
terminals = set()
non_terminals = set()

def create_parse_table():

    if not os.path.exists('parser/y.output'):
        print("Error: parser/y.output not found. Run yacc first.")
        exit(1)

    declared_terminals = set()
    with open('parser/y.output', 'r') as f:
        text = f.read()

    term_section = re.search(
        r'Terminals, with rules where they appear\s*\n(.*?)(?=\nNonterminals,)',
        text, re.DOTALL
    )
    if term_section:
        for line in term_section.group(1).splitlines():
            m = re.match(r'^\s+(\S+)\s+\(\d+\)', line)
            if m:
                declared_terminals.add(m.group(1))
    declared_terminals.add('$end')

    rules = {}   # rule_num -> lhs
    current_lhs = None
    for line in text.splitlines():
        m = re.match(r'^\s+(\d+)\s+(\S+)\s*:', line)
        if m:
            rules[int(m.group(1))] = m.group(2)
            current_lhs = m.group(2)
            continue
        m = re.match(r'^\s+(\d+)\s+\|', line)
        if m and current_lhs:
            rules[int(m.group(1))] = current_lhs

    current_state = None

    default_reduces = {}   # state -> "rN"

    with open('parser/y.output', 'r') as f:
        for line in f:
            line = line.strip()

            state_match  = re.match(r'^State (\d+)$', line)
            shift_match  = re.match(r'^(\S+)\s+shift, and go to state (\d+)', line)
            reduce_match = re.match(r'^(\S+)\s+reduce using rule (\d+)', line)
            default_reduce_match = re.match(r'^\$default\s+reduce using rule (\d+)', line)
            default_accept_match = re.match(r'^\$default\s+accept', line)
            goto_match   = re.match(r'^(\S+)\s+go to state (\d+)', line)

            # STATE
            if state_match:
                current_state = int(state_match.group(1))
                if current_state not in states:
                    states[current_state] = {"actions": {}, "gotos": {}}
                continue

            if current_state is None:
                continue

            # SHIFT
            if shift_match:
                token, target = shift_match.groups()
                states[current_state]["actions"][token] = "s" + target
                terminals.add(token)
                continue

            # $default ACCEPT
            if default_accept_match:
                states[current_state]["actions"]["$end"] = "acc"
                terminals.add("$end")
                continue

            # $default REDUCE  (expand later once all terminals are known)
            if default_reduce_match:
                rule = default_reduce_match.group(1)
                default_reduces[current_state] = "r" + rule
                continue

            # Explicit REDUCE for a specific lookahead
            if reduce_match:
                token, rule = reduce_match.groups()
                if token != "$default":           # $default handled above
                    states[current_state]["actions"][token] = "r" + rule
                    terminals.add(token)
                continue

            # GOTO / shift-on-nonterminal
            if goto_match:
                symbol, target = goto_match.groups()
                if symbol in declared_terminals:
                    # This can happen for terminal "go to" edges (rare) — treat as shift
                    states[current_state]["actions"][symbol] = "s" + target
                    terminals.add(symbol)
                else:
                    states[current_state]["gotos"][symbol] = target
                    non_terminals.add(symbol)

    # --- expand $default reduces across all terminals found ---
    for state, action in default_reduces.items():
        for t in declared_terminals:
            if t not in states[state]["actions"]:
                states[state]["actions"][t] = action
                terminals.add(t)

    terminals_list    = sorted(terminals)
    non_terminals_list = sorted(non_terminals)

    header = ["State"] + terminals_list + non_terminals_list

    print("\n=== LALR(1) Parsing Table ===\n")
    print("\t".join(header))

    for state in sorted(states.keys()):
        row = [str(state)]

        for t in terminals_list:
            row.append(states[state]["actions"].get(t, ""))

        for nt in non_terminals_list:
            row.append(states[state]["gotos"].get(nt, ""))

        print("\t".join(row))

    with open("parsing_table.csv", "w", newline="") as f:
        writer = csv.writer(f)
        writer.writerow(header)

        for state in sorted(states.keys()):
            row = [state]

            for t in terminals_list:
                row.append(states[state]["actions"].get(t, ""))

            for nt in non_terminals_list:
                row.append(states[state]["gotos"].get(nt, ""))

            writer.writerow(row)

    print("\nSaved as parsing_table.csv")


if __name__ == "__main__":
    create_parse_table()