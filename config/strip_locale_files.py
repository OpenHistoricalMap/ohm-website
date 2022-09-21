#!python3
"""
Strip specific keys entries from all of the .yml files in a directory.
Specify the directory on command line.
Recommended to use a Python virtual env,.

python3 -m venv .

source ./bin/activate
python3 -m pip install ruamel.yaml

python3 ./strip_locale_files.py ./locales
"""

from ruamel.yaml import YAML
import sys
import glob
import re

try:
    folder = sys.argv[1]
    filestoparse = glob.glob(f"{folder}/*.yml")
    if not filestoparse:
        raise ValueError
except IndexError:
    print(f"Usage: {sys.argv[0]} <directoryname>")
    sys.exit(10)
except ValueError:
    print(f"Found no *.yml files in {folder}")
    sys.exit(20)

for filename in filestoparse:
    print(filename)

    # collect the comments and initial --- YAML start; we want to prepend these to the final output
    credits = []
    with open(filename) as fh:
        thisline = fh.readline()
        if thisline.startswith('#') or thisline.startswith('---'):
            credits.append(thisline)
            while True:
                thisline = fh.readline()
                credits.append(thisline)
                if thisline.startswith('---'):
                    break

    # load up, make sure we got exactly one root element
    with open(filename) as fh:
        yamltext = fh.read()
        y = YAML()
        yamlstruct = y.load(yamltext)

    rootname = list(yamlstruct.keys())
    if not rootname or len(rootname) != 1:
        print(f"Found more than one root element: {rootname}")
        sys.exit(30)
    rootname = rootname[0]

    # delete the keys if they exist
    try:
        del yamlstruct[rootname]['site']['copyright']['legal_babble']['credit_3_1_html']
    except KeyError:
        pass
    try:
        del yamlstruct[rootname]['site']['copyright']['legal_babble']['credit_4_html']
    except KeyError:
        pass
    try:
        del yamlstruct[rootname]['site']['copyright']['legal_babble']['more_2_html']
    except KeyError:
        pass
    try:
        del yamlstruct[rootname]['site']['copyright']['legal_babble']['contributors_at_html']
    except KeyError:
        pass
    try:
        del yamlstruct[rootname]['site']['copyright']['legal_babble']['contributors_au_html']
    except KeyError:
        pass
    try:
        del yamlstruct[rootname]['site']['copyright']['legal_babble']['contributors_ca_html']
    except KeyError:
        pass
    try:
        del yamlstruct[rootname]['site']['copyright']['legal_babble']['contributors_fi_html']
    except KeyError:
        pass
    try:
        del yamlstruct[rootname]['site']['copyright']['legal_babble']['contributors_fr_html']
    except KeyError:
        pass
    try:
        del yamlstruct[rootname]['site']['copyright']['legal_babble']['contributors_nl_html']
    except KeyError:
        pass
    try:
        del yamlstruct[rootname]['site']['copyright']['legal_babble']['contributors_nz_html']
    except KeyError:
        pass
    try:
        del yamlstruct[rootname]['site']['copyright']['legal_babble']['contributors_si_html']
    except KeyError:
        pass
    try:
        del yamlstruct[rootname]['site']['copyright']['legal_babble']['contributors_es_html']
    except KeyError:
        pass
    try:
        del yamlstruct[rootname]['site']['copyright']['legal_babble']['contributors_za_html']
    except KeyError:
        pass
    try:
        del yamlstruct[rootname]['site']['copyright']['legal_babble']['contributors_gb_html']
    except KeyError:
        pass

    # write it back out: credits and header, YAML content, footer
    def yaml_string_customizations(rawyamlstring):
        lines = []
        for thisline in rawyamlstring.splitlines(True):
            if re.match(r'^\s+yes: ', thisline):
                thisline = thisline.replace('yes:', '"yes":', 1)

            lines.append(thisline)
        return ''.join(lines)

    with open(filename, 'w', encoding='utf-8') as fh:
        for l in credits:
            fh.write(l)

        yamlout = YAML()
        yamlout.default_flow_style = False
        yamlout.dump(yamlstruct, fh, transform=yaml_string_customizations)

        fh.write("...\n")

# done!
print("DONE")
