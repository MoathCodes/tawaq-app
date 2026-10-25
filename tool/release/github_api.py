"""Thin gh wrapper shared by the beta release tools."""
import json
import subprocess


def gh_json(path, *, paginate=False):
    command = ['gh', 'api', path]
    if paginate:
        command.append('--paginate')
    output = subprocess.run(command, check=True, stdout=subprocess.PIPE, text=True).stdout
    if not paginate:
        return json.loads(output)
    # --paginate concatenates one JSON document per page.
    decoder, items, index = json.JSONDecoder(), [], 0
    while index < len(output):
        if output[index].isspace():
            index += 1
            continue
        page, index = decoder.raw_decode(output, index)
        items.append(page)
    return items
