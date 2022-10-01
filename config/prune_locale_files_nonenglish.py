#!python3
"""
Refer to https://github.com/OpenHistoricalMap/issues/issues/443
Strip specific keys entries from all of the .yml files in a directory.
Specify the directory on command line.
Recommended to use a Python virtual env,.

python3 -m venv .

source ./bin/activate
python3 -m pip install ruamel.yaml

python3 ./prune_locale_files_nonenglish.py ./locales
"""

from ruamel.yaml import YAML
import sys
import glob
import re
import os.path

try:
    folder = sys.argv[1]
    filestoparse = glob.glob(f"{folder}/*.yml")
    filestoparse.sort()
    filestoparse = [i for i in filestoparse if os.path.basename(i) not in ('en-GB.yml', 'en.yml')]
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
        del yamlstruct[rootname]['geocoder']['search_osm_nominatim']['prefix']['aeroway']['apron']
    except KeyError:
        pass
    try:
        del yamlstruct[rootname]['geocoder']['search_osm_nominatim']['prefix']['aeroway']['gate']
    except KeyError:
        pass
    try:
        del yamlstruct[rootname]['geocoder']['search_osm_nominatim']['prefix']['aeroway']['terminal']
    except KeyError:
        pass
    try:
        del yamlstruct[rootname]['geocoder']['search_osm_nominatim']['prefix']['amenity']['fuel']
    except KeyError:
        pass
    try:
        del yamlstruct[rootname]['geocoder']['search_osm_nominatim']['prefix']['amenity']['gambling']
    except KeyError:
        pass
    try:
        del yamlstruct[rootname]['geocoder']['search_osm_nominatim']['prefix']['amenity']['grave_yard']
    except KeyError:
        pass
    try:
        del yamlstruct[rootname]['geocoder']['search_osm_nominatim']['prefix']['amenity']['grit_bin']
    except KeyError:
        pass
    try:
        del yamlstruct[rootname]['geocoder']['search_osm_nominatim']['prefix']['landuse']['conservation']
    except KeyError:
        pass
    try:
        del yamlstruct[rootname]['geocoder']['search_osm_nominatim']['prefix']['landuse']['construction']
    except KeyError:
        pass
    try:
        del yamlstruct[rootname]['geocoder']['search_osm_nominatim']['prefix']['landuse']['retail']
    except KeyError:
        pass
    try:
        del yamlstruct[rootname]['geocoder']['search_osm_nominatim']['prefix']['shop']['doityourself']
    except KeyError:
        pass
    try:
        del yamlstruct[rootname]['geocoder']['search_osm_nominatim']['prefix']['shop']['hifi']
    except KeyError:
        pass
    try:
        del yamlstruct[rootname]['geocoder']['search_osm_nominatim']['prefix']['tourism']['cabin']
    except KeyError:
        pass
    try:
        del yamlstruct[rootname]['layouts']['intro_text']
    except KeyError:
        pass
    try:
        del yamlstruct[rootname]['layouts']['intro_1']
    except KeyError:
        pass
    try:
        del yamlstruct[rootname]['layouts']['partners_title']
    except KeyError:
        pass
    try:
        del yamlstruct[rootname]['layouts']['hosting_partners_html']
    except KeyError:
        pass
    try:
        del yamlstruct[rootname]['site']['about']['used_by_html']
    except KeyError:
        pass
    try:
        del yamlstruct[rootname]['site']['about']['lede_text']
    except KeyError:
        pass
    try:
        del yamlstruct[rootname]['site']['about']['local_knowledge_html']
    except KeyError:
        pass
    try:
        del yamlstruct[rootname]['site']['about']['community_driven_html']
    except KeyError:
        pass
    try:
        del yamlstruct[rootname]['site']['about']['open_data_html']
    except KeyError:
        pass
    try:
        del yamlstruct[rootname]['site']['about']['legal_1_html']
    except KeyError:
        pass
    try:
        del yamlstruct[rootname]['site']['about']['legal_2_html']
    except KeyError:
        pass
    try:
        del yamlstruct[rootname]['site']['copyright']['legal_babble']['title_html']
    except KeyError:
        pass
    try:
        del yamlstruct[rootname]['site']['copyright']['legal_babble']['intro_1_html']
    except KeyError:
        pass
    try:
        del yamlstruct[rootname]['site']['copyright']['legal_babble']['intro_2_html']
    except KeyError:
        pass
    try:
        del yamlstruct[rootname]['site']['copyright']['legal_babble']['intro_3_1_html']
    except KeyError:
        pass
    try:
        del yamlstruct[rootname]['site']['copyright']['legal_babble']['credit_title_html']
    except KeyError:
        pass
    try:
        del yamlstruct[rootname]['site']['copyright']['legal_babble']['credit_1_html']
    except KeyError:
        pass
    try:
        del yamlstruct[rootname]['site']['copyright']['legal_babble']['credit_2_1_html']
    except KeyError:
        pass
    try:
        del yamlstruct[rootname]['site']['copyright']['legal_babble']['attribution_example']['alt']
    except KeyError:
        pass
    try:
        del yamlstruct[rootname]['site']['copyright']['legal_babble']['more_1_html']
    except KeyError:
        pass
    try:
        del yamlstruct[rootname]['site']['copyright']['legal_babble']['contributors_title_html']
    except KeyError:
        pass
    try:
        del yamlstruct[rootname]['site']['copyright']['legal_babble']['contributors_intro_html']
    except KeyError:
        pass
    try:
        del yamlstruct[rootname]['site']['copyright']['legal_babble']['contributors_cambridge-anr_html']
    except KeyError:
        pass
    try:
        del yamlstruct[rootname]['site']['copyright']['legal_babble']['contributors_ned_html']
    except KeyError:
        pass
    try:
        del yamlstruct[rootname]['site']['copyright']['legal_babble']['contributors_newberry_html']
    except KeyError:
        pass
    try:
        del yamlstruct[rootname]['site']['copyright']['legal_babble']['contributors_footer_1_html']
    except KeyError:
        pass
    try:
        del yamlstruct[rootname]['site']['copyright']['legal_babble']['contributors_footer_2_html']
    except KeyError:
        pass
    try:
        del yamlstruct[rootname]['site']['copyright']['legal_babble']['infringement_2_html']
    except KeyError:
        pass
    try:
        del yamlstruct[rootname]['site']['copyright']['legal_babble']['trademarks_title_html']
    except KeyError:
        pass
    try:
        del yamlstruct[rootname]['site']['copyright']['legal_babble']['trademarks_1_html']
    except KeyError:
        pass
    try:
        del yamlstruct[rootname]['site']['export']['export_details_html']
    except KeyError:
        pass
    try:
        del yamlstruct[rootname]['site']['help']['welcome']['title']
    except KeyError:
        pass
    try:
        del yamlstruct[rootname]['site']['help']['welcome']['description']
    except KeyError:
        pass
    try:
        del yamlstruct[rootname]['site']['help']['beginners_guide']['url']
    except KeyError:
        pass
    try:
        del yamlstruct[rootname]['site']['help']['beginners_guide']['title']
    except KeyError:
        pass
    try:
        del yamlstruct[rootname]['site']['help']['beginners_guide']['description']
    except KeyError:
        pass
    try:
        del yamlstruct[rootname]['site']['help']['mailing_lists']['url']
    except KeyError:
        pass
    try:
        del yamlstruct[rootname]['site']['help']['mailing_lists']['title']
    except KeyError:
        pass
    try:
        del yamlstruct[rootname]['site']['help']['mailing_lists']['description']
    except KeyError:
        pass
    try:
        del yamlstruct[rootname]['site']['help']['irc']['url']
    except KeyError:
        pass
    try:
        del yamlstruct[rootname]['site']['help']['irc']['title']
    except KeyError:
        pass
    try:
        del yamlstruct[rootname]['site']['help']['irc']['description']
    except KeyError:
        pass
    try:
        del yamlstruct[rootname]['site']['help']['switch2osm']['url']
    except KeyError:
        pass
    try:
        del yamlstruct[rootname]['site']['help']['switch2osm']['title']
    except KeyError:
        pass
    try:
        del yamlstruct[rootname]['site']['help']['switch2osm']['description']
    except KeyError:
        pass
    try:
        del yamlstruct[rootname]['site']['help']['wiki']['url']
    except KeyError:
        pass
    try:
        del yamlstruct[rootname]['site']['help']['wiki']['title']
    except KeyError:
        pass
    try:
        del yamlstruct[rootname]['site']['help']['wiki']['description']
    except KeyError:
        pass
    try:
        del yamlstruct[rootname]['site']['welcome']['introduction_html']
    except KeyError:
        pass
    try:
        del yamlstruct[rootname]['site']['welcome']['whats_on_the_map']['on_html']
    except KeyError:
        pass
    try:
        del yamlstruct[rootname]['site']['welcome']['whats_on_the_map']['off_html']
    except KeyError:
        pass
    try:
        del yamlstruct[rootname]['site']['welcome']['basic_terms']['paragraph_1_html']
    except KeyError:
        pass
    try:
        del yamlstruct[rootname]['site']['welcome']['rules']['paragraph_1_html']
    except KeyError:
        pass
    try:
        del yamlstruct[rootname]['site']['welcome']['questions']['paragraph_1_html']
    except KeyError:
        pass
    try:
        del yamlstruct[rootname]['javascripts']['map']['copyright']
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
