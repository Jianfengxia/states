import re
import sys
import os


def lint_check_tab_char(paths):
    all_found = {}
    tabpat = re.compile('\t')

    def _find_tab_char(filename):
        found = []
        with open(filename, 'rt') as f:
            for lineno, line in enumerate(f):
                if tabpat.findall(line):
                    found.append(' '.join((str(lineno), line.strip('\n'))))
        return found

    for path in paths:
        found = _find_tab_char(path)
        if found:
            all_found[path] = found

    for fn in all_found:
        print fn
        for line in all_found[fn]:
            print line

    if all_found:
        sys.exit(1)


def process_args():
    filepath = sys.argv[1]
    if os.path.isdir(filepath):
        paths = []
        for root, _, fns in os.walk(filepath):
            for fn in fns:
                if any(fn.endswith(ext) for ext in ('.sls', '.jinja2')):
                    paths.append(os.path.join(root, fn))
    else:
        paths = sys.argv[1:]

    return paths


if __name__ == "__main__":
    paths = process_args()
    lint_check_tab_char(paths)
