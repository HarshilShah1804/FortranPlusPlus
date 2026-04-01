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

    current_state = None

    with open('parser/y.output', 'r') as f:
        for line in f:
            line = line.strip()

            state_match = re.match(r'State (\d+)', line)
            shift_match = re.match(r'(\S+)\s+shift, and go to state (\d+)', line)
            reduce_match = re.match(r'\$default\s+reduce using rule (\d+)', line)
            goto_match = re.match(r'(\S+)\s+go to state (\d+)', line)

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

            # REDUCE
            if reduce_match:
                rule = reduce_match.group(1)
                states[current_state]["actions"]["$"] = "r" + rule
                terminals.add("$")
                continue

            # ACCEPT
            if "accept" in line:
                states[current_state]["actions"]["$"] = "acc"
                terminals.add("$")
                continue

            # GOTO
            if goto_match:
                symbol, target = goto_match.groups()

                if symbol.isupper():
                    states[current_state]["gotos"][symbol] = target
                    non_terminals.add(symbol)
                else:
                    states[current_state]["actions"][symbol] = target
                    terminals.add(symbol)

    terminals_list = sorted(terminals)
    non_terminals_list = sorted(non_terminals)

    header = ["State"] + terminals_list + non_terminals_list

    print("\n=== LALR(1) Parsing Table ===\n")
    print("\t".join(header))

    for state in sorted(states.keys()):
        row = [str(state)]

        # ACTION
        for t in terminals_list:
            row.append(states[state]["actions"].get(t, ""))

        # GOTO
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