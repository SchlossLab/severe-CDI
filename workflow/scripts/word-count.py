import yaml

log_txt = list()

def exclude_line(line):
    return line.startswith('<') or ('-->' in line)

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
        elif line.startswith('# References'):
            is_body = False
            break # end of body, stop parsing file
        elif line.startswith('<div') or (line.startswith('<!--') and not ('-->' in line)):
            is_body = False # toggle off for divs and block comments
        elif line.startswith('# Introduction') or line.startswith('</div') or ('-->' in line):
            is_body = True # toggle on for introduction and ends of divs and comments
        elif is_body and not exclude_line(line):
            log_txt.append(f'{line}')
            body_text += line.split()

yaml_dict = yaml.load(''.join(yaml_text), Loader=yaml.CLoader)

report = list()
for key in ['abstract', 'importance']:
    if key in yaml_dict.keys():
        word_count = len(yaml_dict[key].split())
        report.append(f"{key}: {word_count}\n")
report.append(f"body: {len(body_text)}\n")

with open(snakemake.output[0], "w") as outfile:
    outfile.writelines(report)

with open(snakemake.log[0], 'w') as logfile:
    logfile.write("REPORT\n")
    logfile.writelines(report)
    logfile.write('\nBODY LINES\n')
    logfile.writelines(log_txt)
