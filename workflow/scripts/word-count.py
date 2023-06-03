import yaml

with open(snakemake.input[0], "r") as infile:
    is_yaml = False
    yaml_text = list()
    for line in infile:
        if line.startswith('---'):
            is_yaml = not is_yaml
        elif is_yaml:
            yaml_text.append(line)

yaml_dict = yaml.load(''.join(yaml_text), Loader=yaml.CLoader)

with open(snakemake.output[0], "w") as outfile:
    for key in ['abstract', 'importance']:
        if key in yaml_dict.keys():
            word_count = len(yaml_dict[key].split())
            wc_report = f"{key}: {word_count}\n"
            print(wc_report)
            outfile.write(wc_report)
