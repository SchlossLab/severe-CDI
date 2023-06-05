import yaml

def exclude_line(line):
    return line.startswith('<') or line.startswith('<!--') or ('-->' in line)

with open(snakemake.input[0], "r") as infile:
    is_yaml = False
    yaml_block_count = 0
    yaml_text = list()
    is_body = False
    body_text = list()
    for line in infile:
        if line.startswith('---'):
            is_yaml = not is_yaml
            if is_yaml:
                yaml_block_count += 1
        elif is_yaml:
            yaml_text.append(line)
        elif line.startswith('# Acknowledgements'):
            is_body = False
            break # end of body
        elif line.startswith('# Abstract'):
            is_body = True
        elif is_body and not exclude_line(line):
            body_text += line.split()

yaml_dict = yaml.load(''.join(yaml_text), Loader=yaml.CLoader)


with open(snakemake.output[0], "w") as outfile:
    report = list()
    for key in ['abstract', 'importance']:
        if key in yaml_dict.keys():
            word_count = len(yaml_dict[key].split())
            report.append(f"{key}: {word_count}\n")
    report.append(f"body: {len(body_text)}\n")
    outfile.writelines(report)
    for rep in report:
        print(rep)

